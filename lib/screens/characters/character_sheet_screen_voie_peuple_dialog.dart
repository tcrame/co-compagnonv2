part of 'character_sheet_screen.dart';

class _VoiePeupleChoixDialog extends StatelessWidget {
  final String peuple;
  final List<VoieCatalogue> choices;

  const _VoiePeupleChoixDialog({required this.peuple, required this.choices});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Voie de peuple — $peuple'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plusieurs voies de peuple sont disponibles pour ce peuple. Choisissez-en une :',
          ),
          const SizedBox(height: 12),
          ...choices.map(
            (voie) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(voie.nom),
              onTap: () => Navigator.pop(context, voie),
            ),
          ),
        ],
      ),
    );
  }
}
