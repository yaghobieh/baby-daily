import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../state/entry_state.dart';
import '../../state/locale_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_alarm.dart';
import '../../widgets/volume_dial.dart';

class LogEntrySheet extends StatefulWidget {
  final String babyId;
  final String initialType;

  const LogEntrySheet({
    super.key,
    required this.babyId,
    required this.initialType,
  });

  static Future<void> show(BuildContext context, String babyId, String type) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.90,
        child: LogEntrySheet(babyId: babyId, initialType: type),
      ),
    );
  }

  @override
  State<LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<LogEntrySheet> {
  late String _type;

  // FEED state
  String _feedMethod = 'bottle';
  String _milkType = 'formula';
  String _breastSide = 'both';
  int _breastMinutes = 15;
  int _bottleMl = 180;
  final TextEditingController _foodController = TextEditingController();

  // DIAPER state
  String _diaperKind = 'wet';
  String _stoolTexture = 'soft';

  // GROWTH state
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _headController = TextEditingController();

  // MEDICINE state
  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _medDoseController = TextEditingController();
  bool _isVaccine = false;

  // NOTE state
  final String _mood = 'happy';
  final TextEditingController _noteController = TextEditingController();

  DateTime _startedAt = DateTime.now();
  bool _isSubmitting = false;
  bool _setNextMealAlarm = false;
  int _nextMealHours = 3;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (_type == 'FEED') {
      _feedMethod = 'bottle';
    }
  }

  @override
  void dispose() {
    _foodController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _headController.dispose();
    _medNameController.dispose();
    _medDoseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _startedAt = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _submit({String? overrideType}) async {
    final submitType = overrideType ?? _type;
    setState(() => _isSubmitting = true);
    final entryState = context.read<EntryState>();

    final Map<String, dynamic> data = {};
    DateTime? endedAt;

    if (submitType == 'FEED') {
      data['method'] = _feedMethod;
      if (_feedMethod == 'bottle') {
        data['amountMl'] = _bottleMl;
        data['milkType'] = _milkType;
      } else if (_feedMethod == 'breast') {
        data['side'] = _breastSide;
        data['durationMinutes'] = _breastMinutes;
      } else if (_feedMethod == 'solids') {
        data['food'] = _foodController.text.trim();
      }
    } else if (submitType == 'DIAPER') {
      data['kind'] = _diaperKind;
      if (_diaperKind == 'dirty' || _diaperKind == 'mixed') {
        data['stoolTexture'] = _stoolTexture;
      }
    } else if (submitType == 'GROWTH') {
      if (_weightController.text.isNotEmpty) {
        data['weightKg'] = double.tryParse(_weightController.text);
      }
      if (_heightController.text.isNotEmpty) {
        data['heightCm'] = double.tryParse(_heightController.text);
      }
      if (_headController.text.isNotEmpty) {
        data['headCm'] = double.tryParse(_headController.text);
      }
    } else if (submitType == 'MEDICINE') {
      data['name'] = _medNameController.text.trim().isNotEmpty
          ? _medNameController.text.trim()
          : 'Vitamin D';
      if (_medDoseController.text.isNotEmpty) {
        data['dose'] = _medDoseController.text.trim();
      }
      data['isVaccine'] = _isVaccine;
    } else if (submitType == 'NOTE') {
      data['mood'] = _mood;
    }

    final success = await entryState.logEntry(
      babyId: widget.babyId,
      type: submitType,
      startedAt: _startedAt,
      endedAt: endedAt,
      data: data,
      note: _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        if (submitType == 'FEED' && _setNextMealAlarm) {
          await PhoneAlarm.setAlarmAfter(
            duration: Duration(hours: _nextMealHours),
            message: '🍼 BabyDaily: Next Meal',
          );
        }
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(entryState.error ?? 'Error saving entry')),
        );
      }
    }
  }

  // ===========================================================================
  // SCREENSHOT 2 & 5: FEED TRACKER SHEET
  // ===========================================================================

  Widget _buildFeedSheet(AppStrings s) {
    final dateStr = DateFormat('MMM d').format(_startedAt);
    final timeStr = DateFormat('h:mm a').format(_startedAt);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFDE6B52),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Coral Header matching Screenshot 2
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            child: Row(
              children: [
                // Circular baby avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF8F2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('👶', style: TextStyle(fontSize: 30)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        s.isHe ? 'מעקב האכלה' : 'Feed Tracker',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.isHe ? 'היום, $dateStr' : 'Today, $dateStr',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                  tooltip: s.cancel,
                ),
              ],
            ),
          ),

          // Warm cream body container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F1E4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  children: [
                    // Segmented bar: [Bottle | Breast | Solids]
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4ECE0),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFFD5B3A3), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          _buildFeedSegment('bottle', s.isHe ? 'בקבוק' : 'Bottle'),
                          _buildFeedSegment('breast', s.isHe ? 'הנקה' : 'Breast'),
                          _buildFeedSegment('solids', s.isHe ? 'מוצקים' : 'Solids'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // White inner card matching Screenshot 2
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_feedMethod == 'bottle') ...[
                            Center(
                              child: VolumeDial(
                                value: _bottleMl,
                                min: 0,
                                max: 240,
                                onChanged: (val) => setState(() => _bottleMl = val),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              s.isHe ? 'סוג' : 'Type',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F1A17),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildMilkTypePill('formula', s.isHe ? 'תמ״ל' : 'Formula'),
                                const SizedBox(width: 8),
                                _buildMilkTypePill('expressed', s.isHe ? 'חלב שאוב' : 'Expressed Milk', flex: 2),
                                const SizedBox(width: 8),
                                _buildMilkTypePill('water', s.isHe ? 'מים' : 'Water'),
                              ],
                            ),
                          ] else if (_feedMethod == 'breast') ...[
                            Text(
                              s.isHe ? 'צד הנקה' : 'Breast Side',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F1A17)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildBreastSidePill('left', s.sideLeft),
                                const SizedBox(width: 8),
                                _buildBreastSidePill('right', s.sideRight),
                                const SizedBox(width: 8),
                                _buildBreastSidePill('both', s.sideBoth),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s.isHe ? 'משך (דקות)' : 'Duration', style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text('$_breastMinutes min', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFDE6B52))),
                              ],
                            ),
                            Slider(
                              value: _breastMinutes.toDouble(),
                              min: 1,
                              max: 60,
                              activeColor: const Color(0xFFDE6B52),
                              onChanged: (v) => setState(() => _breastMinutes = v.round()),
                            ),
                          ] else ...[
                            Text(
                              s.foodType,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F1A17)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _foodController,
                              decoration: InputDecoration(
                                hintText: s.isHe ? 'למשל: מחית בטטה, אבוקדו' : 'e.g., Avocado puree, Oatmeal',
                                filled: true,
                                fillColor: const Color(0xFFF3ECE0),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),
                          Text(
                            s.isHe ? 'הערה' : 'Note',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F1A17),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Cream note box with pencil icon on top-right
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3ECE0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDFD5C5)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _noteController,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF2B2523)),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                      hintText: s.isHe
                                          ? 'הוסף הערה מהירה...\n(למשל: אכל יפה, מנומנם)'
                                          : 'Add a quick note...\n(e.g., fed well, drowsy)',
                                      hintStyle: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF6E655F),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Icon(Icons.edit, size: 17, color: Color(0xFFC2998B)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          // Start Time dropdown box
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3ECE0),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFDFD5C5)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.isHe ? 'שעת התחלה: $timeStr' : 'Start Time: $timeStr',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F1A17),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: const Color(0xFFD5C8B8),
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Color(0xFFC2998B), size: 22),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          // Next Meal Phone Clock Alarm Switch
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3ECE0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDFD5C5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.alarm_on_rounded, color: Color(0xFFDE6B52), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s.tr(
                                      en: 'Phone Clock Alarm for Next Meal (${_nextMealHours}h)',
                                      he: 'שעון מעורר בנייד לארוחה הבאה (${_nextMealHours} ש׳)',
                                      es: 'Alarma para próxima comida (${_nextMealHours}h)',
                                      ru: 'Будильник на следующее кормление (${_nextMealHours}ч)',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F1A17),
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _setNextMealAlarm,
                                  activeTrackColor: const Color(0xFFDE6B52),
                                  onChanged: (v) => setState(() => _setNextMealAlarm = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Full-width Coral "Log Feeding ->" Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8B73),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _isSubmitting ? null : () => _submit(overrideType: 'FEED'),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Center(
                                          child: Text(
                                            s.isHe ? 'שמור האכלה' : 'Log Feeding',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const Align(
                                          alignment: Alignment.centerRight,
                                          child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedSegment(String key, String label) {
    final isSelected = _feedMethod == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _feedMethod = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDE6B52) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF9E5A49),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilkTypePill(String key, String label, {int flex = 1}) {
    final isSelected = _milkType == key;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => setState(() => _milkType = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDE6B52) : const Color(0xFFF9F3EA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFDE6B52) : const Color(0xFFD2AE9D),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF5D3A2E),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreastSidePill(String key, String label) {
    final isSelected = _breastSide == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _breastSide = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDE6B52) : const Color(0xFFF9F3EA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFDE6B52) : const Color(0xFFD2AE9D),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF5D3A2E),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREENSHOT 3: SLEEP TRACKER + DIAPER LOG COMBINED SHEET
  // ===========================================================================

  Widget _buildSleepAndDiaperSheet(EntryState entryState, AppStrings s) {
    final sleeping = entryState.isSleeping;
    final d = entryState.activeSleepDuration;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    final startTimeStr = DateFormat('h:mm a').format(
      entryState.activeSleep?.startedAt.toLocal() ?? _startedAt,
    );

    final textures = [
      {'key': 'soft', 'label': s.isHe ? 'רך' : 'Soft'},
      {'key': 'mushy', 'label': s.isHe ? 'משחתי' : 'Mushy'},
      {'key': 'hard', 'label': s.isHe ? 'קשה' : 'Hard'},
      {'key': 'watery', 'label': s.isHe ? 'מימי' : 'Watery'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Top sheet grabber bar
          Container(
            width: 52,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                18,
                22,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Night-Sky Purple Card matching Screenshot 3
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFF33266E),
                          Color(0xFF6B5B9E),
                          Color(0xFF9C89CE),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4C3D8F).withValues(alpha: 0.30),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Glowing Crescent Moon on top-right
                        const Positioned(
                          right: 6,
                          top: 24,
                          child: Icon(
                            Icons.nightlight_round,
                            size: 68,
                            color: Color(0xFFE9D8FD),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.isHe ? 'מעקב שינה' : 'Sleep Tracker',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: Text(
                                sleeping
                                    ? (s.isHe ? 'ישן/ה עכשיו ✨' : 'SLEEPING NOW ✨')
                                    : (s.isHe ? 'מוכן/ה לשינה ✨' : 'SLEEPING NOW ✨'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: sleeping ? h : '02',
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                    const TextSpan(
                                      text: 'h ',
                                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                      text: sleeping ? m : '10',
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                    const TextSpan(
                                      text: 'm ',
                                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                      text: sleeping ? sec : '15',
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                    const TextSpan(
                                      text: 's',
                                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Mint green "WAKE UP" / "START SLEEP" pill button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB5EFE0),
                                  foregroundColor: const Color(0xFF111827),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: const StadiumBorder(),
                                  elevation: 3,
                                ),
                                icon: Icon(
                                  sleeping ? Icons.wb_twilight_rounded : Icons.bedtime_outlined,
                                  size: 22,
                                  color: const Color(0xFF111827),
                                ),
                                label: Text(
                                  sleeping
                                      ? (s.isHe ? 'התעורר/ה' : 'WAKE UP')
                                      : (s.isHe ? 'התחל שינה' : 'START SLEEP'),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                onPressed: () async {
                                  if (sleeping) {
                                    await entryState.wakeUp(widget.babyId);
                                  } else {
                                    await entryState.startSleep(widget.babyId);
                                  }
                                  if (mounted) Navigator.pop(context);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.isHe ? 'התחיל ב: $startTimeStr' : 'Log started: $startTimeStr',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF231942),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  const SizedBox(height: 16),

                  // Diaper Log Section right below (matching Screenshot 3)
                  Text(
                    s.isHe ? 'יומן חיתולים' : 'Diaper Log',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.isHe ? 'סוג חיתול:' : 'Diaper Type:',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildDiaperTypePill(
                        key: 'wet',
                        label: s.isHe ? 'רטוב' : 'Wet',
                        icon: Icons.water_drop,
                      ),
                      const SizedBox(width: 10),
                      _buildDiaperTypePill(
                        key: 'dirty',
                        label: s.isHe ? 'מלוכלך' : 'Dirty',
                        icon: Icons.baby_changing_station,
                      ),
                      const SizedBox(width: 10),
                      _buildDiaperTypePill(
                        key: 'mixed',
                        label: s.isHe ? 'משולב' : 'Mixed',
                        icon: Icons.percent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.isHe ? 'מרקם יציאה (אם מלוכלך):' : 'Stool Texture (if Dirty):',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left 2x2 Stool Texture pills
                      Expanded(
                        flex: 5,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: textures.map((t) {
                            final selected = _stoolTexture == t['key'];
                            return GestureDetector(
                              onTap: () => setState(() => _stoolTexture = t['key']!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFFB5EFE0) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected ? const Color(0xFFB5EFE0) : const Color(0xFF6B7280),
                                  ),
                                ),
                                child: Text(
                                  t['label']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Right "✓ SAVE DIAPER" mint pill button
                      Expanded(
                        flex: 5,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB5EFE0),
                            foregroundColor: const Color(0xFF111827),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            shape: const StadiumBorder(),
                            elevation: 3,
                          ),
                          icon: const Icon(Icons.check, size: 20, color: Color(0xFF111827)),
                          label: Text(
                            s.isHe ? 'שמור חיתול' : 'SAVE DIAPER',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : () => _submit(overrideType: 'DIAPER'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaperTypePill({
    required String key,
    required String label,
    required IconData icon,
  }) {
    final selected = _diaperKind == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _diaperKind = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFB5EFE0) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? const Color(0xFFB5EFE0) : const Color(0xFF4B5563),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF111827)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MEDICINE / GROWTH / NOTE SHEET
  // ===========================================================================

  Widget _buildOtherSheet(AppStrings s) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _type == 'MEDICINE'
                      ? (s.isHe ? 'מתן תרופה' : 'Medicine Log')
                      : _type == 'GROWTH'
                          ? (s.isHe ? 'מדדי גדילה' : 'Growth Check')
                          : (s.isHe ? 'פתק מהיר' : 'Quick Note'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_type == 'MEDICINE') ...[
              TextField(
                controller: _medNameController,
                decoration: InputDecoration(
                  labelText: s.medicineName,
                  hintText: 'e.g. Vitamin D, Paracetamol',
                  prefixIcon: const Icon(Icons.medication_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _medDoseController,
                decoration: InputDecoration(
                  labelText: s.medicineDose,
                  hintText: 'e.g. 2 drops, 2.5 ml',
                  prefixIcon: const Icon(Icons.science_outlined),
                ),
              ),
              CheckboxListTile(
                title: Text(s.isVaccine),
                value: _isVaccine,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _isVaccine = v ?? false),
              ),
            ] else if (_type == 'GROWTH') ...[
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: s.weightKg, suffixText: 'kg'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: s.heightCm, suffixText: 'cm'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _headController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: s.headCm, suffixText: 'cm'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.note,
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submit(),
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final entryState = context.watch<EntryState>();

    if (_type == 'FEED') {
      return _buildFeedSheet(s);
    }
    if (_type == 'SLEEP' || _type == 'DIAPER') {
      return _buildSleepAndDiaperSheet(entryState, s);
    }
    return _buildOtherSheet(s);
  }
}
