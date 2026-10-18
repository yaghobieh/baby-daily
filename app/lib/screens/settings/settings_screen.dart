import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../state/auth_state.dart';
import '../../state/baby_state.dart';
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
  late final TextEditingController _urlController;
  final TextEditingController _testPhoneController = TextEditingController();
  bool _notifyEnabled = true;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    final user = context.read<AuthState>().user;
    _urlController = TextEditingController(text: api.baseUrl);
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
          ? 'התראה נשלחה בהצלחה למספר $phone בשעה ${TimeOfDay.now().format(context)}!'
          : 'Notification sent successfully to ${phone.isNotEmpty ? phone : "your device"} at ${TimeOfDay.now().format(context)}!',
    );

    if (mounted) {
      setState(() => _isSendingTest = false);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: res != null ? AppTheme.mint : Colors.redAccent,
          content: Text(res != null ? s.testAlertSentSuccess : s.errorOccurred),
        ),
      );
    }
  }

  Future<void> _sendWhatsAppAlert() async {
    final s = context.read<LocaleState>().strings;
    final phone = _testPhoneController.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = s.isHe
        ? '🍼 *בדיקת התראה מבייבי דיילי*\nשלום! מערכת ההתראות של בייבי דיילי מחוברת ופעילה.'
        : '🍼 *BabyDaily Notification Test*\nHello! The BabyDaily notification system is active.';
    final cleanPhone = phone.startsWith('+') ? phone.substring(1) : (phone.startsWith('0') ? '972${phone.substring(1)}' : phone);
    final url = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}'
        : 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _sendTelegramAlert() async {
    final s = context.read<LocaleState>().strings;
    final msg = s.isHe
        ? '🍼 *בדיקת התראה מבייבי דיילי*\nשלום! מערכת ההתראות של בייבי דיילי מחוברת ופעילה.'
        : '🍼 *BabyDaily Notification Test*\nHello! The BabyDaily notification system is active.';
    final url = 'https://t.me/share/url?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _sendAllChannelsAlert() async {
    final s = context.read<LocaleState>().strings;
    final messenger = ScaffoldMessenger.of(context);
    await _sendTestAlert();
    await _sendWhatsAppAlert();
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
    _urlController.dispose();
    _testPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final localeState = context.watch<LocaleState>();
    final themeState = context.watch<ThemeState>();
    final auth = context.watch<AuthState>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card
          if (user != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

          const SizedBox(height: 24),

          // Application Theme Colors Section (Changes whole app colors!)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeState.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.appThemeColor,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                    final isSelected = themeState.colorHex == hex;

                    return InkWell(
                      onTap: () => themeState.setColorHex(hex),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black87 : Colors.white,
                            width: isSelected ? 3.5 : 2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 22)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Send Test Notification Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.send_to_mobile_outlined, color: AppTheme.mint, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.testNotificationTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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
                  decoration: InputDecoration(
                    labelText: s.enterTestPhone,
                    hintText: '+972 50 123 4567',
                    prefixIcon: const Icon(Icons.phone_iphone),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mint,
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
                const SizedBox(height: 10),
                Row(
                  children: [
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
                    const SizedBox(width: 8),
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
            ),
          ),

          const SizedBox(height: 18),

          // Language Switch
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: ListTile(
              leading: Icon(Icons.language, color: themeState.primaryColor),
              title: Text(s.language),
              trailing: DropdownButton<String>(
                value: localeState.locale,
                underline: const SizedBox(),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined, color: AppTheme.lavender),
              title: Text(s.enablePush),
              subtitle: Text(
                s.enablePushSubtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              value: _notifyEnabled,
              activeTrackColor: themeState.primaryColor,
              onChanged: _updateBabySettings,
            ),
          ),

          const SizedBox(height: 12),

          // Server URL setting
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dns_outlined, color: AppTheme.sky, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      s.serverUrl,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: 'http://localhost:5050',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: () async {
                        final api = context.read<ApiClient>();
                        final messenger = ScaffoldMessenger.of(context);
                        await api.setBaseUrl(_urlController.text.trim());
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(s.serverUrlUpdated)),
                          );
                        }
                      },
                      child: Text(s.save),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
            icon: const Icon(Icons.logout),
            label: Text(s.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}
