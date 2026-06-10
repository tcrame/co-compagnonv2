import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/creature_collection.dart';
import '../models/character_template.dart';
import '../services/database_service.dart';

class CollectionProvider extends ChangeNotifier {
  final _db = DatabaseService();

  // URL de ton Cloudflare Worker (remplace par ton URL de prod)
  final String _workerUrl = const String.fromEnvironment('SYNC_API_BASE_URL');


  List<CreatureCollection> _collections = [];
  bool _loading = false;

  List<CreatureCollection> get collections => _collections;
  bool get loading => _loading;

  // Tri "humain" calqué sur ton BestiaryProvider pour ignorer les accents
  int _compareNames(String a, String b) {
    String removeAccents(String str) {
      const withDiag = 'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
      const noDiag   = 'AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy';
      String result = str.toLowerCase();
      for (int i = 0; i < withDiag.length; i++) {
        result = result.replaceAll(withDiag[i], noDiag[i]);
      }
      return result;
    }
    return removeAccents(a).compareTo(removeAccents(b));
  }

  /// Charge toutes les collections locales depuis SQLite
  Future<void> loadCollections() async {
    _loading = true;
    notifyListeners();
    try {
      _collections = await _db.getCollections();
      _collections.sort((a, b) => _compareNames(a.name, b.name));
    } catch (e) {
      debugPrint('Erreur lors du chargement des collections : $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Crée une nouvelle collection vide
  Future<void> createCollection(String name) async {
    try {
      // On génère tout de suite un UUID unique pour le futur partage
      final syncUuid = const Uuid().v4();
      final newCol = await _db.insertCollection(name, syncUuid: syncUuid);
      _collections.add(newCol);
      _collections.sort((a, b) => _compareNames(a.name, b.name));
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur création collection : $e');
    }
  }

  /// Supprime une collection
  Future<void> deleteCollection(int id) async {
    try {
      await _db.deleteCollection(id);
      _collections.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur suppression collection : $e');
    }
  }

  /// Ajoute un monstre à une collection
  Future<void> addMonsterToCollection(CreatureCollection collection, CharacterTemplate template) async {
    if (collection.id == null || template.id == null) return;
    try {
      await _db.addTemplateToCollection(collection.id!, template.id!);

      // Mise à jour de l'état local en mémoire
      final idx = _collections.indexWhere((c) => c.id == collection.id);
      if (idx != -1) {
        final currentTemplates = List<CharacterTemplate>.from(_collections[idx].templates);
        if (!currentTemplates.any((t) => t.id == template.id)) {
          currentTemplates.add(template);
          currentTemplates.sort((a, b) => _compareNames(a.name, b.name));
          _collections[idx] = _collections[idx].copyWith(templates: currentTemplates);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Erreur ajout monstre à la collection : $e');
    }
  }

  /// Retire un monstre d'une collection
  Future<void> removeMonsterFromCollection(CreatureCollection collection, int templateId) async {
    if (collection.id == null) return;
    try {
      await _db.removeTemplateFromCollection(collection.id!, templateId);

      final idx = _collections.indexWhere((c) => c.id == collection.id);
      if (idx != -1) {
        final currentTemplates = List<CharacterTemplate>.from(_collections[idx].templates);
        currentTemplates.removeWhere((t) => t.id == templateId);
        _collections[idx] = _collections[idx].copyWith(templates: currentTemplates);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur retrait monstre de la collection : $e');
    }
  }

  // ── Sychronisation & Partage (API) ──────────────────────────────────────────

  /// Envoie une collection et ses monstres vers Cloudflare Worker (Route protégée)
  Future<String?> shareCollection(CreatureCollection collection, String googleIdToken) async {
    if (collection.templates.isEmpty) return 'Impossible de partager une collection vide.';

    try {
      final response = await http.post(
        Uri.parse('$_workerUrl/sync/collection/share'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $googleIdToken', // Token requis par ta barrière de sécurité
        },
        body: jsonEncode({
          'sync_uuid': collection.syncUuid,
          'name': collection.name,
          // Convertit tous les monstres liés en dictionnaire JSON pour le data_blob distant
          'templates': collection.templates.map((t) => t.toMap()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        // Renvoie l'UUID qui servira à générer le code ou le lien de partage
        return collection.syncUuid;
      } else {
        final err = jsonDecode(response.body);
        return 'Erreur serveur : ${err['error'] ?? 'Inconnue'}';
      }
    } catch (e) {
      return 'Échec de connexion au serveur de partage.';
    }
  }

  /// Télécharge une collection partagée via son UUID et l'injecte localement (Route publique)
  Future<bool> importCollectionFromShare(String syncUuid) async {
    try {
      final response = await http.post(
        Uri.parse('$_workerUrl/sync/collection/get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sync_uuid': syncUuid}),
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final String collectionName = data['name'];
      final List<dynamic> templatesRaw = data['templates'];

      // 1. Insertion de la structure de l'en-tête de la collection
      final newCol = await _db.insertCollection(collectionName, syncUuid: syncUuid);

      // 2. Insertion des monstres téléchargés et création des liaisons pivots
      for (final raw in templatesRaw) {
        // On convertit proprement l'élément dynamique en Map manipulable
        final Map<String, dynamic> rawMap = Map<String, dynamic>.from(raw as Map);

        // 💡 PROTECTION DE TYPE : On recode en chaînes JSON textuelles si le serveur
        // nous a renvoyé des structures d'objets Dart natives.
        if (rawMap['attacks_json'] != null && rawMap['attacks_json'] is! String) {
          rawMap['attacks_json'] = jsonEncode(rawMap['attacks_json']);
        }
        if (rawMap['capacities_json'] != null && rawMap['capacities_json'] is! String) {
          rawMap['capacities_json'] = jsonEncode(rawMap['capacities_json']);
        }
        if (rawMap['superior_stats_json'] != null && rawMap['superior_stats_json'] is! String) {
          rawMap['superior_stats_json'] = jsonEncode(rawMap['superior_stats_json']);
        }

        // On peut maintenant instancier le template sans risque de crash !
        final template = CharacterTemplate.fromMap(rawMap);

        // On insère le monstre dans le bestiaire global (génère un nouvel ID local)
        final savedTemplate = await _db.insertTemplate(template);

        // On lie ce monstre à la nouvelle collection importée
        await _db.addTemplateToCollection(newCol.id!, savedTemplate.id!);
      }

      // 3. Rechargement complet de l'état pour rafraîchir l'interface graphique
      await loadCollections();
      return true;
    } catch (e, stack) {
      debugPrint('Erreur critique lors de l\'import de la collection : $e');
      debugPrint('$stack');
      return false;
    }
  }

  /// Supprime la collection du Cloudflare Worker sans la supprimer localement
  Future<String?> unshareCollection(String syncUuid, String googleIdToken) async {
    try {
      final response = await http.post(
        // 💡 Assure-toi que cette route correspond bien à ton Worker Cloudflare !
        Uri.parse('$_workerUrl/sync/collection/unshare'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $googleIdToken',
        },
        body: jsonEncode({
          'sync_uuid': syncUuid,
        }),
      );

      if (response.statusCode == 200) {
        return null; // Renvoie null si tout s'est bien passé (pas d'erreur)
      } else {
        final err = jsonDecode(response.body);
        return 'Erreur serveur : ${err['error'] ?? 'Inconnue'}';
      }
    } catch (e) {
      return 'Échec de connexion au serveur pour retirer le partage.';
    }
  }
}