import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../state/auth_state.dart';
import 'premium_sheet.dart';

class AiChatSheet extends StatefulWidget {
  final String babyId;
  final String babyName;

  const AiChatSheet({super.key, required this.babyId, required this.babyName});

  static Future<void> show(BuildContext context, String babyId, String babyName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiChatSheet(babyId: babyId, babyName: babyName),
    );
  }

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  int _queriesToday = 0;
  int _dailyLimit = 3;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthState>().user;
    if (user != null) {
      _queriesToday = user.aiQueriesToday;
      _dailyLimit = user.aiDailyLimit;
    }
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });

    _scrollToBottom();

    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final isHe = (auth.user?.locale ?? 'en') == 'he';

    try {
      final res = await api.post('/babies/${widget.babyId}/ai/chat', {
        'message': text,
        'locale': auth.user?.locale ?? 'en',
      });

      final reply = res['reply'] as String? ?? 'Done.';
      final newCount = res['aiQueriesToday'] as int? ?? (_queriesToday + 1);
      final limit = res['aiDailyLimit'] as int? ?? _dailyLimit;

      if (mounted) {
        setState(() {
          _queriesToday = newCount;
          _dailyLimit = limit;
          _messages.add({
            'role': 'assistant',
            'content': reply,
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        final isLimit = errStr.contains('premium_required') || errStr.contains('402');

        setState(() {
          _isLoading = false;
          _messages.add({
            'role': 'assistant',
            'content': isLimit
                ? (isHe
                    ? '✨ הגעת למגבלת ה-AI החינמית (3/3 שאלות להיום). שדרג/י ל-BabyDaily Premium לשאלות ללא הגבלה!'
                    : '✨ Daily Free AI limit (3/3) reached. Upgrade to BabyDaily Premium (\$4.99/mo) for unlimited AI guidance!')
                : (isHe
                    ? 'מצטערים, חלה שגיאה בקבלת התשובה. נסו שוב בעוד רגע.'
                    : 'Sorry, could not process request right now. Please try again.'),
            'time': DateTime.now(),
            'isError': true,
            'showUpgrade': isLimit,
          });
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isHe = (auth.user?.locale ?? 'en') == 'he';
    final user = auth.user;
    final isPremium = user?.isPremium ?? false;

    final suggestions = isHe
        ? [
            'מתי כדאי להשכיב לתנומה הבאה?',
            'האם ${widget.babyName} אכל/ה מספיק היום?',
            'תן לי סיכום קצר על שגרת היום',
          ]
        : [
            'When is the next nap window?',
            'Did ${widget.babyName} eat enough today?',
            'Give me a routine summary of today',
          ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(18, 16, 18, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A7A), Color(0xFF8C7AE6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('✨', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHe ? 'BabyDaily AI — יועץ השגרה' : 'BabyDaily AI Routine Advisor',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      isPremium
                          ? (isHe ? '✨ פרימיום • שאלות ללא הגבלה' : '✨ Premium • Unlimited questions')
                          : (isHe
                              ? 'חינם: $_queriesToday/$_dailyLimit שאלות היום'
                              : 'Free: $_queriesToday/$_dailyLimit questions today'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPremium ? const Color(0xFF8C7AE6) : const Color(0xFF71788E),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium)
                TextButton(
                  onPressed: () => PremiumSheet.show(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF0F0),
                    foregroundColor: const Color(0xFFFF7A7A),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isHe ? 'שדרג/י' : 'Upgrade',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🤖', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            isHe ? 'שאל/י על שגרת היום של ${widget.babyName}' : 'Ask about ${widget.babyName}\'s routine',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isHe
                                ? 'ה-AI מנתח את כל האכלות, זמני השינה והחיתולים האחרונים בזמן אמת.'
                                : 'AI reviews real logged feedings, wake windows, and diapers.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF71788E)),
                          ),
                          const SizedBox(height: 16),
                          ...suggestions.map(
                            (sugg) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _sendMessage(sugg),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBF7F2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFF0EBE6)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sugg,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2D3142),
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFFF7A7A)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final isUser = m['role'] == 'user';
                      final showUpgrade = m['showUpgrade'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFFFF7A7A)
                                : const Color(0xFFFBF7F2),
                            borderRadius: BorderRadius.circular(18),
                            border: isUser ? null : Border.all(color: const Color(0xFFF0EBE6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['content'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isUser ? Colors.white : const Color(0xFF2D3142),
                                  height: 1.4,
                                ),
                              ),
                              if (showUpgrade) ...[
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF7A7A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => PremiumSheet.show(context),
                                  child: Text(
                                    isHe ? 'שדרג/י ל-Premium (\$4.99)' : 'Upgrade to Premium (\$4.99)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A7A)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isHe ? 'היועץ מעבד תשובה...' : 'Analyzing baby routine...',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF71788E)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7F2),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8E2D9)),
                  ),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: isHe ? 'שאלו שאלה על שגרת התינוק/ת...' : 'Ask about sleep, feedings, etc...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA89E95)),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2D3142)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isLoading ? null : () => _sendMessage(),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A7A),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

