import 'package:flutter/material.dart';

import '../../services/character_sync_service.dart';
import '../../services/remote_character_service.dart';

class CharacterShareScreen extends StatefulWidget {
  const CharacterShareScreen({
    super.key,
    required this.sheetId,
    required this.syncUuid,
  });

  final int sheetId;
  final String syncUuid;

  @override
  State<CharacterShareScreen> createState() => _CharacterShareScreenState();
}

class _CharacterShareScreenState extends State<CharacterShareScreen> {
  final CharacterSyncService _sync = CharacterSyncService();
  final TextEditingController _emailController = TextEditingController();
  CloudSharePermission _permission = CloudSharePermission.read;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<CloudCharacterShareInfo> _shares = const [];

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadShares() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final shares = await _sync.listCloudShares(widget.syncUuid);
      if (!mounted) return;
      setState(() {
        _shares = shares;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _shareCharacter() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Email requis', Colors.orange);
      return;
    }

    setState(() => _submitting = true);
    try {
      await _sync.shareCloudCharacter(
        syncUuid: widget.syncUuid,
        email: email,
        permissionType: _permission,
      );
      _emailController.clear();
      await _loadShares();
      if (!mounted) return;
      _showSnackBar('Partage ajouté', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Échec du partage: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _revokeShare(CloudCharacterShareInfo share) async {
    setState(() => _submitting = true);
    try {
      await _sync.revokeCloudCharacterShare(
        syncUuid: widget.syncUuid,
        sharedWithUserId: share.sharedWithUserId,
      );
      await _loadShares();
      if (!mounted) return;
      _showSnackBar('Accès révoqué', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Échec de la révocation: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _permissionLabel(CloudSharePermission permission) {
    return permission == CloudSharePermission.write ? 'Écriture' : 'Lecture';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partager le personnage'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Code cloud: ${widget.syncUuid}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'ID local: ${widget.sheetId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email du joueur',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CloudSharePermission>(
                        value: _permission,
                        decoration: const InputDecoration(
                          labelText: 'Droit',
                          border: OutlineInputBorder(),
                        ),
                        items: CloudSharePermission.values
                            .map(
                              (permission) => DropdownMenuItem(
                                value: permission,
                                child: Text(_permissionLabel(permission)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _permission = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _submitting ? null : _shareCharacter,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Partager'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Accès actuels',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _submitting ? null : _loadShares,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_shares.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Aucun partage actif'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _shares.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final share = _shares[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(share.sharedWithEmail),
                        subtitle: Text(
                          _permissionLabel(share.permissionType),
                        ),
                        trailing: IconButton(
                          tooltip: 'Révoquer',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _submitting ? null : () => _revokeShare(share),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
