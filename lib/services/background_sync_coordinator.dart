import 'dart:async';
import 'dart:math' as math;

typedef BackgroundSyncSession = ({String username, String uid, int generation});

/// Coalesces requests; the SQLite outbox, not these timers, owns durable changes.
/// Work runs only while started, foregrounded, online and authenticated.
class BackgroundSyncCoordinator {
  final BackgroundSyncSession? Function() currentSession;
  final bool Function() canRun;
  final Future<bool> Function(BackgroundSyncSession session) synchronize;
  final Duration batchDelay;
  final Duration retryDelay;
  final Duration maxRetryDelay;
  final Duration refreshInterval;

  BackgroundSyncCoordinator({
    required this.currentSession,
    required this.canRun,
    required this.synchronize,
    this.batchDelay = const Duration(seconds: 2),
    this.retryDelay = const Duration(seconds: 5),
    this.maxRetryDelay = const Duration(minutes: 5),
    this.refreshInterval = const Duration(minutes: 2),
  });

  Timer? _timer;
  Timer? _poll;
  Future<bool>? _active;
  BackgroundSyncSession? _queued;
  bool _started = false;
  bool _paused = false;
  bool _disposed = false;
  int _failures = 0;

  void start() {
    if (_disposed) return;
    _started = true;
    _paused = false;
    _startPolling();
    request();
  }

  void _startPolling() {
    _poll ??= Timer.periodic(refreshInterval, (_) => request());
  }

  void request({bool immediately = false}) {
    if (!_started || _disposed) return;
    final session = currentSession();
    if (session == null) {
      _queued = null;
      _timer?.cancel();
      _timer = null;
      return;
    }
    _queued = session;
    if (immediately && _active == null) {
      _timer?.cancel();
      _timer = null;
    }
    _schedule(immediately ? Duration.zero : batchDelay);
  }

  void _schedule(Duration delay) {
    if (!_started ||
        _disposed ||
        _paused ||
        _active != null ||
        _queued == null ||
        _timer != null ||
        !canRun()) {
      return;
    }
    _timer = Timer(delay, () {
      _timer = null;
      unawaited(_drain());
    });
  }

  Future<bool> _safeRun(BackgroundSyncSession session) async {
    try {
      return await synchronize(session);
    } catch (_) {
      // Leave durable work queued and retry. Nothing is acknowledged here.
      return false;
    }
  }

  Future<void> _drain() async {
    final session = _queued;
    if (!_started ||
        _paused ||
        _disposed ||
        _active != null ||
        session == null ||
        !canRun()) {
      return;
    }
    if (session != currentSession()) {
      _queued = null;
      return;
    }
    _queued = null;
    _active = _safeRun(session);
    final success = await _active!;
    _active = null;
    if (!_started || _paused || _disposed) return;
    if (session != currentSession()) {
      _failures = 0;
      _schedule(batchDelay);
      return;
    }
    if (success) {
      _failures = 0;
      _schedule(batchDelay); // Includes requests made during this upload.
    } else {
      _queued ??= session;
      _failures++;
      final millis = math.min(
        maxRetryDelay.inMilliseconds,
        retryDelay.inMilliseconds * (1 << math.min(_failures - 1, 10)),
      );
      _schedule(Duration(milliseconds: millis));
    }
  }

  void pause() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
    _poll?.cancel();
    _poll = null;
  }

  void resume() {
    if (!_started || _disposed) return;
    _paused = false;
    _startPolling();
    request(immediately: true);
  }

  void stop() {
    _started = false;
    _queued = null;
    _failures = 0;
    pause();
    // An in-flight request must finish before a new session can run.
  }

  void dispose() {
    stop();
    _disposed = true;
  }
}
