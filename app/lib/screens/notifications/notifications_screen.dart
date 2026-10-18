import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/locale_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final notifState = context.watch<NotificationState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notificationsCenter),
        actions: [
          if (notifState.notifications.isNotEmpty)
            TextButton(
              onPressed: () => notifState.markAllAsRead(),
              child: Text(s.markAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifState.load(),
        child: notifState.notifications.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔔', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        s.noNotifications,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.notificationsSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifState.notifications.length,
                itemBuilder: (ctx, i) {
                  final n = notifState.notifications[i];
                  final isUnread = !n.isRead;
                  final timeStr = DateFormat.jm().format(n.createdAt.toLocal());

                  return InkWell(
                    onTap: () {
                      if (!n.isRead) notifState.markAsRead(n.id);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUnread
                            ? AppTheme.primaryLight.withValues(alpha: 0.4)
                            : AppTheme.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnread ? AppTheme.primary : AppTheme.line(context),
                          width: isUnread ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isUnread ? AppTheme.primary : const Color(0xFFF1F3F6),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.notifications_outlined,
                              size: 18,
                              color: isUnread ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: TextStyle(
                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.ink(context),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
