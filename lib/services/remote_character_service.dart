import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

enum CloudCharacterCategory {
  owned,
  writeShared,
  readShared,
}

enum CloudSharePermission {
  read,
  write,
}

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
    final rawPermission = (map['permission_type'] as String? ?? 'owner').toLowerCase();
    return CloudCharacterInfo(
      syncUuid: map['sync_uuid'] as String? ?? '',
      name: map['name'] as String? ?? '(Sans nom)',
      level: (map['level'] as num?)?.toInt(),
      profile: map['profile'] as String? ?? '',
      race: map['race'] as String? ?? '',
      lastModifiedAt: () {
        final raw = map['last_modified_at'] as String?;
        if (raw == null || raw.isEmpty) return null;
        return DateTime.tryParse(raw);
      }(),
      accessType: rawPermission == 'read' || rawPermission == 'write'
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
    final rawPermission = (map['permission_type'] as String? ?? 'read').toLowerCase();
    return CloudCharacterShareInfo(
      shareId: (map['share_id'] as num?)?.toInt() ?? 0,
      syncUuid: map['sync_uuid'] as String? ?? '',
      sharedWithUserId: map['shared_with_user_id'] as String? ?? '',
      sharedWithEmail: map['shared_with_email'] as String? ?? '',
      permissionType:
          rawPermission == 'write' ? CloudSharePermission.write : CloudSharePermission.read,
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
    final token = await _authService.getToken();
    if (token == null) {
      throw StateError('Utilisateur non connecté. Impossible de synchroniser.');
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
    final headers = await _getSecureHeaders(); // 🔒 Récupération du token

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

  Future<Map<String, dynamic>> pullCharacter({
    required String syncUuid,
  }) async {
    final headers = await _getSecureHeaders(); // 🔒 Récupération du token

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
    final headers = await _getSecureHeaders(); // 🔒 Récupération du token

    final response = await _client.post(
      _uri('/sync/list'),
      headers: headers,
      body: jsonEncode({}),
    );
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = <Map<String, dynamic>>[];
    rows.addAll(_extractCharacters(payload, 'owned_characters', 'owner'));
    rows.addAll(_extractCharacters(payload, 'write_shared_characters', 'write'));
    rows.addAll(_extractCharacters(payload, 'read_shared_characters', 'read'));
    return rows.map(CloudCharacterInfo.fromMap).toList();
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
        'permission_type': permissionType == CloudSharePermission.write ? 'write' : 'read',
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

  List<Map<String, dynamic>> _extractCharacters(
    Map<String, dynamic> payload,
    String key,
    String permissionType,
  ) {
    final raw = (payload[key] as List? ?? []).cast<Map<String, dynamic>>();
    return raw
        .map(
          (row) => <String, dynamic>{
            ...row,
            'permission_type': permissionType,
          },
        )
        .toList();
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

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw StateError(
      'Sync API error (${response.statusCode}): ${response.body}',
    );
  }
}