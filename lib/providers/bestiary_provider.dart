import 'package:flutter/foundation.dart';

import '../models/character_template.dart';
import '../services/database_service.dart';

class BestiaryProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<CharacterTemplate> _templates = [];
  bool _loading = false;

  List<CharacterTemplate> get templates => _templates;
  bool get loading => _loading;

  Future<void> loadTemplates() async {
    _loading = true;
    notifyListeners();
    _templates = await _db.getTemplates();
    _loading = false;
    notifyListeners();
  }

  Future<CharacterTemplate> addTemplate(CharacterTemplate template) async {
    final saved = await _db.insertTemplate(template);
    _templates.add(saved);
    _templates.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return saved;
  }

  Future<void> updateTemplate(CharacterTemplate template) async {
    await _db.updateTemplate(template);
    final idx = _templates.indexWhere((t) => t.id == template.id);
    if (idx != -1) _templates[idx] = template;
    _templates.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> deleteTemplate(int id) async {
    await _db.deleteTemplate(id);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
