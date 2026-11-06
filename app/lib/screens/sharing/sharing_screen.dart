import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../models/baby.dart';
import '../../state/baby_state.dart';
import '../../state/channel_state.dart';
import '../../state/locale_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_alarm.dart';
import '../../widgets/baby_avatar.dart';
import '../reminders/reminders_screen.dart';

class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final _contactController = TextEditingController();
  String _selectedRole = 'CAREGIVER';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final baby = context.read<BabyState>().currentBaby;
      if (baby != null) {
        context.read<ReminderState>().loadForBaby(baby.id);
        context.read<BabyState>().loadBabyDetails();
        context.read<BabyState>().loadReceivedInvites();
      }
    });
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite({String? directInput, String? directRole}) async {
    final s = context.read<LocaleState>().strings;
    final babyState = context.read<BabyState>();
    final channels = context.read<ChannelState>();

    final input = directInput ?? _contactController.text.trim();
    final role = directRole ?? _selectedRole;
    if (input.isEmpty) return;

    final isEmail = input.contains('@');
    final email = isEmail ? input : null;
    final phone = !isEmail ? input : null;

    setState(() => _isSending = true);
    final res = await babyState.inviteMember(
      email: email,
      phone: phone,
      role: role,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (res != null) {
        _contactController.clear();
        await babyState.loadBabyDetails();

        final userExists = res['userExists'] == true || res['memberAdded'] == true;
        final emailSent = res['emailSent'] == true;
        final inviteLink = (res['inviteLink'] as String?) ?? 'https://baby-daily-api.vercel.app';
        final waUrl = res['whatsappUrl'] as String?;
        final tgUrl = res['telegramUrl'] as String?;
        final babyName = babyState.currentBaby?.name ?? 'Baby';

        if (!emailSent && email != null && email.isNotEmpty) {
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
          if (userExists) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.mint,
                content: Text(s.memberAddedDirectly),
              ),
            );
          } else {
            _showInviteSuccessDialog(
              inviteLink: inviteLink,
              emailSent: true,
              whatsappUrl: waUrl,
              telegramUrl: tgUrl,
              channels: channels,
              strings: s,
            );
          }
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
  }

  void _showInviteModal(AppStrings s, BabyModel currentBaby) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final ink = AppTheme.ink(ctx);

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.card(ctx),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.group_add_rounded, color: Color(0xFF7C3AED), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.inviteNew,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
                            ),
                            Text(
                              s.shareSubtitle,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _contactController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: ink),
                    decoration: InputDecoration(
                      labelText: s.email,
                      hintText: 'partner@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '${s.roleLabel}:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ink),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: Text(s.caregiverLabel),
                        selected: _selectedRole == 'CAREGIVER',
                        selectedColor: AppTheme.primaryLight,
                        onSelected: (val) {
                          if (val) setModalState(() => _selectedRole = 'CAREGIVER');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(s.viewerLabel),
                        selected: _selectedRole == 'VIEWER',
                        selectedColor: AppTheme.primaryLight,
                        onSelected: (val) {
                          if (val) setModalState(() => _selectedRole = 'VIEWER');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF312E81),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSending
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _sendInvite();
                            },
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        s.sendInvite,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInviteSuccessDialog({
    required String? inviteLink,
    required bool emailSent,
    required String? whatsappUrl,
    required String? telegramUrl,
    required ChannelState channels,
    required AppStrings strings,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ink = AppTheme.ink(ctx);
        final card = AppTheme.card(ctx);
        final isDark = AppTheme.isDark(ctx);

        return AlertDialog(
          backgroundColor: card,
          title: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.inviteSentSuccess,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emailSent ? strings.emailSentNice : strings.emailNotSentWarn,
                style: TextStyle(
                  fontSize: 13,
                  color: emailSent ? AppTheme.mint : AppTheme.textMuted,
                  fontWeight: emailSent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (inviteLink != null && inviteLink.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  strings.isHe ? 'קישור ישיר לכניסה והצטרפות:' : 'Direct link to enter & join:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ink),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF302E48) : const Color(0xFFF1F3F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          inviteLink,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: ink),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.mint,
                              content: Text(strings.isHe ? 'הקישור הועתק!' : 'Link copied to clipboard!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (channels.whatsapp && whatsappUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat, size: 18),
                    label: Text(strings.shareWhatsApp),
                    onPressed: () => launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (channels.telegram && telegramUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(strings.shareTelegram),
                    onPressed: () => launchUrl(Uri.parse(telegramUrl), mode: LaunchMode.externalApplication),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(strings.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRemoveMember(BabyMemberModel m, AppStrings s) async {
    final babyState = context.read<BabyState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmRemoveMemberTitle),
        content: Text(
          s.isHe
              ? 'האם להסיר את ${m.name} מהמעקב? הם לא יקבלו יותר התראות ולא יוכלו לצפות בשגרה.'
              : 'Are you sure you want to remove ${m.name}? They will no longer receive routine alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await babyState.removeMember(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.memberRemovedSuccess),
            backgroundColor: AppTheme.mint,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Top Circle Banner (Exact Match to Screenshot 4)
  // ---------------------------------------------------------------------------

  Widget _buildCircleBanner(BabyModel baby, int memberCount, AppStrings s) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2648) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF4C3D77) : const Color(0xFFBBF7D0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          BabyAvatar(name: baby.name, colorHex: baby.avatarColor, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isHe ? 'המעגל של ${baby.name}' : '${baby.name}\'s Circle',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.isHe
                          ? 'מסונכרן בזמן אמת • $memberCount מטפלים'
                          : 'All synced • $memberCount caregivers active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Horizontal Caregiver Team Row (Exact Match to Screenshot 4)
  // ---------------------------------------------------------------------------

  Widget _buildCaregiverTeamRow(BabyState babyState, AppStrings s, BabyModel currentBaby) {
    final members = babyState.members;
    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              (s.isHe ? 'צוות המטפלים' : 'CAREGIVER TEAM').toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              '${members.length} members',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (ctx, index) {
              if (index == members.length) {
                // Add Caregiver button
                return InkWell(
                  onTap: () => _showInviteModal(s, currentBaby),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 96,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF232138) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.defaultPrimary.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add_rounded, color: AppTheme.defaultPrimary, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.isHe ? '+ הוסף' : '+ Add',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.defaultPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final m = members[index];
              final isOwner = m.role == 'OWNER';
              final isCaregiver = m.role == 'CAREGIVER';

              Color badgeBg = isOwner
                  ? const Color(0xFFEDE9FE)
                  : (isCaregiver ? const Color(0xFFE6F4EA) : const Color(0xFFE0F2FE));
              Color badgeColor = isOwner
                  ? const Color(0xFF7C3AED)
                  : (isCaregiver ? const Color(0xFF137333) : const Color(0xFF0284C7));
              String badgeText = isOwner
                  ? (s.isHe ? 'הורה' : 'Owner')
                  : (isCaregiver ? (s.isHe ? 'מטפל/ת' : 'Caregiver') : (s.isHe ? 'צופה' : 'Viewer'));

              return Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2648) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4C3D77) : const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: badgeBg,
                          child: Text(
                            m.name.isNotEmpty ? m.name[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Active Reminders Section (Exact Match to Screenshot 4)
  // ---------------------------------------------------------------------------

  Widget _buildActiveRemindersSection(BabyModel baby, AppStrings s) {
    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              (s.isHe ? 'תזכורות פעילות' : 'ACTIVE REMINDERS').toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppTheme.textMuted,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RemindersScreen()),
                );
              },
              child: Text(
                s.isHe ? 'ניהול תזכורות' : 'Manage',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.defaultPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Reminder Card 1: Feed Reminder (Tap to set Phone Clock Alarm!)
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final target = await PhoneAlarm.setAlarmAfter(
              duration: const Duration(minutes: 45),
              message: s.isHe ? '🍼 האכלה הבאה - ${baby.name}' : '🍼 Next Feeding - ${baby.name}',
            );
            if (mounted) {
              final formatted = '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.mint,
                  content: Text('${s.alarmSetSuccess} ($formatted)'),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2648) : const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF4C3D77) : const Color(0xFFDDD6FE),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🍼', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.isHe ? 'האכלה הבאה (לחץ לכיוון שעון מעורר)' : 'Next Feeding (Tap to set Clock Alarm)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.isHe
                            ? 'בעוד כ-45 דקות (התראה בשעון הנייד)'
                            : 'In approx. 45 mins (sets phone clock alarm)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D28D9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.alarm_add_rounded, color: Color(0xFF7C3AED), size: 24),
              ],
            ),
          ),
        ),

        // Reminder Card 2: Vitamin D Drops
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await PhoneAlarm.setAlarm(
              hour: 13,
              minute: 0,
              message: s.isHe ? '💊 טיפות ויטמין D - ${baby.name}' : '💊 Vitamin D Drops - ${baby.name}',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.mint,
                  content: Text('${s.alarmSetSuccess} (13:00)'),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF332A24) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF5A4435) : const Color(0xFFFDE68A),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('💊', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.isHe ? 'טיפות ויטמין D' : 'Vitamin D Drops',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.isHe ? 'מדי יום בשעה 13:00 (לחץ לשעון מעורר)' : 'Daily at 01:00 PM (Tap for Clock Alarm)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.alarm_rounded, color: Color(0xFFD97706), size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build Main Screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final babyState = context.watch<BabyState>();
    final channels = context.watch<ChannelState>();
    final currentBaby = babyState.currentBaby;

    final cardBg = AppTheme.card(context);
    final line = AppTheme.line(context);
    final ink = AppTheme.ink(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.sharingTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: currentBaby == null
          ? Center(child: Text(s.noBabiesYet))
          : RefreshIndicator(
              onRefresh: () async {
                await babyState.loadBabyDetails();
                await babyState.loadReceivedInvites();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Circle Banner (Screenshot 4)
                    _buildCircleBanner(currentBaby, babyState.members.length, s),
                    const SizedBox(height: 22),

                    // Horizontal Caregiver Team (Screenshot 4)
                    _buildCaregiverTeamRow(babyState, s, currentBaby),
                    const SizedBox(height: 24),

                    // Active Reminders Section (Screenshot 4)
                    _buildActiveRemindersSection(currentBaby, s),
                    const SizedBox(height: 24),

                    // Big Team Action Button: "Invite via Link or WhatsApp" (Screenshot 4)
                    if (currentBaby.isOwner) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF312E81),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 3,
                          ),
                          onPressed: () => _showInviteModal(s, currentBaby),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.mark_email_read_outlined, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                s.inviteNew,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Received invitations banner
                    if (babyState.receivedInvites.isNotEmpty) ...[
                      Text(
                        s.receivedInvites,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink),
                      ),
                      const SizedBox(height: 10),
                      ...babyState.receivedInvites.map((inv) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.defaultPrimary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    BabyAvatar(
                                      name: inv.babyName ?? 'Baby',
                                      colorHex: inv.babyAvatarColor,
                                      size: 36,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv.babyName ?? 'Baby',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ink),
                                          ),
                                          Text(
                                            '${s.invitedBy} ${inv.invitedByName ?? "Family"}',
                                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => babyState.declineInvitation(inv.id),
                                      child: Text(s.decline),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => babyState.acceptInvitation(inv.id),
                                      child: Text(s.accept),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],

                    // All Current Members Detailed List
                    Text(
                      s.currentMembers,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink),
                    ),
                    const SizedBox(height: 10),
                    ...babyState.members.map((m) {
                      final isOwner = m.role == 'OWNER';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: line),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isOwner ? const Color(0xFFEDE9FE) : const Color(0xFFE6F4EA),
                              foregroundColor: isOwner ? const Color(0xFF7C3AED) : const Color(0xFF137333),
                              child: Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : 'U'),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ink),
                                  ),
                                  Text(
                                    m.email.isNotEmpty ? m.email : (m.phone ?? ''),
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOwner
                                    ? const Color(0xFFEDE9FE)
                                    : (isDark ? const Color(0xFF302E48) : const Color(0xFFF1F3F6)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isOwner
                                    ? s.roleOwner
                                    : m.role == 'CAREGIVER'
                                        ? s.caregiverLabel
                                        : s.viewerLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isOwner ? const Color(0xFF7C3AED) : AppTheme.textMuted,
                                ),
                              ),
                            ),
                            if (!isOwner && babyState.currentBaby?.role == 'OWNER') ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                                tooltip: s.delete,
                                onPressed: () => _confirmRemoveMember(m, s),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    // Pending Invites
                    if (babyState.pendingInvites.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        s.pendingInvites,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink),
                      ),
                      const SizedBox(height: 10),
                      ...babyState.pendingInvites.map((inv) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: line),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_empty, size: 20, color: AppTheme.sun),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.email ?? inv.phone ?? (s.isHe ? 'מוזמן/ת' : 'Invitee'),
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ink),
                                      ),
                                      Text(
                                        '${s.roleLabel}: ${inv.role == "CAREGIVER" ? s.caregiverLabel : s.viewerLabel}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                if (channels.whatsapp && inv.phone != null)
                                  IconButton(
                                    icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                                    tooltip: s.shareWhatsApp,
                                    onPressed: () {
                                      final msg = s.isHe
                                          ? 'היי! הוזמנת להצטרף למעקב אחרי ${currentBaby.name} ב-BabyDaily! הירשם/י כאן: https://baby-daily-api.vercel.app/privacy'
                                          : 'Hi! You have been invited to follow ${currentBaby.name} on BabyDaily! Register here: https://baby-daily-api.vercel.app/privacy';
                                      final url = 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
                                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 18, color: AppTheme.danger),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(s.revoke),
                                        content: Text(s.isHe ? 'האם לבטל הזמנה זו?' : 'Revoke this invitation?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text(s.revoke, style: const TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true && context.mounted) {
                                      await babyState.revokeInvitation(inv.id);
                                    }
                                  },
                                  tooltip: s.revoke,
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
