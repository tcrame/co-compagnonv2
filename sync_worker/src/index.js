import { neon } from '@neondatabase/serverless';
import { createRemoteJWKSet, jwtVerify } from 'jose';

// --- UTILITAIRES CORS ET RÉPONSES ---
function corsHeaders(origin = '*') {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization', // Ajout de Authorization
    'Content-Type': 'application/json',
  };
}

function jsonResponse(body, status = 200, origin = '*') {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders(origin),
  });
}

function parseOrigin(request, env) {
  const requestOrigin = request.headers.get('Origin');
  if (!requestOrigin) return env.ALLOWED_ORIGIN || '*';
  if (env.ALLOWED_ORIGIN === '*' || !env.ALLOWED_ORIGIN) return '*';
  return requestOrigin === env.ALLOWED_ORIGIN ? requestOrigin : env.ALLOWED_ORIGIN;
}

// --- AUTHENTIFICATION JWT ---
async function verifyGoogleToken(request, env) {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Token manquant ou mal formaté');
  }

  const token = authHeader.split(' ')[1];
  const JWKS = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));

  // env.GOOGLE_CLIENT_ID doit être ajouté dans vos variables d'environnement Cloudflare !
  const { payload } = await jwtVerify(token, JWKS, {
    issuer: ['https://accounts.google.com', 'accounts.google.com'],
    audience: env.GOOGLE_CLIENT_ID,
  });

  return payload; // Retourne l'identité Google (sub, email, etc.)
}

// --- GESTION DE LA BASE DE DONNÉES ---
async function ensureSchema(sql) {
  // Table Utilisateurs
  await sql`
    CREATE TABLE IF NOT EXISTS users (
      user_id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      role TEXT DEFAULT 'free',
      created_at TIMESTAMPTZ DEFAULT now()
    )
  `;

  // Table Personnages (Mise à jour : suppression du mdp, ajout du user_id)
  await sql`
    CREATE TABLE IF NOT EXISTS character_sync (
      sync_uuid TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(user_id),
      character_blob JSONB NOT NULL,
      last_modified_at TIMESTAMPTZ NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;
}

async function upsertUserAndGetRole(googleUser, sql) {
  // Insère l'utilisateur s'il n'existe pas, sinon ne fait rien
  await sql`
    INSERT INTO users (user_id, email)
    VALUES (${googleUser.sub}, ${googleUser.email})
    ON CONFLICT (user_id) DO NOTHING
  `;

  // Récupère son rôle
  const rows = await sql`SELECT role FROM users WHERE user_id = ${googleUser.sub}`;
  return rows[0].role;
}

// --- ROUTES ---
async function handlePush(payload, googleUser, role, sql, origin) {
  const { sync_uuid, character_blob, last_modified_at } = payload;
  if (!sync_uuid || !character_blob || !last_modified_at) {
    return jsonResponse({ error: 'Données incomplètes' }, 400, origin);
  }

  // Vérification des quotas
  const existingChar = await sql`SELECT sync_uuid FROM character_sync WHERE sync_uuid = ${sync_uuid} AND user_id = ${googleUser.sub}`;

  if (existingChar.length === 0) {
    // C'est un nouveau personnage, on vérifie le quota
    const countRes = await sql`SELECT COUNT(*) FROM character_sync WHERE user_id = ${googleUser.sub}`;
    const currentCount = parseInt(countRes[0].count, 10);
    const limit = role === 'premium' ? 10 : 3; // 3 persos max en gratuit, 10 en premium

    if (currentCount >= limit) {
      return jsonResponse({ error: `Quota dépassé (${limit} max). Passez Premium !` }, 403, origin);
    }
  }

  // Insertion ou mise à jour
  await sql`
    INSERT INTO character_sync(sync_uuid, user_id, character_blob, last_modified_at, updated_at)
    VALUES (${sync_uuid}, ${googleUser.sub}, ${JSON.stringify(character_blob)}::jsonb, ${last_modified_at}::timestamptz, now())
    ON CONFLICT (sync_uuid) DO UPDATE SET
      character_blob = EXCLUDED.character_blob,
      last_modified_at = EXCLUDED.last_modified_at,
      updated_at = now()
  `;

  return jsonResponse({ ok: true, sync_uuid }, 200, origin);
}

async function handlePull(payload, googleUser, sql, origin) {
  const { sync_uuid } = payload;
  if (!sync_uuid) return jsonResponse({ error: 'sync_uuid requis' }, 400, origin);

  // On vérifie que le personnage appartient bien à ce user_id
  const rows = await sql`
    SELECT character_blob, last_modified_at
    FROM character_sync
    WHERE sync_uuid = ${sync_uuid} AND user_id = ${googleUser.sub}
    LIMIT 1
  `;

  if (rows.length === 0) return jsonResponse({ error: 'Personnage introuvable ou non autorisé' }, 404, origin);

  return jsonResponse({
    ok: true,
    sync_uuid,
    character_blob: rows[0].character_blob,
    last_modified_at: rows[0].last_modified_at,
  }, 200, origin);
}

async function handleList(googleUser, role, sql, origin) {
  // On ne liste QUE les personnages du compte connecté
  const rows = await sql`
    SELECT sync_uuid, character_blob, last_modified_at
    FROM character_sync
    WHERE user_id = ${googleUser.sub}
    ORDER BY updated_at DESC
  `;

  const characters = rows.map((row) => {
    const blob = row.character_blob || {};
    const sheet = blob.sheet || {};
    return {
      sync_uuid: row.sync_uuid,
      name: sheet.name || '(Sans nom)',
      level: sheet.level ?? null,
      last_modified_at: row.last_modified_at,
    };
  });

  return jsonResponse({ ok: true, role, characters }, 200, origin);
}

// --- POINT D'ENTRÉE ---
export default {
  async fetch(request, env) {
    const origin = parseOrigin(request, env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }
    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Méthode non autorisée' }, 405, origin);
    }

    if (!env.DATABASE_URL || !env.GOOGLE_CLIENT_ID) {
      return jsonResponse({ error: 'Variables environnement manquantes' }, 500, origin);
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return jsonResponse({ error: 'JSON invalide' }, 400, origin);
    }

    // 1. Authentification globale pour toutes les requêtes
    let googleUser;
    try {
      googleUser = await verifyGoogleToken(request, env);
    } catch (e) {
      return jsonResponse({ error: 'Non autorisé: ' + e.message }, 401, origin);
    }

    // 2. Connexion BDD et init des schémas
    const sql = neon(env.DATABASE_URL);
    await ensureSchema(sql);

    // 3. Gestion Utilisateur (Upsert)
    const role = await upsertUserAndGetRole(googleUser, sql);

    // 4. Routage
    const path = new URL(request.url).pathname;
    if (path === '/sync/push') return handlePush(payload, googleUser, role, sql, origin);
    if (path === '/sync/pull') return handlePull(payload, googleUser, sql, origin);
    if (path === '/sync/list') return handleList(googleUser, role, sql, origin);

    return jsonResponse({ error: 'Route inconnue' }, 404, origin);
  },
};