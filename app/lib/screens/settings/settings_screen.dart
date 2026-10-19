import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../state/auth_state.dart';
import '../../state/baby_state.dart';
import '../../state/channel_state.dart';
import '../../state/locale_state.dart';
import '../../state/notification_state.dart';
import '../../state/theme_state.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _testPhoneController = TextEditingController();
  bool _notifyEnabled = true;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthState>().user;
    if (user?.phone != null) {
      _testPhoneController.text = user!.phone!;
    }
    _loadBabySettings();
  }

  Future<void> _loadBabySettings() async {
    final baby = context.read<BabyState>().currentBaby;
    final api = context.read<ApiClient>();
    if (baby == null) return;
    try {
      final res = await api.get('/babies/${baby.id}/settings') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _notifyEnabled = res['notifyEnabled'] as bool? ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _updateBabySettings(bool enabled) async {
    final baby = context.read<BabyState>().currentBaby;
    final api = context.read<ApiClient>();
    if (baby == null) return;

    setState(() => _notifyEnabled = enabled);
    try {
      await api.put('/babies/${baby.id}/settings', {
        'notifyEnabled': enabled,
        'notifyTypes': ['FEED', 'SLEEP', 'DIAPER', 'GROWTH', 'MEDICINE', 'NOTE'],
        'quietStart': null,
        'quietEnd': null,
      });
    } catch (_) {}
  }

  Future<void> _sendTestAlert() async {
    final s = context.read<LocaleState>().strings;
    final notifState = context.read<NotificationState>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSendingTest = true);
    final phone = _testPhoneController.text.trim();

    final res = await notifState.sendTestNotification(
      phone: phone.isNotEmpty ? phone : null,
      title: s.isHe ? '🔔 התראת בדיקה - בייבי דיילי' : '🔔 BabyDaily Test Notification',
      body: s.isHe
          ? 'התראה נשלחה בהצלחה למכשיר שלך בשעה ${TimeOfDay.now().format(context)}!'
          : 'Notification sent successfully at ${TimeOfDay.now().format(context)}!',
    );

    if (mounted) {
      setState(() => _isSendingTest = false);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: res != null ? AppTheme.mint : AppTheme.danger,
          content: Text(res != null ? s.testAlertSentSuccess : s.errorOccurred),
        ),
      );
    }
  }

  Future<void> _sendWhatsAppAlert() async {
    final s = context.read<LocaleState>().strings;
    final phone = _testPhoneController.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = s.isHe
        ? '🍼 *בדיקת התראה מבייבי דיילי* - מערכת ההתראות של בייבי דיילי מחוברת ופעילה.'
        : '🍼 *BabyDaily Notification Test* - BabyDaily notification system is active.';
    final cleanPhone = phone.startsWith('+') ? phone.substring(1) : (phone.startsWith('0') ? '972${phone.substring(1)}' : phone);
    final url = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}'
        : 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _sendTelegramAlert() async {
    final s = context.read<LocaleState>().strings;
    final msg = s.isHe
        ? '🍼 *בדיקת התראה מבייבי דיילי* - מערכת ההתראות של בייבי דיילי מחוברת ופעילה.'
        : '🍼 *BabyDaily Notification Test* - BabyDaily notification system is active.';
    final url = 'https://t.me/share/url?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _sendAllChannelsAlert() async {
    final s = context.read<LocaleState>().strings;
    final channels = context.read<ChannelState>();
    final messenger = ScaffoldMessenger.of(context);
    await _sendTestAlert();
    if (channels.whatsapp) {
      await _sendWhatsAppAlert();
    } else if (channels.telegram) {
      await _sendTelegramAlert();
    }
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primary,
          content: Text(s.shareSuccess),
        ),
      );
    }
  }

  @override
  void dispose() {
    _testPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final localeState = context.watch<LocaleState>();
    final themeState = context.watch<ThemeState>();
    final channels = context.watch<ChannelState>();
    final auth = context.watch<AuthState>();
    final user = auth.user;

    final cardBg = AppTheme.card(context);
    final line = AppTheme.line(context);
    final ink = AppTheme.ink(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Profile Card
          if (user != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: line),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: themeState.primaryColor.withValues(alpha: 0.15),
                    foregroundColor: themeState.primaryColor,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ink),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        if (user.phone != null)
                          Text(
                            user.phone!,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          // Appearance Mode (Light / Dark / System)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.brightness_medium_rounded, color: AppTheme.defaultPrimary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.appearance,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(s.themeModeLight, style: const TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(s.themeModeDark, style: const TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(s.themeModeAuto, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {themeState.mode},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) themeState.setMode(set.first);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Application Theme Colors Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: themeState.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.appThemeColor,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.appThemeSubtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ThemeState.availableColors.map((hex) {
                    final clean = hex.replaceAll('#', '');
                    final color = Color(int.parse('FF$clean', radix: 16));
                    final isSelected = themeState.colorHex.toUpperCase() == hex.toUpperCase();

                    return GestureDetector(
                      onTap: () => themeState.setColorHex(hex),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? ink : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Messaging Channels (WhatsApp / Telegram)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.forum_outlined, color: AppTheme.lavender, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.messagingChannels,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.channelsSubtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    child: Icon(Icons.chat, size: 16),
                  ),
                  title: Text(s.enableWhatsApp, style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                  subtitle: Text(s.enableWhatsAppSubtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  value: channels.whatsapp,
                  activeTrackColor: themeState.primaryColor,
                  onChanged: (v) => channels.setWhatsapp(v),
                ),
                const Divider(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF0088CC),
                    foregroundColor: Colors.white,
                    child: Icon(Icons.send, size: 16),
                  ),
                  title: Text(s.enableTelegram, style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                  subtitle: Text(s.enableTelegramSubtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  value: channels.telegram,
                  activeTrackColor: themeState.primaryColor,
                  onChanged: (v) => channels.setTelegram(v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Instant Test Alert Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: AppTheme.mint, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      s.testNotificationTitle,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ink),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.testNotificationSubtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _testPhoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: ink),
                  decoration: InputDecoration(
                    labelText: s.enterTestPhone,
                    hintText: '+972 50 123 4567',
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeState.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSendingTest ? null : _sendTestAlert,
                    icon: _isSendingTest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.notifications_active),
                    label: Text(s.sendTestAlert),
                  ),
                ),
                if (channels.whatsapp || channels.telegram) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (channels.whatsapp)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _sendWhatsAppAlert,
                            icon: const Icon(Icons.chat, size: 18),
                            label: Text(s.shareWhatsApp),
                          ),
                        ),
                      if (channels.whatsapp && channels.telegram) const SizedBox(width: 8),
                      if (channels.telegram)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _sendTelegramAlert,
                            icon: const Icon(Icons.send, size: 18),
                            label: Text(s.shareTelegram),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeState.primaryColor,
                        side: BorderSide(color: themeState.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _sendAllChannelsAlert,
                      icon: const Icon(Icons.all_inclusive, size: 18),
                      label: Text(s.shareAll),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Language Switch
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line),
            ),
            child: ListTile(
              leading: Icon(Icons.language, color: themeState.primaryColor),
              title: Text(s.language, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
              trailing: DropdownButton<String>(
                value: localeState.locale,
                underline: const SizedBox(),
                dropdownColor: cardBg,
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'he', child: Text('עברית (Hebrew)')),
                ],
                onChanged: (lang) {
                  if (lang != null) localeState.setLocale(lang);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Notifications Switch
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line),
            ),
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined, color: AppTheme.lavender),
              title: Text(s.enablePush, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
              subtitle: Text(
                s.enablePushSubtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              value: _notifyEnabled,
              activeTrackColor: themeState.primaryColor,
              onChanged: _updateBabySettings,
            ),
          ),

          const SizedBox(height: 28),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.danger,
              side: const BorderSide(color: AppTheme.danger),
            ),
            icon: const Icon(Icons.logout),
            label: Text(s.logout),
            onPressed: () => auth.logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
