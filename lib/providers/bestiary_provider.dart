import 'package:flutter/foundation.dart';

import '../models/character_template.dart';
import '../services/database_service.dart';

class BestiaryProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<CharacterTemplate> _templates = [];
  bool _loading = false;

  List<CharacterTemplate> get templates => _templates;
  bool get loading => _loading;

  // 💡 PETITE FONCTION MAISON : Supprime les accents pour un tri parfait
  int _compareNames(CharacterTemplate a, CharacterTemplate b) {
    String removeAccents(String str) {
      const withDiag = 'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
      const noDiag   = 'AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy';

      String result = str.toLowerCase();
      for (int i = 0; i < withDiag.length; i++) {
        result = result.replaceAll(withDiag[i], noDiag[i]);
      }
      return result;
    }

    return removeAccents(a.name).compareTo(removeAccents(b.name));
  }

  Future<void> loadTemplates() async {
    _loading = true;
    notifyListeners();
    _templates = await _db.getTemplates();
    // 💡 AJOUT : On trie également au chargement initial de la base de données
    _templates.sort(_compareNames);
    _loading = false;
    notifyListeners();
  }

  Future<CharacterTemplate> addTemplate(CharacterTemplate template) async {
    final saved = await _db.insertTemplate(template);
    _templates.add(saved);
    // 💡 MODIFICATION : Utilisation de la nouvelle fonction de tri
    _templates.sort(_compareNames);
    notifyListeners();
    return saved;
  }

  Future<void> updateTemplate(CharacterTemplate template) async {
    await _db.updateTemplate(template);
    final idx = _templates.indexWhere((t) => t.id == template.id);
    if (idx != -1) _templates[idx] = template;
    // 💡 MODIFICATION : Utilisation de la nouvelle fonction de tri
    _templates.sort(_compareNames);
    notifyListeners();
  }

  Future<void> deleteTemplate(int id) async {
    await _db.deleteTemplate(id);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
