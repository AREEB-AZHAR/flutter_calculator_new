import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../utils/constants.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: AppState.transactionsNotifier,
        builder: (context, transactions, _) {
          if (transactions.isEmpty) {
            return const Center(child: Text('Add some transactions to see insights!', style: TextStyle(color: Colors.white54)));
          }

          final now = DateTime.now();
          final prevMonthDate = DateTime(now.year, now.month - 1);
          final thisMonth = transactions.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
          final lastMonth = transactions.where((t) => t.date.year == prevMonthDate.year && t.date.month == prevMonthDate.month).toList();

          final thisMonthExpense = thisMonth.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final lastMonthExpense = lastMonth.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final thisMonthIncome = thisMonth.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

          final daysElapsed = now.day;
          final dailyAvg = daysElapsed > 0 ? thisMonthExpense / daysElapsed : 0.0;

          final biggestExpense = thisMonth.where((t) => !t.isIncome).toList()
            ..sort((a, b) => b.amount.compareTo(a.amount));

          final savingsRate = thisMonthIncome > 0 ? ((thisMonthIncome - thisMonthExpense) / thisMonthIncome * 100).clamp(-100.0, 100.0) : 0.0;

          final spendingChange = lastMonthExpense > 0 ? ((thisMonthExpense - lastMonthExpense) / lastMonthExpense * 100) : 0.0;

          // Category breakdown
          final Map<String, double> catSpending = {};
          for (var t in thisMonth.where((t) => !t.isIncome)) {
            catSpending[t.category] = (catSpending[t.category] ?? 0) + t.amount;
          }
          final sortedCats = catSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards Row
                Row(
                  children: [
                    Expanded(child: _insightCard(context, 'Daily Avg', '${AppState.currencyNotifier.value}${dailyAvg.toStringAsFixed(0)}', Icons.calendar_today, const Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: _insightCard(context, 'Savings Rate', '${savingsRate.toStringAsFixed(0)}%', Icons.savings, savingsRate >= 0 ? Colors.greenAccent : Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _insightCard(context, 'This Month', '${AppState.currencyNotifier.value}${thisMonthExpense.toStringAsFixed(0)}', Icons.shopping_bag, Colors.orangeAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _insightCard(context, 'vs Last Month', '${spendingChange >= 0 ? '+' : ''}${spendingChange.toStringAsFixed(0)}%', Icons.trending_up, spendingChange <= 0 ? Colors.greenAccent : Colors.redAccent)),
                  ],
                ),

                const SizedBox(height: 24),
                const Text('Top Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                if (biggestExpense.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(categoryIcons[biggestExpense.first.category] ?? Icons.receipt, color: Colors.redAccent, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(biggestExpense.first.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(biggestExpense.first.category, style: const TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                        Text('-${AppState.currencyNotifier.value}${biggestExpense.first.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                ...sortedCats.map((entry) {
                  final pct = thisMonthExpense > 0 ? entry.value / thisMonthExpense : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Icon(categoryIcons[entry.key] ?? Icons.category, size: 16, color: Colors.white70),
                              const SizedBox(width: 8),
                              Text(entry.key, style: const TextStyle(color: Colors.white70)),
                            ]),
                            Text('${AppState.currencyNotifier.value}${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _insightCard(BuildContext context, String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accent)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}
