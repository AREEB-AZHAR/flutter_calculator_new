import 'dart:math';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../services/state.dart';
import '../services/monetization_service.dart';
import '../services/insights_engine.dart';
import '../utils/constants.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  TimeHorizon _selectedHorizon = TimeHorizon.monthly;
  int _periodOffset = 0; // 0 = current, -1 = previous, etc.

  void _changeHorizon(TimeHorizon horizon) {
    if (_selectedHorizon != horizon) {
      setState(() {
        _selectedHorizon = horizon;
        _periodOffset = 0; // reset offset when switching horizon
      });
    }
  }

  void _stepPeriod(int delta) {
    setState(() {
      _periodOffset += delta;
      // Do not allow stepping beyond current period
      if (_periodOffset > 0) _periodOffset = 0;
    });
  }

  void _resetToCurrent() {
    setState(() {
      _periodOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              'Personal Wealth Intelligence',
              style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.normal),
            ),
          ],
        ),
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
                    color: Colors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('PRO ACTIVE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                );
              }
              return TextButton.icon(
                icon: const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
                label: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                onPressed: () => MonetizationService.showPaywallModal(
                  context,
                  featureTitle: 'Executive Wealth Intelligence',
                  featureDescription: 'Unlock AI personal accountant briefings, debt payoff strategies, tax deductions tracker, and multi-horizon analytics.',
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
                    return Center(
                      child: Text(
                        'Add some transactions to see insights!',
                        style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                      ),
                    );
                  }
                  return ValueListenableBuilder<List<Loan>>(
                    valueListenable: AppState.loansNotifier,
                    builder: (context, loans, _) {
                      return ValueListenableBuilder<Map<String, double>>(
                        valueListenable: AppState.budgetsNotifier,
                        builder: (context, budgets, _) {
                          final report = InsightsEngine.generateReport(
                            transactions: transactions,
                            loans: loans,
                            budgets: budgets,
                            horizon: _selectedHorizon,
                            periodOffset: _periodOffset,
                          );

                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHorizonSelector(theme),
                                const SizedBox(height: 12),
                                _buildPeriodNavigator(theme, report),
                                const SizedBox(height: 16),
                                _buildAccountantBriefCard(theme, report),
                                const SizedBox(height: 16),
                                _buildVelocitySummaryGrid(theme, report, currentCurrency),
                                const SizedBox(height: 20),
                                _build503020PlanningCard(theme, report, currentCurrency),
                                const SizedBox(height: 20),
                                _buildCategoryMatrix(theme, report, currentCurrency),
                                const SizedBox(height: 20),
                                _buildLoansAndDebtCard(theme, report, currentCurrency),
                                const SizedBox(height: 20),
                                _buildTaxIntelligenceCard(theme, report, currentCurrency),
                                const SizedBox(height: 20),
                                _buildPaymentTypeCard(theme, report, currentCurrency),
                                const SizedBox(height: 32),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHorizonSelector(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    final horizons = [
      (TimeHorizon.daily, 'Daily'),
      (TimeHorizon.weekly, 'Weekly'),
      (TimeHorizon.monthly, 'Monthly'),
      (TimeHorizon.yearly, 'Yearly'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: horizons.map((h) {
          final isSelected = _selectedHorizon == h.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeHorizon(h.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    h.$2,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.onPrimary : onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodNavigator(ThemeData theme, InsightsReport report) {
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: () => _stepPeriod(-1),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                report.periodLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (_periodOffset != 0)
                GestureDetector(
                  onTap: _resetToCurrent,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Back to Current',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: _periodOffset < 0 ? () => _stepPeriod(1) : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildAccountantBriefCard(ThemeData theme, InsightsReport report) {
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    Color scoreColor;
    if (report.healthScore.score >= 80) {
      scoreColor = Colors.greenAccent.shade400;
    } else if (report.healthScore.score >= 60) {
      scoreColor = Colors.lightBlueAccent;
    } else if (report.healthScore.score >= 45) {
      scoreColor = Colors.amberAccent;
    } else {
      scoreColor = Colors.redAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Executive Accountant's Take",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      'Automated CPA Financial Assessment',
                      style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${report.healthScore.score}/100',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scoreColor),
                    ),
                    Text(
                      report.healthScore.rating,
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: scoreColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.accountantSummary,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: onSurface.withValues(alpha: 0.88),
            ),
          ),
          if (report.accountantKeyActionItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'Accountant Action Items',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...report.accountantKeyActionItems.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right, size: 18, color: primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              action,
                              style: TextStyle(fontSize: 12, height: 1.35, color: onSurface.withValues(alpha: 0.8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVelocitySummaryGrid(ThemeData theme, InsightsReport report, String currency) {
    final savingsRateColor = report.savingsRate >= 20
        ? Colors.greenAccent.shade400
        : (report.savingsRate >= 0 ? Colors.tealAccent : Colors.redAccent);

    final changeSign = report.spendingChangePercent >= 0 ? '+' : '';
    final changeColor = report.spendingChangePercent <= 0 ? Colors.greenAccent.shade400 : Colors.redAccent;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                theme: theme,
                title: 'Total Inflow',
                value: '$currency${report.totalInflow.toStringAsFixed(0)}',
                subtitle: 'Income this period',
                icon: Icons.trending_up,
                accentColor: Colors.greenAccent.shade400,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                theme: theme,
                title: 'Total Outflow',
                value: '$currency${report.totalOutflow.toStringAsFixed(0)}',
                subtitle: 'Expenses logged',
                icon: Icons.trending_down,
                accentColor: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                theme: theme,
                title: 'Net Savings',
                value: '${report.netSavings >= 0 ? '+' : ''}$currency${report.netSavings.toStringAsFixed(0)}',
                subtitle: 'Savings Rate: ${report.savingsRate.toStringAsFixed(0)}%',
                icon: Icons.savings_outlined,
                accentColor: savingsRateColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                theme: theme,
                title: 'Daily Velocity',
                value: '$currency${report.dailyVelocity.toStringAsFixed(0)}/day',
                subtitle: 'vs Prev: $changeSign${report.spendingChangePercent.toStringAsFixed(0)}%',
                icon: Icons.speed,
                accentColor: changeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _build503020PlanningCard(ThemeData theme, InsightsReport report, String currency) {
    final onSurface = theme.colorScheme.onSurface;
    final r = report.rule503020;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Future Planning: 50/30/20 Rule',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Target 50/30/20', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Multi-colored bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: max(1, r.needsPercent.round()),
                    child: Container(color: Colors.blueAccent),
                  ),
                  Expanded(
                    flex: max(1, r.wantsPercent.round()),
                    child: Container(color: Colors.orangeAccent),
                  ),
                  Expanded(
                    flex: max(1, r.savingsPercent.round()),
                    child: Container(color: Colors.greenAccent.shade400),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem('Needs (50%)', '${r.needsPercent.toStringAsFixed(0)}%', Colors.blueAccent, onSurface),
              _legendItem('Wants (30%)', '${r.wantsPercent.toStringAsFixed(0)}%', Colors.orangeAccent, onSurface),
              _legendItem('Savings (20%)', '${r.savingsPercent.toStringAsFixed(0)}%', Colors.greenAccent.shade400, onSurface),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r.assessment,
            style: TextStyle(fontSize: 12, height: 1.4, color: onSurface.withValues(alpha: 0.75)),
          ),
          const Divider(height: 24),
          // Safe to spend & Wealth trajectory
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Safe-to-Spend Run Rate', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 2),
                    Text(
                      '$currency${report.safeToSpendDaily.toStringAsFixed(0)}/day · $currency${report.safeToSpendWeekly.toStringAsFixed(0)}/wk',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1-Year Projected Savings', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 2),
                    Text(
                      '$currency${report.projected1YearSavings.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, String value, Color color, Color onSurface) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.65)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface),
        ),
      ],
    );
  }

  Widget _buildCategoryMatrix(ThemeData theme, InsightsReport report, String currency) {
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    if (report.categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text('No category activity recorded for this period.', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Category Spending & Budgets',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ],
              ),
              Text(
                '${report.categories.length} Categories',
                style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...report.categories.map((c) {
            Color barColor;
            if (c.isOverBudget) {
              barColor = Colors.redAccent;
            } else if (c.percentOfBudget > 75) {
              barColor = Colors.amberAccent;
            } else {
              barColor = primary;
            }

            final progressValue = (c.percentOfBudget / 100.0).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(categoryIcons[c.category] ?? Icons.circle, size: 16, color: primary),
                          const SizedBox(width: 8),
                          Text(
                            c.category,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface),
                          ),
                          if (c.isOverBudget)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('OVER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            ),
                        ],
                      ),
                      Text(
                        '$currency${c.spent.toStringAsFixed(0)} / $currency${c.budget.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${c.percentOfTotal.toStringAsFixed(0)}% of total outflows',
                        style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.55)),
                      ),
                      Text(
                        c.remaining >= 0
                            ? '$currency${c.remaining.toStringAsFixed(0)} remaining'
                            : '+$currency${c.remaining.abs().toStringAsFixed(0)} over budget',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: c.remaining >= 0 ? Colors.greenAccent.shade400 : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoansAndDebtCard(ThemeData theme, InsightsReport report, String currency) {
    final onSurface = theme.colorScheme.onSurface;
    final loan = report.loanInsight;

    Color dtiColor;
    if (loan.dtiStatus == 'Healthy') {
      dtiColor = Colors.greenAccent.shade400;
    } else if (loan.dtiStatus == 'Moderate') {
      dtiColor = Colors.amberAccent;
    } else {
      dtiColor = Colors.redAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.purpleAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Loans & Liabilities Portfolio',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dtiColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dtiColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'DTI: ${loan.debtToIncomeRatio.toStringAsFixed(0)}% · ${loan.dtiStatus}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dtiColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Debt You Owe', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Text(
                        '$currency${loan.totalPayable.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Money Owed to You', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Text(
                        '$currency${loan.totalReceivable.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent.shade400),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 18, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loan.payoffAdvice,
                    style: TextStyle(fontSize: 12, height: 1.35, color: onSurface.withValues(alpha: 0.85)),
                  ),
                ),
              ],
            ),
          ),
          if (loan.upcomingDueLoans.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Upcoming Loan Payments', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: onSurface)),
            const SizedBox(height: 6),
            ...loan.upcomingDueLoans.take(3).map((l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${l.title} (${l.personName})', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.75))),
                  Text(
                    '$currency${l.amount.toStringAsFixed(0)} · Due ${formatDate(l.dueDate)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTaxIntelligenceCard(ThemeData theme, InsightsReport report, String currency) {
    final onSurface = theme.colorScheme.onSurface;
    final tax = report.taxInsight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.tealAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tax Return & Deductions Tracker',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Tax Year 2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Deductible Expenses', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 4),
                    Text(
                      '$currency${tax.totalDeductible.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Est. Tax Savings (22% Bracket)', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 4),
                    Text(
                      '~$currency${tax.estimatedSavings22Pct.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.tealAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tax.taxTip,
                    style: TextStyle(fontSize: 12, height: 1.35, color: onSurface.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeCard(ThemeData theme, InsightsReport report, String currency) {
    final onSurface = theme.colorScheme.onSurface;

    if (report.paymentTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.indigoAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment Types & Liquidity Split',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...report.paymentTypes.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.accountName, style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.85))),
                Text(
                  '$currency${p.amount.toStringAsFixed(0)} (${p.percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface),
                ),
              ],
            ),
          )),
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          Text(
            'Smart Financial Intelligence',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Meet Your Personal Wealth Accountant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gain elite clarity over your cash flow across Daily, Weekly, Monthly, and Yearly horizons. Unlock 50/30/20 future planning, loan payoff forecasting, and tax return write-off intelligence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: onSurface.withValues(alpha: 0.7),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          // High-Converting Interactive Mocked Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text("Accountant's Take", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('88/100 · Excellent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '“Your monthly savings rate reached 34%! By accelerating \$120 into your auto loan, you will save \$420 in annual interest and be debt-free 4 months ahead of schedule.”',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: onSurface.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tax Write-offs', style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.6))),
                            const SizedBox(height: 2),
                            const Text('\$1,850 Est.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Debt Horizon', style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.6))),
                            const SizedBox(height: 2),
                            const Text('Avalanche Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Upgrade to Pro to run custom live audits on your transactions.',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.85)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildProBenefit(Icons.view_agenda, 'Daily, Weekly, Monthly & Yearly Horizon Controls', onSurface, primary),
          _buildProBenefit(Icons.account_balance, 'Automated Executive CPA Commentary & Health Scoring', onSurface, primary),
          _buildProBenefit(Icons.pie_chart, '50/30/20 Future Planning & Safe-to-Spend Allowances', onSurface, primary),
          _buildProBenefit(Icons.receipt_long, 'Tax Return Deductions & Write-Off Savings Estimator', onSurface, primary),
          _buildProBenefit(Icons.shield_outlined, 'Loans & Liabilities Hub with Snowball/Avalanche Strategy', onSurface, primary),
          _buildProBenefit(Icons.block, '100% Ad-Free Experience Everywhere', onSurface, primary),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => MonetizationService.showPaywallModal(
                context,
                featureTitle: 'Executive Wealth Intelligence',
                featureDescription: 'Unlock AI personal accountant briefings, debt payoff strategies, tax deductions tracker, and multi-horizon analytics.',
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
          const SizedBox(height: 10),
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