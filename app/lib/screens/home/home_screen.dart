import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../l10n/app_strings.dart';
import '../../models/baby.dart';
import '../../models/entry.dart';
import '../../state/auth_state.dart';
import '../../state/baby_state.dart';
import '../../state/channel_state.dart';
import '../../state/entry_state.dart';
import '../../state/locale_state.dart';
import '../../state/notification_state.dart';
import '../../state/theme_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_alarm.dart';
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
import '../ai/ai_advisor_card.dart';
import '../ai/v120_suite_card.dart';

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                subtitle: Text(
                  '${s.roleLabel}: ${b.role == 'OWNER' ? s.roleOwner : b.role == 'CAREGIVER' ? s.caregiverLabel : s.viewerLabel}',
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(s.delete, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(s.confirmDeleteEntryContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel, style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final ok = await context.read<EntryState>().deleteEntry(baby.id, entry.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ok ? s.entryDeletedSuccess : s.errorOccurred),
            backgroundColor: ok ? AppTheme.mint : AppTheme.danger,
            duration: const Duration(seconds: 2),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              trailing: const Icon(Icons.download),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(
                  Uri.parse('$baseUrl/babies/${baby.id}/export?format=csv&token=$tk'),
                  mode: LaunchMode.externalApplication,
                );
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
              trailing: const Icon(Icons.print_outlined),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(
                  Uri.parse('$baseUrl/babies/${baby.id}/export?format=pdf&token=$tk'),
                  mode: LaunchMode.externalApplication,
                );
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

    Future<void> openWa() =>
        launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
    Future<void> openTg() => launchUrl(
        Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent('https://babydaily.app')}&text=$encoded'),
        mode: LaunchMode.externalApplication);

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
            if (ch.whatsapp)
              ListTile(
                leading: const Text('💬', style: TextStyle(fontSize: 22)),
                title: Text(s.shareWhatsApp, style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(context);
                  openWa();
                },
              ),
            if (ch.telegram)
              ListTile(
                leading: const Text('✈️', style: TextStyle(fontSize: 22)),
                title: Text(s.shareTelegram, style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(context);
                  openTg();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Screenshot 1 & 4: Header + Lavender Sleeping Pill + Quick Action + Timeline
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BabyModel? baby, AppStrings s, LocaleState localeState) {
    final dark = AppTheme.isDark(context);
    final authUser = context.watch<AuthState>().user;
    final parentName = authUser != null && authUser.name.isNotEmpty
        ? authUser.name.split(' ').first
        : (s.isHe ? 'שרה' : 'Sarah');
    final ageStr = baby?.ageDescription(localeState.isHe);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F1C2C) : const Color(0xFFF3ECE0),
      ),
      child: Row(
        children: [
          // Cute Baby Face Avatar matching Screenshot 1
          InkWell(
            onTap: () => _showBabyPicker(s),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF6D9CC),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('👶🏼', style: TextStyle(fontSize: 34)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: () => _showBabyPicker(s),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.isHe ? 'שלום, $parentName!' : 'Hello, $parentName!',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : const Color(0xFF2B1810),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    baby == null
                        ? s.appName
                        : (ageStr != null && ageStr.isNotEmpty
                            ? '${baby.name}, $ageStr'
                            : '${baby.name}, 6 months'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: dark ? const Color(0xFFB8B4CC) : const Color(0xFF3E2D24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Language (Heb, English, Spanish, Russian - No Flags) & Family Sharing quick buttons
          PopupMenuButton<String>(
            tooltip: s.language,
            onSelected: (lang) => localeState.setLocale(lang),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ru', child: Text('Русский')),
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'he', child: Text('עברית')),
              PopupMenuItem(value: 'es', child: Text('Español')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2E2648) : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dark ? const Color(0xFF4C3D77) : const Color(0xFFDFD5C5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    size: 16,
                    color: dark ? Colors.white70 : const Color(0xFF4A372D),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    localeState.currentLanguageName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : const Color(0xFF4A372D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SharingScreen()),
              );
            },
            tooltip: s.navShare,
            icon: Icon(
              Icons.group_add_outlined,
              color: dark ? Colors.white70 : const Color(0xFF4A372D),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BabyModel baby, EntryState entryState, AppStrings s) {
    final sleeping = entryState.isSleeping;
    final dark = AppTheme.isDark(context);

    String durationText;
    if (sleeping) {
      final d = entryState.activeSleepDuration;
      final h = d.inHours;
      final m = d.inMinutes % 60;
      durationText = h > 0 ? '${h}h ${m}m' : '${m}m';
    } else {
      final lastSleepEnd = entryState.summary.lastSleep?.endedAt;
      if (lastSleepEnd != null) {
        final d = DateTime.now().difference(lastSleepEnd.toLocal());
        final h = d.inHours;
        final m = d.inMinutes % 60;
        durationText = d.isNegative ? '0m' : (h > 0 ? '${h}h ${m}m' : '${m}m');
      } else {
        durationText = '—';
      }
    }

    final bannerBg = sleeping
        ? (dark ? const Color(0xFF342B54) : const Color(0xFFCBC0EE))
        : (dark ? const Color(0xFF233B2B) : const Color(0xFFD4EDDA));
    final bannerIconColor = sleeping ? const Color(0xFF6B5B9E) : const Color(0xFF2E7D32);
    final bannerTextColor = dark ? Colors.white : (sleeping ? const Color(0xFF1F1A24) : const Color(0xFF1B4332));

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Icon(
            sleeping ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            color: bannerIconColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            sleeping
                ? (s.isHe ? 'ישנ/ה' : 'SLEEPING')
                : (s.isHe ? 'ער/ה' : 'AWAKE'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: bannerTextColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              durationText,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: bannerTextColor,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              if (sleeping) {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await entryState.wakeUp(baby.id);
                if (mounted && ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('${baby.name} ${s.wakeUp}!'),
                        ],
                      ),
                      backgroundColor: AppTheme.mint,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await entryState.startSleep(baby.id);
                if (mounted && ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.nightlight_round, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(s.sleepAlertNotice),
                        ],
                      ),
                      backgroundColor: const Color(0xFF8C7AE6),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1F2937) : const Color(0xFFF6EFE2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sleeping ? Icons.wb_sunny_rounded : Icons.bedtime_rounded,
                    size: 17,
                    color: sleeping ? const Color(0xFFD97706) : const Color(0xFF8C7AE6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sleeping
                        ? (s.isHe ? 'העיר/י' : 'Wake')
                        : (s.isHe ? 'להרדים' : 'Sleep'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : const Color(0xFF2B2523),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BabyModel baby, EntryState entryState, AppStrings s) {
    final dark = AppTheme.isDark(context);

    return RefreshIndicator(
      onRefresh: () => entryState.loadForBaby(baby.id),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lavender Sleeping Banner matching Screenshot 1
            _buildStatusBanner(baby, entryState, s),

            // AI Advisor Card (Nap window predictions, DeepSeek assistant, 7-day stats)
            AiAdvisorCard(babyId: baby.id, babyName: baby.name),

            // v1.2.0 Holistic Parenting Suite (AI Voice/NL, Milk Stash, 100 Foods, Tummy/CDC, WHO, White Noise, Handoff)
            V120SuiteCard(babyId: baby.id, babyName: baby.name),

            // "Quick Action" Header
            Text(
              s.quickActions,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : const Color(0xFF1F1A17),
              ),
            ),
            const SizedBox(height: 12),

            // 4 Circular Pastel Buttons directly on the cream background
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                QuickActionButton(
                  type: 'FEED',
                  label: s.feed,
                  onTap: () => LogEntrySheet.show(context, baby.id, 'FEED'),
                ),
                QuickActionButton(
                  type: 'SLEEP',
                  label: s.sleep,
                  onTap: () => LogEntrySheet.show(context, baby.id, 'SLEEP'),
                ),
                QuickActionButton(
                  type: 'DIAPER',
                  label: s.diaper,
                  onTap: () => LogEntrySheet.show(context, baby.id, 'DIAPER'),
                ),
                QuickActionButton(
                  type: 'MEDICINE',
                  label: s.medicine,
                  onTap: () => LogEntrySheet.show(context, baby.id, 'MEDICINE'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Phone Clock Alarm for Next Meal quick bar
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                final target = await PhoneAlarm.setAlarmAfter(
                  duration: const Duration(hours: 3),
                  message: '🍼 ${s.feed} - ${baby.name}',
                );
                if (mounted) {
                  final formatted =
                      '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.mint,
                      content: Text('${s.alarmSetSuccess} ($formatted)'),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF2E2648) : const Color(0xFFFFF5EE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: dark ? const Color(0xFF4C3D77) : const Color(0xFFF3C6B6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_on_rounded, color: Color(0xFFDE6B52), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.setPhoneClockAlarm,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : const Color(0xFF2B1810),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDE6B52),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s.tr(en: '+3h Clock', he: 'שעון +3 ש׳', es: 'Reloj +3h', ru: '+3ч Будильник'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // "Today's Timeline" Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.tr(en: "Today's Timeline", he: 'יומן היום', es: 'Actividad de hoy', ru: 'Дневник за сегодня'),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : const Color(0xFF1F1A17),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.ios_share_rounded, size: 19, color: Color(0xFF6B7280)),
                      tooltip: s.shareDailySummary,
                      onPressed: () => _showShareSheet(baby, entryState, s),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.file_download_outlined, size: 20, color: Color(0xFF6B7280)),
                      tooltip: s.exportData,
                      onPressed: () => _showExportSheet(baby, s),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (entryState.entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEFEAE2)),
                ),
                child: Column(
                  children: [
                    const Text('🐣', style: TextStyle(fontSize: 38)),
                    const SizedBox(height: 12),
                    Text(
                      s.noEntriesToday,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s.swipeTimelineHint,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              ...entryState.entries.map(
                (e) {
                  final isPinned = entryState.isPinned(e.id);
                  return Dismissible(
                    key: ValueKey('entry_${e.id}'),
                    direction: baby.canLog ? DismissDirection.horizontal : (isPinned ? DismissDirection.none : DismissDirection.endToStart),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        // Swiped LEFT: Pin / Unpin
                        final messenger = ScaffoldMessenger.of(context);
                        await entryState.togglePin(e.id);
                        final nowPinned = entryState.isPinned(e.id);
                        if (!mounted) return false;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  nowPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(nowPinned ? s.pinnedSuccess : s.unpinnedSuccess),
                              ],
                            ),
                            backgroundColor: nowPinned ? const Color(0xFF8C7AE6) : const Color(0xFF6B7280),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return false; // Do not dismiss widget
                      } else if (direction == DismissDirection.startToEnd) {
                        // Swiped RIGHT: Confirm Delete
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            title: Text(s.delete, style: const TextStyle(fontWeight: FontWeight.w800)),
                            content: Text(s.confirmDeleteEntryContent),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(s.cancel, style: const TextStyle(color: AppTheme.textMuted)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.danger,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(s.delete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        return confirmed == true;
                      }
                      return false;
                    },
                    onDismissed: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await entryState.deleteEntry(baby.id, e.id);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(ok ? s.entryDeletedSuccess : s.errorOccurred),
                              backgroundColor: ok ? AppTheme.mint : AppTheme.danger,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    // Swiping RIGHT (startToEnd) -> Delete
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            s.delete,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Swiping LEFT (endToStart) -> Pin / Unpin
                    secondaryBackground: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isPinned ? const Color(0xFF6B7280) : const Color(0xFF8C7AE6),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isPinned ? s.unpin : s.pin,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    child: EntryCard(
                      entry: e,
                      strings: s,
                      isPinned: isPinned,
                      onTogglePin: () => entryState.togglePin(e.id),
                      onDelete: () => _confirmDeleteEntry(baby, e, s),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Stats & Family Tab (Tab 2)
  Widget _buildStatsTab(BabyModel? baby, EntryState entryState, AppStrings s) {
    if (baby == null) return const SizedBox.shrink();
    final summary = entryState.summary;
    final sleepH = summary.sleepMinutes ~/ 60;
    final sleepM = summary.sleepMinutes % 60;
    final sleepStr = sleepH > 0 ? '${sleepH}h ${sleepM}m' : '${sleepM}m';
    final diaperSub = summary.diapersTotal > 0
        ? '${summary.diapersWet} ${s.diaperWet} · ${summary.diapersDirty} ${s.diaperDirty}'
        : s.noneYet;
    final feedSub = summary.bottleMl > 0
        ? '${summary.bottleMl} ml'
        : (summary.breastMinutes > 0 ? '${summary.breastMinutes} min' : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.todaySummary,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  type: 'FEED',
                  title: s.feedsCount,
                  value: '${summary.feeds}',
                  subtitle: summary.feeds > 0 ? feedSub : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  type: 'SLEEP',
                  title: s.totalSleep,
                  value: sleepStr,
                  subtitle: entryState.isSleeping ? s.currentlySleeping : 'total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  type: 'DIAPER',
                  title: s.diaperChanges,
                  value: '${summary.diapersTotal}',
                  subtitle: diaperSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: Colors.white,
            leading: const Icon(Icons.group_outlined, color: Color(0xFFDE6B52)),
            title: Text(s.navShare, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SharingScreen())),
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: Colors.white,
            leading: const Icon(Icons.alarm, color: Color(0xFF7C3AED)),
            title: Text(s.navReminders, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())),
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: Colors.white,
            leading: const Icon(Icons.notifications_outlined, color: Color(0xFF0284C7)),
            title: Text(s.navNotifications, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar with smooth animated sliding indicator between tabs
  Widget _buildNavBar(BabyModel? currentBaby, AppStrings s) {
    final dark = AppTheme.isDark(context);
    final isRtl = context.watch<LocaleState>().isHe;
    final items = <(IconData, String)>[
      (Icons.home_rounded, s.navHome),
      (Icons.assignment_outlined, s.tr(en: 'Log', he: 'רישום', es: 'Registrar', ru: 'Запись')),
      (Icons.bar_chart_rounded, s.tr(en: 'Stats', he: 'נתונים', es: 'Datos', ru: 'Сводка')),
      (Icons.settings_outlined, s.navSettings),
    ];
    final activeColor = const Color(0xFFE68369);
    final inactiveColor = dark ? Colors.white60 : const Color(0xFF4B4440);

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppTheme.cardDark : const Color(0xFFFCF9F5),
        border: Border(
          top: BorderSide(
            color: dark ? AppTheme.lineDark : const Color(0xFFEBE4DA),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / items.length;
              final selectedOffset = isRtl
                  ? (items.length - 1 - _tabIndex) * tabWidth
                  : _tabIndex * tabWidth;

              return SizedBox(
                height: 54,
                child: Stack(
                  children: [
                    // Smooth animated sliding highlight indicator between selections
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.fastOutSlowIn,
                      left: selectedOffset,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: activeColor.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    // Navigation tab buttons
                    Row(
                      children: List.generate(items.length, (i) {
                        final selected = _tabIndex == i;
                        final item = items[i];

                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (i == 1 && currentBaby != null) {
                                LogEntrySheet.show(context, currentBaby.id, 'FEED');
                              } else {
                                setState(() => _tabIndex = i);
                              }
                            },
                            child: AnimatedScale(
                              scale: selected ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item.$1,
                                    size: 24,
                                    color: selected ? activeColor : inactiveColor,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.$2,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                      color: selected ? activeColor : inactiveColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
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
    final currentBaby = babyState.currentBaby;
    final dark = AppTheme.isDark(context);

    Widget bodyContent;
    if (_tabIndex == 2) {
      bodyContent = _buildStatsTab(currentBaby, entryState, s);
    } else if (_tabIndex == 3) {
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
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBabyScreen())),
                    icon: const Icon(Icons.add),
                    label: Text(s.addBaby),
                  ),
                ],
              ),
            )
          : _buildDashboard(currentBaby, entryState, s);
    }

    return Scaffold(
      backgroundColor: dark ? AppTheme.bgDark : const Color(0xFFFAF7F2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_tabIndex == 0 || _tabIndex == 2) _buildHeader(currentBaby, s, localeState),
            Expanded(child: bodyContent),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(currentBaby, s),
    );
  }
}
