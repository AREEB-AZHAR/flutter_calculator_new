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
  bool _isDonutView = false;
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

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter transactions by month & optional account
    final txs = widget.transactions.where((t) {
      final matchesDate = t.date.year == _year && t.date.month == _month;
      final matchesAcc = widget.accountFilter == null || t.account == widget.accountFilter;
      return matchesDate && matchesAcc;
    }).toList();

    double income = 0;
    double expense = 0;
    final Map<String, double> spendCategories = {};
    final Map<String, double> incomeCategories = {};

    for (var t in txs) {
      if (t.isIncome) {
        income += t.amount;
        incomeCategories[t.category] = (incomeCategories[t.category] ?? 0) + t.amount;
      } else {
        expense += t.amount;
        spendCategories[t.category] = (spendCategories[t.category] ?? 0) + t.amount;
      }
    }

    final net = income - expense;
    final currency = AppState.currencyNotifier.value;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Donut segments based on active filter
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
      donutTitle = 'Activity';
    }

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final controlBg = theme.scaffoldBackgroundColor;

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
          // Header: Title & Month Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: controlBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: onSurface.withValues(alpha: 0.7), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _prevMonth,
                    ),
                    Text(
                      '${_months[_month - 1].substring(0, 3)} $_year',
                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.7), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Control Strip: Filter (Spend / Income / All) & View (Line / Donut)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Metric Filter Selector
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

              // View Mode Toggle (Line vs Donut)
              Container(
                decoration: BoxDecoration(
                  color: controlBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.show_chart, size: 18, color: !_isDonutView ? primaryColor : onSurface.withValues(alpha: 0.38)),
                      tooltip: 'Line Flow',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _isDonutView = false),
                    ),
                    IconButton(
                      icon: Icon(Icons.pie_chart_outline, size: 18, color: _isDonutView ? primaryColor : onSurface.withValues(alpha: 0.38)),
                      tooltip: 'Donut Breakdown',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _isDonutView = true),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart Display Area
          SizedBox(
            height: 140,
            width: double.infinity,
            child: _isDonutView
                ? RepaintBoundary(
                    child: CustomPaint(
                      painter: DonutChartPainter(
                        segments: donutSegments,
                        total: donutTotal,
                        currencySymbol: currency,
                        centerTitle: donutTitle,
                      ),
                    ),
                  )
                : RepaintBoundary(
                    child: CustomPaint(
                      painter: MonthChartPainter(
                        transactions: txs,
                        year: _year,
                        month: _month,
                        filter: _filter,
                        lineColor: _filter == 'spend'
                            ? Colors.redAccent
                            : (_filter == 'income' ? Colors.greenAccent : primaryColor),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Monthly Summary Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: controlBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statItem('Received', '+$currency${income.toStringAsFixed(0)}', Colors.greenAccent, onSurface),
                Container(height: 24, width: 1, color: onSurface.withValues(alpha: 0.12)),
                _statItem('Spent', '-$currency${expense.toStringAsFixed(0)}', Colors.redAccent, onSurface),
                Container(height: 24, width: 1, color: onSurface.withValues(alpha: 0.12)),
                _statItem('Net Balance', '$currency${net.toStringAsFixed(0)}', net >= 0 ? onSurface : Colors.redAccent, onSurface),
              ],
            ),
          ),
        ],
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
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Colors.transparent,
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
