import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/baby_state.dart';
import '../../state/locale_state.dart';
import '../../state/theme_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/string_utils.dart';

class CreateBabyScreen extends StatefulWidget {
  const CreateBabyScreen({super.key});

  @override
  State<CreateBabyScreen> createState() => _CreateBabyScreenState();
}

class _CreateBabyScreenState extends State<CreateBabyScreen> {
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  String _avatarColor = '#FF7A7A';
  bool _isSaving = false;

  final List<String> _colors = [
    '#FF7A7A', // Warm coral
    '#F7A8C4', // Soft rose pink
    '#48C78E', // Mint
    '#8C7AE6', // Lavender
    '#3897F0', // Sky blue
    '#FFAA00', // Sun yellow
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _saveBaby() async {
    final s = context.read<LocaleState>().strings;
    final babyState = context.read<BabyState>();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.babyName)),
      );
      return;
    }

    final formattedName = formatName(name);

    setState(() => _isSaving = true);
    final success = await babyState.createBaby(
      name: formattedName,
      birthDate: _birthDate,
      gender: _gender,
      avatarColor: _avatarColor,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        context.read<ThemeState>().setColorHex(_avatarColor);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(babyState.error ?? s.errorOccurred)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.addBaby),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: s.babyName,
                  hintText: s.isHe ? 'לדוגמה: מיה, ליאם, אייר' : 'e.g. Mia, Liam, Maya',
                  prefixIcon: const Icon(Icons.child_care),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.divider),
                ),
                tileColor: const Color(0xFFF4F6F9),
                leading: const Icon(Icons.cake_outlined, color: AppTheme.defaultPrimary),
                title: Text(s.birthDate),
                subtitle: Text(
                  _birthDate == null
                      ? s.selectDate
                      : DateFormat.yMMMMd().format(_birthDate!),
                  style: TextStyle(
                    color: _birthDate == null ? AppTheme.textMuted : AppTheme.textMain,
                    fontWeight: _birthDate == null ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              const SizedBox(height: 18),
              Text(s.gender, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _gender == 'girl' ? const Color(0xFFFFECEB) : null,
                        side: BorderSide(
                          color: _gender == 'girl' ? AppTheme.primary : AppTheme.divider,
                        ),
                      ),
                      onPressed: () => setState(() => _gender = 'girl'),
                      child: Text('👧 ${s.girl}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _gender == 'boy' ? const Color(0xFFEBF4FF) : null,
                        side: BorderSide(
                          color: _gender == 'boy' ? AppTheme.sky : AppTheme.divider,
                        ),
                      ),
                      onPressed: () => setState(() => _gender = 'boy'),
                      child: Text('👦 ${s.boy}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(s.avatarColor, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _colors.map((hex) {
                  final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                  final isSelected = _avatarColor == hex;
                  return InkWell(
                    onTap: () => setState(() => _avatarColor = hex),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Colors.white,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBaby,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(s.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
