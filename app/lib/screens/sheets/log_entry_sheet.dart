import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../state/locale_state.dart';
import '../../state/entry_state.dart';
import '../../theme/app_theme.dart';

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
      builder: (ctx) => LogEntrySheet(babyId: babyId, initialType: type),
    );
  }

  @override
  State<LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<LogEntrySheet> {
  late String _type;

  // FEED state
  String _feedMethod = 'breast';
  String _breastSide = 'both';
  int _bottleMl = 120;
  final TextEditingController _foodController = TextEditingController();

  // DIAPER state
  String _diaperKind = 'wet';

  // GROWTH state
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _headController = TextEditingController();

  // MEDICINE state
  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _medDoseController = TextEditingController();
  bool _isVaccine = false;

  // NOTE state
  String _mood = 'happy';
  final TextEditingController _noteController = TextEditingController();

  final DateTime _startedAt = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
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

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final entryState = context.read<EntryState>();

    final Map<String, dynamic> data = {};
    DateTime? endedAt;

    if (_type == 'FEED') {
      data['method'] = _feedMethod;
      if (_feedMethod == 'breast') {
        data['side'] = _breastSide;
      } else if (_feedMethod == 'bottle') {
        data['amountMl'] = _bottleMl;
      } else if (_feedMethod == 'solids') {
        data['food'] = _foodController.text.trim();
      }
    } else if (_type == 'SLEEP') {
      // Completed nap or instant start
    } else if (_type == 'DIAPER') {
      data['kind'] = _diaperKind;
    } else if (_type == 'GROWTH') {
      if (_weightController.text.isNotEmpty) {
        data['weightKg'] = double.tryParse(_weightController.text);
      }
      if (_heightController.text.isNotEmpty) {
        data['heightCm'] = double.tryParse(_heightController.text);
      }
      if (_headController.text.isNotEmpty) {
        data['headCm'] = double.tryParse(_headController.text);
      }
    } else if (_type == 'MEDICINE') {
      data['name'] = _medNameController.text.trim();
      if (_medDoseController.text.isNotEmpty) {
        data['dose'] = _medDoseController.text.trim();
      }
      data['isVaccine'] = _isVaccine;
    } else if (_type == 'NOTE') {
      data['mood'] = _mood;
    }

    final success = await entryState.logEntry(
      babyId: widget.babyId,
      type: _type,
      startedAt: _startedAt,
      endedAt: endedAt,
      data: data,
      note: _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(entryState.error ?? 'Error saving entry')),
        );
      }
    }
  }

  Widget _buildTypeTabs(AppStrings s) {
    final types = [
      {'key': 'FEED', 'label': s.feed, 'emoji': '🍼'},
      {'key': 'SLEEP', 'label': s.sleep, 'emoji': '😴'},
      {'key': 'DIAPER', 'label': s.diaper, 'emoji': '🧷'},
      {'key': 'GROWTH', 'label': s.growth, 'emoji': '📏'},
      {'key': 'MEDICINE', 'label': s.medicine, 'emoji': '💊'},
      {'key': 'NOTE', 'label': s.note, 'emoji': '📝'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((t) {
          final isSelected = _type == t['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Text(t['emoji']!),
              label: Text(t['label']!),
              selected: isSelected,
              selectedColor: AppTheme.primaryLight,
              backgroundColor: const Color(0xFFF1F3F6),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryDark : AppTheme.textMain,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              onSelected: (val) {
                if (val) setState(() => _type = t['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedForm(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'breast', label: Text(s.breast)),
            ButtonSegment(value: 'bottle', label: Text(s.bottle)),
            ButtonSegment(value: 'solids', label: Text(s.solids)),
          ],
          selected: {_feedMethod},
          onSelectionChanged: (set) => setState(() => _feedMethod = set.first),
        ),
        const SizedBox(height: 16),
        if (_feedMethod == 'breast') ...[
          Text(s.side, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'left', label: Text(s.sideLeft)),
              ButtonSegment(value: 'right', label: Text(s.sideRight)),
              ButtonSegment(value: 'both', label: Text(s.sideBoth)),
            ],
            selected: {_breastSide},
            onSelectionChanged: (set) => setState(() => _breastSide = set.first),
          ),
        ] else if (_feedMethod == 'bottle') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.amountMl, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$_bottleMl ml', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          Slider(
            value: _bottleMl.toDouble(),
            min: 10,
            max: 360,
            divisions: 35,
            activeColor: AppTheme.primary,
            label: '$_bottleMl ml',
            onChanged: (v) => setState(() => _bottleMl = v.round()),
          ),
        ] else ...[
          TextField(
            controller: _foodController,
            decoration: InputDecoration(
              labelText: s.foodType,
              hintText: 'e.g. Avocado puree',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiaperForm(AppStrings s) {
    final kinds = [
      {'key': 'wet', 'label': s.diaperWet, 'emoji': '💧'},
      {'key': 'dirty', 'label': s.diaperDirty, 'emoji': '💩'},
      {'key': 'mixed', 'label': s.diaperMixed, 'emoji': '✨'},
      {'key': 'dry', 'label': s.diaperDry, 'emoji': '☁️'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kinds.map((k) {
        final isSelected = _diaperKind == k['key'];
        return InkWell(
          onTap: () => setState(() => _diaperKind = k['key']!),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.lavenderLight : const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.lavender : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(k['emoji']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  k['label']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.lavender : AppTheme.textMain,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrowthForm(AppStrings s) {
    return Column(
      children: [
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: s.weightKg,
            suffixText: 'kg',
            prefixIcon: const Icon(Icons.scale_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: s.heightCm,
            suffixText: 'cm',
            prefixIcon: const Icon(Icons.straighten_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _headController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: s.headCm,
            suffixText: 'cm',
            prefixIcon: const Icon(Icons.face_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineForm(AppStrings s) {
    return Column(
      children: [
        TextField(
          controller: _medNameController,
          decoration: InputDecoration(
            labelText: s.medicineName,
            hintText: 'e.g. Vitamin D, Novalac',
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
        const SizedBox(height: 8),
        CheckboxListTile(
          title: Text(s.isVaccine),
          value: _isVaccine,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primary,
          onChanged: (v) => setState(() => _isVaccine = v ?? false),
        ),
      ],
    );
  }

  Widget _buildNoteForm(AppStrings s) {
    final moods = [
      {'key': 'happy', 'emoji': '😊'},
      {'key': 'calm', 'emoji': '😌'},
      {'key': 'fussy', 'emoji': '😣'},
      {'key': 'crying', 'emoji': '😢'},
      {'key': 'sick', 'emoji': '🤒'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: moods.map((m) {
            final isSelected = _mood == m['key'];
            return InkWell(
              onTap: () => setState(() => _mood = m['key']!),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryLight : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(m['emoji']!, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            _buildTypeTabs(s),
            const SizedBox(height: 20),
            if (_type == 'FEED') _buildFeedForm(s),
            if (_type == 'SLEEP') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mintLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('😴', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.sleepAlertNotice,
                        style: TextStyle(color: Colors.teal.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_type == 'DIAPER') _buildDiaperForm(s),
            if (_type == 'GROWTH') _buildGrowthForm(s),
            if (_type == 'MEDICINE') _buildMedicineForm(s),
            if (_type == 'NOTE') _buildNoteForm(s),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: s.notesPlaceholder,
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(s.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
