import 'package:flutter/material.dart';
import 'dart:math';
import '../models/transaction.dart';

class MonthChartPainter extends CustomPainter {
  final List<Transaction> transactions;
  final Color lineColor;
  final int year;
  final int month;
  final String filter; // 'all', 'spend', 'income'

  // Pre-calculated values for performance
  late final List<double> _dailyValues;
  late final double _minVal;
  late final double _maxVal;
  late final double _range;
  late final int _daysInMonth;
  late final int _activeDays;

  MonthChartPainter({
    required this.transactions,
    required this.year,
    required this.month,
    this.filter = 'all',
    this.lineColor = const Color(0xFF8B5CF6),
  }) {
    final now = DateTime.now();
    _daysInMonth = DateTime(year, month + 1, 0).day;
    final isCurrentMonth = (now.year == year && now.month == month);
    _activeDays = isCurrentMonth ? now.day : _daysInMonth;
    _dailyValues = List.filled(_daysInMonth, 0.0);

    final monthTxs = transactions.where((t) => t.date.year == year && t.date.month == month).toList();

    for (var tx in monthTxs) {
      final dayIndex = tx.date.day - 1;
      if (dayIndex >= 0 && dayIndex < _daysInMonth) {
        if (filter == 'spend') {
          if (!tx.isIncome) _dailyValues[dayIndex] += tx.amount;
        } else if (filter == 'income') {
          if (tx.isIncome) _dailyValues[dayIndex] += tx.amount;
        } else {
          _dailyValues[dayIndex] += tx.isIncome ? tx.amount : -tx.amount;
        }
      }
    }

    // Cumulative progression
    double running = 0;
    for (int i = 0; i < _daysInMonth; i++) {
      running += _dailyValues[i];
      _dailyValues[i] = running;
    }

    if (_dailyValues.isEmpty) {
      _maxVal = 0;
      _minVal = 0;
      _range = 1;
    } else {
      _maxVal = _dailyValues.reduce(max);
      _minVal = _dailyValues.reduce(min);
      final diff = _maxVal - _minVal;
      _range = diff <= 0 ? 1.0 : diff;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (transactions.isEmpty || _activeDays == 0) {
      final paint = Paint()
        ..color = lineColor.withValues(alpha: 0.2)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final widthStep = size.width / max(1, _daysInMonth - 1);

    Offset firstPoint = Offset.zero;
    Offset lastPoint = Offset.zero;

    for (int i = 0; i < min(_activeDays, _dailyValues.length); i++) {
      final x = i * widthStep;
      final normalizedY = (_dailyValues[i] - _minVal) / _range;
      if (normalizedY.isNaN || normalizedY.isInfinite) continue;

      final y = size.height - (normalizedY * size.height * 0.75) - (size.height * 0.12);

      if (i == 0) {
        firstPoint = Offset(x, y);
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      lastPoint = Offset(x, y);
    }

    if (firstPoint != lastPoint) {
      fillPath.lineTo(lastPoint.dx, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(path, strokePaint);

    // Draw active dot at latest point
    final dotPaint = Paint()..color = lineColor;
    final dotGlow = Paint()..color = lineColor.withValues(alpha: 0.4);
    canvas.drawCircle(lastPoint, 6, dotGlow);
    canvas.drawCircle(lastPoint, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(MonthChartPainter oldDelegate) {
    return oldDelegate.transactions != transactions ||
        oldDelegate.year != year ||
        oldDelegate.month != month ||
        oldDelegate.filter != filter ||
        oldDelegate.lineColor != lineColor;
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> segments;
  final double total;
  final String currencySymbol;
  final String centerTitle;

  static const List<Color> _palette = [
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFF43F5E),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
    Color(0xFF84CC16),
    Color(0xFFEAB308),
  ];

  DonutChartPainter({
    required this.segments,
    required this.total,
    required this.currencySymbol,
    this.centerTitle = 'Total',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;

    if (total <= 0 || segments.isEmpty) {
      final emptyPaint = Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16;
      canvas.drawCircle(center, radius, emptyPaint);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'No Data',
          style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
      return;
    }

    double startAngle = -pi / 2;
    int colorIdx = 0;

    for (var entry in segments.entries) {
      final sweepAngle = (entry.value / total) * 2 * pi;
      if (sweepAngle <= 0 || sweepAngle.isNaN) continue;

      final color = _palette[colorIdx % _palette.length];
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.02, // slight separation gap
        false,
        paint,
      );

      startAngle += sweepAngle;
      colorIdx++;
    }

    // Center Text
    final titlePainter = TextPainter(
      text: TextSpan(
        text: centerTitle.toUpperCase(),
        style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, Offset(center.dx - titlePainter.width / 2, center.dy - 12));

    final amountPainter = TextPainter(
      text: TextSpan(
        text: '$currencySymbol${total.toStringAsFixed(0)}',
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    amountPainter.paint(canvas, Offset(center.dx - amountPainter.width / 2, center.dy + 2));
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.segments != segments ||
        oldDelegate.currencySymbol != currencySymbol;
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
