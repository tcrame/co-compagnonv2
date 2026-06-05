import 'dart:convert';
import 'package:http/http.dart' as http;

// N'oubliez pas d'importer le service d'authentification que nous avons créé
import 'auth_service.dart';

class CloudCharacterInfo {
  CloudCharacterInfo({
    required this.syncUuid,
    required this.name,
    required this.level,
    required this.profile,
    required this.race,
    required this.lastModifiedAt,
  });

  final String syncUuid;
  final String name;
  final int? level;
  final String profile;
  final String race;
  final DateTime? lastModifiedAt;

  factory CloudCharacterInfo.fromMap(Map<String, dynamic> map) {
    return CloudCharacterInfo(
      syncUuid: map['sync_uuid'] as String? ?? '',
      name: map['name'] as String? ?? '(Sans nom)',
      level: map['level'] as int?,
      profile: map['profile'] as String? ?? '',
      race: map['race'] as String? ?? '',
      lastModifiedAt: () {
        final raw = map['last_modified_at'] as String?;
        if (raw == null || raw.isEmpty) return null;
        return DateTime.tryParse(raw);
      }(),
    );
  }
}

class RemoteCharacterService {
  RemoteCharacterService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl =
        (baseUrl ?? const String.fromEnvironment('SYNC_API_BASE_URL')).trim();

  final http.Client _client;
  final String _baseUrl;
  final AuthService _authService = AuthService(); // Ajout du service d'authentification

  bool get isConfigured => _baseUrl.isNotEmpty;

  Uri _uri(String path) {
    if (_baseUrl.isEmpty) {
      throw StateError(
        'SYNC_API_BASE_URL manquante. Lancez Flutter avec '
            '--dart-define=SYNC_API_BASE_URL=https://votre-api',
      );
    }
    return Uri.parse('$_baseUrl$path');
  }

  // --- MÉTHODE UTILITAIRE POUR LES HEADERS SÉCURISÉS ---
  Future<Map<String, String>> _getSecureHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw StateError('Utilisateur non connecté. Impossible de synchroniser.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 🗑️ SUPPRESSION: Le paramètre password a disparu
  Future<void> pushCharacter({
    required String syncUuid,
    required Map<String, dynamic> characterEntry,
    required String lastModifiedAt,
  }) async {
    final headers = await _getSecureHeaders(); // 🔒 Récupération du token

    final response = await _client.post(
      _uri('/sync/push'),
      headers: headers,
      body: jsonEncode({
        'sync_uuid': syncUuid,
        // 🗑️ SUPPRESSION: password retiré du JSON
        'character_blob': characterEntry,
        'last_modified_at': lastModifiedAt,
      }),
    );
    _ensureSuccess(response);
  }

  // 🗑️ SUPPRESSION: Le paramètre password a disparu
  Future<Map<String, dynamic>> pullCharacter({
    required String syncUuid,
  }) async {
    final headers = await _getSecureHeaders(); // 🔒 Récupération du token

    final response = await _client.post(
      _uri('/sync/pull'),
      headers: headers,
      body: jsonEncode({'sync_uuid': syncUuid}), // 🗑️ SUPPRESSION: password retiré du JSON
    );
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final blob = payload['character_blob'];
    if (blob is! Map<String, dynamic>) {
      throw StateError('Réponse distante invalide: character_blob manquant');
    }
    return blob;
  }

  Future<List<CloudCharacterInfo>> listCharacters() async {
    final headers = await _getSecureHeaders(); // 🔒 Récupération du token

    final response = await _client.post(
      _uri('/sync/list'),
      headers: headers,
      body: jsonEncode({}),
    );
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final raw =
    (payload['characters'] as List? ?? []).cast<Map<String, dynamic>>();
    return raw.map(CloudCharacterInfo.fromMap).toList();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw StateError(
      'Sync API error (${response.statusCode}): ${response.body}',
    );
  }
}