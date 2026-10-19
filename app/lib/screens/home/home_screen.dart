import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../l10n/app_strings.dart';
import '../../models/baby.dart';
import '../../models/entry.dart';
import '../../state/baby_state.dart';
import '../../state/channel_state.dart';
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                    color: isSelected ? AppTheme.primaryDark : AppTheme.ink(context),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final api = context.read<ApiClient>();
    final baseUrl = api.baseUrl;
    final tk = Uri.encodeComponent(api.token ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              leading: const Icon(Icons.table_chart_outlined, color: Colors.green),
              title: Text(s.exportCsv, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s.isHe ? 'קובץ נתונים מעוצב עבור Excel ו-Google Sheets' : 'Formatted spreadsheet for Excel & Sheets'),
              trailing: const Icon(Icons.download),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('$baseUrl/babies/${baby.id}/export?format=csv&token=$tk'), mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.divider),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
              title: Text(s.exportPdf, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s.isHe ? 'דוח רפואי מעוצב להדפסה או שמירה כ-PDF' : 'Medical printout / PDF for pediatricians'),
              trailing: const Icon(Icons.print_outlined),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('$baseUrl/babies/${baby.id}/export?format=pdf&token=$tk'), mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.divider),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              leading: const Icon(Icons.description_outlined, color: Colors.blue),
              title: Text(s.exportWord, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s.isHe ? 'מסמך וורד DOC הניתן לעריכה' : 'Editable Microsoft Word / Google Docs file'),
              trailing: const Icon(Icons.download),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('$baseUrl/babies/${baby.id}/export?format=word&token=$tk'), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BabyModel baby, EntryState entryState, AppStrings s) {
    final ch = context.read<ChannelState>();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final recentEntries = entryState.entries.take(5).map((e) {
      final time = DateFormat('HH:mm').format(e.startedAt.toLocal());
      final author = e.authorName ?? '';
      return '${AppTheme.act(e.type).emoji} $time - ${e.type}${author.isNotEmpty ? ' ($author)' : ''}';
    }).join('\n');

    final message = s.isHe
        ? '🍼 *בייבי דיילי - עדכון שגרה עבור ${baby.name}*\n📅 תאריך: $dateStr\n\n✨ *פעילויות אחרונות:*\n${recentEntries.isNotEmpty ? recentEntries : "עדיין אין פעילויות היום"}\n\nנשלח מאפליקציית בייבי דיילי 👶'
        : '🍼 *BabyDaily - Routine Update for ${baby.name}*\n📅 Date: $dateStr\n\n✨ *Recent Activity:*\n${recentEntries.isNotEmpty ? recentEntries : "No entries logged yet today"}\n\nSent from BabyDaily App 👶';
    final encoded = Uri.encodeComponent(message);

    Future<void> openWa() => launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
    Future<void> openTg() => launchUrl(Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent('https://babydaily.app')}&text=$encoded'), mode: LaunchMode.externalApplication);

    Widget tile(String emoji, String label, Color color, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color)),
            leading: Text(emoji, style: const TextStyle(fontSize: 22)),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
              onTap();
            },
          ),
        );

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.shareDailySummary, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            if (!ch.any)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s.isHe ? 'כל ערוצי השיתוף כבויים. אפשר להפעיל אותם בהגדרות.' : 'All sharing channels are off. Enable them in Settings.',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
            if (ch.whatsapp) tile('💬', s.shareWhatsApp, const Color(0xFF25D366), openWa),
            if (ch.telegram) tile('✈️', s.shareTelegram, const Color(0xFF0088CC), openTg),
            if (ch.whatsapp && ch.telegram)
              tile('♾️', s.shareAll, AppTheme.primary, () async {
                await openWa();
                await openTg();
              }),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Today tab
  // ---------------------------------------------------------------------------

  Widget _sectionTitle(String text, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: .6, color: AppTheme.textMuted),
            ),
            ?trailing,
          ],
        ),
      );

  Widget _buildStatusBanner(BabyModel baby, EntryState entryState, AppStrings s) {
    final sleeping = entryState.isSleeping;
    String sub = s.isHe ? 'מוכן/ה לשנת צהריים?' : 'Ready for a nap?';
    if (sleeping) {
      final d = entryState.activeSleepDuration;
      final h = d.inHours;
      final m = d.inMinutes % 60;
      final sec = d.inSeconds % 60;
      sub = h > 0 ? '${h}h ${m}m ${sec}s' : '${m}m ${sec}s';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: sleeping ? const [Color(0xFF5B6CFF), Color(0xFF8B7BFF)] : [AppTheme.primary, const Color(0xFFFFA26B)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sleeping ? '${baby.name} ${s.currentlySleeping} 💤' : '${baby.name} ${s.isAwake} ☀️',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2B2A3D),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            onPressed: () => sleeping ? entryState.wakeUp(baby.id) : entryState.startSleep(baby.id),
            child: Text(sleeping ? s.wakeUp : s.startSleep),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(EntryState entryState, AppStrings s) {
    final items = <MapEntry<String?, String>>[
      MapEntry(null, s.isHe ? 'הכל' : 'All'),
      MapEntry('FEED', '🍼 ${s.feed}'),
      MapEntry('SLEEP', '😴 ${s.sleep}'),
      MapEntry('DIAPER', '🧷 ${s.diaper}'),
      MapEntry('MEDICINE', '💊 ${s.medicine}'),
      MapEntry('GROWTH', '📏 ${s.growth}'),
      MapEntry('NOTE', '📝 ${s.note}'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final it = items[i];
          final selected = entryState.filterType == it.key;
          final color = it.key == null ? AppTheme.primary : AppTheme.act(it.key!).strong;
          return ChoiceChip(
            selected: selected,
            label: Text(it.value),
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? color : AppTheme.textMuted),
            selectedColor: color.withValues(alpha: 0.16),
            side: BorderSide(color: selected ? color : AppTheme.line(context)),
            onSelected: (_) => entryState.setFilter(it.key),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(BabyModel baby, EntryState entryState, AppStrings s) {
    final summary = entryState.summary;

    final sleepH = summary.sleepMinutes ~/ 60;
    final sleepM = summary.sleepMinutes % 60;
    final sleepStr = sleepH > 0 ? '${sleepH}h ${sleepM}m' : '${sleepM}m';
    final diaperSub = summary.diapersTotal > 0
        ? '${summary.diapersWet} ${s.diaperWet} · ${summary.diapersDirty} ${s.diaperDirty}'
        : s.noneYet;
    final feedSub = summary.bottleMl > 0 ? '${summary.bottleMl} ml' : (summary.breastMinutes > 0 ? '${summary.breastMinutes} min' : null);

    Widget action(String type, String label) => QuickActionButton(
          type: type,
          label: label,
          onTap: () => LogEntrySheet.show(context, baby.id, type),
        );

    return RefreshIndicator(
      onRefresh: () => entryState.loadForBaby(baby.id),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(baby, entryState, s),
            _sectionTitle(s.todaySummary),
            Row(
              children: [
                Expanded(child: StatCard(type: 'FEED', title: s.feedsCount, value: '${summary.feeds}', subtitle: summary.feeds > 0 ? feedSub : null)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(type: 'SLEEP', title: s.totalSleep, value: sleepStr, subtitle: entryState.isSleeping ? s.currentlySleeping : (summary.sleepMinutes > 0 ? 'total' : null))),
                const SizedBox(width: 10),
                Expanded(child: StatCard(type: 'DIAPER', title: s.diaperChanges, value: '${summary.diapersTotal}', subtitle: diaperSub)),
              ],
            ),
            _sectionTitle(s.quickActions),
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.12,
              children: [
                action('FEED', s.feed),
                action('SLEEP', s.sleep),
                action('DIAPER', s.diaper),
                action('MEDICINE', s.medicine),
                action('GROWTH', s.growth),
                action('NOTE', s.note),
              ],
            ),
            _sectionTitle(
              s.recentActivity,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Text('📤', style: TextStyle(fontSize: 18)),
                    tooltip: s.exportData,
                    onPressed: () => _showExportSheet(baby, s),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Text('📲', style: TextStyle(fontSize: 18)),
                    tooltip: s.shareDailySummary,
                    onPressed: () => _showShareSheet(baby, entryState, s),
                  ),
                ],
              ),
            ),
            _buildFilterChips(entryState, s),
            const SizedBox(height: 12),
            if (entryState.entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.card(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.line(context)),
                ),
                child: Column(
                  children: [
                    const Text('🐣', style: TextStyle(fontSize: 38)),
                    const SizedBox(height: 12),
                    Text(
                      entryState.filterType == null ? s.noEntriesToday : (s.isHe ? 'אין רישומים מהסוג הזה' : 'No entries of this type'),
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
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(String emoji, VoidCallback onTap, {String? tooltip}) => Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.line(context)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
      );

  Widget _buildHeader(BabyModel? baby, AppStrings s, LocaleState localeState) {
    final dark = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: baby == null
                ? Text(s.appName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))
                : InkWell(
                    onTap: () => _showBabyPicker(s),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
                          child: Text(
                            baby.name.isNotEmpty ? baby.name.characters.first.toUpperCase() : '👶',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(baby.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 4),
                        const Text('⌄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
          ),
          _iconBtn(localeState.isHe ? '🇬🇧' : '🇮🇱', () => localeState.toggle(), tooltip: s.language),
          const SizedBox(width: 8),
          _iconBtn('🌓', () => context.read<ThemeState>().toggleDark(dark)),
        ],
      ),
    );
  }

  Widget _buildNavBar(AppStrings s, NotificationState notifState) {
    final items = <(String, String, bool)>[
      ('🏠', s.navHome, false),
      ('👨‍👩‍👧', s.navShare, false),
      ('⏰', s.navReminders, false),
      ('🔔', s.navNotifications, notifState.unreadCount > 0),
      ('⚙️', s.navSettings, false),
    ];
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.line(context)),
          boxShadow: [BoxShadow(color: const Color(0xFF2B2A3D).withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = _tabIndex == i;
            final it = items[i];
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _tabIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(it.$1, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            it.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? AppTheme.primary : AppTheme.textMuted),
                          ),
                        ],
                      ),
                      if (it.$3)
                        Positioned(
                          top: -2,
                          right: 14,
                          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
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
                  Text(s.noBabiesYet, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBabyScreen())),
                    icon: const Icon(Icons.add),
                    label: Text(s.addBaby),
                  ),
                ],
              ),
            )
          : _buildDashboard(currentBaby, entryState, s);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_tabIndex == 0) _buildHeader(currentBaby, s, localeState),
            Expanded(child: bodyContent),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(s, notifState),
    );
  }
}
