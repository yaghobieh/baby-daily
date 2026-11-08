import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../state/auth_state.dart';

class BabyStatsSheet extends StatefulWidget {
  final String babyId;
  final String babyName;

  const BabyStatsSheet({super.key, required this.babyId, required this.babyName});

  static Future<void> show(BuildContext context, String babyId, String babyName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BabyStatsSheet(babyId: babyId, babyName: babyName),
    );
  }

  @override
  State<BabyStatsSheet> createState() => _BabyStatsSheetState();
}

class _BabyStatsSheetState extends State<BabyStatsSheet> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _statsData;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = context.read<ApiClient>();
    try {
      final res = await api.get('/babies/${widget.babyId}/stats?days=7') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _statsData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isHe = (auth.user?.locale ?? 'en') == 'he';
    final averages = _statsData?['averages'] as Map<String, dynamic>?;
    final daily = (_statsData?['daily'] as List<dynamic>?) ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHe ? '📊 סטטיסטיקות שבועיות' : '📊 7-Day Routine Trends',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  Text(
                    widget.babyName,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF71788E), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF71788E)),
                onPressed: _fetchStats,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7A7A)),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchStats,
                      child: Text(isHe ? 'נסה שוב' : 'Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            isHe ? 'ממוצע האכלות' : 'Avg Feeds/Day',
                            '${averages?['avgFeedsPerDay'] ?? 0}',
                            const Color(0xFFFF7A7A),
                            const Color(0xFFFFF0F0),
                            '🍼',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            isHe ? 'ממוצע שינה' : 'Avg Sleep/Day',
                            '${averages?['avgSleepHoursPerDay'] ?? 0}h',
                            const Color(0xFF8C7AE6),
                            const Color(0xFFF5F3FC),
                            '😴',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            isHe ? 'ממוצע בקבוק' : 'Avg Bottle/Day',
                            '${averages?['avgBottleMlPerDay'] ?? 0} ml',
                            const Color(0xFF48C78E),
                            const Color(0xFFEFFBF5),
                            '🥛',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            isHe ? 'ממוצע חיתולים' : 'Avg Diapers',
                            '${averages?['avgDiapersPerDay'] ?? 0}',
                            const Color(0xFF3897F0),
                            const Color(0xFFEFF8FF),
                            '🧷',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: isHe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        isHe ? 'פירוט לפי ימים (7 ימים אחרונים)' : 'Daily Breakdown (Past 7 Days)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...daily.reversed.map((item) {
                      final map = item as Map<String, dynamic>;
                      final date = map['date'] as String? ?? '';
                      final feeds = map['feedsCount'] ?? 0;
                      final ml = map['bottleMl'] ?? 0;
                      final sleepHrs = map['sleepHours'] ?? 0;
                      final diapers = map['diapersTotal'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF7F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF0EBE6)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const Spacer(),
                            _buildPill('🍼 $feeds ($ml ml)', const Color(0xFFFF7A7A), const Color(0xFFFFF0F0)),
                            const SizedBox(width: 6),
                            _buildPill('😴 ${sleepHrs}h', const Color(0xFF8C7AE6), const Color(0xFFF5F3FC)),
                            const SizedBox(width: 6),
                            _buildPill('🧷 $diapers', const Color(0xFF3897F0), const Color(0xFFEFF8FF)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, Color color, Color bg, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              Text(
                val,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF71788E)),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color textCol, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: textCol),
      ),
    );
  }
}
