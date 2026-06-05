import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/remote_character_service.dart'; // Vérifie le chemin vers ton service
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

class _ImageBankSheetState extends State<_ImageBankSheet> {
  final RemoteCharacterService _remoteService = RemoteCharacterService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _icons = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchIcons(''); // Charge les premières icônes par défaut
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Effectue la recherche sur ton Worker Cloudflare
  Future<void> _fetchIcons(String query) async {
    setState(() => _isLoading = true);
    final results = await _remoteService.searchCloudIcons(query);
    if (mounted) {
      setState(() {
        _icons = results;
        _isLoading = false;
      });
    }
  }

  // Évite d'étouffer ton Worker en attendant que l'utilisateur s'arrête de taper
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchIcons(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
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
            'Banque d\'icônes RPG Dynamique',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const Text(
            'Iconify (Game-icons) — Mots-clés en anglais',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // 🔍 Barre de recherche intégrée
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher (ex: sword, shield, dragon, wolf)...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2A2A3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchCtrl.clear();
                    _fetchIcons('');
                  },
                )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 8),

          // 🎴 Zone de résultats de recherche
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                : _icons.isEmpty
                ? const Center(
              child: Text(
                'Aucune icône trouvée.\nEssayez en anglais (ex: ghost, fire, chest).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38),
              ),
            )
                : GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: _icons.length,
              itemBuilder: (ctx, i) {
                final icon = _icons[i];
                final String iconName = icon['n'] ?? 'Icon';
                final String slug = icon['p'] ?? '';

                // Construction de l'URL CDN universelle d'Iconify hébergeant Game-icons
                final String iconUrl = "https://api.iconify.design/game-icons/$slug.svg?color=%23ffffff";

                return InkWell(
                  onTap: () => Navigator.pop(context, iconUrl),
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
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: SvgPicture.network(
                            iconUrl,
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        iconName,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}