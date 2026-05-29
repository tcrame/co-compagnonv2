import 'package:flutter/foundation.dart';

import '../models/character_sheet.dart';
import '../services/database_service.dart';

class CharacterSheetProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<CharacterSheet> _sheets = [];
  bool _loading = false;

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
    notifyListeners();
  }
}
