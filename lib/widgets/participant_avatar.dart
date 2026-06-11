import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http; // 💡 AJOUT : Pour vérifier l'image en sécurité

// 💡 Caches en mémoire pour ne pas retélécharger les SVG à l'infini en scrollant
final Map<String, String> _validSvgCache = {};
final Set<String> _badUrls = {};

class ParticipantAvatar extends StatefulWidget {
  final String name;
  final bool isAlly;
  final String? imageUrl;
  final double radius;

  const ParticipantAvatar({
    super.key,
    required this.name,
    required this.isAlly,
    this.imageUrl,
    this.radius = 20.0,
  });

  @override
  State<ParticipantAvatar> createState() => _ParticipantAvatarState();
}

class _ParticipantAvatarState extends State<ParticipantAvatar> {
  String? _validSvgData;
  bool _isBadLink = false;

  @override
  void initState() {
    super.initState();
    _checkAndFetchSvg();
  }

  @override
  void didUpdateWidget(ParticipantAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _validSvgData = null;
      _isBadLink = false;
      _checkAndFetchSvg();
    }
  }

  // 🛡️ Le bouclier : On vérifie si l'URL répond bien avec un vrai SVG
  Future<void> _checkAndFetchSvg() async {
    final url = widget.imageUrl;
    if (url == null || !url.toLowerCase().contains('.svg')) return;

    if (_badUrls.contains(url)) {
      if (mounted) setState(() => _isBadLink = true);
      return;
    }
    if (_validSvgCache.containsKey(url)) {
      if (mounted) setState(() => _validSvgData = _validSvgCache[url]);
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      // Si la réponse est un succès ET contient la balise XML d'un SVG
      if (response.statusCode == 200 && response.body.contains('<svg')) {
        _validSvgCache[url] = response.body;
        if (mounted) setState(() => _validSvgData = response.body);
      } else {
        _badUrls.add(url);
        if (mounted) setState(() => _isBadLink = true);
      }
    } catch (e) {
      _badUrls.add(url);
      if (mounted) setState(() => _isBadLink = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isAlly ? Colors.green.shade800 : Colors.red.shade800;
    Widget content;

    // Si on a une URL, qu'elle n'est pas vide et qu'elle n'est pas cassée (404)
    if (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty && !_isBadLink) {

      if (widget.imageUrl!.toLowerCase().contains('.svg')) {
        // C'est un SVG en cours de vérification/chargement
        if (_validSvgData == null) {
          content = SizedBox(
            width: widget.radius,
            height: widget.radius,
            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
          );
        } else {
          // C'est un SVG valide et sécurisé !
          content = SvgPicture.string(
            _validSvgData!,
            width: widget.radius * 1.4,
            height: widget.radius * 1.4,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          );
        }
      } else {
        // C'est une image classique (PNG, JPG)
        content = ClipOval(
          child: Image.network(
            widget.imageUrl!,
            width: widget.radius * 2,
            height: widget.radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackText(),
          ),
        );
      }
    } else {
      // 🔤 Pas d'image valide, on affiche la lettre
      content = _buildFallbackText();
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: bgColor,
      child: content,
    );
  }

  Widget _buildFallbackText() {
    return Text(
      widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: widget.radius * 0.9,
      ),
    );
  }
}