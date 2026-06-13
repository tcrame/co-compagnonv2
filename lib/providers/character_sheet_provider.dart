import 'package:flutter/foundation.dart';

import '../constants/voies_data.dart';
import '../models/character_sheet.dart';
import '../services/database_service.dart';

class CharacterSheetProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<CharacterSheet> _sheets = [];
  bool _loading = false;

  // ── Voie rangs state ─────────────────────────────────────────────────────────
  // Maps sheetId → { voieId → rangActuel }
  final Map<int, Map<String, int>> _voieRangsCache = {};

  List<CharacterSheet> get sheets => _sheets;
  bool get loading => _loading;

  Future<void> loadSheets() async {
    _loading = true;
    notifyListeners();
    _sheets = await _db.getCharacterSheets();
    _loading = false;
    notifyListeners();
  }

  Future<CharacterSheet> createSheet(String name) async {
    final sheet = CharacterSheet(name: name);
    final saved = await _db.insertCharacterSheet(sheet);
    _sheets.insert(0, saved);
    notifyListeners();
    return saved;
  }

  Future<void> saveSheet(CharacterSheet sheet) async {
    await _db.updateCharacterSheet(sheet);
    final idx = _sheets.indexWhere((s) => s.id == sheet.id);
    if (idx != -1) {
      _sheets[idx] = sheet;
      notifyListeners();
    }
  }

  Future<void> deleteSheet(int id) async {
    await _db.deleteCharacterSheet(id);
    _sheets.removeWhere((s) => s.id == id);
    _voieRangsCache.remove(id);
    notifyListeners();
  }

  // ── Voie rangs ───────────────────────────────────────────────────────────────

  /// Loads voie rangs for a character sheet into the cache.
  Future<Map<String, int>> loadVoieRangs(int sheetId) async {
    final rangs = await _db.getVoieRangs(sheetId);
    _voieRangsCache[sheetId] = rangs;
    notifyListeners();
    return rangs;
  }

  /// Returns cached voie rangs (empty map if not loaded yet).
  Map<String, int> getVoieRangs(int sheetId) =>
      _voieRangsCache[sheetId] ?? {};

  /// Sets a voie rang, persists to DB, updates cache, and auto-syncs combat capacities.
  Future<void> setVoieRang(int sheetId, String voieId, int rang) async {
    final oldRang = (_voieRangsCache[sheetId] ?? {})[voieId] ?? 0;
    await _db.setVoieRang(sheetId, voieId, rang);
    final cache = _voieRangsCache[sheetId] ?? {};
    cache[voieId] = rang;
    _voieRangsCache[sheetId] = cache;

    // Sync combat capacities for types A, M, L
    final voie = getVoieById(voieId);
    if (voie != null) {
      if (rang > oldRang) {
        // Newly unlocked rangs
        for (int r = oldRang + 1; r <= rang; r++) {
          final cap = voie.capaciteAtRang(r);
          if (cap != null && const ['A', 'M', 'L'].contains(cap.type)) {
            await _db.upsertVoieCombatCapacity(
              sheetId: sheetId,
              voieCatalogueId: voieId,
              rang: r,
              voieNom: voie.nom,
              nom: cap.nom,
              description: cap.description,
              isMagique: cap.isMagique,
            );
          }
        }
      } else if (rang < oldRang) {
        // Removed rangs
        await _db.deleteVoieCombatCapacitiesFromRang(sheetId, voieId, rang + 1);
      }
    }

    notifyListeners();
  }

  /// Returns true if this character has at least one rang > 0.
  Future<bool> hasAnyRangUnlocked(int sheetId) =>
      _db.hasAnyRangUnlocked(sheetId);

  /// Resets voie rangs and initialises the 5 voies for the new profil.
  /// Also removes all auto-managed combat capacities.
  Future<void> initVoiesForProfil(int sheetId, String profil) async {
    await _db.initVoiesForProfil(sheetId, profil);
    await _db.deleteAllVoieCombatCapacities(sheetId);
    // Reload the fresh rangs into cache
    await loadVoieRangs(sheetId);
  }

  /// Computes the total PC spent for a character based on their voie rangs.
  /// Coût : rang 1-2 = 1 PC each, rang 3-5 = 2 PC each.
  /// Voie de peuple (IDs starting with 'peuple_') are excluded from this budget.
  int getPcDepense(int sheetId) {
    final rangs = _voieRangsCache[sheetId] ?? {};
    int total = 0;
    for (final entry in rangs.entries) {
      if (entry.key.startsWith('peuple_')) continue; // voie de peuple excluded
      final voie = getVoieById(entry.key);
      if (voie == null) continue;
      final rangActuel = entry.value;
      for (int r = 1; r <= rangActuel; r++) {
        total += r <= 2 ? 1 : 2;
      }
    }
    return total;
  }

  /// Number of unlocked magic capacities (isMagique == true) for a character.
  /// PM max = magicCapacitiesKnown + VOL
  int getMagicCapacitesCount(int sheetId) {
    final rangs = _voieRangsCache[sheetId] ?? {};
    int count = 0;
    for (final entry in rangs.entries) {
      final voie = getVoieById(entry.key);
      if (voie == null) continue;
      final rangActuel = entry.value;
      for (final cap in voie.capacites) {
        if (cap.rang <= rangActuel && cap.isMagique) count++;
      }
    }
    return count;
  }

  /// Sets the voie de peuple for a character, persists to DB, updates cache and sheets.
  /// Rang 1 is always free and auto-selected (done in DB layer).
  Future<void> setVoiePeuple(int sheetId, String voieId) async {
    await _db.setVoiePeupleId(sheetId, voieId);
    // Update cache: rang 1 auto-selected for non-empty voie
    if (voieId.isNotEmpty) {
      final cache = _voieRangsCache[sheetId] ?? {};
      if ((cache[voieId] ?? 0) < 1) cache[voieId] = 1;
      _voieRangsCache[sheetId] = cache;
    }
    // Update the in-memory sheet
    final idx = _sheets.indexWhere((s) => s.id == sheetId);
    if (idx != -1) {
      _sheets[idx] = _sheets[idx].copyWith(voiePeupleId: voieId);
    }
    notifyListeners();
  }

  /// Stores the original peuple voie ID when Voie du Mage is chosen.
  Future<void> setVoiePeupleOrigine(int sheetId, String origineId) async {
    await _db.setVoiePeupleOrigineId(sheetId, origineId);
    // Ensure rang 1 is set for the original voie in cache
    if (origineId.isNotEmpty) {
      final cache = _voieRangsCache[sheetId] ?? {};
      if ((cache[origineId] ?? 0) < 1) cache[origineId] = 1;
      _voieRangsCache[sheetId] = cache;
    }
    final idx = _sheets.indexWhere((s) => s.id == sheetId);
    if (idx != -1) {
      _sheets[idx] = _sheets[idx].copyWith(voiePeupleOrigineId: origineId);
    }
    notifyListeners();
  }

  /// Marks the free rang 2 of the mage heritage as taken (or resets it).
  Future<void> setVoieMageRang2Pris(int sheetId, bool pris) async {
    await _db.setVoieMageRang2Pris(sheetId, pris);
    final idx = _sheets.indexWhere((s) => s.id == sheetId);
    if (idx != -1) {
      _sheets[idx] = _sheets[idx].copyWith(voieMageRang2Pris: pris);
    }
    notifyListeners();
  }

  /// Sets the prestige path for a character. Unlike voie peuple, prestige paths
  /// do not auto-select any rank; the player must manually select capabilities.
  Future<void> setVoiePrestige(int sheetId, String voieId) async {
    await _db.setVoiePrestigeId(sheetId, voieId);
    final idx = _sheets.indexWhere((s) => s.id == sheetId);
    if (idx != -1) {
      _sheets[idx] = _sheets[idx].copyWith(voiePrestigeId: voieId);
    }
    notifyListeners();
  }
}
