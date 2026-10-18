import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class EntryCard extends StatelessWidget {
  final EntryModel entry;
  final AppStrings strings;
  final VoidCallback? onDelete;

  const EntryCard({
    super.key,
    required this.entry,
    required this.strings,
    this.onDelete,
  });

  String _typeEmoji(String type) {
    switch (type) {
      case 'FEED':
        return '🍼';
      case 'SLEEP':
        return '😴';
      case 'DIAPER':
        return '🧷';
      case 'GROWTH':
        return '📏';
      case 'MEDICINE':
        return '💊';
      case 'NOTE':
        return '📝';
      default:
        return '✨';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'FEED':
        return AppTheme.sun;
      case 'SLEEP':
        return AppTheme.mint;
      case 'DIAPER':
        return AppTheme.lavender;
      case 'GROWTH':
        return AppTheme.sky;
      case 'MEDICINE':
        return AppTheme.primary;
      default:
        return Colors.teal;
    }
  }

  String _formatDetails() {
    final d = entry.data;
    switch (entry.type) {
      case 'FEED':
        final method = d['method'] == 'breast'
            ? strings.breast
            : d['method'] == 'bottle'
                ? strings.bottle
                : strings.solids;
        final parts = <String>[method];
        if (d['amountMl'] != null) parts.add('${d['amountMl']} ml');
        if (d['side'] != null) {
          final side = d['side'] == 'left'
              ? strings.sideLeft
              : d['side'] == 'right'
                  ? strings.sideRight
                  : strings.sideBoth;
          parts.add(side);
        }
        if (d['food'] != null && d['food'].toString().isNotEmpty) {
          parts.add(d['food'].toString());
        }
        return parts.join(' • ');

      case 'SLEEP':
        if (entry.endedAt == null) {
          return strings.currentlySleeping;
        }
        final mins = entry.durationMinutes ?? 0;
        final h = mins ~/ 60;
        final m = mins % 60;
        final dur = h > 0 ? '${h}h ${m}m' : '${m}m';
        final endTime = DateFormat.jm().format(entry.endedAt!.toLocal());
        return '$dur (until $endTime)';

      case 'DIAPER':
        final kind = d['kind'] == 'wet'
            ? strings.diaperWet
            : d['kind'] == 'dirty'
                ? strings.diaperDirty
                : d['kind'] == 'mixed'
                    ? strings.diaperMixed
                    : strings.diaperDry;
        return kind;

      case 'GROWTH':
        final parts = <String>[];
        if (d['weightKg'] != null) parts.add('${d['weightKg']} kg');
        if (d['heightCm'] != null) parts.add('${d['heightCm']} cm');
        if (d['headCm'] != null) parts.add('${d['headCm']} cm head');
        return parts.join(' • ');

      case 'MEDICINE':
        final name = d['name'] ?? strings.medicine;
        final dose = d['dose'] != null ? ' (${d['dose']})' : '';
        final v = d['isVaccine'] == true ? ' [Vaccine]' : '';
        return '$name$dose$v';

      case 'NOTE':
        final mood = d['mood'] != null ? 'Mood: ${d['mood']} • ' : '';
        return '$mood${entry.note ?? ''}';

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(entry.type);
    final emoji = _typeEmoji(entry.type);
    final timeStr = DateFormat.jm().format(entry.startedAt.toLocal());
    final details = _formatDetails();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      details,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty && entry.type != 'NOTE') ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      entry.authorName ?? (strings.isHe ? 'מטפל/ת' : 'Caregiver'),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
              onPressed: onDelete,
              tooltip: strings.delete,
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}
