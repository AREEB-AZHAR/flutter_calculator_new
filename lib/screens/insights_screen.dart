import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../services/monetization_service.dart';
import '../utils/constants.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: MonetizationService.isProUnlockedNotifier,
            builder: (context, isPro, _) {
              if (isPro) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('PRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                );
              }
              return TextButton.icon(
                icon: const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
                label: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                onPressed: () => MonetizationService.showPaywallModal(
                  context,
                  featureTitle: 'Smart Financial Intelligence',
                  featureDescription: 'Unlock predictive velocity, spending breakdowns, and an ad-free experience.',
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: MonetizationService.isProUnlockedNotifier,
        builder: (context, isPro, _) {
          if (!isPro) {
            return _buildProLockedPreview(context, theme);
          }

          return ValueListenableBuilder<String>(
            valueListenable: AppState.currencyNotifier,
            builder: (context, currentCurrency, _) {
              return ValueListenableBuilder<List<Transaction>>(
                valueListenable: AppState.transactionsNotifier,
                builder: (context, transactions, _) {
                  if (transactions.isEmpty) {
                    return Center(child: Text('Add some transactions to see insights!', style: TextStyle(color: onSurface.withValues(alpha: 0.6))));
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
                Text('Top Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                const SizedBox(height: 10),
                if (biggestExpense.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Icon(categoryIcons[biggestExpense.first.category] ?? Icons.receipt, color: Colors.redAccent, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(biggestExpense.first.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
                              Text(biggestExpense.first.category, style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                        Text('-${AppState.currencyNotifier.value}${biggestExpense.first.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
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
                              Icon(categoryIcons[entry.key] ?? Icons.category, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(entry.key, style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
                            ]),
                            Text('${AppState.currencyNotifier.value}${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(color: onSurface)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: pct,
                          backgroundColor: onSurface.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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
      );
    },
  );
        },
      ),
    );
  }

  Widget _insightCard(BuildContext context, String label, String value, IconData icon, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
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
          Text(label, style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProBenefit(IconData icon, String text, Color onSurface, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          Icon(Icons.check, size: 16, color: Colors.greenAccent.shade400),
        ],
      ),
    );
  }

  Widget _buildProLockedPreview(BuildContext context, ThemeData theme) {
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Pro Glowing Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'TALLY PRO EXCLUSIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'Smart Financial Intelligence',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Gain deep automated clarity over your wealth trajectory, category velocity, and personalized savings forecasting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: onSurface.withValues(alpha: 0.7),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 24),

          // Blurred / Mock Preview Card of Insights
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: onSurface.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.speed_rounded, size: 18, color: Colors.blueAccent),
                            const SizedBox(height: 6),
                            const Text('***', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            Text('Daily Velocity', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.savings_outlined, size: 18, color: Colors.greenAccent),
                            const SizedBox(height: 6),
                            const Text('***%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                            Text('Savings Trajectory', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Unlock Pro to reveal real-time analytics & automated spending drivers.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.85)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Features list
          _buildProBenefit(Icons.insights_rounded, 'Predictive Daily Velocity & Run Rate', onSurface, primary),
          _buildProBenefit(Icons.pie_chart_outline_rounded, 'Real-Time Category Spending Breakdowns', onSurface, primary),
          _buildProBenefit(Icons.compare_arrows_rounded, 'Month-over-Month Cash Flow Shifts', onSurface, primary),
          _buildProBenefit(Icons.block_rounded, '100% Ad-Free Experience Everywhere', onSurface, primary),
          _buildProBenefit(Icons.palette_outlined, 'Graphic Theme Studio & Custom Color Wheels', onSurface, primary),
          _buildProBenefit(Icons.touch_app_outlined, 'Custom Dynamic Launcher App Icons', onSurface, primary),

          const SizedBox(height: 28),

          // Primary Unlock Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => MonetizationService.showPaywallModal(
                context,
                featureTitle: 'Smart Financial Intelligence',
                featureDescription: 'Unlock predictive velocity, spending comparisons, custom themes, app icons, and remove all ads.',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Unlock Tally Pro — \$4.99',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Redeem Code Action
          TextButton.icon(
            icon: const Icon(Icons.vpn_key_outlined, size: 16),
            label: const Text('Have an unlock code? Redeem Promo'),
            onPressed: () => MonetizationService.showPromoCodeDialog(context),
            style: TextButton.styleFrom(
              foregroundColor: onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
