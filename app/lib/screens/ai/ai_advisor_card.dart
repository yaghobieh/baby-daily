import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../state/auth_state.dart';
import 'ai_chat_sheet.dart';
import 'baby_stats_sheet.dart';
import 'premium_sheet.dart';

class AiAdvisorCard extends StatefulWidget {
  final String babyId;
  final String babyName;

  const AiAdvisorCard({super.key, required this.babyId, required this.babyName});

  @override
  State<AiAdvisorCard> createState() => _AiAdvisorCardState();
}

class _AiAdvisorCardState extends State<AiAdvisorCard> {
  Map<String, dynamic>? _insights;
  bool _isSendingSummary = false;

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  @override
  void didUpdateWidget(covariant AiAdvisorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.babyId != widget.babyId) {
      _fetchInsights();
    }
  }

  Future<void> _fetchInsights() async {
    final api = context.read<ApiClient>();
    try {
      final res = await api.get('/babies/${widget.babyId}/ai/insights') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _insights = res;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendDailySummary() async {
    setState(() => _isSendingSummary = true);
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final isHe = (auth.user?.locale ?? 'en') == 'he';
    final messenger = ScaffoldMessenger.of(context);

    try {
      final res = await api.post('/babies/${widget.babyId}/ai/daily-summary', {
        'sendToEmail': true,
        'sendNotification': true,
        'locale': auth.user?.locale ?? 'en',
      });
      final emailSent = res['emailSent'] as bool? ?? false;

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF8C7AE6),
            content: Text(
              isHe
                  ? '✨ הסיכום היומי נוצר ונשלח בהתראה${emailSent ? ' ולמייל' : ''}!'
                  : '✨ AI Summary sent to notifications${emailSent ? ' and email' : ''}!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isHe = (auth.user?.locale ?? 'en') == 'he';
    final user = auth.user;
    final isPremium = user?.isPremium ?? false;

    final suggestions = (_insights?['suggestions'] as List<dynamic>?) ?? [];
    final firstSuggestion = suggestions.isNotEmpty ? suggestions.first as Map<String, dynamic> : null;

    final title = firstSuggestion?['title'] as String? ??
        (isHe ? 'יועץ שגרה חכם מבוסס AI' : 'Smart AI Routine Advisor');
    final body = firstSuggestion?['body'] as String? ??
        (isHe
            ? 'קבל/י תחזיות חכמות לחלון השינה הבא, תזכורות האכלה וסיכום יומי.'
            : 'Get sweet-spot nap predictions, feed interval guidance, and daily digests.');
    final icon = firstSuggestion?['icon'] as String? ?? '✨';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7F5), Color(0xFFF7F5FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3DB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A7A).withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isHe ? 'AI LIVE ADVISOR' : 'AI LIVE ADVISOR',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Color(0xFFFF7A7A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8C7AE6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _fetchInsights,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPillButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: isHe ? 'שאל/י AI' : 'Ask AI',
                color: const Color(0xFFFF7A7A),
                bgColor: const Color(0xFFFFF0F0),
                onTap: () => AiChatSheet.show(context, widget.babyId, widget.babyName),
              ),
              _buildPillButton(
                icon: Icons.bar_chart_rounded,
                label: isHe ? 'סטטיסטיקות 7 ימים' : '7-Day Stats',
                color: const Color(0xFF8C7AE6),
                bgColor: const Color(0xFFF5F3FC),
                onTap: () => BabyStatsSheet.show(context, widget.babyId, widget.babyName),
              ),
              _buildPillButton(
                icon: Icons.mark_email_read_outlined,
                label: _isSendingSummary
                    ? (isHe ? 'שולח...' : 'Sending...')
                    : (isHe ? 'סיכום למייל' : 'Daily Email'),
                color: const Color(0xFF48C78E),
                bgColor: const Color(0xFFEFFBF5),
                onTap: _isSendingSummary ? null : _sendDailySummary,
              ),
              if (!isPremium)
                _buildPillButton(
                  icon: Icons.star_rounded,
                  label: isHe ? 'פרימיום (\$4.99)' : 'Premium (\$4.99)',
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                  onTap: () => PremiumSheet.show(context),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
