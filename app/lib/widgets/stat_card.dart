import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// "Today" tile: soft tint background, colored label, big value, muted sub-label.
class StatCard extends StatelessWidget {
  final String type; // FEED | SLEEP | DIAPER ...
  final String title;
  final String value;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.type,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final act = AppTheme.act(type);
    final dark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: act.soft(dark), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: act.strong)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.ink(context), height: 1.1)),
          const SizedBox(height: 2),
          Text(subtitle ?? ' ', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
