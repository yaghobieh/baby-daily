import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Quick action tile (emoji + label) tinted with the activity's own color.
class QuickActionButton extends StatelessWidget {
  final String type;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.type,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final act = AppTheme.act(type);
    final dark = AppTheme.isDark(context);
    return Material(
      color: act.soft(dark),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(act.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: act.strong)),
            ],
          ),
        ),
      ),
    );
  }
}
