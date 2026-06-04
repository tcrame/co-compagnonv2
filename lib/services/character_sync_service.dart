import 'package:uuid/uuid.dart';

import '../models/character_sheet.dart';
import 'backup_service.dart';
import 'database_service.dart';
import 'remote_character_service.dart';

class SyncConflictException implements Exception {
  SyncConflictException({
    required this.direction,
    required this.localLastModifiedAt,
    required this.remoteLastModifiedAt,
  });

  final String direction; // push | pull
  final DateTime localLastModifiedAt;
  final DateTime remoteLastModifiedAt;

  @override
  String toString() {
    if (direction == 'push') {
      return 'Conflit: version distante plus récente que locale.';
    }
    return 'Conflit: version locale plus récente que distante.';
  }
}

class CharacterSyncService {
  CharacterSyncService({
    DatabaseService? databaseService,
    BackupService? backupService,
    RemoteCharacterService? remoteService,
    Uuid? uuid,
  }) : _db = databaseService ?? DatabaseService(),
       _backup =
           backupService ?? BackupService(databaseService ?? DatabaseService()),
       _remote = remoteService ?? RemoteCharacterService(),
       _uuid = uuid ?? const Uuid();

  final DatabaseService _db;
  final BackupService _backup;
  final RemoteCharacterService _remote;
  final Uuid _uuid;

  bool get isConfigured => _remote.isConfigured;

  Future<String> pushSheet({
    required int sheetId,
    required String password,
    bool allowOverwriteRemote = false,
  }) async {
    if (password.trim().isEmpty) {
      throw ArgumentError('Mot de passe requis pour la synchronisation');
    }

    final sheet = await _db.getCharacterSheetById(sheetId);
    if (sheet == null) {
      throw StateError('Fiche introuvable');
    }

    final syncUuid = await _ensureSyncUuid(sheet);

    if (!allowOverwriteRemote) {
      final cloudCharacters = await _remote.listCharacters();
      CloudCharacterInfo? remote;
      for (final c in cloudCharacters) {
        if (c.syncUuid == syncUuid) {
          remote = c;
          break;
        }
      }
      if (remote != null &&
          remote.lastModifiedAt != null &&
          remote.lastModifiedAt!.isAfter(sheet.lastModifiedAt)) {
        throw SyncConflictException(
          direction: 'push',
          localLastModifiedAt: sheet.lastModifiedAt,
          remoteLastModifiedAt: remote.lastModifiedAt!,
        );
      }
    }

    final entry = await _backup.exportCharacterEntry(sheetId);
    final refreshed = await _db.getCharacterSheetById(sheetId);
    if (refreshed == null) {
      throw StateError('Fiche introuvable après préparation sync');
    }

    await _remote.pushCharacter(
      syncUuid: syncUuid,
      password: password,
      characterEntry: entry,
      lastModifiedAt: refreshed.lastModifiedAt.toIso8601String(),
    );

    await _db.setCharacterLastSyncedAt(sheetId, DateTime.now());
    return syncUuid;
  }

  Future<CharacterSheet> pullSheet({
    required String syncUuid,
    required String password,
    DateTime? remoteLastModifiedAt,
    bool allowOverwriteLocal = false,
  }) async {
    if (syncUuid.trim().isEmpty) {
      throw ArgumentError('Code de synchronisation requis');
    }
    if (password.trim().isEmpty) {
      throw ArgumentError('Mot de passe requis pour la synchronisation');
    }

    if (!allowOverwriteLocal && remoteLastModifiedAt != null) {
      final local = await _db.getCharacterSheetBySyncUuid(syncUuid.trim());
      if (local != null && local.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
        throw SyncConflictException(
          direction: 'pull',
          localLastModifiedAt: local.lastModifiedAt,
          remoteLastModifiedAt: remoteLastModifiedAt,
        );
      }
    }

    final entry = await _remote.pullCharacter(
      syncUuid: syncUuid.trim(),
      password: password,
    );
    return _backup.upsertCharacterEntryFromSync(entry);
  }

  Future<List<CloudCharacterInfo>> listCloudCharacters() async {
    return _remote.listCharacters();
  }

  Future<String> _ensureSyncUuid(CharacterSheet sheet) async {
    if (sheet.syncUuid.isNotEmpty) return sheet.syncUuid;
    final generated = _uuid.v4();
    await _db.setCharacterSyncUuid(sheet.id!, generated);
    return generated;
  }
}
