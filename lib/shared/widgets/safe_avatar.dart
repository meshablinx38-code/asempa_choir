import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A safe CircleAvatar that handles null/empty photoUrl gracefully.
/// Avoids the Flutter assertion: backgroundImage != null || onBackgroundImageError == null
class SafeAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final String voicePart;
  final double radius;
  final double fontSize;

  const SafeAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    required this.voicePart,
    this.radius = 24,
    this.fontSize = 16,
  });

  bool get _hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final color = voicePartColor(voicePart);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (!_hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withOpacity(0.2),
        child: Text(initial,
            style: TextStyle(color: color,
                fontSize: fontSize, fontWeight: FontWeight.w600)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.2),
      child: ClipOval(
        child: Image.network(
          photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(initial,
              style: TextStyle(color: color,
                  fontSize: fontSize, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}