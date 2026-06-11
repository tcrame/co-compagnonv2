part of 'character_sheet_screen.dart';

// ── Header Field ──────────────────────────────────────────────────────────────

class _HeaderField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _HeaderField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.onSurfaceMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header Dropdown ───────────────────────────────────────────────────────────

class _HeaderDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? badge;
  final VoidCallback? onInfo;

  const _HeaderDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.badge,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 0.8,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.allyPrimary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.allyPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (onInfo != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onInfo,
                child: const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                '—',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceMuted.withValues(alpha: 0.5),
                ),
              ),
              dropdownColor: AppColors.surface,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.onSurfaceMuted,
                size: 20,
              ),
              onChanged: onChanged,
              items:
                  items
                      .map(
                        (item) => DropdownMenuItem<T>(
                          value: item,
                          child: Text(
                            item.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Notes Tab ─────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  const _NotesTab({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(hintText: hint, alignLabelWithHint: true),
      ),
    );
  }
}

// ── Carac Tab ─────────────────────────────────────────────────────────────────
