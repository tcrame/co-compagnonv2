import 'dart:convert';

import 'database_service.dart';
import '../models/character_sheet.dart';
import '../models/character_template.dart';
import '../models/combat_weapon.dart';
import '../models/combat_armor.dart';
import '../models/combat_capacity.dart';
import '../models/inventory_item.dart';
import '../models/item_effect.dart';

class BackupService {
  final DatabaseService _db;

  BackupService(this._db);

  // ── Export ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportCharacterEntry(int sheetId) async {
    final sheets = await _db.getCharacterSheets();
    final sheet = sheets.firstWhere((s) => s.id == sheetId);
    return _buildSheetBackup(sheet);
  }

  Future<String> exportToJson() async {
    final templates = await _db.getTemplates();
    final sheets = await _db.getCharacterSheets();

    final sheetBackups = <Map<String, dynamic>>[];
    for (final sheet in sheets) {
      sheetBackups.add(await _buildSheetBackup(sheet));
    }

    final backup = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'bestiary': templates.map((t) => t.toMap()).toList(),
      'characters': sheetBackups,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<CharacterSheet> upsertCharacterEntryFromSync(
    Map<String, dynamic> entry,
  ) async {
    final rawSheet = Map<String, dynamic>.from(
      entry['sheet'] as Map<String, dynamic>,
    );
    final incoming = CharacterSheet.fromMap(rawSheet);
    final syncUuid = incoming.syncUuid;
    if (syncUuid.isEmpty) {
      throw ArgumentError('sync_uuid manquant dans la fiche synchronisée');
    }

    final existing = await _db.getCharacterSheetBySyncUuid(syncUuid);
    int targetId;

    if (existing == null) {
      final sheetToInsert = CharacterSheet.fromMap(rawSheet..remove('id'));
      final inserted = await _db.insertCharacterSheet(sheetToInsert);
      targetId = inserted.id!;
    } else {
      targetId = existing.id!;
      final mapped = CharacterSheet.fromMap({...rawSheet, 'id': targetId});
      await _db.replaceCharacterSheet(mapped);
      await _db.clearCharacterDetails(targetId);
    }

    await _importCharacterDetails(entry, targetId);
    await _db.setCharacterLastSyncedAt(targetId, DateTime.now());

    final refreshed = await _db.getCharacterSheetById(targetId);
    if (refreshed == null) {
      throw StateError('Impossible de relire la fiche synchronisée');
    }
    return refreshed;
  }

  /// Imports backup JSON. Returns a summary string on success.
  /// Throws on parse errors.
  Future<String> importFromJson(String json) async {
    final Map<String, dynamic> backup =
        jsonDecode(json) as Map<String, dynamic>;

    final bestiaryRaw =
        (backup['bestiary'] as List? ?? []).cast<Map<String, dynamic>>();
    final charactersRaw =
        (backup['characters'] as List? ?? []).cast<Map<String, dynamic>>();

    int templatesImported = 0;
    int sheetsImported = 0;

    // ── Bestiary ──────────────────────────────────────────────────────────
    for (final raw in bestiaryRaw) {
      final stripped = Map<String, dynamic>.from(raw)..remove('id');
      final template = CharacterTemplate.fromMap(stripped);
      await _db.insertTemplate(template);
      templatesImported++;
    }

    // ── Character sheets ──────────────────────────────────────────────────
    for (final entry in charactersRaw) {
      final sheetRaw = Map<String, dynamic>.from(
        entry['sheet'] as Map<String, dynamic>,
      )..remove('id');

      final sheet = CharacterSheet.fromMap(sheetRaw);
      final inserted = await _db.insertCharacterSheet(sheet);
      final newId = inserted.id!;
      await _importCharacterDetails(entry, newId);

      sheetsImported++;
    }

    return '$templatesImported créature(s) et $sheetsImported fiche(s) importées.';
  }

  Future<Map<String, dynamic>> _buildSheetBackup(CharacterSheet sheet) async {
    final id = sheet.id!;
    final weapons = await _db.getCombatWeapons(id);
    final armors = await _db.getCombatArmors(id);
    final capacities = await _db.getCombatCapacities(id);
    final inventory = await _db.getInventoryItems(id);
    final voieRangs = await _db.getVoieRangs(id);

    final weaponsWithEffects = <Map<String, dynamic>>[];
    for (final w in weapons) {
      final effects = await _db.getItemEffects('weapon', w.id!);
      weaponsWithEffects.add({
        'weapon': w.toMap(),
        'effects': effects.map((e) => e.toMap()).toList(),
      });
    }

    final armorsWithEffects = <Map<String, dynamic>>[];
    for (final a in armors) {
      final effects = await _db.getItemEffects('armor', a.id!);
      armorsWithEffects.add({
        'armor': a.toMap(),
        'effects': effects.map((e) => e.toMap()).toList(),
      });
    }

    return {
      'sheet': sheet.toMap(),
      'inventory': inventory.map((i) => i.toMap()).toList(),
      'weapons': weaponsWithEffects,
      'armors': armorsWithEffects,
      'capacities': capacities.map((c) => c.toMap()).toList(),
      'voieRangs': voieRangs,
    };
  }

  Future<void> _importCharacterDetails(
    Map<String, dynamic> entry,
    int targetSheetId,
  ) async {
    for (final raw
        in (entry['inventory'] as List? ?? []).cast<Map<String, dynamic>>()) {
      final m =
          Map<String, dynamic>.from(raw)
            ..remove('id')
            ..['character_sheet_id'] = targetSheetId;
      await _db.insertInventoryItem(InventoryItem.fromMap(m));
    }

    for (final entry2
        in (entry['weapons'] as List? ?? []).cast<Map<String, dynamic>>()) {
      final weapRaw =
          Map<String, dynamic>.from(entry2['weapon'] as Map<String, dynamic>)
            ..remove('id')
            ..['character_sheet_id'] = targetSheetId;
      final weap = await _db.insertCombatWeapon(CombatWeapon.fromMap(weapRaw));
      for (final er
          in (entry2['effects'] as List? ?? []).cast<Map<String, dynamic>>()) {
        final em =
            Map<String, dynamic>.from(er)
              ..remove('id')
              ..['item_type'] = 'weapon'
              ..['item_id'] = weap.id;
        await _db.insertItemEffect(ItemEffect.fromMap(em));
      }
    }

    for (final entry2
        in (entry['armors'] as List? ?? []).cast<Map<String, dynamic>>()) {
      final armorRaw =
          Map<String, dynamic>.from(entry2['armor'] as Map<String, dynamic>)
            ..remove('id')
            ..['character_sheet_id'] = targetSheetId;
      final armor = await _db.insertCombatArmor(CombatArmor.fromMap(armorRaw));
      for (final er
          in (entry2['effects'] as List? ?? []).cast<Map<String, dynamic>>()) {
        final em =
            Map<String, dynamic>.from(er)
              ..remove('id')
              ..['item_type'] = 'armor'
              ..['item_id'] = armor.id;
        await _db.insertItemEffect(ItemEffect.fromMap(em));
      }
    }

    for (final raw
        in (entry['capacities'] as List? ?? []).cast<Map<String, dynamic>>()) {
      final m =
          Map<String, dynamic>.from(raw)
            ..remove('id')
            ..['character_sheet_id'] = targetSheetId;
      await _db.insertCombatCapacity(CombatCapacity.fromMap(m));
    }

    final voieRangs = (entry['voieRangs'] as Map<String, dynamic>? ?? {});
    for (final e in voieRangs.entries) {
      await _db.setVoieRang(targetSheetId, e.key, e.value as int);
    }
  }
}
