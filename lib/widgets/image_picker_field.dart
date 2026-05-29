import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/image_bank.dart';
import 'participant_avatar.dart';

class ImagePickerField extends StatefulWidget {
  final String? initialUrl;
  final String participantName;
  final bool isAlly;
  final ValueChanged<String?> onChanged;

  const ImagePickerField({
    super.key,
    this.initialUrl,
    required this.participantName,
    required this.isAlly,
    required this.onChanged,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openBank() async {
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _ImageBankSheet(),
    );
    if (url != null) {
      setState(() => _ctrl.text = url);
      widget.onChanged(url.isEmpty ? null : url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _ctrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          children: [
            ParticipantAvatar(
              name: widget.participantName,
              isAlly: widget.isAlly,
              imageUrl: url.isEmpty ? null : url,
              radius: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'URL de l\'image (optionnel)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2A2A3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: url.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            setState(() => _ctrl.clear());
                            widget.onChanged(null);
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged(v.trim().isEmpty ? null : v.trim());
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _openBank,
              icon: const Icon(Icons.image_search, size: 16),
              label: const Text('Banque'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A3A5E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImageBankSheet extends StatefulWidget {
  const _ImageBankSheet();

  @override
  State<_ImageBankSheet> createState() => _ImageBankSheetState();
}

class _ImageBankSheetState extends State<_ImageBankSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = imageBankCategories;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Banque d\'icônes RPG',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'game-icons.net — CC BY 3.0',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          TabBar(
            controller: _tabController,
            tabs: _categories.map((c) => Tab(text: c)).toList(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            indicatorColor: Colors.purple,
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories
                  .map((cat) => _CategoryGrid(
                        entries: imageBankForCategory(cat),
                        onSelect: (url) => Navigator.pop(context, url),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<ImageBankEntry> entries;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({required this.entries, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return InkWell(
          onTap: () => onSelect(entry.url),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: entry.url.endsWith('.svg')
                      ? SvgPicture.network(
                          entry.url,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : Image.network(
                          entry.url,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.white24,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.name,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
