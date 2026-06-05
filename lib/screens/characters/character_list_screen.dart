import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/character_sheet_provider.dart';
import '../../services/character_sync_service.dart';
import '../../services/remote_character_service.dart';
import '../../services/auth_service.dart'; // 👈 N'oubliez pas cet import !
import 'character_sheet_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterSheetProvider>().loadSheets();
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
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async => _confirmDelete(context),
                      onDismissed: (_) => provider.deleteSheet(sheet.id!),
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
                              IconButton(
                                tooltip: 'Synchroniser vers le cloud',
                                icon: const Icon(Icons.cloud_upload_outlined),
                                onPressed:
                                _sync.isConfigured
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

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
        title: const Text('Supprimer la fiche ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
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
    try {
      final syncUuid = await _sync.pushSheet(sheetId: sheetId);

      if (!context.mounted) return;
      await context.read<CharacterSheetProvider>().loadSheets();
      ScaffoldMessenger.of(context).showSnackBar(
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
        await context.read<CharacterSheetProvider>().loadSheets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Sync forcée envoyée. Code: $syncUuid'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Échec sync envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Échec sync envoi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pullFromCloud(BuildContext context) async {
    CloudCharacterInfo? selectedCharacter;

    try {
      final candidates = await _sync.listCloudCharacters();
      if (!context.mounted) return;

      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
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
      await context.read<CharacterSheetProvider>().loadSheets();
      ScaffoldMessenger.of(context).showSnackBar(
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
        await context.read<CharacterSheetProvider>().loadSheets();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sync cloud forcée'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Échec sync réception: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
    return showDialog<CloudCharacterInfo>(
      context: context,
      builder:
          (ctx) => AlertDialog(
        title: const Text('Choisir un personnage cloud'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: characters.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = characters[index];
              final parts = <String>[];
              if (c.level != null) parts.add('Niv. ${c.level}');
              if (c.race.isNotEmpty) parts.add(c.race);
              if (c.profile.isNotEmpty) parts.add(c.profile);
              final subtitle = parts.join(' · ');
              return ListTile(
                title: Text(c.name),
                subtitle: subtitle.isEmpty ? null : Text(subtitle),
                onTap: () => Navigator.pop(ctx, c),
              );
            },
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