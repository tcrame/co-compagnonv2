import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/character_sheet.dart';
import '../../providers/character_sheet_provider.dart';
import '../../services/auth_service.dart';
import '../../services/character_sync_service.dart';
import '../../services/remote_character_service.dart';
import 'character_share_screen.dart';
import 'character_sheet_screen.dart';

final GlobalKey<_CloudAuthBannerState> cloudAuthBannerKey =
    GlobalKey<_CloudAuthBannerState>();

class CloudAuthBanner extends StatefulWidget {
  const CloudAuthBanner({super.key});

  @override
  State<CloudAuthBanner> createState() => _CloudAuthBannerState();
}

class _CloudAuthBannerState extends State<CloudAuthBanner> {
  final AuthService _auth = AuthService();
  final RemoteCharacterService _remoteService = RemoteCharacterService();

  bool _isLoggedIn = false;
  bool _isLoading = true;

  String _role = 'free';
  int _totalCharacters = 0;

  // 👇 AJOUTE CES DEUX LIGNES ICI :
  String get currentRole => _role;
  int get totalCharacters => _totalCharacters;

  @override
  void initState() {
    super.initState();
    checkAuthAndFetchQuota();
  }

  Future<void> checkAuthAndFetchQuota() async {
    final loggedIn = await _auth.isLoggedIn();
    if (!loggedIn) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final profile = await _remoteService.getCloudProfileInfo();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _role = profile['role'];
          _totalCharacters = profile['total'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    await _auth.signIn();
    await checkAuthAndFetchQuota();
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    await _auth.signOut();
    await checkAuthAndFetchQuota();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_isLoggedIn) {
      final int maxLimit = _role == 'premium' ? 10 : 3;
      final bool isLimitReached = _totalCharacters >= maxLimit;

      return Material(
        color: isLimitReached ? Colors.orange.shade50 : Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isLimitReached ? Icons.cloud_queue : Icons.cloud_done,
                    color:
                        isLimitReached
                            ? Colors.orange.shade800
                            : Colors.green.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _role == 'premium'
                              ? "Compte Premium 👑"
                              : "Compte Gratuit",
                          style: TextStyle(
                            color:
                                _role == 'premium'
                                    ? Colors.purple.shade900
                                    : Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Stockage Cloud : $_totalCharacters / $maxLimit personnages",
                          style: TextStyle(
                            color:
                                isLimitReached
                                    ? Colors.orange.shade900
                                    : Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight:
                                isLimitReached
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                    ),
                    child: const Text("Déconnexion"),
                  ),
                ],
              ),
              if (_role == 'free' && isLimitReached)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    "⚠️ Quota max atteint. Passez Premium pour stocker jusqu'à 10 personnages !",
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.blue),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Sauvegardez vos persos dans le cloud.",
                style: TextStyle(color: Colors.blue, fontSize: 13),
              ),
            ),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text("Google"),
            ),
          ],
        ),
      ),
    );
  }
}

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  final _sync = CharacterSyncService();
  final Map<String, String> _cloudAccessBySyncUuid = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterSheetProvider>().loadSheets();
      _refreshCloudAccess();
      cloudAuthBannerKey.currentState?.checkAuthAndFetchQuota();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiches de Personnages'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Récupérer depuis le cloud',
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed:
                _sync.isConfigured ? () => _pullFromCloud(context) : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau personnage'),
      ),
      body: Column(
        children: [
          CloudAuthBanner(key: cloudAuthBannerKey),
          Expanded(
            child: Consumer<CharacterSheetProvider>(
              builder: (context, provider, _) {
                if (provider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.sheets.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: provider.sheets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sheet = provider.sheets[index];
                    return Dismissible(
                      key: ValueKey(sheet.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_sweep,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        final result = await _confirmAdvancedDelete(
                          context,
                          sheet.name,
                          sheet.syncUuid.isNotEmpty,
                        );

                        if (result == null) return false;

                        try {
                          await _sync.deleteCharacter(
                            sheetId: sheet.id!,
                            syncUuid: sheet.syncUuid,
                            deleteLocal: result['local']!,
                            deleteCloud: result['cloud']!,
                          );

                          if (context.mounted) {
                            await provider.loadSheets();
                            cloudAuthBannerKey.currentState
                                ?.checkAuthAndFetchQuota();
                            _refreshCloudAccess();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Action de suppression effectuée avec succès.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Échec de la suppression : $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        return result['local']!;
                      },
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF5C6BC0),
                            child: Text(
                              sheet.name.isNotEmpty
                                  ? sheet.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            sheet.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            _buildSubtitle(
                              sheet.race,
                              sheet.profile,
                              sheet.level,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_canShare(sheet))
                                IconButton(
                                  tooltip: 'Partager',
                                  icon: const Icon(Icons.ios_share_outlined),
                                  onPressed:
                                      () => _openShareScreen(
                                        context,
                                        sheet.id!,
                                        sheet.syncUuid,
                                      ),
                                ),
                              Builder(
                                builder: (context) {
                                  // 1. Une fiche est VRAIMENT synchronisée si elle a un UUID
                                  // ET que le Worker a confirmé ses droits d'accès.
                                  final bool hasUuid = sheet.syncUuid.isNotEmpty;
                                  final bool isKnownByCloud = _cloudAccessBySyncUuid.containsKey(sheet.syncUuid);
                                  final bool isSynchronized = hasUuid && isKnownByCloud;

                                  final bool canPush = _canPush(sheet);

                                  // 2. Récupération des quotas
                                  final bannerState = cloudAuthBannerKey.currentState;
                                  final String userRole = bannerState?.currentRole ?? 'free';
                                  final int currentTotal = bannerState?.totalCharacters ?? 0;

                                  final int maxLimit = userRole == 'premium' ? 10 : 3;
                                  final bool isLimitReached = currentTotal >= maxLimit;

                                  // 3. Si le quota est atteint ET que le perso n'est pas encore synchronisé sur CE compte,
                                  // on masque l'icône immédiatement.
                                  if (isLimitReached && !isSynchronized) {
                                    return const SizedBox.shrink();
                                  }

                                  IconData iconData;
                                  Color iconColor;
                                  String tooltipMessage;

                                  // Le reste de ta logique de dessin d'icône 👇
                                  if (!isSynchronized) {
                                    iconData = Icons.cloud_upload_outlined;
                                    iconColor = Colors.grey.shade600;
                                    tooltipMessage = 'Sauvegarder dans le cloud';
                                  } else if (!canPush) {
                                    iconData = Icons.lock_outline;
                                    iconColor = Colors.amber.shade700;
                                    tooltipMessage = 'Personnage en lecture seule (partagé)';
                                  } else {
                                    iconData = Icons.cloud_done;
                                    iconColor = Colors.green.shade600;
                                    tooltipMessage = 'Synchronisé dans le cloud (cliquer pour mettre à jour)';
                                  }

                                  return IconButton(
                                    tooltip: tooltipMessage,
                                    icon: Icon(
                                      iconData,
                                      color: _sync.isConfigured ? iconColor : Colors.grey.shade400,
                                    ),
                                    onPressed: _sync.isConfigured && canPush
                                        ? () => _pushToCloud(context, sheet.id!)
                                        : null,
                                  );
                                },
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CharacterSheetScreen(
                                        sheetId: sheet.id!,
                                      ),
                                ),
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(String race, String profile, int level) {
    final parts = <String>[];
    if (race.isNotEmpty) parts.add(race);
    if (profile.isNotEmpty) parts.add(profile);
    final info = parts.join(' · ');
    return info.isEmpty ? 'Niv. $level' : 'Niv. $level · $info';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 72, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            'Aucune fiche de personnage',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur + pour en créer une',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<Map<String, bool>?> _confirmAdvancedDelete(
    BuildContext context,
    String characterName,
    bool hasCloudBackup,
  ) {
    final controller = TextEditingController();
    String enteredName = '';
    String deleteMode = hasCloudBackup ? 'both' : 'local';

    return showDialog<Map<String, bool>>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      const Text('Option de suppression'),
                    ],
                  ),
                  // 💡 AJOUT D'UN SINGLECHILDSCROLLVIEW ICI POUR ÉVITER L'OVERFLOW AVEC LE CLAVIER
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choisissez où vous souhaitez supprimer ce personnage :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<String>(
                          title: const Text('Uniquement sur ce téléphone'),
                          subtitle: const Text(
                            'Le personnage restera accessible dans le cloud.',
                          ),
                          value: 'local',
                          groupValue: deleteMode,
                          activeColor: Colors.red.shade700,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => deleteMode = val!),
                        ),
                        if (hasCloudBackup)
                          RadioListTile<String>(
                            title: const Text('Uniquement dans le cloud'),
                            subtitle: const Text(
                              'Le personnage restera sur ce téléphone mais ne sera plus synchronisé.',
                            ),
                            value: 'cloud',
                            groupValue: deleteMode,
                            activeColor: Colors.red.shade700,
                            contentPadding: EdgeInsets.zero,
                            onChanged:
                                (val) => setState(() => deleteMode = val!),
                          ),
                        if (hasCloudBackup)
                          RadioListTile<String>(
                            title: const Text('Partout (Téléphone + Cloud)'),
                            subtitle: Text(
                              'Action destructive définitive.',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                            value: 'both',
                            groupValue: deleteMode,
                            activeColor: Colors.red.shade700,
                            contentPadding: EdgeInsets.zero,
                            onChanged:
                                (val) => setState(() => deleteMode = val!),
                          ),
                        const Divider(height: 24),
                        Text(
                          'Pour valider, veuillez saisir le nom du personnage ($characterName) :',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: characterName,
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                          onChanged:
                              (v) => setState(() => enteredName = v.trim()),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed:
                          enteredName == characterName.trim()
                              ? () {
                                Navigator.pop(ctx, {
                                  'local':
                                      deleteMode == 'local' ||
                                      deleteMode == 'both',
                                  'cloud':
                                      deleteMode == 'cloud' ||
                                      deleteMode == 'both',
                                });
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Nouveau personnage'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Nom du personnage'),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Créer'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      final sheet = await context.read<CharacterSheetProvider>().createSheet(
        result,
      );
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CharacterSheetScreen(sheetId: sheet.id!),
          ),
        );
      }
    }
  }

  Future<void> _pushToCloud(BuildContext context, int sheetId) async {
    final provider = context.read<CharacterSheetProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final syncUuid = await _sync.pushSheet(sheetId: sheetId);

      if (!context.mounted) return;
      await provider.loadSheets();
      await _refreshCloudAccess();
      cloudAuthBannerKey.currentState?.checkAuthAndFetchQuota();
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ Sync envoyée. Code: $syncUuid'),
          backgroundColor: Colors.green,
        ),
      );
    } on SyncConflictException catch (_) {
      if (!context.mounted) return;
      final overwrite = await _confirmOverwrite(
        context,
        title: 'Conflit de synchronisation',
        message:
            'Version cloud plus récente détectée.\n\nÉcraser version cloud avec version locale ?',
      );
      if (overwrite != true || !context.mounted) return;
      try {
        final syncUuid = await _sync.pushSheet(
          sheetId: sheetId,
          allowOverwriteRemote: true,
        );
        if (!context.mounted) return;
        await provider.loadSheets();
        await _refreshCloudAccess();
        cloudAuthBannerKey.currentState?.checkAuthAndFetchQuota();
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ Sync forcée envoyée. Code: $syncUuid'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Échec sync envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Échec sync envoi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pullFromCloud(BuildContext context) async {
    CloudCharacterInfo? selectedCharacter;
    final provider = context.read<CharacterSheetProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final candidates = await _sync.listCloudCharacters();
      if (!context.mounted) return;

      if (candidates.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Aucun personnage cloud disponible'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final selected = await _pickCloudCharacter(context, candidates);
      if (selected == null || !context.mounted) return;
      selectedCharacter = selected;

      await _sync.pullSheet(
        syncUuid: selected.syncUuid,
        remoteLastModifiedAt: selected.lastModifiedAt,
      );

      if (!context.mounted) return;
      await provider.loadSheets();
      await _refreshCloudAccess();
      cloudAuthBannerKey.currentState?.checkAuthAndFetchQuota();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Personnage synchronisé depuis le cloud'),
          backgroundColor: Colors.green,
        ),
      );
    } on SyncConflictException catch (_) {
      if (!context.mounted) return;
      final overwrite = await _confirmOverwrite(
        context,
        title: 'Conflit de synchronisation',
        message:
            'Version locale plus récente détectée.\n\nÉcraser version locale avec version cloud ?',
      );
      if (overwrite != true || !context.mounted) return;
      if (selectedCharacter == null) return;

      try {
        await _sync.pullSheet(
          syncUuid: selectedCharacter.syncUuid,
          remoteLastModifiedAt: selectedCharacter.lastModifiedAt,
          allowOverwriteLocal: true,
        );
        if (!context.mounted) return;
        await provider.loadSheets();
        await _refreshCloudAccess();
        cloudAuthBannerKey.currentState?.checkAuthAndFetchQuota();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Sync cloud forcée'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Échec sync réception: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Échec sync réception: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<CloudCharacterInfo?> _pickCloudCharacter(
    BuildContext context,
    List<CloudCharacterInfo> characters,
  ) {
    final owned = characters.where((c) => c.isOwned).toList();
    final writeShared =
        characters
            .where((c) => c.category == CloudCharacterCategory.writeShared)
            .toList();
    final readShared =
        characters
            .where((c) => c.category == CloudCharacterCategory.readShared)
            .toList();

    return showDialog<CloudCharacterInfo>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Choisir un personnage cloud'),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: ListView(
                children: [
                  if (owned.isEmpty &&
                      writeShared.isEmpty &&
                      readShared.isEmpty &&
                      characters.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 6),
                      child: Text(
                        'Tous les personnages (${characters.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    ...characters.map(
                      (c) => ListTile(
                        title: Text(c.name),
                        subtitle: Text('ID de synchro : ${c.syncUuid}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, c),
                      ),
                    ),
                  ] else ...[
                    if (owned.isNotEmpty)
                      _buildCloudSection(ctx, 'Mes Personnages', owned),
                    if (writeShared.isNotEmpty)
                      _buildCloudSection(
                        ctx,
                        'Partagés en écriture',
                        writeShared,
                      ),
                    if (readShared.isNotEmpty)
                      _buildCloudSection(
                        ctx,
                        'Partagés en lecture',
                        readShared,
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
            ],
          ),
    );
  }

  Future<void> _refreshCloudAccess() async {
    if (!_sync.isConfigured) {
      if (mounted) {
        setState(() {
          _cloudAccessBySyncUuid.clear();
        });
      }
      return;
    }

    try {
      final characters = await _sync.listCloudCharacters();
      if (!mounted) return;
      setState(() {
        _cloudAccessBySyncUuid
          ..clear()
          ..addEntries(
            characters.map((c) => MapEntry(c.syncUuid, c.accessType)),
          );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cloudAccessBySyncUuid.clear();
      });
    }
  }

  bool _canShare(CharacterSheet sheet) {
    if (sheet.syncUuid.isEmpty) return false;
    return _cloudAccessBySyncUuid[sheet.syncUuid] == 'owner';
  }

  bool _canPush(CharacterSheet sheet) {
    if (sheet.syncUuid.isEmpty) return _sync.isConfigured;
    final access = _cloudAccessBySyncUuid[sheet.syncUuid];
    return access != 'read';
  }

  Future<void> _openShareScreen(
    BuildContext context,
    int sheetId,
    String syncUuid,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CharacterShareScreen(sheetId: sheetId, syncUuid: syncUuid),
      ),
    );
    if (context.mounted) {
      await _refreshCloudAccess();
    }
  }

  Widget _buildCloudSection(
    BuildContext context,
    String title,
    List<CloudCharacterInfo> characters,
  ) {
    if (characters.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      ...characters.map((c) {
        final parts = <String>[];
        if (c.level != null) parts.add('Niv. ${c.level}');
        if (c.race.isNotEmpty) parts.add(c.race);
        if (c.profile.isNotEmpty) parts.add(c.profile);
        if (c.ownerEmail != null && c.ownerEmail!.isNotEmpty && !c.isOwned) {
          parts.add('Propriétaire: ${c.ownerEmail}');
        }
        final subtitle = parts.join(' · ');
        return ListTile(
          title: Text(c.name),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, c),
        );
      }),
      const Divider(height: 1),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Future<bool?> _confirmOverwrite(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Écraser'),
              ),
            ],
          ),
    );
  }
}
