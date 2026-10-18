import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/baby_state.dart';
import '../../state/locale_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _titleController = TextEditingController();
  String _kind = 'AFTER_LAST'; // AFTER_LAST or DAILY_AT
  String _entryType = 'FEED';
  int _intervalHours = 3;
  TimeOfDay _timeOfDay = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final baby = context.read<BabyState>().currentBaby;
      if (baby != null) {
        context.read<ReminderState>().loadForBaby(baby.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    final s = context.read<LocaleState>().strings;
    final baby = context.read<BabyState>().currentBaby;
    if (baby == null) return;

    _titleController.text = _kind == 'AFTER_LAST'
        ? '${s.feed} - every $_intervalHours hours'
        : 'Vitamin D drops';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.card(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.addReminder,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'AFTER_LAST', label: Text(s.afterLastEntry)),
                  ButtonSegment(value: 'DAILY_AT', label: Text(s.dailyAtTime)),
                ],
                selected: {_kind},
                onSelectionChanged: (set) {
                  setModalState(() {
                    _kind = set.first;
                    _titleController.text = _kind == 'AFTER_LAST'
                        ? '${s.feed} - every $_intervalHours hours'
                        : 'Daily reminder';
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_kind == 'AFTER_LAST') ...[
                DropdownButtonFormField<String>(
                  initialValue: _entryType,
                  decoration: InputDecoration(labelText: s.reminderType),
                  items: [
                    DropdownMenuItem(value: 'FEED', child: Text('🍼 ${s.feed}')),
                    DropdownMenuItem(value: 'SLEEP', child: Text('😴 ${s.sleep}')),
                    DropdownMenuItem(value: 'DIAPER', child: Text('🧷 ${s.diaper}')),
                    DropdownMenuItem(value: 'MEDICINE', child: Text('💊 ${s.medicine}')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => _entryType = v);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.hoursInterval, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('$_intervalHours hours', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
                Slider(
                  value: _intervalHours.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  label: '$_intervalHours hrs',
                  activeColor: AppTheme.primary,
                  onChanged: (v) {
                    setModalState(() => _intervalHours = v.round());
                  },
                ),
              ] else ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.divider),
                  ),
                  tileColor: const Color(0xFFF4F6F9),
                  leading: Icon(Icons.alarm, color: AppTheme.primary),
                  title: Text(s.timeOfDay),
                  subtitle: Text(_timeOfDay.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showTimePicker(context: ctx, initialTime: _timeOfDay);
                    if (picked != null) {
                      setModalState(() => _timeOfDay = picked);
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: s.reminderTitle,
                  prefixIcon: const Icon(Icons.notifications_active_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final remState = context.read<ReminderState>();
                    await remState.createReminder(
                      babyId: baby.id,
                      kind: _kind,
                      title: _titleController.text.trim(),
                      entryType: _kind == 'AFTER_LAST' ? _entryType : null,
                      intervalMinutes: _kind == 'AFTER_LAST' ? _intervalHours * 60 : null,
                      timeOfDay: _kind == 'DAILY_AT' ? _timeOfDay.hour * 60 + _timeOfDay.minute : null,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(s.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final baby = context.watch<BabyState>().currentBaby;
    final remState = context.watch<ReminderState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.remindersTitle),
        actions: [
          if (baby != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddDialog,
            ),
        ],
      ),
      floatingActionButton: baby != null
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_alarm),
              label: Text(s.addReminder),
            )
          : null,
      body: baby == null
          ? Center(child: Text(s.noBabiesYet))
          : remState.reminders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⏰', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          s.noRemindersSet,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.remindersHelp,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add),
                          label: Text(s.addReminder),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: remState.reminders.length,
                  itemBuilder: (ctx, i) {
                    final r = remState.reminders[i];
                    final isAfter = r.kind == 'AFTER_LAST';
                    final h = (r.intervalMinutes ?? 0) ~/ 60;
                    final timeFormatted = '${(r.timeOfDay ?? 0) ~/ 60}:${((r.timeOfDay ?? 0) % 60).toString().padLeft(2, '0')}';

                    final subText = isAfter
                        ? (s.isHe ? 'כל $h שעות לאחר הרישום האחרון' : 'Every ${h}h after last event')
                        : (s.isHe ? 'בכל יום בשעה $timeFormatted' : 'Daily at $timeFormatted');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.line(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isAfter ? AppTheme.sunLight : AppTheme.lavenderLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isAfter ? '⏳' : '⏰',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.ink(context)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subText,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                            tooltip: s.delete,
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(s.confirmDeleteReminderTitle),
                                  content: Text(s.confirmDeleteReminderContent),
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
                              if (confirmed == true && context.mounted) {
                                await remState.deleteReminder(baby.id, r.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(s.reminderDeletedSuccess),
                                      backgroundColor: AppTheme.mint,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
