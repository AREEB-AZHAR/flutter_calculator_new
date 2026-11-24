import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/perf/frame_watchdog.dart';
import 'package:balance_tracker/widgets/surface_card.dart';

void main() {
  test('FrameWatchdog computes 120 Hz budget and percentiles from vsync deltas', () {
    final samples = List<FrameSample>.generate(
      100,
      (i) => FrameSample(
        1.0 + (i % 5) * 0.1,
        i < 95 ? 3.5 : 10.0,
        i * 8333, // 120 Hz vsync cadence (8.333 ms)
      ),
    );
    final stats = FrameWatchdog.computeStats(samples);
    expect(stats.frameCount, 100);
    expect(stats.budgetMs, closeTo(8.333, 0.01));
    expect(stats.deliveredHz, closeTo(120.0, 1.0));
    expect(stats.rasterP50Ms, closeTo(3.5, 0.01));
    expect(stats.rasterP95Ms, closeTo(3.5, 0.01));
    expect(stats.worstFrameMs, closeTo(10.0, 0.01));
    expect(stats.jankyRatio, closeTo(0.05, 0.001));
  });

  test('FrameWatchdog computes 60 Hz budget when vsync deltas are ~16.67 ms', () {
    final samples = List<FrameSample>.generate(
      20,
      (i) => FrameSample(1.2, 5.0, i * 16667),
    );
    final stats = FrameWatchdog.computeStats(samples);
    expect(stats.budgetMs, closeTo(16.667, 0.01));
    expect(stats.jankyRatio, 0.0);
  });

  testWidgets('SurfaceCard renders opaque zero-blur container with Clip.none', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SurfaceCard(
            padding: EdgeInsets.all(16),
            child: Text('Fast Card'),
          ),
        ),
      ),
    );
    expect(find.text('Fast Card'), findsOneWidget);
    final container = tester.widget<Container>(find.byType(Container));
    expect(container.clipBehavior, Clip.none);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.boxShadow, isNull);
  });
}
