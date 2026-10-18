import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../models/baby.dart';
import '../../state/baby_state.dart';
import '../../state/channel_state.dart';
import '../../state/locale_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/baby_avatar.dart';

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
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final s = context.read<LocaleState>().strings;
    final babyState = context.read<BabyState>();
    final channels = context.read<ChannelState>();

    final input = _contactController.text.trim();
    if (input.isEmpty) return;

    final isEmail = input.contains('@');
    final email = isEmail ? input : null;
    final phone = !isEmail ? input : null;

    setState(() => _isSending = true);
    final res = await babyState.inviteMember(
      email: email,
      phone: phone,
      role: _selectedRole,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (res != null) {
        _contactController.clear();
        await babyState.loadBabyDetails();

        final userExists = res['userExists'] == true || res['memberAdded'] == true;
        final emailSent = res['emailSent'] == true;
        final inviteLink = res['inviteLink'] as String?;
        final waUrl = res['whatsappUrl'] as String?;
        final tgUrl = res['telegramUrl'] as String?;

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
              emailSent: emailSent,
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
        title: Text(s.sharingTitle),
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
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
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

                    // Invite Box
                    if (currentBaby.isOwner) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('💌', style: TextStyle(fontSize: 18)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.inviteNew,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.shareSubtitle,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _contactController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: ink),
                              decoration: InputDecoration(
                                labelText: s.emailOrPhone,
                                hintText: 'partner@example.com / 0501234567',
                                prefixIcon: const Icon(Icons.alternate_email),
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
                                    if (val) setState(() => _selectedRole = 'CAREGIVER');
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(s.viewerLabel),
                                  selected: _selectedRole == 'VIEWER',
                                  selectedColor: AppTheme.primaryLight,
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedRole = 'VIEWER');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSending ? null : _sendInvite,
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: Text(s.sendInvite),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Current Followers / Members
                    Text(
                      s.currentMembers,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink),
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
                              backgroundColor: isOwner ? AppTheme.primaryLight : AppTheme.skyLight,
                              foregroundColor: isOwner ? AppTheme.primary : AppTheme.sky,
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
                                    ? AppTheme.primaryLight
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
                                  fontWeight: FontWeight.w600,
                                  color: isOwner ? AppTheme.primaryDark : AppTheme.textMuted,
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink),
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
                                          ? 'היי! הוזמנת להצטרף למעקב אחרי ${currentBaby.name} ב-BabyDaily! הירשם/י כאן: https://baby-daily.vercel.app/?invite=1'
                                          : 'Hi! You have been invited to follow ${currentBaby.name} on BabyDaily! Register here: https://baby-daily.vercel.app/?invite=1';
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
