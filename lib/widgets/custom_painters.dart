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

    for (var tx in transactions) {
      if (tx.date.year == year && tx.date.month == month) {
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

List<Color> getThemeChartPalette(ThemeData theme) {
  final primary = theme.colorScheme.primary;
  final secondary = theme.colorScheme.secondary;
  final hsv = HSVColor.fromColor(primary);
  final isLight = theme.brightness == Brightness.light;
  final baseVal = isLight ? 0.75 : 0.9;
  final baseSat = isLight ? 0.8 : 0.75;

  return [
    primary,
    secondary,
    HSVColor.fromAHSV(1.0, (hsv.hue + 40) % 360, baseSat, baseVal).toColor(),
    HSVColor.fromAHSV(1.0, (hsv.hue + 85) % 360, baseSat, baseVal).toColor(),
    HSVColor.fromAHSV(1.0, (hsv.hue + 135) % 360, baseSat, baseVal).toColor(),
    HSVColor.fromAHSV(1.0, (hsv.hue + 190) % 360, baseSat, baseVal).toColor(),
    HSVColor.fromAHSV(1.0, (hsv.hue + 245) % 360, baseSat, baseVal).toColor(),
    HSVColor.fromAHSV(1.0, (hsv.hue + 300) % 360, baseSat, baseVal).toColor(),
  ];
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> segments;
  final double total;
  final String currencySymbol;
  final String centerTitle;
  final List<Color>? palette;
  final Color? textColor;
  final Color? subtextColor;
  final Color? emptyColor;

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
    this.palette,
    this.textColor,
    this.subtextColor,
    this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    final effectivePalette = palette != null && palette!.isNotEmpty ? palette! : _palette;

    if (total <= 0 || segments.isEmpty) {
      final emptyPaint = Paint()
        ..color = emptyColor ?? Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16;
      canvas.drawCircle(center, radius, emptyPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'No Data',
          style: TextStyle(color: subtextColor ?? Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
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

      final color = effectivePalette[colorIdx % effectivePalette.length];
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
        style: TextStyle(color: subtextColor ?? Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, Offset(center.dx - titlePainter.width / 2, center.dy - 12));

    final amountPainter = TextPainter(
      text: TextSpan(
        text: '$currencySymbol${total.toStringAsFixed(0)}',
        style: TextStyle(color: textColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    amountPainter.paint(canvas, Offset(center.dx - amountPainter.width / 2, center.dy + 2));
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.segments != segments ||
        oldDelegate.currencySymbol != currencySymbol ||
        oldDelegate.textColor != textColor ||
        oldDelegate.subtextColor != subtextColor ||
        oldDelegate.palette != palette ||
        oldDelegate.emptyColor != emptyColor;
  }
}

class PieChartPainter extends CustomPainter {
  final double income;
  final double expense;
  final String currencySymbol;
  final Color incomeColor;
  final Color expenseColor;
  final Color? emptyColor;

  PieChartPainter(
    this.income, 
    this.expense, {
    this.currencySymbol = '\$',
    this.incomeColor = Colors.greenAccent,
    this.expenseColor = Colors.redAccent,
    this.emptyColor,
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
          ..color = emptyColor ?? Colors.white10
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
        oldDelegate.expenseColor != expenseColor ||
        oldDelegate.emptyColor != emptyColor;
  }
}

/// A high-performance, GPU-accelerated bar chart painter for 12-month yearly tracking
class BarChartPainter extends CustomPainter {
  final List<double> monthlyValues; // 12 elements (Jan to Dec)
  final Color barColor;
  final Color secondaryColor;
  final Color textColor;
  final Color? emptyColor;
  final String currencySymbol;
  final int? selectedMonth; // 1-12

  final List<String>? customLabels;

  static const List<String> _monthLabels = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];

  BarChartPainter({
    required this.monthlyValues,
    required this.barColor,
    required this.secondaryColor,
    required this.textColor,
    this.currencySymbol = '\$',
    this.selectedMonth,
    this.emptyColor,
    this.customLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 18.0;
    final chartHeight = size.height - bottomLabelHeight;
    final barCount = monthlyValues.length; // 12 or custom
    if (barCount == 0) return;

    final maxVal = monthlyValues.fold<double>(0.0, (prev, elem) => max(prev, elem.abs()));
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    final totalBarAreaWidth = size.width;
    final slotWidth = totalBarAreaWidth / barCount;
    final barWidth = max(6.0, slotWidth * 0.55);

    // Draw baseline
    final baseLinePaint = Paint()
      ..color = (emptyColor ?? textColor.withValues(alpha: 0.15))
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), baseLinePaint);

    for (int i = 0; i < barCount; i++) {
      final val = monthlyValues[i];
      final isCurrent = selectedMonth != null && selectedMonth == (i + 1);
      final xCenter = slotWidth * i + (slotWidth / 2);
      final barHeight = val <= 0 ? 2.0 : (val / safeMax) * (chartHeight - 14);

      final barRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(xCenter, chartHeight - (barHeight / 2)),
          width: barWidth,
          height: max(2.0, barHeight),
        ),
        const Radius.circular(4),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isCurrent ? secondaryColor : barColor,
            barColor.withValues(alpha: isCurrent ? 0.9 : 0.6),
          ],
        ).createShader(barRect.outerRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(barRect, barPaint);

      // Label below bar
      final effectiveLabels = customLabels ?? _monthLabels;
      final label = (i < effectiveLabels.length) ? effectiveLabels[i] : '${i + 1}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isCurrent ? secondaryColor : textColor.withValues(alpha: 0.65),
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(xCenter - (textPainter.width / 2), size.height - bottomLabelHeight + 3),
      );
    }
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) {
    return oldDelegate.monthlyValues != monthlyValues ||
        oldDelegate.barColor != barColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.selectedMonth != selectedMonth ||
        oldDelegate.currencySymbol != currencySymbol ||
        oldDelegate.customLabels != customLabels;
  }
}

/// A smooth, GPU-accelerated spline line chart painter for 12-month yearly tracking
class YearlyLineChartPainter extends CustomPainter {
  final List<double> monthlyValues; // 12 elements (Jan to Dec)
  final Color lineColor;
  final Color secondaryColor;
  final Color textColor;
  final Color? emptyColor;
  final int? selectedMonth;
  final List<String>? customLabels;

  static const List<String> _monthLabels = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];

  YearlyLineChartPainter({
    required this.monthlyValues,
    required this.lineColor,
    required this.secondaryColor,
    required this.textColor,
    this.selectedMonth,
    this.emptyColor,
    this.customLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 18.0;
    final chartHeight = size.height - bottomLabelHeight;
    final count = monthlyValues.length;
    if (count == 0) return;

    final maxVal = monthlyValues.fold<double>(0.0, (prev, elem) => max(prev, elem));
    final minVal = monthlyValues.fold<double>(0.0, (prev, elem) => min(prev, elem));
    final diff = maxVal - minVal;
    final range = diff <= 0 ? 1.0 : diff;

    final widthStep = size.width / max(1, count - 1);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < count; i++) {
      final x = i * widthStep;
      final normalized = (monthlyValues[i] - minVal) / range;
      final y = chartHeight - (normalized * (chartHeight - 16)) - 8;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * widthStep;
        final prevNorm = (monthlyValues[i - 1] - minVal) / range;
        final prevY = chartHeight - (prevNorm * (chartHeight - 16)) - 8;

        final cx = (prevX + x) / 2;
        path.cubicTo(cx, prevY, cx, y, x, y);
        fillPath.cubicTo(cx, prevY, cx, y, x, y);
      }

      // Draw month label
      final label = (i < _monthLabels.length) ? _monthLabels[i] : '${i + 1}';
      final isCurrent = selectedMonth != null && selectedMonth == (i + 1);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isCurrent ? secondaryColor : textColor.withValues(alpha: 0.65),
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - bottomLabelHeight + 3),
      );
    }

    fillPath.lineTo((count - 1) * widthStep, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.35),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(YearlyLineChartPainter oldDelegate) {
    return oldDelegate.monthlyValues != monthlyValues ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.selectedMonth != selectedMonth ||
        oldDelegate.emptyColor != emptyColor;
  }
}


