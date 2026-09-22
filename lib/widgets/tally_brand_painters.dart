import 'package:flutter/material.dart';

/// Painter for the Tally App Icon (4 vertical strokes + 1 diagonal slash)
class TallyIconPainter extends CustomPainter {
  final double stroke1Progress;
  final double stroke2Progress;
  final double stroke3Progress;
  final double stroke4Progress;
  final double slashProgress;
  final Color bgColor;
  final Color strokeColor;
  final Color slashColor;
  final double cornerRadiusRatio;

  TallyIconPainter({
    this.stroke1Progress = 1.0,
    this.stroke2Progress = 1.0,
    this.stroke3Progress = 1.0,
    this.stroke4Progress = 1.0,
    this.slashProgress = 1.0,
    this.bgColor = const Color(0xFF17493B),
    this.strokeColor = const Color(0xFFF6F0E1),
    this.slashColor = const Color(0xFFE4572E),
    this.cornerRadiusRatio = 0.224, // 115 / 512 ≈ 0.2246
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512.0;
    final radius = Radius.circular(size.width * cornerRadiusRatio);

    // 1. Draw rounded rectangle background
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      bgPaint,
    );

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final slashPaint = Paint()
      ..color = slashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stroke 1: M136 164 C132 216 140 300 136 348
    if (stroke1Progress > 0) {
      final p1 = Path()
        ..moveTo(136 * scale, 164 * scale)
        ..cubicTo(132 * scale, 216 * scale, 140 * scale, 300 * scale, 136 * scale, 348 * scale);
      _drawAnimatedPath(canvas, p1, strokePaint, stroke1Progress);
    }

    // Stroke 2: M216 158 C219 210 212 300 216 354
    if (stroke2Progress > 0) {
      final p2 = Path()
        ..moveTo(216 * scale, 158 * scale)
        ..cubicTo(219 * scale, 210 * scale, 212 * scale, 300 * scale, 216 * scale, 354 * scale);
      _drawAnimatedPath(canvas, p2, strokePaint, stroke2Progress);
    }

    // Stroke 3: M296 162 C292 212 300 300 296 352
    if (stroke3Progress > 0) {
      final p3 = Path()
        ..moveTo(296 * scale, 162 * scale)
        ..cubicTo(292 * scale, 212 * scale, 300 * scale, 300 * scale, 296 * scale, 352 * scale);
      _drawAnimatedPath(canvas, p3, strokePaint, stroke3Progress);
    }

    // Stroke 4: M376 166 C380 214 372 298 376 344
    if (stroke4Progress > 0) {
      final p4 = Path()
        ..moveTo(376 * scale, 166 * scale)
        ..cubicTo(380 * scale, 214 * scale, 372 * scale, 298 * scale, 376 * scale, 344 * scale);
      _drawAnimatedPath(canvas, p4, strokePaint, stroke4Progress);
    }

    // Slash (p5): M104 366 C205 313 322 214 408 146
    if (slashProgress > 0) {
      final p5 = Path()
        ..moveTo(104 * scale, 366 * scale)
        ..cubicTo(205 * scale, 313 * scale, 322 * scale, 214 * scale, 408 * scale, 146 * scale);
      _drawAnimatedPath(canvas, p5, slashPaint, slashProgress);
    }
  }

  void _drawAnimatedPath(Canvas canvas, Path path, Paint paint, double progress) {
    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      final extract = metric.extractPath(0.0, metric.length * progress.clamp(0.0, 1.0));
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TallyIconPainter oldDelegate) {
    return oldDelegate.stroke1Progress != stroke1Progress ||
        oldDelegate.stroke2Progress != stroke2Progress ||
        oldDelegate.stroke3Progress != stroke3Progress ||
        oldDelegate.stroke4Progress != stroke4Progress ||
        oldDelegate.slashProgress != slashProgress ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.slashColor != slashColor;
  }
}

/// Painter for the Tally signature uwash swoosh (M6 14 C84 20 208 3 294 9)
class TallyUwashPainter extends CustomPainter {
  final double progress;
  final Color color;

  TallyUwashPainter({
    this.progress = 1.0,
    this.color = const Color(0xFFE4572E),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final scaleX = size.width / 300.0;
    final scaleY = size.height / 20.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0 * scaleX
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(6 * scaleX, 14 * scaleY)
      ..cubicTo(84 * scaleX, 20 * scaleY, 208 * scaleX, 3 * scaleY, 294 * scaleX, 9 * scaleY);

    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }

    for (final metric in path.computeMetrics()) {
      final extract = metric.extractPath(0.0, metric.length * progress.clamp(0.0, 1.0));
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TallyUwashPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Reusable Tally Wordmark Widget with "TALLY" in Fraunces/Serif Italic and sweeping uwash
class TallyWordmarkWidget extends StatelessWidget {
  final double fontSize;
  final Color textColor;
  final Color uwashColor;
  final double typeProgress; // 0.0 to 1.0 (controls letter-by-letter appearance)
  final double uwashProgress; // 0.0 to 1.0 (controls swoosh drawing)
  final double letterSpacing;

  const TallyWordmarkWidget({
    super.key,
    this.fontSize = 42,
    this.textColor = const Color(0xFF152A22),
    this.uwashColor = const Color(0xFFE4572E),
    this.typeProgress = 1.0,
    this.uwashProgress = 1.0,
    this.letterSpacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    const letters = ['T', 'A', 'L', 'L', 'Y'];
    final width = fontSize * 4.2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(letters.length, (index) {
            // Stagger letter appearance across typeProgress (0.0 to 1.0)
            final start = index * 0.18;
            final end = (start + 0.35).clamp(0.0, 1.0);
            final charProgress = ((typeProgress - start) / (end - start)).clamp(0.0, 1.0);

            return Opacity(
              opacity: charProgress,
              child: Transform.translate(
                offset: Offset(0, (1.0 - charProgress) * 10),
                child: Text(
                  letters[index],
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize,
                    letterSpacing: index == letters.length - 1 ? 0 : letterSpacing,
                    color: textColor,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: width,
          height: fontSize * 0.28,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: TallyUwashPainter(
                progress: uwashProgress,
                color: uwashColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
