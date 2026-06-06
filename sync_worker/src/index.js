import {neon} from '@neondatabase/serverless';
import {createRemoteJWKSet, jwtVerify} from 'jose';
import {gameIconsBank} from './game_icons_bank.js';

function corsHeaders(origin = '*') {
    return {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
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

function toCharacterInfo(row, permissionType = 'owner') {
    const blob = row.character_blob || {};
    const sheet = blob.sheet || {};

    return {
        sync_uuid: row.sync_uuid,
        name: sheet.name || '(Sans nom)',
        level: sheet.level ?? null,
        profile: sheet.profile ?? '',
        race: sheet.race ?? '',
        last_modified_at: row.last_modified_at,
        permission_type: permissionType,
        owner_user_id: row.owner_user_id || row.user_id || null,
        owner_email: row.owner_email || null,
    };
}

function normalizePermission(permissionType) {
    if (permissionType === 'write') return 'write';
    if (permissionType === 'read') return 'read';
    return 'owner';
}

async function getUserByEmail(sql, email) {
    const rows = await sql`
        SELECT user_id, email
        FROM users
        WHERE lower(email) = lower(${email})
        ORDER BY user_id ASC
        LIMIT 2
    `;

    if (rows.length === 0) return null;
    if (rows.length > 1) {
        throw new Error('Adresse email ambiguë dans users');
    }
    return rows[0];
}

async function getCharacterOwnership(sql, syncUuid) {
    const rows = await sql`
        SELECT sync_uuid, user_id, last_modified_at
        FROM character_sync
        WHERE sync_uuid = ${syncUuid}
        LIMIT 1
    `;
    return rows[0] || null;
}

async function getAccessForUser(sql, syncUuid, userId) {
    const rows = await sql`
        SELECT cs.sync_uuid,
               cs.user_id AS owner_user_id,
               sh.permission_type
        FROM character_sync cs
                 LEFT JOIN character_shares sh
                           ON sh.sync_uuid = cs.sync_uuid
                               AND sh.shared_with_user_id = ${userId}
        WHERE cs.sync_uuid = ${syncUuid}
        LIMIT 1
    `;

    if (rows.length === 0) return null;
    return {
        ownerUserId: rows[0].owner_user_id,
        permissionType: normalizePermission(rows[0].permission_type),
    };
}

async function verifyGoogleToken(request, env) {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('Token manquant ou mal formaté');
    }

    const token = authHeader.split(' ')[1];
    const JWKS = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));

    const {payload} = await jwtVerify(token, JWKS, {
        issuer: ['https://accounts.google.com', 'accounts.google.com'],
        audience: env.GOOGLE_CLIENT_ID,
    });

    return payload;
}

async function ensureSchema(sql) {
    await sql`
        CREATE TABLE IF NOT EXISTS users
        (
            user_id    TEXT PRIMARY KEY,
            email      TEXT NOT NULL,
            role       TEXT        DEFAULT 'free',
            created_at TIMESTAMPTZ DEFAULT now()
        )
    `;

    await sql`
        CREATE TABLE IF NOT EXISTS character_sync
        (
            sync_uuid        TEXT PRIMARY KEY,
            user_id          TEXT        NOT NULL REFERENCES users (user_id),
            character_blob   JSONB       NOT NULL,
            last_modified_at TIMESTAMPTZ NOT NULL,
            updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    `;

    await sql`
        CREATE TABLE IF NOT EXISTS character_shares
        (
            share_id            SERIAL PRIMARY KEY,
            sync_uuid           TEXT        NOT NULL REFERENCES character_sync (sync_uuid) ON DELETE CASCADE,
            shared_with_user_id TEXT        NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
            permission_type     TEXT        NOT NULL CHECK (permission_type IN ('read', 'write')),
            created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
            CONSTRAINT character_shares_sync_uuid_shared_with_user_id_key UNIQUE (sync_uuid, shared_with_user_id)
        )
    `;

    await sql`
        CREATE INDEX IF NOT EXISTS idx_character_shares_sync_uuid
            ON character_shares (sync_uuid)
    `;

    await sql`
        CREATE INDEX IF NOT EXISTS idx_character_shares_shared_with_user_id
            ON character_shares (shared_with_user_id)
    `;

    await sql`
        CREATE INDEX IF NOT EXISTS idx_character_shares_permission_type
            ON character_shares (permission_type)
    `;

    // ⚔️ NOUVELLE TABLE POUR LES TRACKERS DE COMBAT
    await sql`
        CREATE TABLE IF NOT EXISTS combat_sessions
        (
            session_id       TEXT PRIMARY KEY, -- 💡 Reçoit désormais le code aléatoire (ex: "X9R2A4")
            session_name     TEXT NOT NULL,
            combat_blob      JSONB NOT NULL,
            updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    `;
}

async function upsertUserAndGetRole(googleUser, sql) {
    await sql`
        INSERT INTO users (user_id, email)
        VALUES (${googleUser.sub}, ${googleUser.email})
        ON CONFLICT (user_id) DO UPDATE SET email = EXCLUDED.email
    `;

    const rows = await sql`SELECT role
                           FROM users
                           WHERE user_id = ${googleUser.sub}`;
    return rows[0].role;
}

async function handlePush(payload, googleUser, role, sql, origin) {
    const {sync_uuid, character_blob, last_modified_at} = payload;
    if (!sync_uuid || !character_blob || !last_modified_at) {
        return jsonResponse({error: 'Données incomplètes'}, 400, origin);
    }

    const access = await getAccessForUser(sql, sync_uuid, googleUser.sub);
    const ownership = await getCharacterOwnership(sql, sync_uuid);

    if (!ownership) {
        const countRes = await sql`
            SELECT COUNT(*)::int AS count
            FROM character_sync
            WHERE user_id = ${googleUser.sub}
        `;
        const currentCount = Number(countRes[0].count);
        const limit = role === 'premium' ? 10 : 3;

        if (currentCount >= limit) {
            return jsonResponse({error: `Quota dépassé (${limit} max). Passez Premium !`}, 403, origin);
        }

        await sql`
            INSERT INTO character_sync(sync_uuid, user_id, character_blob, last_modified_at, updated_at)
            VALUES (${sync_uuid}, ${googleUser.sub}, ${JSON.stringify(character_blob)}::jsonb,
                    ${last_modified_at}::timestamptz, now())
        `;

        return jsonResponse({ok: true, sync_uuid, action: 'created'}, 200, origin);
    }

    const isOwner = ownership.user_id === googleUser.sub;
    const canWrite = isOwner || access?.permissionType === 'write';

    if (!canWrite) {
        return jsonResponse({error: 'Accès refusé: écriture non autorisée'}, 403, origin);
    }

    await sql`
        UPDATE character_sync
        SET character_blob   = ${JSON.stringify(character_blob)}::jsonb,
            last_modified_at = ${last_modified_at}::timestamptz,
            updated_at       = now()
        WHERE sync_uuid = ${sync_uuid}
    `;

    return jsonResponse({ok: true, sync_uuid, action: 'updated'}, 200, origin);
}

async function handlePull(payload, googleUser, sql, origin) {
    const {sync_uuid} = payload;
    if (!sync_uuid) return jsonResponse({error: 'sync_uuid requis'}, 400, origin);

    const rows = await sql`
        SELECT cs.sync_uuid,
               cs.character_blob,
               cs.last_modified_at,
               cs.user_id  AS owner_user_id,
               owner.email AS owner_email,
               sh.permission_type
        FROM character_sync cs
                 JOIN users owner
                      ON owner.user_id = cs.user_id
                 LEFT JOIN character_shares sh
                           ON sh.sync_uuid = cs.sync_uuid
                               AND sh.shared_with_user_id = ${googleUser.sub}
        WHERE cs.sync_uuid = ${sync_uuid}
          AND (
            cs.user_id = ${googleUser.sub}
                OR sh.permission_type IN ('read', 'write')
            )
        LIMIT 1
    `;

    if (rows.length === 0) {
        return jsonResponse({error: 'Personnage introuvable ou non autorisé'}, 404, origin);
    }

    return jsonResponse({
        ok: true,
        sync_uuid: rows[0].sync_uuid,
        character_blob: rows[0].character_blob,
        last_modified_at: rows[0].last_modified_at,
        owner_user_id: rows[0].owner_user_id,
        owner_email: rows[0].owner_email,
        permission_type: normalizePermission(rows[0].permission_type),
    }, 200, origin);
}

async function handleList(googleUser, role, sql, origin) {
    const ownedRows = await sql`
        SELECT cs.sync_uuid,
               cs.character_blob,
               cs.last_modified_at,
               cs.user_id  AS owner_user_id,
               owner.email AS owner_email
        FROM character_sync cs
                 JOIN users owner
                      ON owner.user_id = cs.user_id
        WHERE cs.user_id = ${googleUser.sub}
        ORDER BY cs.updated_at DESC
    `;

    const writeSharedRows = await sql`
        SELECT cs.sync_uuid,
               cs.character_blob,
               cs.last_modified_at,
               cs.user_id  AS owner_user_id,
               owner.email AS owner_email,
               sh.permission_type
        FROM character_shares sh
                 JOIN character_sync cs
                      ON cs.sync_uuid = sh.sync_uuid
                 JOIN users owner
                      ON owner.user_id = cs.user_id
        WHERE sh.shared_with_user_id = ${googleUser.sub}
          AND sh.permission_type = 'write'
        ORDER BY cs.updated_at DESC
    `;

    const readSharedRows = await sql`
        SELECT cs.sync_uuid,
               cs.character_blob,
               cs.last_modified_at,
               cs.user_id  AS owner_user_id,
               owner.email AS owner_email,
               sh.permission_type
        FROM character_shares sh
                 JOIN character_sync cs
                      ON cs.sync_uuid = sh.sync_uuid
                 JOIN users owner
                      ON owner.user_id = cs.user_id
        WHERE sh.shared_with_user_id = ${googleUser.sub}
          AND sh.permission_type = 'read'
        ORDER BY cs.updated_at DESC
    `;

    // 1. Conversion des listes SQL en tableaux d'objets standardisés
    const ownedMapped = ownedRows.map((row) => toCharacterInfo(row, 'owner'));
    const writeMapped = writeSharedRows.map((row) => toCharacterInfo(row, 'write'));
    const readMapped = readSharedRows.map((row) => toCharacterInfo(row, 'read'));

    // 2. Fusion de toutes les catégories dans une liste globale unique 'characters'
    // pour que l'ancien système de désérialisation Flutter reste compatible et ne reçoive pas du vide !
    const allCharacters = [...ownedMapped, ...writeMapped, ...readMapped];

    return jsonResponse({
        ok: true,
        role,
        total: ownedRows.length, // Quota basé uniquement sur les personnages possédés (owned)
        characters: allCharacters, // Liste globale pour débloquer le pull Flutter !
        owned_characters: ownedMapped,
        write_shared_characters: writeMapped,
        read_shared_characters: readMapped,
    }, 200, origin);
}

async function handleShare(payload, googleUser, sql, origin) {
    const {sync_uuid, email, permission_type} = payload;

    if (!sync_uuid || !email || !permission_type) {
        return jsonResponse({error: 'sync_uuid, email et permission_type requis'}, 400, origin);
    }

    if (!['read', 'write'].includes(permission_type)) {
        return jsonResponse({error: "permission_type doit valoir 'read' ou 'write'"}, 400, origin);
    }

    const ownership = await sql`
        SELECT sync_uuid
        FROM character_sync
        WHERE sync_uuid = ${sync_uuid}
          AND user_id = ${googleUser.sub}
        LIMIT 1
    `;

    if (ownership.length === 0) {
        return jsonResponse({error: 'Seul le propriétaire peut partager ce personnage'}, 403, origin);
    }

    const targetUser = await getUserByEmail(sql, email);
    if (!targetUser) {
        return jsonResponse({error: 'Utilisateur introuvable pour cet email'}, 404, origin);
    }

    if (targetUser.user_id === googleUser.sub) {
        return jsonResponse({error: 'Impossible de se partager un personnage à soi-même'}, 400, origin);
    }

    await sql`
        INSERT INTO character_shares (sync_uuid, shared_with_user_id, permission_type)
        VALUES (${sync_uuid}, ${targetUser.user_id}, ${permission_type})
        ON CONFLICT (sync_uuid, shared_with_user_id) DO UPDATE SET permission_type = EXCLUDED.permission_type
    `;

    return jsonResponse({
        ok: true,
        sync_uuid,
        shared_with_user_id: targetUser.user_id,
        shared_with_email: targetUser.email,
        permission_type,
    }, 200, origin);
}

async function handleRevoke(payload, googleUser, sql, origin) {
    const {sync_uuid, email, shared_with_user_id} = payload;

    if (!sync_uuid || (!email && !shared_with_user_id)) {
        return jsonResponse({error: 'sync_uuid et email (ou shared_with_user_id) requis'}, 400, origin);
    }

    const ownership = await sql`
        SELECT sync_uuid
        FROM character_sync
        WHERE sync_uuid = ${sync_uuid}
          AND user_id = ${googleUser.sub}
        LIMIT 1
    `;

    if (ownership.length === 0) {
        return jsonResponse({error: 'Seul le propriétaire peut révoquer ce partage'}, 403, origin);
    }

    let targetUserId = shared_with_user_id || null;
    if (!targetUserId) {
        const targetUser = await getUserByEmail(sql, email);
        if (!targetUser) {
            return jsonResponse({error: 'Utilisateur introuvable pour cet email'}, 404, origin);
        }
        targetUserId = targetUser.user_id;
    }

    const deleted = await sql`
        DELETE
        FROM character_shares
        WHERE sync_uuid = ${sync_uuid}
          AND shared_with_user_id = ${targetUserId}
        RETURNING share_id
    `;

    return jsonResponse({
        ok: true,
        sync_uuid,
        revoked: deleted.length > 0,
        shared_with_user_id: targetUserId,
    }, 200, origin);
}

async function handleShares(payload, googleUser, sql, origin) {
    const {sync_uuid} = payload;
    if (!sync_uuid) {
        return jsonResponse({error: 'sync_uuid requis'}, 400, origin);
    }

    const ownership = await sql`
        SELECT sync_uuid
        FROM character_sync
        WHERE sync_uuid = ${sync_uuid}
          AND user_id = ${googleUser.sub}
        LIMIT 1
    `;

    if (ownership.length === 0) {
        return jsonResponse({error: 'Seul le propriétaire peut voir les partages'}, 403, origin);
    }

    const shares = await sql`
        SELECT sh.share_id,
               sh.sync_uuid,
               sh.shared_with_user_id,
               u.email AS shared_with_email,
               sh.permission_type,
               sh.created_at
        FROM character_shares sh
                 JOIN users u
                      ON u.user_id = sh.shared_with_user_id
        WHERE sh.sync_uuid = ${sync_uuid}
        ORDER BY sh.created_at DESC
    `;

    return jsonResponse({
        ok: true,
        sync_uuid,
        shares: shares.map((row) => ({
            share_id: row.share_id,
            sync_uuid: row.sync_uuid,
            shared_with_user_id: row.shared_with_user_id,
            shared_with_email: row.shared_with_email,
            permission_type: row.permission_type,
            created_at: row.created_at,
        })),
    }, 200, origin);
}

async function handleDelete(payload, googleUser, sql, origin) {
    const {sync_uuid} = payload;
    if (!sync_uuid) return jsonResponse({error: 'sync_uuid requis'}, 400, origin);

    const existing = await sql`
        SELECT sync_uuid
        FROM character_sync
        WHERE sync_uuid = ${sync_uuid}
          AND user_id = ${googleUser.sub}
    `;

    if (existing.length === 0) {
        return jsonResponse({error: 'Personnage introuvable ou non autorisé'}, 404, origin);
    }

    await sql`
        DELETE
        FROM character_sync
        WHERE sync_uuid = ${sync_uuid}
          AND user_id = ${googleUser.sub}
    `;

    return jsonResponse({ok: true, message: 'Personnage supprimé du cloud'}, 200, origin);
}

async function handleIconSearch(payload, origin) {
    const query = (payload.query || '').toLowerCase().trim();

    if (!query) {
        // Si la recherche est vide, on renvoie les 30 premières icônes par défaut
        return jsonResponse({ok: true, icons: gameIconsBank.slice(0, 30)}, 200, origin);
    }

    // Filtrage intelligent : on cherche dans le nom (n) OU dans les tags/catégories (t)
    const filtered = gameIconsBank.filter(icon => {
        const matchName = icon.n.toLowerCase().includes(query);
        const matchTags = icon.t.some(tag => tag.toLowerCase().includes(query));
        return matchName || matchTags;
    });

    // On limite à 50 résultats pour que la réponse reste ultra-rapide et légère
    return jsonResponse({ok: true, icons: filtered.slice(0, 50)}, 200, origin);
}

async function handleSessionPush(payload, sql, origin) {
    const { session_id, session_name, combat_blob } = payload; // session_id est une String

    if (!session_id || !session_name || !combat_blob) {
        return jsonResponse({ error: 'Données de session incomplètes' }, 400, origin);
    }

    await sql`
        INSERT INTO combat_sessions (session_id, session_name, combat_blob, updated_at)
        VALUES (${session_id}, ${session_name}, ${JSON.stringify(combat_blob)}::jsonb, now())
        ON CONFLICT (session_id)
            DO UPDATE SET
                          session_name = EXCLUDED.session_name,
                          combat_blob = EXCLUDED.combat_blob,
                          updated_at = now()
    `;

    return jsonResponse({ ok: true, message: 'Session synchronisée' }, 200, origin);
}

async function handleSpectate(payload, sql, origin) {
    const shortCode = (payload.short_code || '').toUpperCase().trim();

    if (!shortCode) {
        return jsonResponse({ error: 'Code de session requis' }, 400, origin);
    }

    // 🎯 Recherche par correspondance exacte du code unique à 6 lettres
    const rows = await sql`
        SELECT session_name, combat_blob
        FROM combat_sessions
        WHERE session_id = ${shortCode}
        LIMIT 1
    `;

    if (rows.length === 0) {
        return jsonResponse({ error: 'Session de combat introuvable. Le MJ doit activer le partage.' }, 404, origin);
    }

    // 🛠️ FIX 1 : On cible STRICTEMENT combat_blob pour le tracker de combat
    const sessionData = rows[0].combat_blob || {};
    let participantsParsed = [];

    // 🛡️ SÉCURISATION DES DONNÉES (Brouillard de guerre)
    if (sessionData && sessionData.participants) {
        participantsParsed = sessionData.participants.map(p => {
            // Extraction adaptative robuste des forces et PV
            const currentHp = Number(p.currentHp !== undefined ? p.currentHp : (p.current_hp !== undefined ? p.current_hp : 0));
            const maxHp = Number(p.maxHp !== undefined ? p.maxHp : (p.max_hp !== undefined ? p.max_hp : 1));
            const isAlly = p.isAlly !== undefined ? p.isAlly : (p.is_ally !== undefined ? p.is_ally : false);
            const def = p.def !== undefined ? p.def : (p.def_val !== undefined ? p.def_val : 10);
            const imageUrl = p.imageUrl !== undefined ? p.imageUrl : (p.image_url !== undefined ? p.image_url : null);

            // 🎲 FIX 2 : Détection ultra-blindée de l'initiative (gère TOUS les formats d'envoi possibles)
            let rolledInitiative = 0;
            if (p.rolledInitiative !== undefined) rolledInitiative = Number(p.rolledInitiative);
            else if (p.rolled_initiative !== undefined) rolledInitiative = Number(p.rolled_initiative);
            else if (p.baseInitiative !== undefined) rolledInitiative = Number(p.baseInitiative);
            else if (p.base_initiative !== undefined) rolledInitiative = Number(p.base_initiative);

            const isAlive = currentHp > 0;
            const hpPercent = maxHp > 0 ? Math.max(0, Math.min(1, currentHp / maxHp)) : 0;

            if (!isAlly) {
                // Pour un ENNEMI : Brouillard de guerre (PV masqués, mais initiative publique !)
                return {
                    id: p.id,
                    name: p.name,
                    isAlly: false,
                    rolledInitiative: rolledInitiative, // Transmis explicitement
                    hpPercent: hpPercent,
                    isAlive: isAlive,
                    imageUrl: imageUrl,
                    statusEffects: p.statusEffects || p.status_effects || []
                };
            } else {
                // Pour un AVENTURIER : Données complètes transparentes
                return {
                    id: p.id,
                    name: p.name,
                    isAlly: true,
                    rolledInitiative: rolledInitiative, // Transmis explicitement
                    currentHp: currentHp,
                    maxHp: maxHp,
                    hpPercent: hpPercent,
                    isAlive: isAlive,
                    def: def,
                    imageUrl: imageUrl,
                    statusEffects: p.statusEffects || p.status_effects || []
                };
            }
        });
    }

    return jsonResponse({
        ok: true,
        session: {
            name: rows[0].session_name,
            combatStarted: sessionData.combatStarted ?? false,
            turnCount: sessionData.turnCount ?? 1,
            activeIndex: sessionData.activeIndex !== undefined ? sessionData.activeIndex : null,
            participants: participantsParsed // 💡 On injecte notre tableau nettoyé et harmonisé
        }
    }, 200, origin);
}

export default {
    async fetch(request, env) {
        const origin = parseOrigin(request, env);

        if (request.method === 'OPTIONS') {
            return new Response(null, {status: 204, headers: corsHeaders(origin)});
        }
        if (request.method !== 'POST') {
            return jsonResponse({error: 'Méthode non autorisée'}, 405, origin);
        }

        if (!env.DATABASE_URL || !env.GOOGLE_CLIENT_ID) {
            return jsonResponse({error: 'Variables environnement manquantes'}, 500, origin);
        }

        let payload;
        try {
            payload = await request.json();
        } catch (_) {
            return jsonResponse({error: 'JSON invalide'}, 400, origin);
        }

        const path = new URL(request.url).pathname;

        // 1. Instanciation du driver SQL
        const sql = neon(env.DATABASE_URL);

        // ⚙️ FIX : On force la vérification/création des tables ICI, pour TOUTES les requêtes !
        try {
            await ensureSchema(sql);
        } catch (schemaError) {
            return jsonResponse({error: 'Erreur d\'initialisation de la base de données: ' + schemaError.message}, 500, origin);
        }

        // 🔍 ROUTES PUBLIQUES (Accessibles sans Token Google - Maintenant la table existe !)
        if (path === '/icons/search') return handleIconSearch(payload, origin);
        if (path === '/session/spectate') return handleSpectate(payload, sql, origin);
        if (path === '/session/push') return handleSessionPush(payload, sql, origin);

        // 🔐 BARRIÈRE DE SÉCURITÉ : Tout ce qui est en dessous nécessite un compte Google valide
        let googleUser;
        try {
            googleUser = await verifyGoogleToken(request, env);
        } catch (e) {
            return jsonResponse({error: 'Non autorisé: ' + e.message}, 401, origin);
        }

        // Récupération du rôle utilisateur (uniquement pour les fonctionnalités synchronisées privées)
        const role = await upsertUserAndGetRole(googleUser, sql);

        // Aiguillage des routes protégées
        if (path === '/sync/push') return handlePush(payload, googleUser, role, sql, origin);
        if (path === '/sync/pull') return handlePull(payload, googleUser, sql, origin);
        if (path === '/sync/list') return handleList(googleUser, role, sql, origin);
        if (path === '/sync/share') return handleShare(payload, googleUser, sql, origin);
        if (path === '/sync/revoke') return handleRevoke(payload, googleUser, sql, origin);
        if (path === '/sync/shares') return handleShares(payload, googleUser, sql, origin);
        if (path === '/sync/delete') return handleDelete(payload, googleUser, sql, origin);

        return jsonResponse({error: 'Route inconnue'}, 404, origin);
    },
};