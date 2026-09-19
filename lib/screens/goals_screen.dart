import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../services/state.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showAddGoalDialog(BuildContext context) {
    String title = '';
    String targetStr = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('New Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Goal Name'),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: 15),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Target Amount (\$)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => targetStr = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, SavingsGoal goal) {
    String amountStr = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Add to "${goal.title}"'),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Amount (\$)'),
          keyboardType: TextInputType.number,
          onChanged: (v) => amountStr = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<SavingsGoal>>(
        valueListenable: AppState.goalsNotifier,
        builder: (context, goals, _) {
          if (goals.isEmpty) {
            return const Center(child: Text('No goals yet. Tap + to create one!', style: TextStyle(color: Colors.white54)));
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Icon(Icons.flag, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 10),
                          Text(goal.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            final g = List<SavingsGoal>.from(AppState.goalsNotifier.value);
                            g.removeWhere((x) => x.id == goal.id);
                            AppState.goalsNotifier.value = g;
                            if (AppState.currentUser != null) AppState.saveGoals(AppState.currentUser!, g);
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
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(goal.progress >= 1.0 ? Colors.greenAccent : const Color(0xFF8B5CF6)),
                              ),
                            ),
                            Text('${(goal.progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${AppState.currencyNotifier.value}${goal.saved.toStringAsFixed(0)} saved', style: const TextStyle(color: Colors.greenAccent)),
                        Text('${AppState.currencyNotifier.value}${goal.target.toStringAsFixed(0)} target', style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: goal.progress >= 1.0 ? null : () => _showAddFundsDialog(context, goal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goal.progress >= 1.0 ? Colors.greenAccent : const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(goal.progress >= 1.0 ? '🎉 Goal Reached!' : 'Add Funds', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
