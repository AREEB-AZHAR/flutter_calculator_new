import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../services/state.dart';
import '../widgets/delete_confirmation_dialog.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showAddGoalDialog(BuildContext context) {
    String title = '';
    String targetStr = '';
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('New Savings Goal', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(labelText: 'Goal Name', labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6))),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: 15),
            TextField(
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(labelText: 'Target Amount (${AppState.currencyNotifier.value})', labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6))),
              keyboardType: TextInputType.number,
              onChanged: (v) => targetStr = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              final target = double.tryParse(targetStr);
              if (title.isNotEmpty && target != null && target > 0) {
                final goals = List<SavingsGoal>.from(AppState.goalsNotifier.value);
                goals.add(SavingsGoal(title: title, target: target));
                AppState.goalsNotifier.value = goals;
                if (AppState.currentUser != null) AppState.saveGoals(AppState.currentUser!, goals);
                Navigator.pop(ctx);
              }
            },
            child: Text('Create', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, SavingsGoal goal) {
    String amountStr = '';
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Add to "${goal.title}"', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        content: TextField(
          style: TextStyle(color: onSurface),
          decoration: InputDecoration(labelText: 'Amount (${AppState.currencyNotifier.value})', labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6))),
          keyboardType: TextInputType.number,
          onChanged: (v) => amountStr = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountStr);
              if (amount != null && amount > 0) {
                final goals = List<SavingsGoal>.from(AppState.goalsNotifier.value);
                final idx = goals.indexWhere((g) => g.id == goal.id);
                if (idx != -1) {
                  goals[idx].saved = (goals[idx].saved + amount).clamp(0, goals[idx].target);
                  AppState.goalsNotifier.value = List.from(goals);
                  if (AppState.currentUser != null) AppState.saveGoals(AppState.currentUser!, goals);
                }
                Navigator.pop(ctx);
              }
            },
            child: Text('Add', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals', style: TextStyle(fontWeight: FontWeight.bold)),
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
            return Center(child: Text('No goals yet. Tap + to create one!', style: TextStyle(color: onSurface.withValues(alpha: 0.6))));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: goals.length,
            itemBuilder: (ctx, index) {
              final goal = goals[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.flag, color: primary),
                          const SizedBox(width: 10),
                          Text(goal.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                        ]),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: 'Delete Goal',
                          onPressed: () async {
                            final confirmed = await showDeleteConfirmationDialog(
                              context: context,
                              title: 'Delete Goal?',
                              message: 'Are you sure you want to delete this savings goal?',
                              itemDetail: '${goal.title} • Target: ${AppState.currencyNotifier.value}${goal.target.toStringAsFixed(0)}',
                            );
                            if (confirmed && context.mounted) {
                              AppState.deleteGoalWithUndo(context, goal);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress ring
                    Center(
                      child: SizedBox(
                        width: 120, height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120, height: 120,
                              child: CircularProgressIndicator(
                                value: goal.progress,
                                strokeWidth: 10,
                                backgroundColor: onSurface.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(goal.progress >= 1.0 ? Colors.greenAccent : primary),
                              ),
                            ),
                            Text('${(goal.progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${AppState.currencyNotifier.value}${goal.saved.toStringAsFixed(0)} saved', style: const TextStyle(color: Colors.greenAccent)),
                        Text('${AppState.currencyNotifier.value}${goal.target.toStringAsFixed(0)} target', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Builder(
                        builder: (context) {
                          final btnBg = goal.progress >= 1.0 ? Colors.greenAccent : primary;
                          final btnFg = btnBg.computeLuminance() > 0.5 ? const Color(0xFF152A22) : Colors.white;
                          return ElevatedButton(
                            onPressed: goal.progress >= 1.0 ? null : () => _showAddFundsDialog(context, goal),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnBg,
                              foregroundColor: btnFg,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              goal.progress >= 1.0 ? '🎉 Goal Reached!' : 'Add Funds',
                              style: TextStyle(color: btnFg, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
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
}
