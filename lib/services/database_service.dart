import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/character_template.dart';
import '../models/combat_session.dart';
import '../models/participant.dart';
import '../models/status_effect.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'co_compagnon.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS character_templates (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              is_ally INTEGER NOT NULL,
              base_initiative INTEGER NOT NULL,
              max_hp INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE sessions ADD COLUMN turn_count INTEGER NOT NULL DEFAULT 0');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS status_effects (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              participant_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              remaining_turns INTEGER NOT NULL DEFAULT 1
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE participants ADD COLUMN image_url TEXT');
          await db.execute(
              'ALTER TABLE character_templates ADD COLUMN image_url TEXT');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        turn_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        is_ally INTEGER NOT NULL,
        base_initiative INTEGER NOT NULL,
        max_hp INTEGER NOT NULL,
        current_hp INTEGER NOT NULL,
        image_url TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE character_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_ally INTEGER NOT NULL,
        base_initiative INTEGER NOT NULL,
        max_hp INTEGER NOT NULL,
        image_url TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE status_effects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        remaining_turns INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // ── Sessions ────────────────────────────────────────────────────────────────

  Future<List<CombatSession>> getSessions() async {
    final db = await database;
    final rows = await db.query('sessions', orderBy: 'created_at DESC');
    return rows.map(CombatSession.fromMap).toList();
  }

  Future<CombatSession> insertSession(CombatSession session) async {
    final db = await database;
    final id = await db.insert('sessions', session.toMap());
    return session.copyWith(id: id);
  }

  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Participants ─────────────────────────────────────────────────────────────

  Future<List<Participant>> getParticipants(int sessionId) async {
    final db = await database;
    final rows = await db.query(
      'participants',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'name ASC',
    );
    return rows.map(Participant.fromMap).toList();
  }

  Future<Participant> insertParticipant(Participant participant) async {
    final db = await database;
    final id = await db.insert('participants', participant.toMap());
    return participant.copyWith(id: id);
  }

  Future<void> updateParticipantHp(int id, int currentHp) async {
    final db = await database;
    await db.update(
      'participants',
      {'current_hp': currentHp},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateParticipantImage(int id, String? imageUrl) async {
    final db = await database;
    await db.update(
      'participants',
      {'image_url': imageUrl},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteParticipant(int id) async {
    final db = await database;
    await db.delete('participants', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetAllHp(int sessionId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE participants SET current_hp = max_hp WHERE session_id = ?',
      [sessionId],
    );
  }

  // ── Character Templates (Bestiaire) ─────────────────────────────────────────

  Future<List<CharacterTemplate>> getTemplates() async {
    final db = await database;
    final rows = await db.query('character_templates', orderBy: 'name ASC');
    return rows.map(CharacterTemplate.fromMap).toList();
  }

  Future<CharacterTemplate> insertTemplate(CharacterTemplate template) async {
    final db = await database;
    final id = await db.insert('character_templates', template.toMap());
    return template.copyWith(id: id);
  }

  Future<void> updateTemplate(CharacterTemplate template) async {
    final db = await database;
    await db.update(
      'character_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<void> deleteTemplate(int id) async {
    final db = await database;
    await db.delete('character_templates', where: 'id = ?', whereArgs: [id]);
  }

  // ── Turn Count ──────────────────────────────────────────────────────────────

  Future<int> getTurnCount(int sessionId) async {
    final db = await database;
    final rows = await db.query('sessions',
        columns: ['turn_count'], where: 'id = ?', whereArgs: [sessionId]);
    if (rows.isEmpty) return 0;
    return (rows.first['turn_count'] as int?) ?? 0;
  }

  Future<void> updateTurnCount(int sessionId, int turnCount) async {
    final db = await database;
    await db.update('sessions', {'turn_count': turnCount},
        where: 'id = ?', whereArgs: [sessionId]);
  }

  // ── Status Effects ───────────────────────────────────────────────────────────

  Future<StatusEffect> insertStatusEffect(StatusEffect effect) async {
    final db = await database;
    final id = await db.insert('status_effects', effect.toMap());
    return effect.copyWith(id: id);
  }

  Future<void> updateStatusEffectTurns(int id, int remainingTurns) async {
    final db = await database;
    await db.update('status_effects', {'remaining_turns': remainingTurns},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteStatusEffect(int id) async {
    final db = await database;
    await db.delete('status_effects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteStatusEffectsForParticipant(int participantId) async {
    final db = await database;
    await db.delete('status_effects',
        where: 'participant_id = ?', whereArgs: [participantId]);
  }

  Future<List<StatusEffect>> getStatusEffectsForSession(int sessionId) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT se.* FROM status_effects se '
      'INNER JOIN participants p ON se.participant_id = p.id '
      'WHERE p.session_id = ?',
      [sessionId],
    );
    return maps.map(StatusEffect.fromMap).toList();
  }
}
