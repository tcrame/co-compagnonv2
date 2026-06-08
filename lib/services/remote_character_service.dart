import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

enum CloudCharacterCategory { owned, writeShared, readShared }

enum CloudSharePermission { read, write }

class CloudCharacterInfo {
  CloudCharacterInfo({
    required this.syncUuid,
    required this.name,
    required this.level,
    required this.profile,
    required this.race,
    required this.lastModifiedAt,
    required this.accessType,
    required this.ownerUserId,
    required this.ownerEmail,
  });

  final String syncUuid;
  final String name;
  final int? level;
  final String profile;
  final String race;
  final DateTime? lastModifiedAt;
  final String accessType;
  final String? ownerUserId;
  final String? ownerEmail;

  bool get isOwned => accessType == 'owner';

  bool get canWrite => accessType == 'owner' || accessType == 'write';

  CloudCharacterCategory get category {
    if (accessType == 'write') return CloudCharacterCategory.writeShared;
    if (accessType == 'read') return CloudCharacterCategory.readShared;
    return CloudCharacterCategory.owned;
  }

  String get categoryLabel {
    if (category == CloudCharacterCategory.writeShared) {
      return 'Partagés en écriture';
    }
    if (category == CloudCharacterCategory.readShared) {
      return 'Partagés en lecture';
    }
    return 'Mes Personnages';
  }

  factory CloudCharacterInfo.fromMap(Map<String, dynamic> map) {
    final rawPermission =
        (map['permission_type'] as String? ?? 'owner').toLowerCase();

    // Sécurisation du décodage du niveau
    int? parsedLevel;
    if (map['level'] != null) {
      if (map['level'] is num) {
        parsedLevel = (map['level'] as num).toInt();
      } else if (map['level'] is String) {
        parsedLevel = int.tryParse(map['level'] as String);
      }
    }

    return CloudCharacterInfo(
      syncUuid: map['sync_uuid'] as String? ?? '',
      name: map['name'] as String? ?? '(Sans nom)',
      level: parsedLevel,
      profile: map['profile'] as String? ?? '',
      race: map['race'] as String? ?? '',
      lastModifiedAt: () {
        final raw = map['last_modified_at'];
        if (raw == null || raw.toString().isEmpty) return null;
        return DateTime.tryParse(raw.toString());
      }(),
      accessType:
          rawPermission == 'read' || rawPermission == 'write'
              ? rawPermission
              : 'owner',
      ownerUserId: map['owner_user_id'] as String?,
      ownerEmail: map['owner_email'] as String?,
    );
  }
}

class CloudCharacterShareInfo {
  CloudCharacterShareInfo({
    required this.shareId,
    required this.syncUuid,
    required this.sharedWithUserId,
    required this.sharedWithEmail,
    required this.permissionType,
    required this.createdAt,
  });

  final int shareId;
  final String syncUuid;
  final String sharedWithUserId;
  final String sharedWithEmail;
  final CloudSharePermission permissionType;
  final DateTime? createdAt;

  factory CloudCharacterShareInfo.fromMap(Map<String, dynamic> map) {
    final rawPermission =
        (map['permission_type'] as String? ?? 'read').toLowerCase();
    return CloudCharacterShareInfo(
      shareId: (map['share_id'] as num?)?.toInt() ?? 0,
      syncUuid: map['sync_uuid'] as String? ?? '',
      sharedWithUserId: map['shared_with_user_id'] as String? ?? '',
      sharedWithEmail: map['shared_with_email'] as String? ?? '',
      permissionType:
          rawPermission == 'write'
              ? CloudSharePermission.write
              : CloudSharePermission.read,
      createdAt: () {
        final raw = map['created_at'] as String?;
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
  final AuthService _authService = AuthService();

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

  Future<Map<String, String>> _getSecureHeaders() async {
    // 1. Récupération du token depuis l'instance unique
    final token = await _authService.getToken();

    // 🔍 LOG DE CONTRÔLE SÉCURISÉ : On affiche juste les 15 premiers caractères du jeton s'il existe
    if (token != null && token.isNotEmpty) {
      final preview = token.length > 15 ? '${token.substring(0, 15)}...' : token;
      print("[RemoteService] Jeton envoyé au Worker : Présent ($preview)");
    } else {
      print("[RemoteService] Jeton envoyé au Worker : NULL ou Vide");
    }

    if (token == null || token.isEmpty || token == "null") {
      throw StateError('Utilisateur non connecté ou session corrompue. Impossible de synchroniser.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> pushCharacter({
    required String syncUuid,
    required Map<String, dynamic> characterEntry,
    required String lastModifiedAt,
  }) async {
    final headers = await _getSecureHeaders();

    final response = await _client.post(
      _uri('/sync/push'),
      headers: headers,
      body: jsonEncode({
        'sync_uuid': syncUuid,
        'character_blob': characterEntry,
        'last_modified_at': lastModifiedAt,
      }),
    );
    _ensureSuccess(response);
  }

  Future<Map<String, dynamic>> pullCharacter({required String syncUuid}) async {
    final headers = await _getSecureHeaders();

    final response = await _client.post(
      _uri('/sync/pull'),
      headers: headers,
      body: jsonEncode({'sync_uuid': syncUuid}),
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
    final headers = await _getSecureHeaders();

    final response = await _client.post(
      _uri('/sync/list'),
      headers: headers,
      body: jsonEncode({}),
    );
    _ensureSuccess(response);

    final Map<String, dynamic> payload = jsonDecode(response.body);
    final List<dynamic> characterList =
        payload['characters'] as List<dynamic>? ?? [];

    return characterList
        .map((c) => CloudCharacterInfo.fromMap(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> shareCharacter({
    required String syncUuid,
    required String email,
    required CloudSharePermission permissionType,
  }) async {
    final headers = await _getSecureHeaders();
    final response = await _client.post(
      _uri('/sync/share'),
      headers: headers,
      body: jsonEncode({
        'sync_uuid': syncUuid,
        'email': email,
        'permission_type':
            permissionType == CloudSharePermission.write ? 'write' : 'read',
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> revokeCharacterShare({
    required String syncUuid,
    String? sharedWithUserId,
    String? email,
  }) async {
    final headers = await _getSecureHeaders();
    final response = await _client.post(
      _uri('/sync/revoke'),
      headers: headers,
      body: jsonEncode({
        'sync_uuid': syncUuid,
        if (sharedWithUserId != null && sharedWithUserId.isNotEmpty)
          'shared_with_user_id': sharedWithUserId,
        if (email != null && email.isNotEmpty) 'email': email,
      }),
    );
    _ensureSuccess(response);
  }

  Future<List<CloudCharacterShareInfo>> listShares({
    required String syncUuid,
  }) async {
    final headers = await _getSecureHeaders();
    final response = await _client.post(
      _uri('/sync/shares'),
      headers: headers,
      body: jsonEncode({'sync_uuid': syncUuid}),
    );
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (payload['shares'] as List? ?? []).cast<Map<String, dynamic>>();
    return raw.map(CloudCharacterShareInfo.fromMap).toList();
  }

  Future<void> deleteRemoteCharacter({required String syncUuid}) async {
    final headers = await _getSecureHeaders();

    final response = await _client.post(
      _uri('/sync/delete'),
      headers: headers,
      body: jsonEncode({'sync_uuid': syncUuid}),
    );
    _ensureSuccess(response);
  }

  Future<Map<String, dynamic>> getCloudProfileInfo() async {
    final headers = await _getSecureHeaders();

    final response = await _client.post(
      _uri('/sync/list'),
      headers: headers,
      body: jsonEncode({}),
    );
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    return {
      'role': payload['role'] as String? ?? 'free',
      'total': payload['total'] as int? ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> searchCloudIcons(String query) async {
    // Si l'URL de ton API est vide, on lève une erreur
    if (!isConfigured) return [];

    try {
      final response = await _client.post(
        _uri('/icons/search'),
        headers: {
          'Content-Type': 'application/json',
          // Pas besoin de token d'authentification ici si tu as mis la route publique,
          // sinon utilise: ...(await _getSecureHeaders())
        },
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode != 200) return [];

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawIcons = payload['icons'] as List<dynamic>? ?? [];

      return rawIcons.map((icon) => icon as Map<String, dynamic>).toList();
    } catch (_) {
      return []; // En cas d'erreur réseau, on renvoie une liste vide pour éviter le crash
    }
  }

  Future<Map<String, dynamic>?> getSpectatorSession(String shortCode) async {
    if (!isConfigured) return null;
    try {
      final response = await _client.post(
        _uri('/session/spectate'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({'short_code': shortCode}), // Envoi du code court épuré
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> pushCombatSession({
    required String sessionCode, // 💡 Changé int en String pour le code aléatoire
    required String sessionName,
    required Map<String, dynamic> combatBlob,
  }) async {
    if (!isConfigured) return false;
    try {
      final response = await _client.post(
        _uri('/session/push'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({
          'session_id': sessionCode,
          'session_name': sessionName,
          'combat_blob': combatBlob,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw StateError(
      'Sync API error (${response.statusCode}): ${response.body}',
    );
  }
}
