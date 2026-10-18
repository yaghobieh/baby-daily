import 'package:flutter/material.dart';

class BabyAvatar extends StatelessWidget {
  final String name;
  final String? colorHex;
  final double size;

  const BabyAvatar({
    super.key,
    required this.name,
    this.colorHex,
    this.size = 44,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFFF7A7A);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFFF7A7A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(colorHex);
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '👶';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.44,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
