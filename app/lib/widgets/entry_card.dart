import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Recent-activity row: soft colored icon tile, title, author, time and a delete button.
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
    final act = AppTheme.act(entry.type);
    final dark = AppTheme.isDark(context);
    final timeStr = DateFormat.jm().format(entry.startedAt.toLocal());
    final details = _formatDetails();
    final title = details.isEmpty ? _label() : details;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: act.soft(dark), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(act.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink(context)),
                ),
                if (entry.note != null && entry.note!.isNotEmpty && entry.type != 'NOTE')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(entry.note!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ),
                const SizedBox(height: 2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      entry.authorName ?? (strings.isHe ? 'מטפל/ת' : 'Caregiver'),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    if (entry.taggedUserName != null && entry.taggedUserName!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '👥 ${strings.withPerson} ${entry.taggedUserName}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(timeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF25D366)),
            tooltip: strings.shareWhatsApp,
            visualDensity: VisualDensity.compact,
            onPressed: () {
              final withWhom = entry.taggedUserName != null ? ' (ביחד עם ${entry.taggedUserName})' : '';
              final msg = strings.isHe
                  ? '🍼 בייבי דיילי: $title$withWhom בשעה $timeStr'
                  : '🍼 BabyDaily: $title$withWhom at $timeStr';
              launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication);
            },
          ),
          if (onDelete != null)
            IconButton(
              icon: const Text('🗑', style: TextStyle(fontSize: 18)),
              onPressed: onDelete,
              tooltip: strings.delete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  String _label() {
    switch (entry.type) {
      case 'FEED':
        return strings.feed;
      case 'SLEEP':
        return strings.sleep;
      case 'DIAPER':
        return strings.diaper;
      case 'GROWTH':
        return strings.growth;
      case 'MEDICINE':
        return strings.medicine;
      default:
        return strings.note;
    }
  }
}
