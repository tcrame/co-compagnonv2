import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../providers/bestiary_provider.dart';
import '../../providers/character_sheet_provider.dart';
import '../../services/backup_service.dart';
import '../../services/database_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _importController = TextEditingController();
  bool _exporting = false;
  bool _importing = false;
  String? _exportPreview;

  BackupService get _svc => BackupService(DatabaseService());

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final json = await _svc.exportToJson();
      await Clipboard.setData(ClipboardData(text: json));
      setState(() => _exportPreview = json);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sauvegarde copiée dans le presse-papiers'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Export échoué: $e');
    } finally {
      setState(() => _exporting = false);
    }
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _import() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      _showError('Collez votre sauvegarde JSON dans le champ ci-dessus.');
      return;
    }

    final confirmed = await _confirmImport();
    if (confirmed != true) return;

    setState(() => _importing = true);
    try {
      final summary = await _svc.importFromJson(text);

      if (mounted) {
        context.read<BestiaryProvider>().loadTemplates();
        context.read<CharacterSheetProvider>().loadSheets();
        _importController.clear();
        setState(() => _exportPreview = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $summary'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Import échoué: $e\n\nVérifiez que le JSON est valide.');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<bool?> _confirmImport() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer la sauvegarde ?'),
        content: const Text(
          'Les données importées seront AJOUTÉES à celles existantes (pas de remplacement).\n\n'
          'Si vous voulez repartir de zéro, supprimez d\'abord vos données depuis le bestiaire et les fiches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegarde & Restauration'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('📤 Exporter'),
          const SizedBox(height: 8),
          Text(
            'Exporte le bestiaire et les fiches de personnage en JSON. '
            'Copiez le résultat dans un fichier texte ou envoyez-le par mail pour garder une sauvegarde.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.copy),
              label: const Text('Copier la sauvegarde (JSON)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_exportPreview != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _exportPreview!.length > 300
                    ? '${_exportPreview!.substring(0, 300)}…\n\n'
                        '[${_exportPreview!.length} caractères — copié dans le presse-papiers]'
                    : _exportPreview!,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
          const SizedBox(height: 36),
          _sectionTitle('📥 Importer'),
          const SizedBox(height: 8),
          Text(
            'Collez une sauvegarde JSON exportée précédemment. '
            'Les données seront ajoutées à celles existantes.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _importController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Collez votre JSON ici…',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                tooltip: 'Coller depuis le presse-papiers',
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _importController.text = data!.text!;
                  }
                },
              ),
            ),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _importing ? null : _import,
              icon: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: const Text('Restaurer depuis le JSON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF311B92),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _infoBox(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️  Pourquoi sauvegarder ?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 6),
          Text(
            'Lors des mises à jour de l\'application, les données peuvent être '
            'effacées si l\'application est désinstallée. Exportez régulièrement '
            'votre bestiaire et vos fiches pour ne pas les perdre.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
