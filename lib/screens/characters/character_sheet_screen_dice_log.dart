part of 'character_sheet_screen.dart';

class DiceLogEntry {
  final String label;
  final String die;
  final int dieResult;
  final int bonus;
  final int total;
  final String detail;
  final DateTime timestamp;

  DiceLogEntry({
    required this.label,
    required this.die,
    required this.dieResult,
    required this.bonus,
    required this.total,
    required this.detail,
  }) : timestamp = DateTime.now();
}

class _DiceLogScreen extends StatelessWidget {
  final List<DiceLogEntry> log;

  const _DiceLogScreen({required this.log});

  String _elapsed(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.casino_outlined, size: 22),
            const SizedBox(width: 8),
            const Text('Journal des dés'),
            const SizedBox(width: 8),
            if (log.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.allyPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${log.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.allyPrimary,
                  ),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fermer',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          log.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.casino_outlined,
                      size: 64,
                      color: AppColors.onSurfaceMuted.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun lancer pour l\'instant',
                      style: TextStyle(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                itemCount: log.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = log[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.allyPrimary.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        e.die,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.allyPrimary,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            e.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.allyPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${e.total}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.allyPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        e.detail,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                    trailing: Text(
                      _elapsed(e.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

// ── Combat Tab ────────────────────────────────────────────────────────────────
