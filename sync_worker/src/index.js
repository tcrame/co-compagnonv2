import { neon } from '@neondatabase/serverless';
import bcrypt from 'bcryptjs';

function corsHeaders(origin = '*') {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
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

async function ensureSchema(sql) {
  await sql`
    CREATE TABLE IF NOT EXISTS character_sync (
      sync_uuid TEXT PRIMARY KEY,
      password_hash TEXT NOT NULL,
      character_blob JSONB NOT NULL,
      last_modified_at TIMESTAMPTZ NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;
}

async function handlePush(payload, sql, origin) {
  const { sync_uuid, password, character_blob, last_modified_at } = payload;
  if (!sync_uuid || !password || !character_blob || !last_modified_at) {
    return jsonResponse(
      { error: 'sync_uuid, password, character_blob et last_modified_at requis' },
      400,
      origin,
    );
  }

  const existing = await sql`
    SELECT password_hash FROM character_sync WHERE sync_uuid = ${sync_uuid}
  `;

  let passwordHash;
  if (existing.length === 0) {
    passwordHash = await bcrypt.hash(password, 10);
  } else {
    const ok = await bcrypt.compare(password, existing[0].password_hash);
    if (!ok) {
      return jsonResponse({ error: 'Mot de passe invalide' }, 401, origin);
    }
    passwordHash = existing[0].password_hash;
  }

  await sql`
    INSERT INTO character_sync(sync_uuid, password_hash, character_blob, last_modified_at, updated_at)
    VALUES (${sync_uuid}, ${passwordHash}, ${JSON.stringify(character_blob)}::jsonb, ${last_modified_at}::timestamptz, now())
    ON CONFLICT (sync_uuid) DO UPDATE SET
      password_hash = EXCLUDED.password_hash,
      character_blob = EXCLUDED.character_blob,
      last_modified_at = EXCLUDED.last_modified_at,
      updated_at = now()
  `;

  return jsonResponse({ ok: true, sync_uuid }, 200, origin);
}

async function handlePull(payload, sql, origin) {
  const { sync_uuid, password } = payload;
  if (!sync_uuid || !password) {
    return jsonResponse({ error: 'sync_uuid et password requis' }, 400, origin);
  }

  const rows = await sql`
    SELECT character_blob, password_hash, last_modified_at
    FROM character_sync
    WHERE sync_uuid = ${sync_uuid}
    LIMIT 1
  `;
  if (rows.length === 0) {
    return jsonResponse({ error: 'Personnage introuvable' }, 404, origin);
  }

  const ok = await bcrypt.compare(password, rows[0].password_hash);
  if (!ok) {
    return jsonResponse({ error: 'Mot de passe invalide' }, 401, origin);
  }

  return jsonResponse(
    {
      ok: true,
      sync_uuid,
      character_blob: rows[0].character_blob,
      last_modified_at: rows[0].last_modified_at,
    },
    200,
    origin,
  );
}

async function handleList(payload, sql, origin) {
  const rows = await sql`
    SELECT sync_uuid, character_blob, last_modified_at
    FROM character_sync
    ORDER BY updated_at DESC
  `;

  const characters = rows.map((row) => {
    const blob = row.character_blob || {};
    const sheet = blob.sheet || {};
    return {
      sync_uuid: row.sync_uuid,
      name: sheet.name || '(Sans nom)',
      level: sheet.level ?? null,
      profile: sheet.profile || '',
      race: sheet.race || '',
      last_modified_at: row.last_modified_at,
    };
  });

  return jsonResponse({ ok: true, characters }, 200, origin);
}

export default {
  async fetch(request, env) {
    const origin = parseOrigin(request, env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }
    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Méthode non autorisée' }, 405, origin);
    }

    if (!env.DATABASE_URL) {
      return jsonResponse(
        { error: 'DATABASE_URL manquante dans les variables Worker' },
        500,
        origin,
      );
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return jsonResponse({ error: 'JSON invalide' }, 400, origin);
    }

    const sql = neon(env.DATABASE_URL);
    await ensureSchema(sql);

    const path = new URL(request.url).pathname;
    if (path === '/sync/push') {
      return handlePush(payload, sql, origin);
    }
    if (path === '/sync/pull') {
      return handlePull(payload, sql, origin);
    }
    if (path === '/sync/list') {
      return handleList(payload, sql, origin);
    }

    return jsonResponse({ error: 'Route inconnue' }, 404, origin);
  },
};
