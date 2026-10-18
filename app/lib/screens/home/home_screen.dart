import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../l10n/app_strings.dart';
import '../../models/baby.dart';
import '../../models/entry.dart';
import '../../state/baby_state.dart';
import '../../state/entry_state.dart';
import '../../state/locale_state.dart';
import '../../state/notification_state.dart';
import '../../state/theme_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/baby_avatar.dart';
import '../../widgets/entry_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/stat_card.dart';
import '../babies/create_baby_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reminders/reminders_screen.dart';
import '../settings/settings_screen.dart';
import '../sharing/sharing_screen.dart';
import '../sheets/log_entry_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final babyState = context.read<BabyState>();
      final notifState = context.read<NotificationState>();
      final entryState = context.read<EntryState>();

      await babyState.loadBabies();
      await notifState.load();

      if (babyState.currentBaby != null) {
        await entryState.loadForBaby(babyState.currentBaby!.id);
      }
    });
  }

  void _showBabyPicker(AppStrings s) {
    final babyState = context.read<BabyState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.selectBaby,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...babyState.babies.map((b) {
              final isSelected = b.id == babyState.currentBaby?.id;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                selected: isSelected,
                selectedTileColor: AppTheme.primaryLight,
                leading: BabyAvatar(name: b.name, colorHex: b.avatarColor, size: 40),
                title: Text(
                  b.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppTheme.primaryDark : AppTheme.textMain,
                  ),
                ),
                subtitle: Text('${s.roleLabel}: ${b.role == 'OWNER' ? s.roleOwner : b.role == 'CAREGIVER' ? s.caregiverLabel : s.viewerLabel}'),
                trailing: isSelected ? Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  babyState.selectBaby(b);
                  context.read<ThemeState>().syncWithBabyColor(b.avatarColor);
                  context.read<EntryState>().loadForBaby(b.id);
                  Navigator.pop(ctx);
                },
              );
            }),
            const Divider(height: 24),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F3F6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.add, color: AppTheme.primary),
              ),
              title: Text(s.addBaby, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateBabyScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteEntry(BabyModel baby, EntryModel entry, AppStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmDeleteEntryTitle),
        content: Text(s.confirmDeleteEntryContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await context.read<EntryState>().deleteEntry(baby.id, entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? s.entryDeletedSuccess : s.errorOccurred),
            backgroundColor: ok ? Colors.green.shade700 : Colors.red,
          ),
        );
      }
    }
  }

  void _showExportSheet(BabyModel baby, AppStrings s) {
    final baseUrl = context.read<ApiClient>().baseUrl;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.file_download_outlined, color: AppTheme.sky, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.exportData,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.exportSubtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 18),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.divider),
              ),
              tileColor: const Color(0xFFF7FAFC),
              leading: const Icon(Icons.table_chart_outlined, color: Colors.green),
              title: Text(s.exportCsv, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s.isHe ? 'קובץ נתונים מעוצב עבור Excel ו-Google Sheets' : 'Formatted spreadsheet for Excel & Sheets'),
              trailing: const Icon(Icons.download),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('$baseUrl/babies/${baby.id}/export?format=csv'), mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.divider),
              ),
              tileColor: const Color(0xFFF7FAFC),
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
              title: Text(s.exportPdf, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s.isHe ? 'דוח רפואי מעוצב להדפסה או שמירה כ-PDF' : 'Medical printout / PDF for pediatricians'),
              trailing: const Icon(Icons.print_outlined),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('$baseUrl/babies/${baby.id}/export?format=pdf'), mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.divider),
              ),
              tileColor: const Color(0xFFF7FAFC),
              leading: const Icon(Icons.description_outlined, color: Colors.blue),
              title: Text(s.exportWord, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s.isHe ? 'מסמך וורד DOC הניתן לעריכה' : 'Editable Microsoft Word / Google Docs file'),
              trailing: const Icon(Icons.download),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('$baseUrl/babies/${baby.id}/export?format=word'), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BabyModel baby, EntryState entryState, AppStrings s) {
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final recentEntries = entryState.entries.take(5).map((e) {
      final time = DateFormat('HH:mm').format(e.startedAt);
      final typeEmoji = e.type == 'FEED'
          ? '🍼'
          : e.type == 'SLEEP'
              ? '😴'
              : e.type == 'DIAPER'
                  ? '🧷'
                  : e.type == 'MEDICINE'
                      ? '💊'
                      : '📝';
      final author = e.authorName ?? '';
      return '$typeEmoji $time - ${e.type}${author.isNotEmpty ? ' ($author)' : ''}';
    }).join('\n');

    final message = s.isHe
        ? '🍼 *בייבי דיילי - עדכון שגרה עבור ${baby.name}*\n'
            '📅 תאריך: $dateStr\n\n'
            '✨ *פעילויות אחרונות:*\n'
            '${recentEntries.isNotEmpty ? recentEntries : "עדיין אין פעילויות היום"}\n\n'
            'נשלח מאפליקציית בייבי דיילי 👶'
        : '🍼 *BabyDaily - Routine Update for ${baby.name}*\n'
            '📅 Date: $dateStr\n\n'
            '✨ *Recent Activity:*\n'
            '${recentEntries.isNotEmpty ? recentEntries : "No entries logged yet today"}\n\n'
            'Sent from BabyDaily App 👶';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share_outlined, color: AppTheme.defaultPrimary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.shareDailySummary,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF25D366)),
              ),
              tileColor: const Color(0xFFF0FDF4),
              leading: const Icon(Icons.chat_bubble, color: Color(0xFF25D366)),
              title: Text(s.shareWhatsApp, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                final encoded = Uri.encodeComponent(message);
                launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF0088CC)),
              ),
              tileColor: const Color(0xFFF0F9FF),
              leading: const Icon(Icons.send, color: Color(0xFF0088CC)),
              title: Text(s.shareTelegram, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                final encoded = Uri.encodeComponent(message);
                launchUrl(Uri.parse('https://t.me/share/url?text=$encoded'), mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.defaultPrimary),
              ),
              tileColor: AppTheme.primaryLight,
              leading: const Icon(Icons.all_inclusive, color: AppTheme.defaultPrimary),
              title: Text(s.shareAll, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.check_circle_outline, color: AppTheme.defaultPrimary),
              onTap: () async {
                Navigator.pop(ctx);
                final encoded = Uri.encodeComponent(message);
                await launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepBanner(BabyModel baby, EntryState entryState, AppStrings s) {
    final isSleeping = entryState.isSleeping;

    if (isSleeping) {
      final dur = entryState.activeSleepDuration;
      final h = dur.inHours;
      final m = dur.inMinutes % 60;
      final sec = dur.inSeconds % 60;
      final timeFormatted = h > 0 ? '${h}h ${m}m ${sec}s' : '${m}m ${sec}s';

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.mintLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.mint.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('😴', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${baby.name} ${s.currentlySleeping}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E272E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeFormatted,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mint,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => entryState.wakeUp(baby.id),
              icon: const Text('🌤️'),
              label: Text(s.wakeUp),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Text('🌤️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${baby.name} ${s.isAwake}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: const BorderSide(color: AppTheme.mint),
              foregroundColor: AppTheme.mint,
            ),
            onPressed: () => entryState.startSleep(baby.id),
            icon: const Text('😴'),
            label: Text(s.startSleep),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BabyModel baby, EntryState entryState, AppStrings s) {
    final summary = entryState.summary;

    final sleepH = summary.sleepMinutes ~/ 60;
    final sleepM = summary.sleepMinutes % 60;
    final sleepStr = sleepH > 0 ? '${sleepH}h ${sleepM}m' : '${sleepM}m';

    final diaperStr = '${summary.diapersTotal}';
    final diaperSub = summary.diapersTotal > 0
        ? '${summary.diapersWet} ${s.diaperWet} • ${summary.diapersDirty} ${s.diaperDirty}'
        : s.noneYet;

    final feedSub = summary.bottleMl > 0 ? '${summary.bottleMl} ${s.amountMl}' : '${summary.breastMinutes} ${s.breast}';

    return RefreshIndicator(
      onRefresh: () => entryState.loadForBaby(baby.id),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sleep Active Banner
            _buildSleepBanner(baby, entryState, s),

            // Today's summary cards
            Text(
              s.todaySummary,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: s.feedsCount,
                    value: '${summary.feeds}',
                    subtitle: summary.feeds > 0 ? feedSub : null,
                    emoji: '🍼',
                    color: AppTheme.sun,
                    bgColor: AppTheme.sunLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: s.totalSleep,
                    value: sleepStr,
                    subtitle: entryState.isSleeping ? s.currentlySleeping : null,
                    emoji: '😴',
                    color: AppTheme.mint,
                    bgColor: AppTheme.mintLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: s.diaperChanges,
                    value: diaperStr,
                    subtitle: diaperSub,
                    emoji: '🧷',
                    color: AppTheme.lavender,
                    bgColor: AppTheme.lavenderLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions Grid
            Text(
              s.quickActions,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    label: s.feed,
                    emoji: '🍼',
                    color: AppTheme.sun,
                    bgColor: AppTheme.sunLight,
                    onTap: () => LogEntrySheet.show(context, baby.id, 'FEED'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionButton(
                    label: s.sleep,
                    emoji: '😴',
                    color: AppTheme.mint,
                    bgColor: AppTheme.mintLight,
                    onTap: () => LogEntrySheet.show(context, baby.id, 'SLEEP'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionButton(
                    label: s.diaper,
                    emoji: '🧷',
                    color: AppTheme.lavender,
                    bgColor: AppTheme.lavenderLight,
                    onTap: () => LogEntrySheet.show(context, baby.id, 'DIAPER'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    label: s.medicine,
                    emoji: '💊',
                    color: AppTheme.primary,
                    bgColor: AppTheme.primaryLight,
                    onTap: () => LogEntrySheet.show(context, baby.id, 'MEDICINE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionButton(
                    label: s.growth,
                    emoji: '📏',
                    color: AppTheme.sky,
                    bgColor: AppTheme.skyLight,
                    onTap: () => LogEntrySheet.show(context, baby.id, 'GROWTH'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickActionButton(
                    label: s.note,
                    emoji: '📝',
                    color: Colors.teal,
                    bgColor: const Color(0xFFE6F7F5),
                    onTap: () => LogEntrySheet.show(context, baby.id, 'NOTE'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Timeline header, export & social share buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      s.recentActivity,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (entryState.filterType != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => entryState.setFilter(null),
                        child: Text(s.showAll),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, color: AppTheme.sky, size: 22),
                      tooltip: s.exportData,
                      onPressed: () => _showExportSheet(baby, s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: AppTheme.defaultPrimary, size: 22),
                      tooltip: s.shareDailySummary,
                      onPressed: () => _showShareSheet(baby, entryState, s),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Activity feed
            if (entryState.entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    const Text('🐣', style: TextStyle(fontSize: 38)),
                    const SizedBox(height: 12),
                    Text(
                      s.noEntriesToday,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...entryState.entries.map((e) => EntryCard(
                    entry: e,
                    strings: s,
                    onDelete: () => _confirmDeleteEntry(baby, e, s),
                  )),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final localeState = context.watch<LocaleState>();
    final babyState = context.watch<BabyState>();
    final entryState = context.watch<EntryState>();
    final notifState = context.watch<NotificationState>();
    final currentBaby = babyState.currentBaby;

    // Body by selected tab
    Widget bodyContent;
    if (_tabIndex == 1) {
      bodyContent = const SharingScreen();
    } else if (_tabIndex == 2) {
      bodyContent = const RemindersScreen();
    } else if (_tabIndex == 3) {
      bodyContent = const NotificationsScreen();
    } else if (_tabIndex == 4) {
      bodyContent = const SettingsScreen();
    } else {
      bodyContent = currentBaby == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👶', style: TextStyle(fontSize: 54)),
                  const SizedBox(height: 16),
                  Text(
                    s.noBabiesYet,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateBabyScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(s.addBaby),
                  ),
                ],
              ),
            )
          : _buildDashboard(currentBaby, entryState, s);
    }

    return Scaffold(
      appBar: _tabIndex == 0
          ? AppBar(
              title: currentBaby != null
                  ? InkWell(
                      onTap: () => _showBabyPicker(s),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BabyAvatar(
                              name: currentBaby.name,
                              colorHex: currentBaby.avatarColor,
                              size: 36,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              currentBaby.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 20),
                          ],
                        ),
                      ),
                    )
                  : Text(s.appName),
              actions: [
                // Language Switcher
                TextButton(
                  onPressed: () => localeState.toggle(),
                  child: Text(
                    localeState.isHe ? 'EN' : 'עב',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Notifications bell with badge
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {
                        setState(() => _tabIndex = 3);
                      },
                    ),
                    if (notifState.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${notifState.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: bodyContent,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: s.navShare,
          ),
          NavigationDestination(
            icon: const Icon(Icons.alarm_outlined),
            selectedIcon: const Icon(Icons.alarm),
            label: s.navReminders,
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_outlined),
                if (notifState.unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: s.navNotifications,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}
