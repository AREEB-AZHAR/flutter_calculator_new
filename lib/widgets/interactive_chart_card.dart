import 'dart:math';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import 'custom_painters.dart';

class InteractiveChartCard extends StatefulWidget {
  final List<Transaction> transactions;
  final String? accountFilter;
  final String title;

  const InteractiveChartCard({
    super.key,
    required this.transactions,
    this.accountFilter,
    this.title = 'Financial Flow & Analytics',
  });

  @override
  State<InteractiveChartCard> createState() => _InteractiveChartCardState();
}

class _InteractiveChartCardState extends State<InteractiveChartCard> {
  late int _year;
  late int _month;
  String _scope = 'month'; // 'month' or 'year'
  String _chartType = 'line'; // 'line', 'bar', 'pie'
  String _filter = 'all'; // 'all', 'spend', 'income'

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevPeriod() {
    setState(() {
      if (_scope == 'year') {
        _year--;
      } else {
        if (_month == 1) {
          _month = 12;
          _year--;
        } else {
          _month--;
        }
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_scope == 'year') {
        _year++;
      } else {
        if (_month == 12) {
          _month = 1;
          _year++;
        } else {
          _month++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final controlBg = theme.scaffoldBackgroundColor;
    final isLight = theme.brightness == Brightness.light;
    final positiveColor = isLight ? const Color(0xFF059669) : const Color(0xFF10B981);
    final negativeColor = isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171);

    // Filter transactions matching accountFilter and period
    final relevantTxs = widget.transactions.where((t) {
      final matchesAcc = widget.accountFilter == null || t.account == widget.accountFilter;
      if (!matchesAcc) return false;
      if (_scope == 'year') {
        return t.date.year == _year;
      } else {
        return t.date.year == _year && t.date.month == _month;
      }
    }).toList();

    double income = 0;
    double expense = 0;
    final Map<String, double> spendCategories = {};
    final Map<String, double> incomeCategories = {};

    for (var t in relevantTxs) {
      if (t.isIncome) {
        income += t.amount;
        incomeCategories[t.category] = (incomeCategories[t.category] ?? 0) + t.amount;
      } else {
        expense += t.amount;
        spendCategories[t.category] = (spendCategories[t.category] ?? 0) + t.amount;
      }
    }

    final net = income - expense;

    // Determine segments for Donut/Pie chart
    Map<String, double> donutSegments;
    double donutTotal;
    String donutTitle;

    if (_filter == 'spend') {
      donutSegments = spendCategories;
      donutTotal = expense;
      donutTitle = 'Spent';
    } else if (_filter == 'income') {
      donutSegments = incomeCategories;
      donutTotal = income;
      donutTitle = 'Received';
    } else {
      donutSegments = {
        'Income': income,
        'Expense': expense,
      };
      donutTotal = income + expense;
      donutTitle = _scope == 'year' ? 'Year Activity' : 'Month Activity';
    }

    return ValueListenableBuilder<String>(
      valueListenable: AppState.currencyNotifier,
      builder: (context, currency, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title, Scope Toggle, and Date Navigator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Scope Switcher [ Month | Year ]
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: controlBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _scopeButton('month', 'Month', onSurface),
                        _scopeButton('year', 'Year', onSurface),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Period Navigator (< Label >)
                  Container(
                    decoration: BoxDecoration(
                      color: controlBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: onSurface.withValues(alpha: 0.7), size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: _prevPeriod,
                        ),
                        Text(
                          _scope == 'year'
                              ? '$_year'
                              : '${_months[_month - 1].substring(0, 3)} $_year',
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.7), size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: _nextPeriod,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Control Strip: Metric Filter (All / Spend / Income) & Chart Type (Line / Bar / Pie)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Chips
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: controlBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _filterButton('all', 'All (Net)', onSurface),
                        _filterButton('spend', 'Spend', onSurface),
                        _filterButton('income', 'Income', onSurface),
                      ],
                    ),
                  ),

                  // Chart View Mode Selector (Line / Bar / Pie)
                  Container(
                    decoration: BoxDecoration(
                      color: controlBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.show_chart, size: 18, color: _chartType == 'line' ? primaryColor : onSurface.withValues(alpha: 0.38)),
                          tooltip: 'Line Graph',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 30),
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => _chartType = 'line'),
                        ),
                        IconButton(
                          icon: Icon(Icons.bar_chart_rounded, size: 18, color: _chartType == 'bar' ? primaryColor : onSurface.withValues(alpha: 0.38)),
                          tooltip: 'Bar Chart',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 30),
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => _chartType = 'bar'),
                        ),
                        IconButton(
                          icon: Icon(Icons.pie_chart_outline, size: 18, color: _chartType == 'pie' ? primaryColor : onSurface.withValues(alpha: 0.38)),
                          tooltip: 'Pie / Donut Breakdown',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 30),
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => _chartType = 'pie'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Chart Canvas Area
              SizedBox(
                height: 145,
                width: double.infinity,
                child: _buildChart(
                  context: context,
                  relevantTxs: relevantTxs,
                  currency: currency,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  onSurface: onSurface,
                  donutSegments: donutSegments,
                  donutTotal: donutTotal,
                  donutTitle: donutTitle,
                ),
              ),

              const SizedBox(height: 12),

              // Period Summary Stats Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: controlBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statItem('Received', '+$currency${income.toStringAsFixed(0)}', positiveColor, onSurface),
                    Container(height: 24, width: 1, color: onSurface.withValues(alpha: 0.12)),
                    _statItem('Spent', '-$currency${expense.toStringAsFixed(0)}', negativeColor, onSurface),
                    Container(height: 24, width: 1, color: onSurface.withValues(alpha: 0.12)),
                    _statItem('Net Balance', '$currency${net.toStringAsFixed(0)}', net >= 0 ? positiveColor : negativeColor, onSurface),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart({
    required BuildContext context,
    required List<Transaction> relevantTxs,
    required String currency,
    required Color primaryColor,
    required Color secondaryColor,
    required Color onSurface,
    required Map<String, double> donutSegments,
    required double donutTotal,
    required String donutTitle,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final chartPositive = isLight ? const Color(0xFF059669) : const Color(0xFF10B981);
    final chartNegative = isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171);
    final activeColor = _filter == 'spend'
        ? chartNegative
        : (_filter == 'income' ? chartPositive : primaryColor);

    if (_chartType == 'pie') {
      return RepaintBoundary(
        child: CustomPaint(
          painter: DonutChartPainter(
            segments: donutSegments,
            total: donutTotal,
            currencySymbol: currency,
            centerTitle: donutTitle,
            palette: getThemeChartPalette(theme),
            textColor: onSurface,
            subtextColor: onSurface.withValues(alpha: 0.6),
            emptyColor: onSurface.withValues(alpha: 0.12),
          ),
        ),
      );
    }

    if (_scope == 'year') {
      // 12-month aggregated tracking
      final monthlyValues = List<double>.filled(12, 0.0);
      for (var t in relevantTxs) {
        final m = (t.date.month - 1).clamp(0, 11);
        if (_filter == 'spend') {
          if (!t.isIncome) monthlyValues[m] += t.amount;
        } else if (_filter == 'income') {
          if (t.isIncome) monthlyValues[m] += t.amount;
        } else {
          monthlyValues[m] += t.isIncome ? t.amount : -t.amount;
        }
      }

      if (_chartType == 'bar') {
        return RepaintBoundary(
          child: CustomPaint(
            painter: BarChartPainter(
              monthlyValues: monthlyValues,
              barColor: activeColor,
              secondaryColor: secondaryColor,
              textColor: onSurface,
              currencySymbol: currency,
              selectedMonth: DateTime.now().year == _year ? DateTime.now().month : null,
              emptyColor: onSurface.withValues(alpha: 0.1),
            ),
          ),
        );
      } else {
        // Line chart for 12 months
        return RepaintBoundary(
          child: CustomPaint(
            painter: YearlyLineChartPainter(
              monthlyValues: monthlyValues,
              lineColor: activeColor,
              secondaryColor: secondaryColor,
              textColor: onSurface,
              selectedMonth: DateTime.now().year == _year ? DateTime.now().month : null,
              emptyColor: onSurface.withValues(alpha: 0.1),
            ),
          ),
        );
      }
    } else {
      // Month-scope tracking
      if (_chartType == 'bar') {
        // Break down month into 5 weekly buckets (W1, W2, W3, W4, W5)
        final weeklyValues = List<double>.filled(5, 0.0);
        for (var t in relevantTxs) {
          final w = min(4, (t.date.day - 1) ~/ 7);
          if (_filter == 'spend') {
            if (!t.isIncome) weeklyValues[w] += t.amount;
          } else if (_filter == 'income') {
            if (t.isIncome) weeklyValues[w] += t.amount;
          } else {
            weeklyValues[w] += t.isIncome ? t.amount : -t.amount;
          }
        }

        return RepaintBoundary(
          child: CustomPaint(
            painter: BarChartPainter(
              monthlyValues: weeklyValues,
              barColor: activeColor,
              secondaryColor: secondaryColor,
              textColor: onSurface,
              currencySymbol: currency,
              customLabels: const ['W1', 'W2', 'W3', 'W4', 'W5'],
              emptyColor: onSurface.withValues(alpha: 0.1),
            ),
          ),
        );
      } else {
        // Daily progression line
        return RepaintBoundary(
          child: CustomPaint(
            painter: MonthChartPainter(
              transactions: relevantTxs,
              year: _year,
              month: _month,
              filter: _filter,
              lineColor: activeColor,
            ),
          ),
        );
      }
    }
  }

  Widget _scopeButton(String key, String label, Color onSurface) {
    final isSelected = _scope == key;
    return GestureDetector(
      onTap: () => setState(() => _scope = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _filterButton(String key, String label, Color onSurface) {
    final isSelected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color, Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
