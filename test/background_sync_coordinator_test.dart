import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/services/background_sync_coordinator.dart';

void main() {
  const alice = (username: 'alice', uid: 'uid-a', generation: 1);
  const bob = (username: 'bob', uid: 'uid-b', generation: 2);

  testWidgets('rapid changes coalesce into one bounded-delay run', (
    tester,
  ) async {
    var runs = 0;
    final queue = BackgroundSyncCoordinator(
      currentSession: () => alice,
      canRun: () => true,
      synchronize: (_) async {
        runs++;
        return true;
      },
    );
    addTearDown(queue.dispose);
    queue.start();
    for (var i = 0; i < 100; i++) {
      queue.request();
    }
    await tester.pump(const Duration(milliseconds: 1999));
    expect(runs, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(runs, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(runs, 1);
    queue.dispose();
  });

  testWidgets('changes during upload cause one follow-up, never overlap', (
    tester,
  ) async {
    final first = Completer<bool>();
    var runs = 0;
    final queue = BackgroundSyncCoordinator(
      currentSession: () => alice,
      canRun: () => true,
      synchronize: (_) {
        runs++;
        return runs == 1 ? first.future : Future.value(true);
      },
    );
    addTearDown(queue.dispose);
    queue.start();
    await tester.pump(const Duration(seconds: 2));
    for (var i = 0; i < 10; i++) {
      queue.request();
    }
    await tester.pump(const Duration(seconds: 10));
    expect(runs, 1);
    first.complete(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(runs, 2);
    queue.dispose();
  });

  testWidgets(
    'offline queue wakes on reconnect without repeated network calls',
    (tester) async {
      var online = false;
      var runs = 0;
      final queue = BackgroundSyncCoordinator(
        currentSession: () => alice,
        canRun: () => online,
        synchronize: (_) async {
          runs++;
          return true;
        },
      );
      addTearDown(queue.dispose);
      queue.start();
      await tester.pump(const Duration(minutes: 3));
      expect(runs, 0);
      online = true;
      queue.request(immediately: true);
      await tester.pump(const Duration(milliseconds: 1));
      expect(runs, 1);
      queue.dispose();
    },
  );

  testWidgets('failures retry with backoff and recover', (tester) async {
    var runs = 0;
    final queue = BackgroundSyncCoordinator(
      currentSession: () => alice,
      canRun: () => true,
      synchronize: (_) async {
        runs++;
        if (runs == 1) throw StateError('offline');
        return runs >= 3;
      },
    );
    addTearDown(queue.dispose);
    queue.start();
    await tester.pump(const Duration(seconds: 2));
    expect(runs, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(runs, 2);
    await tester.pump(const Duration(seconds: 9));
    expect(runs, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(runs, 3);
    await tester.pump(const Duration(seconds: 30));
    expect(runs, 3);
    queue.dispose();
  });

  testWidgets('account changes and logout invalidate queued work', (
    tester,
  ) async {
    BackgroundSyncSession? session = alice;
    final seen = <BackgroundSyncSession>[];
    final queue = BackgroundSyncCoordinator(
      currentSession: () => session,
      canRun: () => true,
      synchronize: (s) async {
        seen.add(s);
        return true;
      },
    );
    addTearDown(queue.dispose);
    queue.start();
    session = bob;
    await tester.pump(const Duration(seconds: 2));
    expect(seen, isEmpty);
    queue.request();
    await tester.pump(const Duration(seconds: 2));
    expect(seen, [bob]);
    queue.request();
    session = null;
    queue.stop();
    await tester.pump(const Duration(minutes: 3));
    expect(seen, [bob]);
    queue.dispose();
  });

  testWidgets('new session waits for an old in-flight operation to finish', (
    tester,
  ) async {
    BackgroundSyncSession? session = alice;
    final first = Completer<bool>();
    final seen = <BackgroundSyncSession>[];
    final queue = BackgroundSyncCoordinator(
      currentSession: () => session,
      canRun: () => true,
      synchronize: (s) {
        seen.add(s);
        return s == alice ? first.future : Future.value(true);
      },
    );
    addTearDown(queue.dispose);
    queue.start();
    await tester.pump(const Duration(seconds: 2));
    queue.stop();
    session = bob;
    queue.start();
    await tester.pump(const Duration(seconds: 10));
    expect(seen, [alice]);
    first.complete(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(seen, [alice, bob]);
    queue.dispose();
  });

  testWidgets('foreground polling stops while paused and resumes once', (
    tester,
  ) async {
    var runs = 0;
    final queue = BackgroundSyncCoordinator(
      currentSession: () => alice,
      canRun: () => true,
      synchronize: (_) async {
        runs++;
        return true;
      },
    );
    addTearDown(queue.dispose);
    queue.start();
    await tester.pump(const Duration(seconds: 2));
    queue.pause();
    await tester.pump(const Duration(minutes: 5));
    expect(runs, 1);
    queue.resume();
    await tester.pump(const Duration(milliseconds: 1));
    expect(runs, 2);
    await tester.pump(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(runs, 3);
    queue.dispose();
  });
}
