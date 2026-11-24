import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Snapshot of recent frame timings computed from raw `FrameTiming` data.
class FrameWindowStats {
  final int frameCount;
  final double buildP50Ms;
  final double buildP95Ms;
  final double rasterP50Ms;
  final double rasterP95Ms;
  final double worstFrameMs;
  final double budgetMs;
  final double jankyRatio;
  final double? deliveredHz;

  const FrameWindowStats({
    required this.frameCount,
    required this.buildP50Ms,
    required this.buildP95Ms,
    required this.rasterP50Ms,
    required this.rasterP95Ms,
    required this.worstFrameMs,
    required this.budgetMs,
    required this.jankyRatio,
    required this.deliveredHz,
  });
}

class FrameSample {
  final double buildMs;
  final double rasterMs;
  final int vsyncStartUs;
  const FrameSample(this.buildMs, this.rasterMs, this.vsyncStartUs);
}

/// Lightweight ring-buffer frame-timing watchdog.
///
/// Completely inert in production unless enabled with
/// `--dart-define=ENABLE_PERF_WATCHDOG=true` (or explicitly forced in tests).
/// Never triggers `setState`, layout, or I/O inside `addTimingsCallback`.
class FrameWatchdog {
  FrameWatchdog._();

  static const bool enabledByFlag =
      bool.fromEnvironment('ENABLE_PERF_WATCHDOG', defaultValue: false);

  static const int _capacity = 256;
  static final ListQueue<FrameSample> _ring = ListQueue<FrameSample>(_capacity);
  static bool _installed = false;
  static DateTime _lastFlush = DateTime.fromMillisecondsSinceEpoch(0);
  static final ValueNotifier<FrameWindowStats?> latestStats =
      ValueNotifier<FrameWindowStats?>(null);

  static void install({bool force = false}) {
    if (_installed) return;
    if (!force && !enabledByFlag) return;
    _installed = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<ui.FrameTiming> timings) {
    for (final timing in timings) {
      if (_ring.length >= _capacity) {
        _ring.removeFirst();
      }
      _ring.addLast(
        FrameSample(
          timing.buildDuration.inMicroseconds / 1000.0,
          timing.rasterDuration.inMicroseconds / 1000.0,
          timing.timestampInMicroseconds(ui.FramePhase.vsyncStart),
        ),
      );
    }

    final now = DateTime.now();
    if (now.difference(_lastFlush).inSeconds >= 5 && _ring.isNotEmpty) {
      _lastFlush = now;
      latestStats.value = computeStats(_ring.toList(growable: false));
    }
  }

  @visibleForTesting
  static FrameWindowStats computeStats(List<FrameSample> samples) {
    final n = samples.length;
    final builds = List<double>.generate(n, (i) => samples[i].buildMs)..sort();
    final rasters = List<double>.generate(n, (i) => samples[i].rasterMs)..sort();

    // Estimate effective vsync cadence from consecutive vsyncStart deltas
    // (1 ms .. 50 ms filters out idle pauses between user interactions).
    final deltasMs = <double>[];
    for (var i = 1; i < n; i++) {
      final deltaMs = (samples[i].vsyncStartUs - samples[i - 1].vsyncStartUs) / 1000.0;
      if (deltaMs >= 4.0 && deltaMs <= 50.0) {
        deltasMs.add(deltaMs);
      }
    }
    deltasMs.sort();
    final medianDeltaMs = deltasMs.isEmpty ? 16.666667 : _percentile(deltasMs, 0.50);
    // Derive refresh budget from measured vsync cadence (8.33 ms for 120 Hz, 16.67 ms for 60 Hz).
    final budgetMs = medianDeltaMs < 11.0 ? 8.333333 : 16.666667;
    final deliveredHz = deltasMs.isEmpty ? null : 1000.0 / medianDeltaMs;

    var jankyCount = 0;
    var worstFrameMs = 0.0;
    for (final s in samples) {
      final worst = math.max(s.buildMs, s.rasterMs);
      if (worst > worstFrameMs) worstFrameMs = worst;
      if (worst > budgetMs) jankyCount++;
    }

    return FrameWindowStats(
      frameCount: n,
      buildP50Ms: _percentile(builds, 0.50),
      buildP95Ms: _percentile(builds, 0.95),
      rasterP50Ms: _percentile(rasters, 0.50),
      rasterP95Ms: _percentile(rasters, 0.95),
      worstFrameMs: worstFrameMs,
      budgetMs: budgetMs,
      jankyRatio: jankyCount / n,
      deliveredHz: deliveredHz,
    );
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0.0;
    final idx = ((p * sorted.length).ceil() - 1).clamp(0, sorted.length - 1);
    return sorted[idx];
  }
}
