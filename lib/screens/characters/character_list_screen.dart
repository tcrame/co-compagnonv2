import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/character_sheet.dart';
import '../../providers/character_sheet_provider.dart';
import '../../services/character_sync_service.dart';
import '../../services/remote_character_service.dart';
import '../../services/auth_service.dart'; // 👈 N'oubliez pas cet import !
import 'character_sheet_screen.dart';
import 'character_share_screen.dart';

// --- NOUVEAU WIDGET : BANNIÈRE D'AUTHENTIFICATION ---
class CloudAuthBanner extends StatefulWidget {
  const CloudAuthBanner({super.key});

  @override
  State<CloudAuthBanner> createState() => _CloudAuthBannerState();
}

class _CloudAuthBannerState extends State<CloudAuthBanner> {
  final AuthService _auth = AuthService();
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _auth.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    await _auth.signIn();
    await _checkAuth();
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    await _auth.signOut();
    await _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_isLoggedIn) {
      return Material(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Connecté au Cloud",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: _logout,
                style: TextButton.styleFrom(foregroundColor: Colors.green.shade900),
                child: const Text("Se déconnecter"),
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
// ----------------------------------------------------

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
          // 👈 Insertion de notre bannière Cloud ici !
          const CloudAuthBanner(),

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
                        child: const Icon(Icons.delete_sweep, color: Colors.white),
                      ),

                      // 1. On intercepte les choix de l'utilisateur
                      confirmDismiss: (_) async {
                        final result = await _confirmAdvancedDelete(
                          context,
                          sheet.name,
                          sheet.syncUuid.isNotEmpty, // true si le perso est dans le cloud
                        );

                        if (result == null) return false; // Annulé, on ne fait rien

                        try {
                          // 2. On exécute le choix personnalisé du joueur
                          await _sync.deleteCharacter(
                            sheetId: sheet.id!,
                            syncUuid: sheet.syncUuid,
                            deleteLocal: result['local']!,
                            deleteCloud: result['cloud']!,
                          );

                          if (context.mounted) {
                            // 3. On rafraîchit les données locales (le Provider)
                            await context.read<CharacterSheetProvider>().loadSheets();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Action de suppression effectuée avec succès.'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ Échec de la suppression : $e'), backgroundColor: Colors.red),
                            );
                          }
                        }

                        // 🔴 TRÈS IMPORTANT : Le Dismissible ne doit s'animer visuellement et quitter
                        // l'écran QUE si le personnage a été supprimé localement.
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
                            _buildSubtitle(sheet.race, sheet.profile, sheet.level),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_canShare(sheet))
                                IconButton(
                                  tooltip: 'Partager',
                                  icon: const Icon(Icons.ios_share_outlined),
                                  onPressed: () => _openShareScreen(context, sheet.id!, sheet.syncUuid),
                                ),
                              IconButton(
                                tooltip: _canPush(sheet)
                                    ? 'Synchroniser vers le cloud'
                                    : 'Lecture seule',
                                icon: const Icon(Icons.cloud_upload_outlined),
                                onPressed: _sync.isConfigured && _canPush(sheet)
                                    ? () => _pushToCloud(context, sheet.id!)
                                    : null,
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap:
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CharacterSheetScreen(sheetId: sheet.id!),
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

  Future<Map<String, bool>?> _confirmAdvancedDelete(BuildContext context, String characterName, bool hasCloudBackup) {
    final controller = TextEditingController();
    String enteredName = '';

    // Par défaut, si le perso est sur le cloud, on propose de supprimer "Partout". Sinon, "Local uniquement".
    String deleteMode = hasCloudBackup ? 'both' : 'local';

    return showDialog<Map<String, bool>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 10),
              const Text('Option de suppression'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez où vous souhaitez supprimer ce personnage :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Option 1 : Local uniquement
              RadioListTile<String>(
                title: const Text('Uniquement sur ce téléphone'),
                subtitle: const Text('Le personnage restera accessible dans le cloud.'),
                value: 'local',
                groupValue: deleteMode,
                activeColor: Colors.red.shade700,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => deleteMode = val!),
              ),

              // Option 2 : Cloud uniquement (Affiché uniquement si le perso possède un syncUuid)
              if (hasCloudBackup)
                RadioListTile<String>(
                  title: const Text('Uniquement dans le cloud'),
                  subtitle: const Text('Le personnage restera sur ce téléphone mais ne sera plus synchronisé.'),
                  value: 'cloud',
                  groupValue: deleteMode,
                  activeColor: Colors.red.shade700,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => deleteMode = val!),
                ),

              // Option 3 : Partout
              if (hasCloudBackup)
                RadioListTile<String>(
                  title: const Text('Partout (Téléphone + Cloud)'),
                  subtitle: Text('Action destructive définitive.', style: TextStyle(color: Colors.red.shade700)),
                  value: 'both',
                  groupValue: deleteMode,
                  activeColor: Colors.red.shade700,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => deleteMode = val!),
                ),

              const Divider(height: 24),
              Text(
                'Pour valider, veuillez saisir le nom du personnage ($characterName) :',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: characterName,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red.shade700),
                  ),
                ),
                onChanged: (v) => setState(() => enteredName = v.trim()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: enteredName == characterName.trim()
                  ? () {
                Navigator.pop(ctx, {
                  'local': deleteMode == 'local' || deleteMode == 'both',
                  'cloud': deleteMode == 'cloud' || deleteMode == 'both',
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
    // 🗑️ PLUS DE DEMANDE DE MOT DE PASSE ICI
    final provider = context.read<CharacterSheetProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final syncUuid = await _sync.pushSheet(sheetId: sheetId);

      if (!context.mounted) return;
      await provider.loadSheets();
      await _refreshCloudAccess();
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

      // 🗑️ PLUS DE DEMANDE DE MOT DE PASSE ICI
      await _sync.pullSheet(
        syncUuid: selected.syncUuid,
        remoteLastModifiedAt: selected.lastModifiedAt,
      );

      if (!context.mounted) return;
      await provider.loadSheets();
      await _refreshCloudAccess();
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
        characters.where((c) => c.category == CloudCharacterCategory.writeShared).toList();
    final readShared =
        characters.where((c) => c.category == CloudCharacterCategory.readShared).toList();

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
              _buildCloudSection(ctx, 'Mes Personnages', owned),
              _buildCloudSection(ctx, 'Partagés en écriture', writeShared),
              _buildCloudSection(ctx, 'Partagés en lecture', readShared),
            ].whereType<Widget>().toList(),
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
        builder: (_) => CharacterShareScreen(
          sheetId: sheetId,
          syncUuid: syncUuid,
        ),
      ),
    );
    if (context.mounted) {
      await _refreshCloudAccess();
    }
  }

  Widget? _buildCloudSection(
    BuildContext context,
    String title,
    List<CloudCharacterInfo> characters,
  ) {
    if (characters.isEmpty) return null;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      ...characters.map(
        (c) {
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
        },
      ),
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