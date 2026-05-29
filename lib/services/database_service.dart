import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/voies_data.dart';
import '../models/character_sheet.dart';
import '../models/character_template.dart';
import '../models/combat_armor.dart';
import '../models/combat_capacity.dart';
import '../models/combat_session.dart';
import '../models/combat_weapon.dart';
import '../models/inventory_item.dart';
import '../models/item_effect.dart';
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
      version: 10,
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
        if (oldVersion < 5) {
          await _createCharacterSheetsTable(db);
        }
        if (oldVersion < 6) {
          const cols = ['agi', 'con', 'for', 'per', 'cha', 'int', 'vol'];
          for (final c in cols) {
            await db.execute(
                'ALTER TABLE character_sheets ADD COLUMN ${c}_bonus INTEGER NOT NULL DEFAULT 0');
          }
          await db.execute(
              "ALTER TABLE character_sheets ADD COLUMN stat_preset TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 7) {
          await _createInventoryItemsTable(db);
        }
        if (oldVersion < 8) {
          await db.execute(
              "ALTER TABLE character_sheets ADD COLUMN equipment_bonuses_json TEXT NOT NULL DEFAULT '{}'");
          await _createCombatWeaponsTable(db);
          await _createCombatArmorsTable(db);
          await _createCombatCapacitiesTable(db);
          await _createItemEffectsTable(db);
        }
        if (oldVersion < 9) {
          await db.execute(
              "ALTER TABLE combat_weapons ADD COLUMN dm TEXT NOT NULL DEFAULT ''");
          await db.execute(
              "ALTER TABLE combat_capacities ADD COLUMN dm TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 10) {
          await db.execute(
              "ALTER TABLE character_sheets ADD COLUMN points_competence INTEGER NOT NULL DEFAULT 0");
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
    await _createCharacterSheetsTable(db);
    await _createInventoryItemsTable(db);
    await _createCombatWeaponsTable(db);
    await _createCombatArmorsTable(db);
    await _createCombatCapacitiesTable(db);
    await _createItemEffectsTable(db);
  }

  Future<void> _createCharacterSheetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS character_sheets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        race TEXT NOT NULL DEFAULT '',
        profile TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        agi_val INTEGER NOT NULL DEFAULT 0,
        agi_racial INTEGER NOT NULL DEFAULT 0,
        agi_bonus INTEGER NOT NULL DEFAULT 0,
        con_val INTEGER NOT NULL DEFAULT 0,
        con_racial INTEGER NOT NULL DEFAULT 0,
        con_bonus INTEGER NOT NULL DEFAULT 0,
        for_val INTEGER NOT NULL DEFAULT 0,
        for_racial INTEGER NOT NULL DEFAULT 0,
        for_bonus INTEGER NOT NULL DEFAULT 0,
        per_val INTEGER NOT NULL DEFAULT 0,
        per_racial INTEGER NOT NULL DEFAULT 0,
        per_bonus INTEGER NOT NULL DEFAULT 0,
        cha_val INTEGER NOT NULL DEFAULT 0,
        cha_racial INTEGER NOT NULL DEFAULT 0,
        cha_bonus INTEGER NOT NULL DEFAULT 0,
        int_val INTEGER NOT NULL DEFAULT 0,
        int_racial INTEGER NOT NULL DEFAULT 0,
        int_bonus INTEGER NOT NULL DEFAULT 0,
        vol_val INTEGER NOT NULL DEFAULT 0,
        vol_racial INTEGER NOT NULL DEFAULT 0,
        vol_bonus INTEGER NOT NULL DEFAULT 0,
        stat_preset TEXT NOT NULL DEFAULT '',
        att_contact_base INTEGER NOT NULL DEFAULT 0,
        att_contact_bonus INTEGER NOT NULL DEFAULT 0,
        att_contact_malus INTEGER NOT NULL DEFAULT 0,
        att_distance_base INTEGER NOT NULL DEFAULT 0,
        att_distance_bonus INTEGER NOT NULL DEFAULT 0,
        att_distance_malus INTEGER NOT NULL DEFAULT 0,
        att_magique_base INTEGER NOT NULL DEFAULT 0,
        att_magique_bonus INTEGER NOT NULL DEFAULT 0,
        att_magique_malus INTEGER NOT NULL DEFAULT 0,
        init_base INTEGER NOT NULL DEFAULT 0,
        init_bonus INTEGER NOT NULL DEFAULT 0,
        init_malus INTEGER NOT NULL DEFAULT 0,
        pv_dv TEXT NOT NULL DEFAULT '1d8',
        pv_base INTEGER NOT NULL DEFAULT 0,
        pv_bonus INTEGER NOT NULL DEFAULT 0,
        pv_actuel INTEGER NOT NULL DEFAULT 0,
        dr_base INTEGER NOT NULL DEFAULT 0,
        dr_bonus INTEGER NOT NULL DEFAULT 0,
        dr_actuel INTEGER NOT NULL DEFAULT 0,
        def_base INTEGER NOT NULL DEFAULT 10,
        def_bonus INTEGER NOT NULL DEFAULT 0,
        def_malus INTEGER NOT NULL DEFAULT 0,
        rd_base INTEGER NOT NULL DEFAULT 0,
        rd_bonus INTEGER NOT NULL DEFAULT 0,
        rd_malus INTEGER NOT NULL DEFAULT 0,
        pm_base INTEGER NOT NULL DEFAULT 0,
        pm_bonus INTEGER NOT NULL DEFAULT 0,
        pm_actuel INTEGER NOT NULL DEFAULT 0,
        pc_base INTEGER NOT NULL DEFAULT 0,
        pc_bonus INTEGER NOT NULL DEFAULT 0,
        pc_actuel INTEGER NOT NULL DEFAULT 0,
        enc_armure INTEGER NOT NULL DEFAULT 0,
        enc_autre INTEGER NOT NULL DEFAULT 0,
        description TEXT NOT NULL DEFAULT '',
        notes_combat TEXT NOT NULL DEFAULT '',
        notes_inventaire TEXT NOT NULL DEFAULT '',
        notes_voies TEXT NOT NULL DEFAULT '',
        notes_effets TEXT NOT NULL DEFAULT '',
        equipment_bonuses_json TEXT NOT NULL DEFAULT '{}'
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

  Future<void> _createInventoryItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_sheet_id INTEGER NOT NULL,
        name TEXT NOT NULL DEFAULT '',
        quantity INTEGER NOT NULL DEFAULT 1,
        description TEXT NOT NULL DEFAULT '',
        position INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (character_sheet_id) REFERENCES character_sheets(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Character Sheets ─────────────────────────────────────────────────────────

  Future<List<CharacterSheet>> getCharacterSheets() async {
    final db = await database;
    final rows = await db.query('character_sheets', orderBy: 'created_at DESC');
    return rows.map(CharacterSheet.fromMap).toList();
  }

  Future<CharacterSheet> insertCharacterSheet(CharacterSheet sheet) async {
    final db = await database;
    final id = await db.insert('character_sheets', sheet.toMap());
    return sheet.copyWith(id: id);
  }

  Future<void> updateCharacterSheet(CharacterSheet sheet) async {
    final db = await database;
    await db.update(
      'character_sheets',
      sheet.toMap(),
      where: 'id = ?',
      whereArgs: [sheet.id],
    );
  }

  Future<void> deleteCharacterSheet(int id) async {
    final db = await database;
    await db.delete('character_sheets', where: 'id = ?', whereArgs: [id]);
  }

  // ── Inventory Items ──────────────────────────────────────────────────────────

  Future<List<InventoryItem>> getInventoryItems(int sheetId) async {
    final db = await database;
    final rows = await db.query(
      'inventory_items',
      where: 'character_sheet_id = ?',
      whereArgs: [sheetId],
      orderBy: 'position ASC, id ASC',
    );
    return rows.map(InventoryItem.fromMap).toList();
  }

  Future<InventoryItem> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    final id = await db.insert('inventory_items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.update(
      'inventory_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteInventoryItem(int id) async {
    final db = await database;
    await db.delete('inventory_items', where: 'id = ?', whereArgs: [id]);
  }

  // ── Combat Tables helpers ────────────────────────────────────────────────────

  Future<void> _createCombatWeaponsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS combat_weapons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_sheet_id INTEGER NOT NULL,
        name TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL DEFAULT 'contact',
        portee INTEGER NOT NULL DEFAULT 0,
        equipped INTEGER NOT NULL DEFAULT 0,
        description TEXT NOT NULL DEFAULT '',
        position INTEGER NOT NULL DEFAULT 0,
        dm TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_sheet_id) REFERENCES character_sheets(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createCombatArmorsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS combat_armors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_sheet_id INTEGER NOT NULL,
        name TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL DEFAULT 'principale',
        matiere TEXT NOT NULL DEFAULT 'tissus',
        def_bonus INTEGER NOT NULL DEFAULT 0,
        enc_base INTEGER NOT NULL DEFAULT 0,
        niveau_magie INTEGER NOT NULL DEFAULT 0,
        equipped INTEGER NOT NULL DEFAULT 0,
        description TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_sheet_id) REFERENCES character_sheets(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createCombatCapacitiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS combat_capacities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_sheet_id INTEGER NOT NULL,
        name TEXT NOT NULL DEFAULT '',
        is_magique INTEGER NOT NULL DEFAULT 0,
        voie TEXT NOT NULL DEFAULT '',
        rang INTEGER NOT NULL DEFAULT 1,
        portee INTEGER NOT NULL DEFAULT 0,
        activated INTEGER NOT NULL DEFAULT 0,
        description TEXT NOT NULL DEFAULT '',
        position INTEGER NOT NULL DEFAULT 0,
        dm TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_sheet_id) REFERENCES character_sheets(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createItemEffectsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_effects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        stat_key TEXT NOT NULL,
        modifier_value INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ── Combat Weapons CRUD ──────────────────────────────────────────────────────

  Future<List<CombatWeapon>> getCombatWeapons(int sheetId) async {
    final db = await database;
    final rows = await db.query('combat_weapons',
        where: 'character_sheet_id = ?',
        whereArgs: [sheetId],
        orderBy: 'position ASC, id ASC');
    return rows.map(CombatWeapon.fromMap).toList();
  }

  Future<CombatWeapon> insertCombatWeapon(CombatWeapon w) async {
    final db = await database;
    final id = await db.insert('combat_weapons', w.toMap());
    return w.copyWith(id: id);
  }

  Future<void> updateCombatWeapon(CombatWeapon w) async {
    final db = await database;
    await db.update('combat_weapons', w.toMap(),
        where: 'id = ?', whereArgs: [w.id]);
  }

  Future<void> deleteCombatWeapon(int id) async {
    final db = await database;
    await db.delete('combat_weapons', where: 'id = ?', whereArgs: [id]);
    await db.delete('item_effects',
        where: "item_type = 'weapon' AND item_id = ?", whereArgs: [id]);
  }

  // ── Combat Armors CRUD ───────────────────────────────────────────────────────

  Future<List<CombatArmor>> getCombatArmors(int sheetId) async {
    final db = await database;
    final rows = await db.query('combat_armors',
        where: 'character_sheet_id = ?',
        whereArgs: [sheetId],
        orderBy: 'id ASC');
    return rows.map(CombatArmor.fromMap).toList();
  }

  Future<CombatArmor> insertCombatArmor(CombatArmor a) async {
    final db = await database;
    final id = await db.insert('combat_armors', a.toMap());
    return a.copyWith(id: id);
  }

  Future<void> updateCombatArmor(CombatArmor a) async {
    final db = await database;
    await db.update('combat_armors', a.toMap(),
        where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> deleteCombatArmor(int id) async {
    final db = await database;
    await db.delete('combat_armors', where: 'id = ?', whereArgs: [id]);
    await db.delete('item_effects',
        where: "item_type = 'armor' AND item_id = ?", whereArgs: [id]);
  }

  // ── Combat Capacities CRUD ───────────────────────────────────────────────────

  Future<List<CombatCapacity>> getCombatCapacities(int sheetId) async {
    final db = await database;
    final rows = await db.query('combat_capacities',
        where: 'character_sheet_id = ?',
        whereArgs: [sheetId],
        orderBy: 'position ASC, id ASC');
    return rows.map(CombatCapacity.fromMap).toList();
  }

  Future<CombatCapacity> insertCombatCapacity(CombatCapacity c) async {
    final db = await database;
    final id = await db.insert('combat_capacities', c.toMap());
    return c.copyWith(id: id);
  }

  Future<void> updateCombatCapacity(CombatCapacity c) async {
    final db = await database;
    await db.update('combat_capacities', c.toMap(),
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteCombatCapacity(int id) async {
    final db = await database;
    await db.delete('combat_capacities', where: 'id = ?', whereArgs: [id]);
    await db.delete('item_effects',
        where: "item_type = 'capacity' AND item_id = ?", whereArgs: [id]);
  }

  // ── Item Effects CRUD ────────────────────────────────────────────────────────

  Future<List<ItemEffect>> getItemEffects(String itemType, int itemId) async {
    final db = await database;
    final rows = await db.query('item_effects',
        where: 'item_type = ? AND item_id = ?',
        whereArgs: [itemType, itemId]);
    return rows.map(ItemEffect.fromMap).toList();
  }

  Future<ItemEffect> insertItemEffect(ItemEffect e) async {
    final db = await database;
    final id = await db.insert('item_effects', e.toMap());
    return e.copyWith(id: id);
  }

  Future<void> updateItemEffect(ItemEffect e) async {
    final db = await database;
    await db.update('item_effects', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteItemEffect(int id) async {
    final db = await database;
    await db.delete('item_effects', where: 'id = ?', whereArgs: [id]);
  }

  // ── Equipment Bonus Recalculation ────────────────────────────────────────────

  /// Recomputes equipment bonuses for a character sheet from all equipped/activated
  /// items and their effects. Updates [character_sheets.equipment_bonuses_json]
  /// and [enc_armure]. Returns the updated CharacterSheet, or null if not found.
  Future<CharacterSheet?> recalculateEquipmentBonuses(int sheetId) async {
    final db = await database;
    final Map<String, int> bonuses = {};

    // 1. Equipped armors → DEF + ENC
    final armorRows = await db.query('combat_armors',
        where: 'character_sheet_id = ? AND equipped = 1',
        whereArgs: [sheetId]);
    int encArmureTotal = 0;
    for (final row in armorRows) {
      final armor = CombatArmor.fromMap(row);
      bonuses['def'] = (bonuses['def'] ?? 0) + armor.defBonus;
      encArmureTotal += armor.encEffectif;
    }

    // 2. Effects from equipped weapons
    final weaponRows = await db.query('combat_weapons',
        where: 'character_sheet_id = ? AND equipped = 1',
        whereArgs: [sheetId]);
    for (final row in weaponRows) {
      final wId = row['id'] as int;
      final effects = await db.query('item_effects',
          where: "item_type = 'weapon' AND item_id = ?", whereArgs: [wId]);
      for (final e in effects) {
        final key = e['stat_key'] as String;
        bonuses[key] = (bonuses[key] ?? 0) + (e['modifier_value'] as int);
      }
    }

    // 3. Effects from equipped armors
    for (final row in armorRows) {
      final aId = row['id'] as int;
      final effects = await db.query('item_effects',
          where: "item_type = 'armor' AND item_id = ?", whereArgs: [aId]);
      for (final e in effects) {
        final key = e['stat_key'] as String;
        bonuses[key] = (bonuses[key] ?? 0) + (e['modifier_value'] as int);
      }
    }

    // 4. Effects from activated capacities
    final capacityRows = await db.query('combat_capacities',
        where: 'character_sheet_id = ? AND activated = 1',
        whereArgs: [sheetId]);
    for (final row in capacityRows) {
      final cId = row['id'] as int;
      final effects = await db.query('item_effects',
          where: "item_type = 'capacity' AND item_id = ?", whereArgs: [cId]);
      for (final e in effects) {
        final key = e['stat_key'] as String;
        bonuses[key] = (bonuses[key] ?? 0) + (e['modifier_value'] as int);
      }
    }

    // 5. Persist
    final bonusesJson = jsonEncode(bonuses);
    await db.update(
      'character_sheets',
      {'equipment_bonuses_json': bonusesJson, 'enc_armure': encArmureTotal},
      where: 'id = ?',
      whereArgs: [sheetId],
    );

    // 6. Return fresh sheet
    final rows =
        await db.query('character_sheets', where: 'id = ?', whereArgs: [sheetId]);
    if (rows.isEmpty) return null;
    return CharacterSheet.fromMap(rows.first);
  }
}
