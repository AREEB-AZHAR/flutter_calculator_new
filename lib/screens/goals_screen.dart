import 'dart:math';
import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../models/goal_entry.dart';
import '../services/state.dart';
import '../utils/constants.dart';
import '../widgets/delete_confirmation_dialog.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Set<String> _expandedGoals = {};

  // ────────────────────────────────────────────────────────────────
  // Create / Add Goal Dialog
  // ────────────────────────────────────────────────────────────────
  void _showAddGoalDialog(BuildContext context) {
    String title = '';
    String targetStr = '';
    DateTime? dueDate;
    String periodType = 'monthly';
    bool isRecurring = false;
    String recurrence = 'none';
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('New Savings Goal', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    labelText: 'Goal Name',
                    labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.flag_outlined, color: primary, size: 20),
                  ),
                  onChanged: (v) => title = v,
                ),
                const SizedBox(height: 14),
                TextField(
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    labelText: 'Target Amount (${AppState.currencyNotifier.value})',
                    labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.savings_outlined, color: primary, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => targetStr = v,
                ),
                const SizedBox(height: 18),

                // Due Date Quick Chips
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Due Date', style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _dueDateChip('Today', () {
                      setDialogState(() {
                        dueDate = DateTime.now();
                        periodType = 'daily';
                      });
                    }, dueDate != null && periodType == 'daily', primary, onSurface),
                    _dueDateChip('1 Week', () {
                      setDialogState(() {
                        dueDate = DateTime.now().add(const Duration(days: 7));
                        periodType = 'weekly';
                      });
                    }, periodType == 'weekly', primary, onSurface),
                    _dueDateChip('1 Month', () {
                      setDialogState(() {
                        final now = DateTime.now();
                        dueDate = DateTime(now.year, now.month + 1, now.day);
                        periodType = 'monthly';
                      });
                    }, periodType == 'monthly' && dueDate != null, primary, onSurface),
                    _dueDateChip('Custom', () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          dueDate = picked;
                          periodType = 'custom';
                        });
                      }
                    }, periodType == 'custom', primary, onSurface),
                    _dueDateChip('No Date', () {
                      setDialogState(() {
                        dueDate = null;
                        periodType = 'monthly';
                      });
                    }, dueDate == null && periodType == 'monthly', primary, onSurface),
                  ],
                ),
                if (dueDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event, size: 16, color: primary),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${formatDateWithYear(dueDate!)}',
                          style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Recurrence Toggle
                Row(
                  children: [
                    Icon(Icons.repeat, size: 18, color: onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text('Recurring Goal', style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch.adaptive(
                      value: isRecurring,
                      activeTrackColor: primary,
                      onChanged: (val) => setDialogState(() {
                        isRecurring = val;
                        if (val && recurrence == 'none') {
                          recurrence = periodType == 'daily' ? 'daily' : (periodType == 'weekly' ? 'weekly' : 'monthly');
                        }
                        if (!val) recurrence = 'none';
                      }),
                    ),
                  ],
                ),
                if (isRecurring) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['daily', 'weekly', 'monthly'].map((r) => ChoiceChip(
                      label: Text(r[0].toUpperCase() + r.substring(1), style: TextStyle(color: recurrence == r ? Colors.white : onSurface, fontSize: 12)),
                      selected: recurrence == r,
                      selectedColor: primary,
                      backgroundColor: theme.colorScheme.surface,
                      side: BorderSide(color: onSurface.withValues(alpha: 0.15)),
                      onSelected: (sel) => setDialogState(() => recurrence = sel ? r : 'none'),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
            ),
            ElevatedButton(
              onPressed: () {
                final target = double.tryParse(targetStr);
                if (title.isNotEmpty && target != null && target > 0) {
                  final goal = SavingsGoal(
                    title: title,
                    target: target,
                    dueDate: dueDate,
                    periodType: periodType,
                    isRecurring: isRecurring,
                    recurrence: isRecurring ? recurrence : 'none',
                  );
                  final goals = List<SavingsGoal>.from(AppState.goalsNotifier.value);
                  goals.add(goal);
                  AppState.goalsNotifier.value = goals;
                  if (AppState.currentUser != null) AppState.saveGoals(AppState.currentUser!, goals);
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dueDateChip(String label, VoidCallback onTap, bool selected, Color primary, Color onSurface) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? primary : onSurface.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: TextStyle(color: selected ? primary : onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Add Funds Dialog
  // ────────────────────────────────────────────────────────────────
  void _showAddFundsDialog(BuildContext context, SavingsGoal goal) {
    String amountStr = '';
    String note = '';
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Deposit to "${goal.title}"', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Amount (${AppState.currencyNotifier.value})',
                labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.attach_money, color: primary, size: 20),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => amountStr = v,
            ),
            const SizedBox(height: 12),
            TextField(
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.note_outlined, color: onSurface.withValues(alpha: 0.4), size: 20),
              ),
              onChanged: (v) => note = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountStr);
              if (amount != null && amount > 0 && AppState.currentUser != null) {
                final entry = GoalEntry(
                  goalId: goal.id,
                  amount: amount,
                  note: note.isNotEmpty ? note : null,
                );
                AppState.addGoalEntry(AppState.currentUser!, entry);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Goal Detail Bottom Sheet
  // ────────────────────────────────────────────────────────────────
  void _showGoalDetailSheet(BuildContext context, SavingsGoal goal) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final currency = AppState.currencyNotifier.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => ValueListenableBuilder<List<SavingsGoal>>(
          valueListenable: AppState.goalsNotifier,
          builder: (ctx, goals, _) {
            final currentGoal = goals.firstWhere((g) => g.id == goal.id, orElse: () => goal);
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Status
                  Row(
                    children: [
                      Icon(currentGoal.icon, color: primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentGoal.title,
                              style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold, color: onSurface,
                                decoration: (currentGoal.isFailed || currentGoal.isCompleted)
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: currentGoal.isFailed ? Colors.redAccent : Colors.greenAccent,
                              ),
                            ),
                            if (currentGoal.isCompleted)
                              Text('🎉 Goal Completed!', style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                            if (currentGoal.isFailed)
                              Text('❌ Goal Expired', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Donut Chart
                  Center(
                    child: SizedBox(
                      width: 160, height: 160,
                      child: CustomPaint(
                        painter: _DonutChartPainter(
                          progress: currentGoal.progress,
                          primaryColor: currentGoal.isCompleted ? Colors.greenAccent : (currentGoal.isFailed ? Colors.redAccent : primary),
                          trackColor: onSurface.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(currentGoal.progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface),
                              ),
                              Text(
                                '$currency${currentGoal.saved.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 14, color: Colors.greenAccent, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'of $currency${currentGoal.target.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pacing info: Shown for all active goals
                  if (currentGoal.isActive) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.speed, size: 18, color: primary),
                              const SizedBox(width: 8),
                              Text('Pacing', style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(
                                currentGoal.remainingToSave <= 0
                                    ? 'Target Met'
                                    : '$currency${currentGoal.remainingToSave.toStringAsFixed(0)} left',
                                style: TextStyle(
                                  color: currentGoal.remainingToSave <= 0 ? Colors.greenAccent : primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Due: ${formatDateWithYear(currentGoal.effectiveDueDate)} · ${currentGoal.daysRemaining} day${currentGoal.daysRemaining == 1 ? '' : 's'} left',
                            style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentGoal.remainingToSave <= 0
                                ? '🎉 Target reached! Stash more if you wish.'
                                : (currentGoal.daysRemaining <= 1 || currentGoal.isDueToday
                                    ? 'Save $currency${currentGoal.remainingToSave.toStringAsFixed(0)} today to reach target'
                                    : 'Save $currency${currentGoal.dailySavingsNeeded.toStringAsFixed(0)}/day to reach target on time'),
                            style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Recurring badge
                  if (currentGoal.isRecurring)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.repeat, size: 18, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            'Recurring: ${currentGoal.recurrence[0].toUpperCase()}${currentGoal.recurrence.substring(1)}',
                            style: const TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                  // Failed + recurring: Start New Cycle
                  if (currentGoal.isFailed && currentGoal.isRecurring)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (AppState.currentUser == null) return;
                          final newGoal = currentGoal.startNewCycle();
                          final goals = List<SavingsGoal>.from(AppState.goalsNotifier.value);
                          // Archive the old one
                          final idx = goals.indexWhere((g) => g.id == currentGoal.id);
                          if (idx != -1) goals[idx] = currentGoal.copyWith(isArchived: true);
                          goals.add(newGoal);
                          AppState.goalsNotifier.value = goals;
                          AppState.saveGoals(AppState.currentUser!, goals);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Start New Cycle', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ),

                  // Contribution Entries
                  Row(
                    children: [
                      Text('Contributions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
                      const Spacer(),
                      Text('${currentGoal.entries.length} entries', style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (currentGoal.entries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No contributions yet', style: TextStyle(color: onSurface.withValues(alpha: 0.4))),
                      ),
                    )
                  else
                    ...currentGoal.entries.map((entry) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('+$currency${entry.amount.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(
                                      '${formatDateWithYear(entry.date)}${entry.note != null ? ' · ${entry.note}' : ''}',
                                      style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Edit
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 16, color: onSurface.withValues(alpha: 0.4)),
                                onPressed: () => _showEditEntryDialog(context, currentGoal, entry),
                              ),
                              // Delete
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                onPressed: () async {
                                  if (AppState.currentUser == null) return;
                                  final confirmed = await showDeleteConfirmationDialog(
                                    context: context,
                                    title: 'Delete Entry?',
                                    message: 'Remove this $currency${entry.amount.toStringAsFixed(0)} deposit?',
                                  );
                                  if (confirmed) {
                                    AppState.deleteGoalEntry(AppState.currentUser!, entry.id, entry.goalId);
                                  }
                                },
                              ),
                            ],
                          ),
                        )),

                  const SizedBox(height: 16),

                  // Add Deposit button
                  if (currentGoal.isActive)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddFundsDialog(context, currentGoal);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditEntryDialog(BuildContext context, SavingsGoal goal, GoalEntry entry) {
    final amountCtrl = TextEditingController(text: entry.amount.toString());
    final noteCtrl = TextEditingController(text: entry.note ?? '');
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Entry', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Note',
                labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount != null && amount > 0 && AppState.currentUser != null) {
                final updated = entry.copyWith(
                  amount: amount,
                  note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                );
                AppState.updateGoalEntry(AppState.currentUser!, updated);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: AppState.currencyNotifier,
        builder: (context, currentCurrency, _) {
          return ValueListenableBuilder<List<SavingsGoal>>(
            valueListenable: AppState.goalsNotifier,
            builder: (context, goals, _) {
              if (goals.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings_outlined, size: 60, color: onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No savings goals yet', style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Tap + to create your first goal!', style: TextStyle(color: onSurface.withValues(alpha: 0.35), fontSize: 13)),
                    ],
                  ),
                );
              }

              // Separate active and completed/failed goals
              final activeGoals = goals.where((g) => g.isActive).toList();
              final endedGoals = goals.where((g) => !g.isActive).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                children: [
                  // Vault Summary Header
                  _buildVaultSummary(context, goals, currentCurrency),
                  const SizedBox(height: 20),

                  if (activeGoals.isNotEmpty) ...[
                    Text('Active Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 12),
                    ...activeGoals.map((g) => _buildGoalCard(context, g, currentCurrency)),
                  ],
                  if (endedGoals.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Completed & Expired', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 12),
                    ...endedGoals.map((g) => _buildGoalCard(context, g, currentCurrency)),
                  ],
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final fabBg = theme.colorScheme.primary;
          final fabFg = fabBg.computeLuminance() > 0.5 ? const Color(0xFF152A22) : Colors.white;
          return FloatingActionButton(
            onPressed: () => _showAddGoalDialog(context),
            backgroundColor: fabBg,
            foregroundColor: fabFg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.add, color: fabFg),
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Vault Summary Card
  // ────────────────────────────────────────────────────────────────
  Widget _buildVaultSummary(BuildContext context, List<SavingsGoal> goals, String currency) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final totalStashed = goals.fold(0.0, (sum, g) => sum + g.saved);
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.target);
    final activeCount = goals.where((g) => g.isActive).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [theme.colorScheme.surface, primary.withValues(alpha: 0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, size: 20, color: primary),
              const SizedBox(width: 8),
              Text('Savings Vault', style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency${totalStashed.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'of $currency${totalTarget.toStringAsFixed(0)} across $activeCount active goal${activeCount == 1 ? '' : 's'}',
            style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 13),
          ),
          if (totalTarget > 0) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (totalStashed / totalTarget).clamp(0.0, 1.0),
              backgroundColor: onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Goal Card
  // ────────────────────────────────────────────────────────────────
  Widget _buildGoalCard(BuildContext context, SavingsGoal goal, String currency) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final isExpanded = _expandedGoals.contains(goal.id);

    return GestureDetector(
      onTap: () => _showGoalDetailSheet(context, goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon, title, status, delete
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(goal.icon, color: primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: onSurface,
                          decoration: (goal.isFailed || goal.isCompleted)
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: goal.isFailed ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ),
                      if (goal.isCompleted)
                        const Text('🎉 Completed', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                      if (goal.isFailed)
                        const Text('❌ Expired', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                      if (goal.isRecurring)
                        Row(
                          children: [
                            const Icon(Icons.repeat, size: 12, color: Colors.teal),
                            const SizedBox(width: 4),
                            Text(goal.recurrence[0].toUpperCase() + goal.recurrence.substring(1),
                                style: const TextStyle(color: Colors.teal, fontSize: 11)),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  tooltip: 'Delete Goal',
                  onPressed: () async {
                    final confirmed = await showDeleteConfirmationDialog(
                      context: context,
                      title: 'Delete Goal?',
                      message: 'Are you sure you want to delete this savings goal?',
                      itemDetail: '${goal.title} · Target: $currency${goal.target.toStringAsFixed(0)}',
                    );
                    if (confirmed && context.mounted) {
                      AppState.deleteGoalWithUndo(context, goal);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar + numbers with explicit Remaining Left badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '$currency${goal.saved.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'of $currency${goal.target.toStringAsFixed(0)}',
                      style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: goal.remainingToSave <= 0
                        ? Colors.greenAccent.withValues(alpha: 0.15)
                        : primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: goal.remainingToSave <= 0
                          ? Colors.greenAccent.withValues(alpha: 0.3)
                          : primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    goal.remainingToSave <= 0
                        ? '🎉 Target Met'
                        : '$currency${goal.remainingToSave.toStringAsFixed(0)} left',
                    style: TextStyle(
                      color: goal.remainingToSave <= 0 ? Colors.greenAccent : primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isCompleted ? Colors.greenAccent : (goal.isFailed ? Colors.redAccent : primary),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text('${(goal.progress * 100).toStringAsFixed(0)}% complete', style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12)),

            // Pacing badge: Shown for all active goals
            if (goal.isActive) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.speed, size: 14, color: primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        goal.remainingToSave <= 0
                            ? '🎉 Target Reached!'
                            : (goal.daysRemaining <= 1 || goal.isDueToday
                                ? 'Save $currency${goal.remainingToSave.toStringAsFixed(0)} today · Due Today'
                                : 'Save $currency${goal.dailySavingsNeeded.toStringAsFixed(0)}/day · ${goal.daysRemaining}d left'),
                        style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Collapsible Recent Entries
            if (goal.entries.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedGoals.remove(goal.id);
                  } else {
                    _expandedGoals.add(goal.id);
                  }
                }),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18, color: onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpanded ? 'Hide entries' : 'Recent ${min(2, goal.entries.length)} entries',
                      style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isExpanded)
                ...goal.entries.take(2).map((e) => Padding(
                      padding: const EdgeInsets.only(top: 6, left: 22),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('+$currency${e.amount.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Text(formatDate(e.date), style: TextStyle(color: onSurface.withValues(alpha: 0.35), fontSize: 11)),
                          if (e.note != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(e.note!, style: TextStyle(color: onSurface.withValues(alpha: 0.3), fontSize: 11), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ],
                      ),
                    )),
            ],

            // Add funds button for active goals
            if (goal.isActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Builder(
                  builder: (context) {
                    final btnBg = goal.progress >= 1.0 ? Colors.greenAccent : primary;
                    final btnFg = btnBg.computeLuminance() > 0.5 ? const Color(0xFF152A22) : Colors.white;
                    return ElevatedButton.icon(
                      onPressed: goal.progress >= 1.0 ? null : () => _showAddFundsDialog(context, goal),
                      icon: Icon(goal.progress >= 1.0 ? Icons.check : Icons.add, size: 18, color: btnFg),
                      label: Text(
                        goal.progress >= 1.0 ? 'Goal Reached!' : 'Add Deposit',
                        style: TextStyle(color: btnFg, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnBg,
                        foregroundColor: btnFg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Start New Cycle for failed recurring goals
            if (goal.isFailed && goal.isRecurring) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (AppState.currentUser == null) return;
                    final newGoal = goal.startNewCycle();
                    final goals = List<SavingsGoal>.from(AppState.goalsNotifier.value);
                    final idx = goals.indexWhere((g) => g.id == goal.id);
                    if (idx != -1) goals[idx] = goal.copyWith(isArchived: true);
                    goals.add(newGoal);
                    AppState.goalsNotifier.value = goals;
                    AppState.saveGoals(AppState.currentUser!, goals);
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Start New Cycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.teal),
                    foregroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Donut Chart Painter for Goal Detail Sheet
// ────────────────────────────────────────────────────────────────
class _DonutChartPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;

  _DonutChartPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const strokeWidth = 14.0;

    // Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = primaryColor
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.primaryColor != primaryColor;
}