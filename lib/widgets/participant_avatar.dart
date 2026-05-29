import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ParticipantAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final bool isAlly;
  final double radius;

  const ParticipantAvatar({
    super.key,
    required this.name,
    required this.isAlly,
    this.imageUrl,
    this.radius = 22,
  });

  bool get _isSvg => imageUrl != null && imageUrl!.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final color = isAlly ? Colors.green : Colors.red;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final size = radius * 2;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: 0.25),
        child: ClipOval(
          child: _isSvg
              ? SvgPicture.network(
                  imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => _initials(initials, color),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _initials(initials, color),
                  errorWidget: (_, __, ___) => _initials(initials, color),
                ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.25),
      child: _initials(initials, color),
    );
  }

  Widget _initials(String text, Color color) => Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      );
}
