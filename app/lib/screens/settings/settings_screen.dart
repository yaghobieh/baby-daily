import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../l10n/app_strings.dart';
import '../../state/auth_state.dart';
import '../../state/baby_state.dart';
import '../../state/locale_state.dart';
import '../../state/notification_state.dart';
import '../../state/theme_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_alarm.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _inviteEmailController = TextEditingController();
  String _inviteRole = 'CAREGIVER';
  bool _notifyEnabled = true;
  bool _isSendingTest = false;
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
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
    final s = context.read<LocaleState>().strings;
    setState(() => _notifyEnabled = enabled);

    if (enabled) {
      await PhoneAlarm.showNotification(
        title: '🔔 ${s.appName}',
        body: s.enablePushSubtitle,
      );
    }

    if (baby == null) return;
    try {
      await api.put('/babies/${baby.id}/settings', {
        'notifyEnabled': enabled,
        'notifyTypes': ['FEED', 'SLEEP', 'DIAPER', 'GROWTH', 'MEDICINE', 'NOTE'],
        'quietStart': null,
        'quietEnd': null,
      });
    } catch (_) {}
  }

  Future<void> _sendPhoneNotificationTest() async {
    final s = context.read<LocaleState>().strings;
    final notifState = context.read<NotificationState>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSendingTest = true);
    final title = s.tr(
      en: '🔔 BabyDaily Phone Alert',
      he: '🔔 התראת בייבי דיילי למכשיר',
      es: '🔔 Alerta de BabyDaily',
      ru: '🔔 Уведомление BabyDaily',
    );
    final body = s.tr(
      en: 'Notifications are active on this phone (${TimeOfDay.now().format(context)})',
      he: 'ההתראות פעילות במכשיר זה (${TimeOfDay.now().format(context)})',
      es: 'Las notificaciones están activas en este teléfono',
      ru: 'Уведомления активны на этом телефоне',
    );

    await PhoneAlarm.showNotification(title: title, body: body);
    await notifState.sendTestNotification(title: title, body: body);

    if (mounted) {
      setState(() => _isSendingTest = false);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.mint,
          content: Text(s.testAlertSentSuccess),
        ),
      );
    }
  }

  Future<void> _showQuickNextMealAlarmSheet(AppStrings s) async {
    final baby = context.read<BabyState>().currentBaby;
    final babyName = baby?.name ?? 'Baby';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardBg = AppTheme.card(ctx);
        final ink = AppTheme.ink(ctx);
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.alarm_on_rounded, color: AppTheme.defaultPrimary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.setPhoneClockAlarm,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.remindersHelp,
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [2, 3, 4].map((hrs) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: AppTheme.primaryDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.access_alarm, size: 18),
                    label: Text(
                      s.tr(
                        en: 'In $hrs hours',
                        he: 'בעוד $hrs שעות',
                        es: 'En $hrs horas',
                        ru: 'Через $hrs ч.',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final label = s.tr(
                        en: '🍼 BabyDaily: Next Meal ($babyName)',
                        he: '🍼 בייבי דיילי: האכלה הבאה ($babyName)',
                        es: '🍼 BabyDaily: Próxima comida ($babyName)',
                        ru: '🍼 BabyDaily: Кормление ($babyName)',
                      );
                      final target = await PhoneAlarm.setAlarmAfter(
                        duration: Duration(hours: hrs),
                        message: label,
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
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    s.tr(
                      en: 'Pick Exact Alarm Time on Clock',
                      he: 'בחר שעה מדויקת בשעון המעורר',
                      es: 'Elegir hora exacta en el reloj',
                      ru: 'Выбрать точное время будильника',
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 3))),
                    );
                    if (picked != null) {
                      final label = s.tr(
                        en: '🍼 BabyDaily: Next Meal ($babyName)',
                        he: '🍼 בייבי דיילי: האכלה הבאה ($babyName)',
                        es: '🍼 BabyDaily: Próxima comida ($babyName)',
                        ru: '🍼 BabyDaily: Кормление ($babyName)',
                      );
                      await PhoneAlarm.setAlarm(
                        hour: picked.hour,
                        minute: picked.minute,
                        message: label,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.mint,
                            content: Text(s.alarmSetSuccess),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _inviteNewMemberByEmail() async {
    final s = context.read<LocaleState>().strings;
    final babyState = context.read<BabyState>();
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text(
            s.tr(
              en: 'Please enter a valid email address',
              he: 'אנא הזן/י כתובת אימייל תקינה',
              es: 'Ingresa un correo electrónico válido',
              ru: 'Введите корректный адрес email',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isInviting = true);
    final res = await babyState.inviteMember(
      email: email,
      role: _inviteRole,
    );

    if (!mounted) return;
    setState(() => _isInviting = false);

    if (res != null) {
      _inviteEmailController.clear();
      final emailSent = res['emailSent'] == true;
      final inviteLink = (res['inviteLink'] as String?) ?? 'https://baby-daily-api.vercel.app';
      final babyName = babyState.currentBaby?.name ?? 'Baby';

      if (!emailSent) {
        final subject = Uri.encodeComponent(
          s.tr(
            en: 'Join $babyName on BabyDaily 🍼',
            he: 'הזמנה להצטרף למעקב אחרי $babyName ב-BabyDaily 🍼',
            es: 'Únete a $babyName en BabyDaily 🍼',
            ru: 'Приглашение в BabyDaily ($babyName) 🍼',
          ),
        );
        final body = Uri.encodeComponent(
          s.tr(
            en: 'Hi!\nYou have been invited to follow $babyName on BabyDaily.\nJoin here: $inviteLink',
            he: 'היי!\nהוזמנת להצטרף למעקב אחרי $babyName באפליקציית BabyDaily.\nקישור הצטרפות: $inviteLink',
            es: '¡Hola!\nHas sido invitado a seguir a $babyName en BabyDaily.\nÚnete aquí: $inviteLink',
            ru: 'Привет!\nВас пригласили следить за малышом $babyName в BabyDaily.\nСсылка: $inviteLink',
          ),
        );
        try {
          await launchUrl(Uri.parse('mailto:$email?subject=$subject&body=$body'));
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.mint,
            content: Text(s.memberAddedAndNotified),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text(babyState.error ?? s.errorOccurred),
        ),
      );
    }
  }

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final localeState = context.watch<LocaleState>();
    final themeState = context.watch<ThemeState>();
    final auth = context.watch<AuthState>();
    final babyState = context.watch<BabyState>();
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          // Language Selector Card (Hebrew, English, Spanish, Russian - No Flags)
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
                    Icon(Icons.language, color: themeState.primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.language,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LocaleState.supportedCodes.map((code) {
                    final selected = localeState.locale == code;
                    final label = LocaleState.languageNames[code] ?? code;
                    return ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : ink,
                        ),
                      ),
                      selected: selected,
                      selectedColor: themeState.primaryColor,
                      backgroundColor: cardBg,
                      onSelected: (_) => localeState.setLocale(code),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Current Phone Notification & Phone Clock Alarm Card
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppTheme.lavender),
                  title: Text(s.enablePush, style: TextStyle(color: ink, fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(
                    s.enablePushSubtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  value: _notifyEnabled,
                  activeTrackColor: themeState.primaryColor,
                  onChanged: _updateBabySettings,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeState.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _isSendingTest ? null : _sendPhoneNotificationTest,
                    icon: _isSendingTest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.notifications_active, size: 18),
                    label: Text(s.sendTestAlert),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeState.primaryColor,
                      side: BorderSide(color: themeState.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => _showQuickNextMealAlarmSheet(s),
                    icon: const Icon(Icons.alarm_rounded, size: 18),
                    label: Text(s.setPhoneClockAlarm),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Invite / Join New Member by Email Card
          if (babyState.currentBaby != null)
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
                      const Icon(Icons.mark_email_read_outlined, color: AppTheme.mint, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.inviteNew,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.shareSubtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _inviteEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: ink),
                    decoration: InputDecoration(
                      labelText: s.email,
                      hintText: 'partner@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${s.roleLabel}:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ink),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: Text(s.caregiverLabel),
                        selected: _inviteRole == 'CAREGIVER',
                        selectedColor: AppTheme.primaryLight,
                        onSelected: (v) {
                          if (v) setState(() => _inviteRole = 'CAREGIVER');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(s.viewerLabel),
                        selected: _inviteRole == 'VIEWER',
                        selectedColor: AppTheme.primaryLight,
                        onSelected: (v) {
                          if (v) setState(() => _inviteRole = 'VIEWER');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF312E81),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _isInviting ? null : _inviteNewMemberByEmail,
                      icon: _isInviting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(s.sendInvite),
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
