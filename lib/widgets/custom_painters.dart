import 'package:flutter/material.dart';
import 'dart:math';
import '../models/transaction.dart';

class MonthChartPainter extends CustomPainter {
  final List<Transaction> transactions;
  final Color lineColor;

  // Pre-calculated values for performance
  late final List<double> _dailyBalances;
  late final double _minBal;
  late final double _maxBal;
  late final double _range;
  late final int _daysInMonth;
  late final int _currentDay;

  MonthChartPainter(this.transactions, {
    this.lineColor = const Color(0xFF8B5CF6),
  }) {
    final now = DateTime.now();
    _currentDay = now.day;
    _daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    _dailyBalances = List.filled(_daysInMonth, 0.0);

    final thisMonthTx = transactions.where((t) => 
      t.date.year == now.year && t.date.month == now.month).toList();

    for (var tx in thisMonthTx) {
      int dayIndex = tx.date.day - 1;
      if (dayIndex >= 0 && dayIndex < _daysInMonth) {
        _dailyBalances[dayIndex] += tx.isIncome ? tx.amount : -tx.amount;
      }
    }

    double current = 0;
    for (int i = 0; i < _daysInMonth; i++) {
      current += _dailyBalances[i];
      _dailyBalances[i] = current;
    }

    if (_dailyBalances.isEmpty) {
      _maxBal = 0;
      _minBal = 0;
      _range = 1;
    } else {
      _maxBal = _dailyBalances.reduce(max);
      _minBal = _dailyBalances.reduce(min);
      final diff = _maxBal - _minBal;
      _range = diff <= 0 ? 1.0 : diff;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (transactions.isEmpty || _currentDay == 0) {
      final paint = Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final widthStep = size.width / max(1, _daysInMonth - 1);

    for (int i = 0; i < min(_currentDay, _dailyBalances.length); i++) {
      final x = i * widthStep;
      final normalizedY = (_dailyBalances[i] - _minBal) / _range;
      // Guard against NaN or Infinity from normalizedY
      if (normalizedY.isNaN || normalizedY.isInfinite) continue;
      
      final y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MonthChartPainter oldDelegate) {
    return oldDelegate.transactions != transactions || oldDelegate.lineColor != lineColor;
  }
}

class PieChartPainter extends CustomPainter {
  final double income;
  final double expense;
  final String currencySymbol;
  final Color incomeColor;
  final Color expenseColor;

  PieChartPainter(
    this.income, 
    this.expense, {
    this.currencySymbol = '\$',
    this.incomeColor = Colors.greenAccent,
    this.expenseColor = Colors.redAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = income + expense;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 25;

    if (total <= 0 || total.isNaN || total.isInfinite) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white10
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20,
      );
      return;
    }

    final incomeAngle = (income / total) * 2 * pi;

    final paintIncome = Paint()
      ..color = incomeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    final paintExpense = Paint()
      ..color = expenseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    // Draw background (expense)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      paintExpense,
    );

    // Draw income arc
    if (!incomeAngle.isNaN && !incomeAngle.isInfinite) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        incomeAngle,
        false,
        paintIncome,
      );
    }

    _drawLabels(canvas, center, radius, incomeAngle);
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, double incomeAngle) {
    void drawAmountLabel(String text, double angle, Color color) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final labelRadius = radius + 32;
      final x = center.dx + labelRadius * cos(angle) - textPainter.width / 2;
      final y = center.dy + labelRadius * sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(x, y));
    }

    if (income > 0 && !incomeAngle.isNaN && !incomeAngle.isInfinite) {
      drawAmountLabel(
        '+$currencySymbol${income.toStringAsFixed(0)}',
        -pi / 2 + incomeAngle / 2,
        incomeColor,
      );
    }
    if (expense > 0 && !incomeAngle.isNaN && !incomeAngle.isInfinite) {
      drawAmountLabel(
        '-$currencySymbol${expense.toStringAsFixed(0)}',
        -pi / 2 + incomeAngle + (2 * pi - incomeAngle) / 2,
        expenseColor,
      );
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) {
    return oldDelegate.income != income ||
        oldDelegate.expense != expense ||
        oldDelegate.currencySymbol != currencySymbol ||
        oldDelegate.incomeColor != incomeColor ||
        oldDelegate.expenseColor != expenseColor;
  }
}
