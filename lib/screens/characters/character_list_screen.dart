import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/character_sheet_provider.dart';
import '../../services/character_sync_service.dart';
import '../../services/remote_character_service.dart';
import 'character_sheet_screen.dart';

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
      body: Consumer<CharacterSheetProvider>(
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
    final sheet = context.read<CharacterSheetProvider>().sheets.firstWhere(
      (s) => s.id == sheetId,
    );

    final password =
        sheet.syncUuid.isEmpty
            ? await _askPasswordWithConfirmation(
              context,
              title: 'Créer mot de passe sync',
              label: 'Mot de passe personnage',
            )
            : await _askPassword(
              context,
              title: 'Mot de passe sync',
              label: 'Mot de passe personnage',
            );
    if (password == null || password.isEmpty || !context.mounted) return;

    try {
      final syncUuid = await _sync.pushSheet(
        sheetId: sheetId,
        password: password,
      );
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
          password: password,
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
    String? enteredPassword;
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

      final password = await _askPassword(
        context,
        title: 'Mot de passe requis',
        label: 'Mot de passe personnage',
      );
      if (password == null || password.isEmpty || !context.mounted) return;
      enteredPassword = password;

      await _sync.pullSheet(
        syncUuid: selected.syncUuid,
        password: password,
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
      if (selectedCharacter == null ||
          enteredPassword == null ||
          enteredPassword.isEmpty) {
        return;
      }

      try {
        await _sync.pullSheet(
          syncUuid: selectedCharacter.syncUuid,
          password: enteredPassword,
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

  Future<String?> _askPassword(
    BuildContext context, {
    required String title,
    required String label,
  }) {
    return _askText(context, title: title, label: label, obscureText: true);
  }

  Future<String?> _askPasswordWithConfirmation(
    BuildContext context, {
    required String title,
    required String label,
  }) async {
    String password = '';
    String confirmation = '';
    String? error;
    return showDialog<String>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: Text(title),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mot de passe sync non récupérable. Impossible de le retrouver ou le réinitialiser.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        obscureText: true,
                        decoration: InputDecoration(labelText: label),
                        onChanged: (v) => password = v,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer mot de passe',
                        ),
                        onChanged: (v) => confirmation = v,
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        final p = password.trim();
                        final c = confirmation.trim();
                        if (p.isEmpty || c.isEmpty || p != c) {
                          setState(() {
                            error =
                                'Les deux mots de passe doivent être identiques.';
                          });
                          return;
                        }
                        Navigator.pop(ctx, p);
                      },
                      child: const Text('Valider'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<String?> _askText(
    BuildContext context, {
    required String title,
    required String label,
    String? hint,
    bool obscureText = false,
  }) async {
    String value = '';
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: TextField(
              autofocus: true,
              obscureText: obscureText,
              decoration: InputDecoration(labelText: label, hintText: hint),
              onChanged: (v) => value = v,
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, value.trim()),
                child: const Text('Valider'),
              ),
            ],
          ),
    );
    return result;
  }
}
