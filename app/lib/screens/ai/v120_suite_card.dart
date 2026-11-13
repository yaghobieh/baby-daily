import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../state/auth_state.dart';
import '../../state/entry_state.dart';
import '../../state/theme_state.dart';
import '../../theme/app_theme.dart';

class V120SuiteCard extends StatefulWidget {
  final String babyId;
  final String babyName;

  const V120SuiteCard({
    super.key,
    required this.babyId,
    required this.babyName,
  });

  @override
  State<V120SuiteCard> createState() => _V120SuiteCardState();
}

class _V120SuiteCardState extends State<V120SuiteCard> {
  int _selectedTab = 0;
  bool _busy = false;

  // 1. AI Voice/Text Logger
  final TextEditingController _nlController = TextEditingController();
  Map<String, dynamic>? _parsedPreview;

  // 2. Milk Stash
  Map<String, dynamic>? _stashData;
  final TextEditingController _leftMlCtrl = TextEditingController(text: '60');
  final TextEditingController _rightMlCtrl = TextEditingController(text: '60');
  String _storageLoc = 'fridge';

  // 3. 100 First Foods & Allergens
  Map<String, dynamic>? _solidsData;
  final TextEditingController _foodNameCtrl = TextEditingController();
  String _foodCategory = 'fruit';
  String _foodPref = 'loved';
  String _foodReaction = 'none';
  bool _isAllergen = false;

  // 4. Tummy Time & Milestones
  Map<String, dynamic>? _milestonesData;
  int _tummySeconds = 0;
  bool _tummyRunning = false;
  Timer? _tummyTimer;

  // 5. WHO Percentiles & Vaccines
  Map<String, dynamic>? _growthData;
  final TextEditingController _weightCtrl = TextEditingController(text: '6.8');
  final TextEditingController _heightCtrl = TextEditingController(text: '64');
  final TextEditingController _headCtrl = TextEditingController(text: '41.5');

  // 6. Soothing Sound Machine
  String? _activeSound;
  int _soundMinutesLeft = 30;
  Timer? _soundTimer;

  // 7. Shift Handoff
  Map<String, dynamic>? _handoffData;

  @override
  void initState() {
    super.initState();
    _loadAllV120Data();
  }

  @override
  void didUpdateWidget(covariant V120SuiteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.babyId != widget.babyId) {
      _loadAllV120Data();
    }
  }

  @override
  void dispose() {
    _nlController.dispose();
    _leftMlCtrl.dispose();
    _rightMlCtrl.dispose();
    _foodNameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _headCtrl.dispose();
    _tummyTimer?.cancel();
    _soundTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllV120Data() async {
    final api = context.read<ApiClient>();
    try {
      final results = await Future.wait([
        api.get('/babies/${widget.babyId}/milk-stash').catchError((_) => <String, dynamic>{}),
        api.get('/babies/${widget.babyId}/solids-summary').catchError((_) => <String, dynamic>{}),
        api.get('/babies/${widget.babyId}/milestones').catchError((_) => <String, dynamic>{}),
        api.get('/babies/${widget.babyId}/growth-percentiles').catchError((_) => <String, dynamic>{}),
        api.get('/babies/${widget.babyId}/handoff', {'hours': '8'}).catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      setState(() {
        _stashData = results[0] as Map<String, dynamic>?;
        _solidsData = results[1] as Map<String, dynamic>?;
        _milestonesData = results[2] as Map<String, dynamic>?;
        _growthData = results[3] as Map<String, dynamic>?;
        _handoffData = results[4] as Map<String, dynamic>?;
      });
    } catch (_) {}
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8C7AE6),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _parseOrLogNl({required bool autoSave}) async {
    final text = _nlController.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    final entryState = context.read<EntryState>();
    try {
      final res = await api.post('/babies/${widget.babyId}/ai/parse-entry', {
        'text': text,
        'autoSave': autoSave,
      }) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _parsedPreview = res['parsed'] as Map<String, dynamic>?;
      });
      if (autoSave) {
        _nlController.clear();
        _toast('✨ AI logged routine entry for ${widget.babyName}!');
        await entryState.loadForBaby(widget.babyId);
        await _loadAllV120Data();
      }
    } catch (e) {
      _toast('Could not parse: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logPumpBag() async {
    final left = int.tryParse(_leftMlCtrl.text) ?? 0;
    final right = int.tryParse(_rightMlCtrl.text) ?? 0;
    final total = left + right;
    if (total <= 0) return;
    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    final entryState = context.read<EntryState>();
    try {
      await api.post('/babies/${widget.babyId}/entries', {
        'type': 'FEED',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'method': 'pump',
          'leftMl': left,
          'rightMl': right,
          'amountMl': total,
          'storageLocation': _storageLoc,
        },
      });
      _toast('🍼 Stored ${total}mL in $_storageLoc stash!');
      await entryState.loadForBaby(widget.babyId);
      await _loadAllV120Data();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _consumeOldestBag(String entryId) async {
    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    final entryState = context.read<EntryState>();
    try {
      await api.post('/babies/${widget.babyId}/milk-stash/$entryId/consume', {
        'createBottleEntry': true,
      });
      _toast('🍼 Fed oldest milk bag (FIFO) & logged bottle feed!');
      await entryState.loadForBaby(widget.babyId);
      await _loadAllV120Data();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logSolidFood({String? quickFood, bool? quickAllergen}) async {
    final food = (quickFood ?? _foodNameCtrl.text).trim();
    if (food.isEmpty) return;
    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    final entryState = context.read<EntryState>();
    try {
      final allergenFlag = quickAllergen ?? _isAllergen;
      await api.post('/babies/${widget.babyId}/entries', {
        'type': 'FEED',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'method': 'solids',
          'food': food,
          'foodCategory': allergenFlag ? 'allergen' : _foodCategory,
          'isAllergen': allergenFlag,
          if (allergenFlag) 'allergenName': food.toLowerCase(),
          'preference': _foodPref,
          'reaction': _foodReaction,
        },
      });
      _foodNameCtrl.clear();
      _toast('🥑 Logged "$food" to 100 First Foods!');
      await entryState.loadForBaby(widget.babyId);
      await _loadAllV120Data();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleTummyTimer() {
    if (_tummyRunning) {
      _tummyTimer?.cancel();
      setState(() => _tummyRunning = false);
    } else {
      setState(() => _tummyRunning = true);
      _tummyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _tummySeconds++);
      });
    }
  }

  Future<void> _saveTummySession({int? overrideMinutes}) async {
    final mins = overrideMinutes ?? (_tummySeconds / 60).ceil().clamp(1, 120);
    _tummyTimer?.cancel();
    setState(() {
      _tummyRunning = false;
      _tummySeconds = 0;
      _busy = true;
    });
    final api = context.read<ApiClient>();
    final entryState = context.read<EntryState>();
    try {
      await api.post('/babies/${widget.babyId}/entries', {
        'type': 'NOTE',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'subType': 'activity',
          'activityKind': 'tummy_time',
          'durationMinutes': mins,
          'text': 'Tummy Time (${mins}m)',
        },
      });
      _toast('🤸 Saved ${mins}m of Tummy Time!');
      await entryState.loadForBaby(widget.babyId);
      await _loadAllV120Data();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeMilestone(String key, String title, String category) async {
    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    final entryState = context.read<EntryState>();
    try {
      await api.post('/babies/${widget.babyId}/entries', {
        'type': 'NOTE',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'subType': 'milestone',
          'milestoneKey': key,
          'milestoneTitle': title,
          'milestoneCategory': category,
          'text': 'Milestone unlocked: $title',
        },
      });
      _toast('🏆 Milestone unlocked: $title!');
      await entryState.loadForBaby(widget.babyId);
      await _loadAllV120Data();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logGrowthMeasurement() async {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    final hc = double.tryParse(_headCtrl.text);
    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    final entryState = context.read<EntryState>();
    try {
      await api.post('/babies/${widget.babyId}/entries', {
        'type': 'GROWTH',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          if (w != null) 'weightKg': w,
          if (h != null) 'heightCm': h,
          if (hc != null) 'headCm': hc,
        },
      });
      _toast('📈 Logged WHO Growth measurements!');
      await entryState.loadForBaby(widget.babyId);
      await _loadAllV120Data();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logVaccine(String code, String name) async {
    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    final entryState = context.read<EntryState>();
    try {
      await api.post('/babies/${widget.babyId}/entries', {
        'type': 'MEDICINE',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'name': name,
          'vaccineCode': code,
          'notes': 'Pediatric immunization completed',
        },
      });
      _toast('💉 Marked $code vaccine as completed!');
      await entryState.loadForBaby(widget.babyId);
      await _loadAllV120Data();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleSound(String soundName) {
    _soundTimer?.cancel();
    if (_activeSound == soundName) {
      setState(() => _activeSound = null);
      _toast('🔇 Sound machine stopped');
    } else {
      setState(() {
        _activeSound = soundName;
        _soundMinutesLeft = 30;
      });
      _toast('🎵 Playing soothing $soundName (30m auto-fade)');
      _soundTimer = Timer.periodic(const Duration(minutes: 1), (t) {
        if (!mounted) return;
        setState(() {
          if (_soundMinutesLeft <= 1) {
            _activeSound = null;
            t.cancel();
          } else {
            _soundMinutesLeft--;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final themeState = context.watch<ThemeState>();
    final isDark = AppTheme.isDark(context);
    final isHe = (auth.user?.locale ?? 'en') == 'he';

    final tabs = [
      {'icon': '🎙️', 'label': isHe ? 'פקודת AI' : 'AI Voice/NL'},
      {'icon': '🍼', 'label': isHe ? 'מאגר חלב' : 'Milk Stash'},
      {'icon': '🥑', 'label': isHe ? '100 טעימות' : '100 Foods'},
      {'icon': '🤸', 'label': isHe ? 'זמן בטן' : 'Tummy/CDC'},
      {'icon': '📈', 'label': isHe ? 'אחוזוני WHO' : 'WHO/Vaccines'},
      {'icon': '🎵', 'label': isHe ? 'רעש לבן' : 'White Noise'},
      {'icon': '🤝', 'label': isHe ? 'החלפת משמרת' : 'Shift Handoff'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2430) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF343B4F) : const Color(0xFFE9E4FA),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C7AE6).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header Row with v1.2.0 Badge & 3 AM Night-Shift Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8C7AE6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'v1.2.0 SUITE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHe ? 'ערכת הורות חכמה 360°' : 'Holistic Parenting Suite',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF2D3142),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  themeState.toggleDark(isDark);
                  _toast(
                    isDark
                        ? '☀️ Standard Day Mode restored'
                        : '🌙 3 AM Night-Shift Mode activated',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B1D2E) : const Color(0xFFF5F3FC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFFFF7A7A) : const Color(0xFFDCD3F8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDark ? Icons.nightlight_round : Icons.bedtime_outlined,
                        size: 14,
                        color: isDark ? const Color(0xFFFF7A7A) : const Color(0xFF8C7AE6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isHe ? 'מצב 3:00' : '3 AM Mode',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFFF7A7A) : const Color(0xFF8C7AE6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Module Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = _selectedTab == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    selectedColor: const Color(0xFF8C7AE6),
                    backgroundColor: isDark
                        ? const Color(0xFF2A3040)
                        : const Color(0xFFF7F5FE),
                    label: Text(
                      '${tabs[i]['icon']} ${tabs[i]['label']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF4A4E69)),
                      ),
                    ),
                    onSelected: (_) => setState(() => _selectedTab = i),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Active Module Content
          _buildActiveTabContent(isHe, isDark),
        ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isHe, bool isDark) {
    switch (_selectedTab) {
      case 0:
        return _buildNlLoggerTab(isHe, isDark);
      case 1:
        return _buildMilkStashTab(isHe, isDark);
      case 2:
        return _buildFirstFoodsTab(isHe, isDark);
      case 3:
        return _buildTummyMilestonesTab(isHe, isDark);
      case 4:
        return _buildWhoVaccinesTab(isHe, isDark);
      case 5:
        return _buildSoundMachineTab(isHe, isDark);
      case 6:
        return _buildHandoffTab(isHe, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. AI Voice & Natural Language Logger
  Widget _buildNlLoggerTab(bool isHe, bool isDark) {
    final samples = [
      'Fed 140ml bottle and wet diaper',
      'Pumped 70ml left and 60ml right into fridge',
      'Tummy time for 15 minutes',
      'Ate avocado loved it no reaction',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHe
              ? 'כתוב/י או הקלט/י משפט חופשי וה-AI יתעד אוטומטית:'
              : 'Type or dictate a natural phrase and AI logs it automatically:',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nlController,
          decoration: InputDecoration(
            hintText: isHe
                ? 'למשל: אכל 120 מ"ל מטרנה וחיתול רטוב...'
                : 'e.g. "Fed 120ml bottle 15m ago and dirty diaper"',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: samples
              .map(
                (s) => InkWell(
                  onTap: () => setState(() => _nlController.text = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A3040) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '"$s"',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _parseOrLogNl(autoSave: false),
                child: Text(isHe ? 'תצוגה מקדימה' : 'Preview AI Parse'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C7AE6)),
                onPressed: _busy ? null : () => _parseOrLogNl(autoSave: true),
                child: Text(
                  isHe ? '⚡ תעד מיד' : '⚡ Parse & Log Now',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        if (_parsedPreview != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '✨ Detected: ${_parsedPreview!['summary'] ?? _parsedPreview!['type']}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A3794),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 2. Pumping & Milk Stash Inventory Manager
  Widget _buildMilkStashTab(bool isHe, bool isDark) {
    final fridgeMl = _stashData?['fridgeTotalMl'] ?? 0;
    final freezerMl = _stashData?['freezerTotalMl'] ?? 0;
    final nextToUse = _stashData?['nextToUse'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _metricBox('🧊 Fridge (4d)', '${fridgeMl}mL', const Color(0xFF3897F0)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricBox('❄️ Freezer (6m)', '${freezerMl}mL', const Color(0xFF8C7AE6)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _leftMlCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Left (mL)', isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _rightMlCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Right (mL)', isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _storageLoc,
              items: const [
                DropdownMenuItem(value: 'fridge', child: Text('Fridge')),
                DropdownMenuItem(value: 'freezer', child: Text('Freezer')),
              ],
              onChanged: (v) => setState(() => _storageLoc = v ?? 'fridge'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _busy ? null : _logPumpBag,
                child: const Text('🍼 Store Pumped Bag'),
              ),
            ),
            if (nextToUse != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _consumeOldestBag(nextToUse['id'] as String),
                  child: Text('Use Oldest (${nextToUse['amountMl']}mL)'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // 3. 100 First Foods & Top 9 Allergens
  Widget _buildFirstFoodsTab(bool isHe, bool isDark) {
    final count = _solidsData?['uniqueFoodsCount'] ?? 0;
    final topAllergens = (_solidsData?['top9Allergens'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🥑 100 First Foods Progress: $count / 100',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            Text(
              '$count%',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF48C78E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (count as num).toDouble().clamp(0, 100) / 100.0,
          backgroundColor: const Color(0xFFE5E7EB),
          color: const Color(0xFF48C78E),
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _foodNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Food name (e.g. Avocado, Banana)',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _busy ? null : () => _logSolidFood(),
              child: const Text('+ Log Food'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Top 9 Allergens (Tap to log exposure):',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: topAllergens.map((item) {
            final m = item as Map<String, dynamic>;
            final name = m['allergen'] as String? ?? '';
            final introduced = m['introduced'] as bool? ?? false;
            return ActionChip(
              backgroundColor: introduced ? const Color(0xFFD4EDDA) : const Color(0xFFF3F4F6),
              label: Text(
                '${introduced ? '✅' : '⚪'} $name',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              onPressed: _busy
                  ? null
                  : () => _logSolidFood(quickFood: name, quickAllergen: true),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 4. Tummy Time & CDC/WHO Milestones
  Widget _buildTummyMilestonesTab(bool isHe, bool isDark) {
    final tummyToday = _milestonesData?['todayTummyMinutes'] ?? 0;
    final goal = _milestonesData?['dailyTummyGoalMinutes'] ?? 30;
    final catalog = (_milestonesData?['milestones'] as List<dynamic>?) ?? [];
    final mm = (_tummySeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_tummySeconds % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _metricBox(
                '🤸 Today Tummy Time',
                '${tummyToday}m / ${goal}m',
                const Color(0xFF48C78E),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _toggleTummyTimer,
              icon: Icon(_tummyRunning ? Icons.pause : Icons.play_arrow, size: 16),
              label: Text(_tummyRunning ? '$mm:$ss' : 'Start Timer'),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: _busy ? null : () => _saveTummySession(overrideMinutes: _tummySeconds > 0 ? null : 10),
              child: Text(_tummySeconds > 0 ? 'Save' : '+10m'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'CDC / WHO Developmental Milestones:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        ...catalog.take(4).map((item) {
          final m = item as Map<String, dynamic>;
          final done = m['completed'] as bool? ?? false;
          final key = m['key'] as String? ?? '';
          final title = m['title'] as String? ?? '';
          final cat = m['category'] as String? ?? 'motor';
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: done,
            title: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${m['ageMonths']}m • $cat', style: const TextStyle(fontSize: 10)),
            onChanged: done || _busy ? null : (_) => _completeMilestone(key, title, cat),
          );
        }),
      ],
    );
  }

  // 5. WHO Growth Percentiles & Vaccine Checklist
  Widget _buildWhoVaccinesTab(bool isHe, bool isDark) {
    final latest = _growthData?['latestPercentiles'] as Map<String, dynamic>?;
    final vaccines = (_growthData?['vaccines'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latest != null) ...[
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  '⚖️ Weight',
                  '${latest['weightKg'] ?? '-'}kg (P${latest['weightPercentile'] ?? 50})',
                  const Color(0xFF3897F0),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _metricBox(
                  '📏 Height',
                  '${latest['heightCm'] ?? '-'}cm (P${latest['heightPercentile'] ?? 50})',
                  const Color(0xFF48C78E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (kg)', isDense: true),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height (cm)', isDense: true),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: _busy ? null : _logGrowthMeasurement,
              child: const Text('Calc WHO'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '💉 Pediatrician Immunization Schedule:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: vaccines.map((v) {
            final m = v as Map<String, dynamic>;
            final code = m['code'] as String? ?? '';
            final name = m['name'] as String? ?? '';
            final done = m['completed'] as bool? ?? false;
            return ActionChip(
              backgroundColor: done ? const Color(0xFFD4EDDA) : const Color(0xFFF3F4F6),
              label: Text(
                '${done ? '✅' : '💉'} $code',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              onPressed: done || _busy ? null : () => _logVaccine(code, name),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 6. Built-In Soothing White Noise & Sleep Sound Machine
  Widget _buildSoundMachineTab(bool isHe, bool isDark) {
    final sounds = [
      {'id': 'White Noise', 'icon': '🌊', 'desc': 'Continuous shushing spectrum'},
      {'id': 'Pink Rain', 'icon': '🌧️', 'desc': 'Warm low-frequency rain'},
      {'id': 'Womb Heartbeat', 'icon': '💓', 'desc': '60 BPM soothing pulse'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _activeSound != null
              ? '🎵 Active: $_activeSound • Auto-fade in $_soundMinutesLeft min'
              : 'Select a continuous soothing sleep sound for ${widget.babyName}:',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: sounds.map((s) {
            final id = s['id']!;
            final active = _activeSound == id;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => _toggleSound(id),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF8C7AE6) : const Color(0xFFF5F3FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(s['icon']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          id,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : const Color(0xFF2D3142),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 7. Caregiver Shift Handoff Card
  Widget _buildHandoffTab(bool isHe, bool isDark) {
    final text = _handoffData?['shareText'] as String? ??
        '👶 ${widget.babyName} Shift Handoff: All routines synced and up to date.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A3040) : const Color(0xFFFFF9EB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCE3B4)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF4A372D),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  _toast('📋 Shift Handoff copied to clipboard!');
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Digest'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                onPressed: () async {
                  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.share, size: 16, color: Colors.white),
                label: const Text(
                  'WhatsApp Handoff',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricBox(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent),
          ),
        ],
      ),
    );
  }
}
