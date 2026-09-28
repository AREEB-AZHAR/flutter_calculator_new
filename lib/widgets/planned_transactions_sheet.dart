import 'package:flutter/material.dart';
import '../models/planned_transaction.dart';
import '../services/state.dart';
import '../utils/constants.dart';

Future<void> showPlannedTransactionsSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const PlannedTransactionsSheet(),
  );
}

class PlannedTransactionsSheet extends StatelessWidget {
  const PlannedTransactionsSheet({super.key});

  String _formatCountdown(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final isLight = theme.brightness == Brightness.light;
    final positiveColor = isLight ? const Color(0xFF059669) : const Color(0xFF10B981);
    final negativeColor = isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171);
    final planAccent = isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24);

    return ValueListenableBuilder<String>(
      valueListenable: AppState.currencyNotifier,
      builder: (context, currency, _) {
        return ValueListenableBuilder<List<PlannedTransaction>>(
          valueListenable: AppState.plannedTransactionsNotifier,
          builder: (context, plans, _) {
            double totalPlannedIncome = 0;
            double totalPlannedExpense = 0;
            for (var p in plans) {
              if (p.isIncome) {
                totalPlannedIncome += p.amount;
              } else {
                totalPlannedExpense += p.amount;
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: onSurface.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: planAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.event_note_rounded, color: planAccent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Planned & Future Sheet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: onSurface,
                                  ),
                                ),
                                Text(
                                  'Auto-posts on set date without affecting current balance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Summary strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Planned Inflow', style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.6))),
                              Text('+$currency${totalPlannedIncome.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: positiveColor)),
                            ],
                          ),
                          Container(height: 24, width: 1, color: onSurface.withValues(alpha: 0.1)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Planned Outflow', style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.6))),
                              Text('-$currency${totalPlannedExpense.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: negativeColor)),
                            ],
                          ),
                          Container(height: 24, width: 1, color: onSurface.withValues(alpha: 0.1)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pending Total', style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.6))),
                              Text('${plans.length} items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // List of Planned Transactions
                  Expanded(
                    child: plans.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_month_rounded, size: 56, color: onSurface.withValues(alpha: 0.25)),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No Planned Future Transactions',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'When adding a transaction with a future date, turn on "Future Planning" to stage it here without altering your active ledger balance.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: plans.length,
                            itemBuilder: (ctx, i) {
                              final plan = plans[i];
                              final isIncome = plan.isIncome;
                              final countdown = _formatCountdown(plan.date);
                              final isDue = countdown == 'Due Today' || countdown == 'Overdue';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDue
                                        ? planAccent.withValues(alpha: 0.4)
                                        : onSurface.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: (isIncome ? positiveColor : negativeColor).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        categoryIcons[plan.category] ?? Icons.category,
                                        color: isIncome ? positiveColor : negativeColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  plan.title,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDue
                                                      ? planAccent.withValues(alpha: 0.2)
                                                      : primary.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  countdown,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDue ? planAccent : primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                formatDateWithYear(plan.date),
                                                style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                                              ),
                                              if (plan.recurrence != 'None') ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: onSurface.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '↻ ${plan.recurrence}',
                                                    style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.7)),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              Text(
                                                '• ${plan.account}',
                                                style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isIncome ? '+' : '-'}$currency${plan.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isIncome ? positiveColor : negativeColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Post Now Action
                                            InkWell(
                                              onTap: () {
                                                if (AppState.currentUser != null) {
                                                  AppState.executePlannedTransactionNow(AppState.currentUser!, plan);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('"${plan.title}" posted to active transactions!'),
                                                      backgroundColor: Colors.teal,
                                                    ),
                                                  );
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: Icon(Icons.check_circle_outline_rounded, size: 20, color: positiveColor.withValues(alpha: 0.8)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Delete Action
                                            InkWell(
                                              onTap: () {
                                                if (AppState.currentUser != null) {
                                                  AppState.deletePlannedTransaction(AppState.currentUser!, plan.id);
                                                  AppState.showAutoDismissingSnackBar(
                                                    context,
                                                    SnackBar(
                                                      content: Text('Planned transaction "${plan.title}" removed'),
                                                      duration: const Duration(seconds: 5),
                                                    ),
                                                  );
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent.withValues(alpha: 0.8)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
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
  }
}
