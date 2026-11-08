import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../state/auth_state.dart';

class PremiumSheet extends StatefulWidget {
  const PremiumSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PremiumSheet(),
    );
  }

  @override
  State<PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<PremiumSheet> {
  String _selectedPlan = 'YEARLY';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'MONTHLY',
      'title': 'Monthly Care',
      'titleHe': 'חודשי גמיש',
      'price': '\$4.99',
      'period': '/ month',
      'periodHe': '/ חודש',
      'badge': 'Flexible',
      'badgeHe': 'גמיש',
      'desc': 'Full AI assistant, sweet-spot sleep predictions & 7-day routine trends.',
      'descHe': 'עוזר AI מלא, חיזוי חלונות שינה חכמים ודוחות סטטיסטיקה שבועיים.',
    },
    {
      'id': 'YEARLY',
      'title': 'Annual Family Plan',
      'titleHe': 'שנתי משפחתי',
      'price': '\$39.99',
      'period': '/ year (\$3.33/mo)',
      'periodHe': '/ שנה (3.33\$ לחודש)',
      'badge': 'Most Popular • 7-Day Free Trial',
      'badgeHe': 'הכי משתלם • 7 ימי ניסיון חינם',
      'desc': 'Save 33%. Includes full family sharing, unlimited AI guidance & daily email summaries.',
      'descHe': 'חיסכון של 33%. כולל שיתוף מלא לכל המשפחה, שאלות AI ללא הגבלה וסיכום יומי למייל.',
    },
    {
      'id': 'LIFETIME',
      'title': 'Lifetime Family Pass',
      'titleHe': 'מנוי משפחתי לכל החיים',
      'price': '\$69.99',
      'period': 'one-time',
      'periodHe': 'תשלום חד-פעמי',
      'badge': 'Best Value',
      'badgeHe': 'תשלום אחד לתמיד',
      'desc': 'Pay once for all your children forever. Every future AI and analytics feature included.',
      'descHe': 'תשלום אחד לכל הילדים ולכל החיים. כולל כל תכונות ה-AI והדוחות העתידיים.',
    },
  ];

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthState>();
    final s = AppStrings(auth.user?.locale ?? 'en');
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final ok = await auth.updateSubscription(_selectedPlan);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF48C78E),
          content: Text(
            s.isHe
                ? '🎉 שודרגת בהצלחה ל-BabyDaily Premium!'
                : '🎉 Successfully upgraded to BabyDaily Premium!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(auth.error ?? 'Upgrade failed. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isHe = (auth.user?.locale ?? 'en') == 'he';
    final user = auth.user;
    final isPremium = user?.isPremium ?? false;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD5D5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          isHe ? 'בייבי דיילי פרימיום' : 'BabyDaily Premium',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF7A7A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isHe ? 'שקט נפשי והדרכת AI לכל המשפחה' : 'Peace of Mind & Smart AI for Your Family',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D3142),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isHe
                        ? 'במחיר הנמוך ביותר (עד 60% פחות מ-Huckleberry). מנוי אחד משותף לכל המטפלים והמכשירים.'
                        : 'Up to 60% more affordable than Huckleberry (\$14.99/mo). One pass synced across all caregivers.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF71788E)),
                  ),
                  const SizedBox(height: 18),
                  ..._plans.map((p) {
                    final isSel = _selectedPlan == p['id'];
                    final isCurrent = isPremium && user?.subscriptionPlan == p['id'];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedPlan = p['id'] as String),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFF9F8) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? const Color(0xFFFF7A7A) : const Color(0xFFF0EBE6),
                            width: isSel ? 2 : 1.2,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF7A7A).withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: p['id'] as String,
                              groupValue: _selectedPlan,
                              activeColor: const Color(0xFFFF7A7A),
                              onChanged: (v) => setState(() => _selectedPlan = v!),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isHe ? p['titleHe'] as String : p['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2D3142),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF0F0),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isHe ? p['badgeHe'] as String : p['badge'] as String,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFFF7A7A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isHe ? p['descHe'] as String : p['desc'] as String,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF71788E)),
                                  ),
                                  if (isCurrent)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        isHe ? '✓ המנוי הפעיל שלך' : '✓ Your Active Plan',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF48C78E),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  p['price'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2D3142),
                                  ),
                                ),
                                Text(
                                  isHe ? p['periodHe'] as String : p['period'] as String,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF71788E)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _buildFeatureBullet(
                    '🤖',
                    isHe ? 'שאלות AI ועוזר חכם ללא הגבלה' : 'Unlimited AI routine assistant & sleep questions',
                  ),
                  _buildFeatureBullet(
                    '☀️',
                    isHe ? 'חיזוי חלונות שינה וזמני הרדמה אופטימליים' : 'Live sweet-spot nap window predictions',
                  ),
                  _buildFeatureBullet(
                    '📧',
                    isHe ? 'סיכום יומי חכם אוטומטי למייל ולהתראות' : 'Daily AI summary sent to email & push notification',
                  ),
                  _buildFeatureBullet(
                    '📊',
                    isHe ? 'סטטיסטיקות 7 ו-14 ימים (האכלות, שינה, חיתולים)' : '7-day & 14-day routine analytics & pediatric trends',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A7A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _handleSubscribe,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      isHe ? 'הפעלת פרימיום עכשיו ✨' : 'Activate BabyDaily Premium ✨',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHe
                ? 'מסלול חינמי כולל תמיד מעקב מלא, שיתוף משפחה ו-3 שאלות AI ביום.'
                : 'Free tier always includes complete tracking, family sync & 3 AI queries/day.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
            ),
          ),
        ],
      ),
    );
  }
}
