import 'dart:async';
import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';
import '../services/cloud_sync_service.dart';
import '../services/notification_service.dart';

class GoalManagerDialog extends StatefulWidget {
  const GoalManagerDialog({super.key});
  @override
  State<GoalManagerDialog> createState() => _GoalManagerDialogState();
}

class _GoalManagerDialogState extends State<GoalManagerDialog> {
  final _username = AppState.currentUser;
  final _generation = AppState.sessionGeneration;
  List<SavingsGoal> _goals = [];
  bool _busy = true;
  String? _error;
  bool get _sameSession =>
      _username != null &&
      _username == AppState.currentUser &&
      _generation == AppState.sessionGeneration;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool cloud = false}) async {
    if (!_sameSession) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Sign in again to manage your goals.';
        });
      }
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (cloud) {
        if (!CloudSyncService.isCloudAvailable) {
          throw StateError(
            'Sign in with Google and connect to cloud sync first.',
          );
        }
        final complete = await CloudSyncService.sync(_username!);
        if (!complete) {
          throw StateError('Cloud refresh incomplete; retry sync.');
        }
      }
      if (!_sameSession || !mounted) return;
      final goals = await AppDatabase.instance.loadGoals(
        _username!,
        includeArchived: true,
      );
      if (!_sameSession || !mounted) return;
      AppState.goalsNotifier.value = goals.where((g) => !g.isArchived).toList();
      setState(() => _goals = goals);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = cloud
              ? 'Cloud refresh failed or is unavailable. Local goals remain available; retry when connected.'
              : 'Could not load goals.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove goal permanently?'),
        content: Text(
          'Remove "${goal.title}" and its deposit history from goals? Existing financial transactions stay in your ledger. The deletion is queued for cloud sync. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove goal'),
          ),
        ],
      ),
    );
    if (confirmed != true || !_sameSession || !mounted) return;
    setState(() => _busy = true);
    try {
      await AppDatabase.instance.permanentlyDeleteGoal(_username!, goal.id);
      unawaited(
        NotificationService.instance
            .cancelGoalReminders(goal.id)
            .catchError((Object _) {}),
      );
      if (!_sameSession || !mounted) return;
      await _load();
      // Durable outbox protects the removal even if offline or the process exits.
      unawaited(
        CloudSyncService.sync(
          _username,
        ).then<void>((_) {}).catchError((Object _) {}),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not remove the goal. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Manage all goals'),
    content: SizedBox(
      width: 480,
      height: 420,
      child: Column(
        children: [
          const Text(
            'Includes archived goals hidden from the main vault. Refresh from cloud to find cloud-only records.',
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: _goals.isEmpty && !_busy
                ? const Center(child: Text('No goals on this device.'))
                : ListView.builder(
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return ListTile(
                        key: ValueKey('manage_goal_${goal.id}'),
                        title: Text(
                          goal.title.isEmpty ? '(Untitled goal)' : goal.title,
                        ),
                        subtitle: Text(
                          '${goal.isArchived ? 'Archived' : 'Visible'} · ${goal.saved}/${goal.target}\nID: ${goal.id}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove goal permanently',
                          icon: const Icon(Icons.delete_forever),
                          onPressed: _busy || !_sameSession
                              ? null
                              : () => _remove(goal),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy || !_sameSession ? null : () => _load(cloud: true),
        child: const Text('Refresh from cloud'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
