import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/baby.dart';
import '../../state/baby_state.dart';
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

    final input = _contactController.text.trim();
    if (input.isEmpty) return;

    final isEmail = input.contains('@');
    final email = isEmail ? input : null;
    final phone = !isEmail ? input : null;

    setState(() => _isSending = true);
    final success = await babyState.inviteMember(
      email: email,
      phone: phone,
      role: _selectedRole,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _contactController.clear();
        await babyState.loadBabyDetails();
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
          SnackBar(content: Text(babyState.error ?? s.errorOccurred)),
        );
      }
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final babyState = context.watch<BabyState>();
    final currentBaby = babyState.currentBaby;

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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Received invitations banner
                    if (babyState.receivedInvites.isNotEmpty) ...[
                      Text(
                        s.receivedInvites,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            '${s.invitedBy} ${inv.invitedByName ?? 'Family'}',
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.divider),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              decoration: InputDecoration(
                                labelText: s.emailOrPhone,
                                hintText: 'partner@example.com or +972 50 123 4567',
                                prefixIcon: const Icon(Icons.share_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'CAREGIVER',
                                  label: Text(s.roleCaregiver),
                                ),
                                ButtonSegment(
                                  value: 'VIEWER',
                                  label: Text(s.roleViewer),
                                ),
                              ],
                              selected: {_selectedRole},
                              onSelectionChanged: (set) => setState(() => _selectedRole = set.first),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSending ? null : _sendInvite,
                                child: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(s.addMemberAndNotify),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Current Followers
                    Text(
                      s.currentMembers,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...babyState.members.map((m) {
                      final isOwner = m.role == 'OWNER';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                                color: isOwner ? AppTheme.primaryLight : const Color(0xFFF1F3F6),
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
                                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...babyState.pendingInvites.map((inv) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_empty, size: 20, color: Colors.amber),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.email ?? inv.phone ?? (s.isHe ? 'מוזמן/ת' : 'Invitee'),
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      Text(
                                        '${s.roleLabel}: ${inv.role == 'CAREGIVER' ? s.caregiverLabel : s.viewerLabel}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(s.revoke),
                                        content: Text(s.isHe ? 'האם לבטל הזמנה זו?' : 'Revoke this invitation?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
