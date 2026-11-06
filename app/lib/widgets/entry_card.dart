import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Recent-activity card matching Screenshot 1:
/// White rounded card, pastel square icon on left, bold title ("Feed", "Diaper", "Nap"),
/// clean detail line below, and timestamp aligned at top-right.
class EntryCard extends StatelessWidget {
  final EntryModel entry;
  final AppStrings strings;
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;

  const EntryCard({
    super.key,
    required this.entry,
    required this.strings,
    this.isPinned = false,
    this.onTogglePin,
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
        final parts = <String>[];
        final milkLabel = d['milkType'] == 'formula'
            ? (strings.isHe ? 'תמ״ל' : 'Formula')
            : (d['milkType'] == 'expressed' || d['milkType'] == 'breast_milk'
                ? (strings.isHe ? 'חלב שאוב' : 'Expressed Milk')
                : (d['milkType'] == 'water' ? (strings.isHe ? 'מים' : 'Water') : 'Formula'));

        if (d['amountMl'] != null) {
          parts.add('${d['amountMl']}ml $milkLabel');
        } else if (d['method'] == 'bottle') {
          parts.add(milkLabel);
        } else {
          parts.add(method);
        }

        if (d['durationMinutes'] != null) {
          parts.add('${d['durationMinutes']}m');
        } else if (d['amountMl'] != null) {
          parts.add('15m');
        }

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
        return parts.isNotEmpty ? parts.join(', ') : method;

      case 'SLEEP':
        if (entry.endedAt == null) {
          return strings.currentlySleeping;
        }
        final mins = entry.durationMinutes ?? 0;
        final h = mins ~/ 60;
        final m = mins % 60;
        final dur = h > 0 ? '${h}h ${m}m' : '${m}m';
        final endTime = DateFormat('h:mm a').format(entry.endedAt!.toLocal());
        return strings.isHe
            ? 'משך: $dur (התעורר/ה ב-$endTime)'
            : 'Duration: $dur (Woke $endTime)';

      case 'DIAPER':
        final rawKind = d['kind']?.toString() ?? 'wet';
        String kindLabel;
        if (strings.isHe) {
          kindLabel = rawKind == 'wet'
              ? strings.diaperWet
              : rawKind == 'dirty'
                  ? strings.diaperDirty
                  : rawKind == 'mixed'
                      ? 'רטוב ומלוכלך'
                      : strings.diaperDry;
        } else {
          kindLabel = rawKind == 'wet'
              ? 'Wet'
              : rawKind == 'dirty'
                  ? 'Dirty'
                  : rawKind == 'mixed'
                      ? 'Wet & Dirty'
                      : 'Dry';
        }
        final texture = d['stoolTexture'] != null ? ' (${d['stoolTexture']})' : '';
        return strings.isHe ? '$kindLabel$texture, החלפה' : '$kindLabel$texture, Change';

      case 'GROWTH':
        final parts = <String>[];
        if (d['weightKg'] != null) parts.add('${d['weightKg']} kg');
        if (d['heightCm'] != null) parts.add('${d['heightCm']} cm');
        if (d['headCm'] != null) parts.add('${d['headCm']} cm head');
        return parts.join(' • ');

      case 'MEDICINE':
        final name = d['name'] ?? strings.medicine;
        final dose = d['dose'] != null ? ', ${d['dose']}' : '';
        final v = d['isVaccine'] == true ? ' [Vaccine]' : '';
        return '$name$dose$v';

      case 'NOTE':
        final mood = d['mood'] != null ? 'Mood: ${d['mood']} • ' : '';
        return '$mood${entry.note ?? ''}';

      default:
        return '';
    }
  }

  Color _iconBgColor(String type) {
    switch (type) {
      case 'FEED':
        return const Color(0xFFF28B72);
      case 'SLEEP':
        return const Color(0xFFC5B4E3);
      case 'DIAPER':
        return const Color(0xFFB6E2D3);
      case 'MEDICINE':
        return const Color(0xFFB9D9EB);
      case 'GROWTH':
        return const Color(0xFFFDE68A);
      default:
        return const Color(0xFFA7F3D0);
    }
  }

  Widget _buildSquareIllustration(String type) {
    switch (type) {
      case 'FEED':
        return Transform.rotate(
          angle: 0.65,
          child: const Text('🍼', style: TextStyle(fontSize: 24)),
        );
      case 'DIAPER':
        final kind = entry.data['kind']?.toString() ?? 'wet';
        return Text(
          kind == 'wet' ? '💧' : '💩',
          style: const TextStyle(fontSize: 24),
        );
      case 'SLEEP':
        return const Text('😴', style: TextStyle(fontSize: 24));
      case 'MEDICINE':
        return const Text('💊', style: TextStyle(fontSize: 22));
      case 'GROWTH':
        return const Text('📏', style: TextStyle(fontSize: 22));
      default:
        return const Text('📝', style: TextStyle(fontSize: 22));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final timeStr = DateFormat('h:mm a').format(entry.startedAt.toLocal());
    final details = _formatDetails();
    final primaryTitle = _label();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: dark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? AppTheme.lineDark : const Color(0xFFEFEAE2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pastel Rounded-Square Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _iconBgColor(entry.type),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: _buildSquareIllustration(entry.type),
          ),
          const SizedBox(width: 14),
          // Title + Details + Timestamp on top row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          primaryTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : const Color(0xFF1F1A17),
                          ),
                        ),
                        if (isPinned) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8C7AE6).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFF8C7AE6)),
                                const SizedBox(width: 3),
                                Text(
                                  strings.pin,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF8C7AE6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: dark ? const Color(0xFFA5A2BD) : const Color(0xFF2B2523),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: dark ? const Color(0xFFA5A2BD) : const Color(0xFF3D3530),
                        ),
                      ),
                    ),
                    if (onTogglePin != null)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onTogglePin,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Icon(
                            isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                            size: 16,
                            color: isPinned ? const Color(0xFF8C7AE6) : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final withWhom = entry.taggedUserName != null ? ' (with ${entry.taggedUserName})' : '';
                        final msg = strings.isHe
                            ? '🍼 בייבי דיילי: $primaryTitle - $details$withWhom בשעה $timeStr'
                            : '🍼 BabyDaily: $primaryTitle - $details$withWhom at $timeStr';
                        launchUrl(
                          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(Icons.share_outlined, size: 15, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    if (onDelete != null)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFEF4444)),
                        ),
                      ),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty && entry.type != 'NOTE')
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      entry.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
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
