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
    bool allowOverwriteRemote = false,
  }) async {
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
      characterEntry: entry,
      lastModifiedAt: refreshed.lastModifiedAt.toIso8601String(),
    );

    await _db.setCharacterLastSyncedAt(sheetId, DateTime.now());
    return syncUuid;
  }

  Future<CharacterSheet> pullSheet({
    required String syncUuid,
    DateTime? remoteLastModifiedAt,
    bool allowOverwriteLocal = false,
  }) async {
    if (syncUuid.trim().isEmpty) {
      throw ArgumentError('Code de synchronisation requis');
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
    );
    return _backup.upsertCharacterEntryFromSync(entry);
  }

  Future<List<CloudCharacterInfo>> listCloudCharacters() async {
    return _remote.listCharacters();
  }

  Future<List<CloudCharacterShareInfo>> listCloudShares(String syncUuid) async {
    return _remote.listShares(syncUuid: syncUuid);
  }

  Future<void> shareCloudCharacter({
    required String syncUuid,
    required String email,
    required CloudSharePermission permissionType,
  }) async {
    await _remote.shareCharacter(
      syncUuid: syncUuid,
      email: email,
      permissionType: permissionType,
    );
  }

  Future<void> revokeCloudCharacterShare({
    required String syncUuid,
    String? sharedWithUserId,
    String? email,
  }) async {
    await _remote.revokeCharacterShare(
      syncUuid: syncUuid,
      sharedWithUserId: sharedWithUserId,
      email: email,
    );
  }

  Future<String> _ensureSyncUuid(CharacterSheet sheet) async {
    if (sheet.syncUuid.isNotEmpty) return sheet.syncUuid;
    final generated = _uuid.v4();
    await _db.setCharacterSyncUuid(sheet.id!, generated);
    return generated;
  }

  Future<void> deleteCharacterEverywhere({required int sheetId, required String syncUuid}) async {
    // 1. Si le personnage est synchronisé, on le supprime d'abord du Cloud
    if (syncUuid.isNotEmpty && isConfigured) {
      try {
        await _remote.deleteRemoteCharacter(syncUuid: syncUuid);
      } catch (e) {
        // Optionnel : On peut lever l'erreur ou laisser passer si le cloud est inaccessible,
        // mais idéalement on prévient l'utilisateur.
        print("Erreur suppression Cloud (ignorable si le serveur est down) : $e");
      }
    }

    // 2. Nettoyage complet des tables liées localement (armes, armures, capacités, inventaire)
    await _db.clearCharacterDetails(sheetId);

    // 3. Suppression définitive de la fiche principale dans SQLite
    await _db.deleteCharacterSheet(sheetId);
  }

  Future<void> deleteCharacter({
    required int sheetId,
    required String syncUuid,
    required bool deleteLocal,
    required bool deleteCloud,
  }) async {
    // 1. Suppression dans le Cloud si demandé et configuré
    if (deleteCloud && syncUuid.isNotEmpty && isConfigured) {
      try {
        await _remote.deleteRemoteCharacter(syncUuid: syncUuid);
      } catch (e) {
        print("Erreur lors de la suppression Cloud : $e");
        // Si on ne supprime QUE le cloud et que ça plante, on lève l'exception pour avertir l'utilisateur
        if (!deleteLocal) rethrow;
      }
    }

    // 2. Suppression Locale si demandée
    if (deleteLocal) {
      // Nettoyage des tables secondaires (armes, armures, capacités, inventaire)
      await _db.clearCharacterDetails(sheetId);
      // Suppression de la fiche principale
      await _db.deleteCharacterSheet(sheetId);
    } else if (deleteCloud) {
      // Cas particulier : On a supprimé le cloud mais on GARDE le personnage en local.
      // Il faut donc vider le 'sync_uuid' et le 'last_synced_at' dans la base SQLite locale
      // pour que l'application sache que ce personnage n'est plus lié au cloud.
      await _db.setCharacterSyncUuid(sheetId, '');
      await _db.setCharacterLastSyncedAt(sheetId, DateTime.fromMillisecondsSinceEpoch(0)); // Reset date
    }
  }
}