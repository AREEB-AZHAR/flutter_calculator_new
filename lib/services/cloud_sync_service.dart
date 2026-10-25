import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart' as model;
import '../models/user_profile.dart';
import 'database/app_database.dart';
import 'state.dart';
import 'ledger_sync.dart';
import 'background_sync_coordinator.dart';
import 'connectivity_service.dart';
import 'sync_fingerprint.dart';
import 'sync_metadata.dart';

class CloudSyncConflict {
  final BackgroundSyncSession session;
  final VaultSummary local;
  final VaultSummary cloud;
  final int count;
  const CloudSyncConflict(this.session, this.local, this.cloud, this.count);
}

/// Secure Cloud Data Synchronization Engine for Tally.
///
/// Coordinates two-way synchronization between on-device SQLite
/// and Google Cloud Firestore under strictly isolated per-user vault paths:
/// `/users/{userId}/...`.
/// Data summary representing vault contents for conflict comparison
class VaultSummary {
  final double totalBalance;
  final int transactionCount;
  final int goalsCount;
  final DateTime? lastModified;

  const VaultSummary({
    required this.totalBalance,
    required this.transactionCount,
    required this.goalsCount,
    this.lastModified,
  });
}

class CloudSyncService {
  CloudSyncService._();
  static BackgroundSyncCoordinator? _background;
  static bool _backgroundRunning = false;
  static bool _foreground = true;
  static StreamSubscription<User?>? _authChanges;
  static void Function(CloudSyncConflict)? _loginConflictHandler;
  static Future<void> _syncTail = Future.value();
  static Object? _viewOwner;
  static final needsReviewNotifier = ValueNotifier<CloudSyncConflict?>(null);

  static BackgroundSyncSession? get _session => !isCloudAvailable
      ? null
      : (
          username: AppState.currentUser!,
          uid: currentUid!,
          generation: AppState.sessionGeneration,
        );

  static void startBackgroundSync({
    void Function(CloudSyncConflict)? onLoginConflict,
    Object? owner,
  }) {
    if (owner != null) _viewOwner = owner;
    if (_session == null) return;
    _loginConflictHandler = onLoginConflict;
    final review = needsReviewNotifier.value;
    if (review != null &&
        review.session == _session &&
        onLoginConflict != null) {
      _loginConflictHandler = null;
      scheduleMicrotask(() => onLoginConflict(review));
    }
    if (!_backgroundRunning) {
      _backgroundRunning = true;
      _foreground = true;
      ConnectivityService.isOnlineNotifier.addListener(_onConnectivityChanged);
      _authChanges = FirebaseAuth.instance.authStateChanges().listen(
        (_) => _background?.request(immediately: true),
      );
      _background ??= BackgroundSyncCoordinator(
        refreshInterval: const Duration(minutes: 15),
        currentSession: () => _session,
        canRun: () =>
            _foreground &&
            ConnectivityService.isOnline &&
            isCloudAvailable &&
            needsReviewNotifier.value == null,
        synchronize: (session) async =>
            session == _session && await _runSync(session.username),
      );
      _background!.start();
    } else {
      _background?.request();
    }
  }

  static void requestBackgroundSync([String? username]) {
    if (username != null && username != AppState.currentUser) return;
    if (!_backgroundRunning) {
      startBackgroundSync();
    } else {
      _background?.request();
    }
  }

  static void _onConnectivityChanged() {
    if (ConnectivityService.isOnline) _background?.request(immediately: true);
  }

  static void pauseBackgroundSync({Object? owner}) {
    if (owner != null && !identical(owner, _viewOwner)) return;
    _foreground = false;
    _background?.pause();
  }

  static void resumeBackgroundSync({Object? owner}) {
    if (owner != null && !identical(owner, _viewOwner)) return;
    _foreground = true;
    if (needsReviewNotifier.value == null) _background?.resume();
  }

  static void stopBackgroundSync({Object? owner}) {
    if (owner != null && !identical(owner, _viewOwner)) return;
    _background?.stop();
    if (_backgroundRunning) {
      ConnectivityService.isOnlineNotifier.removeListener(
        _onConnectivityChanged,
      );
    }
    _backgroundRunning = false;
    unawaited(_authChanges?.cancel());
    _authChanges = null;
    _loginConflictHandler = null;
    if (owner != null) _viewOwner = null;
    needsReviewNotifier.value = null;
  }

  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(
    false,
  );
  static final ValueNotifier<DateTime?> lastSyncTimeNotifier =
      ValueNotifier<DateTime?>(null);
  static final ValueNotifier<String?> syncStatusMessageNotifier =
      ValueNotifier<String?>(null);

  /// Returns true if the user is authenticated with Firebase and cloud sync is available.
  static bool get isCloudAvailable {
    if (Firebase.apps.isEmpty) return false;
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return false;
    final currentAppUser = AppState.currentUser;
    // A verified Firebase UID must match the durable local vault binding.
    // A legacy username need not equal the Firebase email.
    if (currentAppUser == null || currentAppUser.isEmpty) return false;
    if (!fbUser.emailVerified || AppState.firebaseUid != fbUser.uid) {
      return false;
    }
    return true;
  }

  /// Current authenticated Firebase User UID
  static String? get currentUid =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  /// Checks whether cloud Firestore already has any data stored for the current Firebase UID or user.
  static Future<bool> hasCloudData([String? targetUid]) async {
    try {
      if (Firebase.apps.isEmpty) return false;
      final uid = targetUid ?? currentUid;
      if (uid == null) return false;
      final firestore = FirebaseFirestore.instance;
      for (final collection in SqliteLedgerStore.collections) {
        QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
        while (true) {
          Query<Map<String, dynamic>> query = firestore
              .collection('users')
              .doc(uid)
              .collection(collection)
              .orderBy(FieldPath.documentId)
              .limit(100);
          if (cursor != null) {
            query = query.startAfterDocument(cursor);
          }
          final page = await query.get(const GetOptions(source: Source.server));
          if (page.docs.any((d) => d.data()['_deleted'] != true)) {
            return true;
          }
          if (page.docs.length < 100) {
            break;
          }
          cursor = page.docs.last;
        }
      }
      final vaultDoc = await firestore
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('budgets')
          .get();
      if (vaultDoc.exists) return true;
    } catch (e) {
      debugPrint('CloudSyncService.hasCloudData check note: $e');
    }
    return false;
  }

  /// Calculates a summary of the local SQLite vault for conflict comparisons.
  static Future<VaultSummary> fetchLocalSummary(String username) async {
    final txs = await AppDatabase.instance.loadTransactions(username);
    final goals = await AppDatabase.instance.loadGoals(
      username,
      includeArchived: true,
    );
    double balance = 0.0;
    DateTime? latest;
    for (var tx in txs) {
      if (tx.isIncome) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
      if (latest == null || tx.date.isAfter(latest)) {
        latest = tx.date;
      }
    }
    return VaultSummary(
      totalBalance: balance,
      transactionCount: txs.length,
      goalsCount: goals.length,
      lastModified: latest,
    );
  }

  /// Calculates a summary of the Google Cloud Firestore vault for conflict comparisons.
  static Future<VaultSummary?> fetchCloudSummary([String? targetUid]) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      final uid = targetUid ?? currentUid;
      if (uid == null) return null;
      final firestore = FirebaseFirestore.instance;
      final txSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .get();
      final goalsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .get();
      double balance = 0.0;
      DateTime? latest;

      for (var doc in txSnapshot.docs) {
        final data = doc.data();
        if (data['_deleted'] == true) continue;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final isIncome = data['isIncome'] as bool? ?? false;
        if (isIncome) {
          balance += amount;
        } else {
          balance -= amount;
        }
        final dateStr = data['date'] as String?;
        if (dateStr != null) {
          final d = DateTime.tryParse(dateStr);
          if (d != null && (latest == null || d.isAfter(latest))) {
            latest = d;
          }
        }
      }

      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data()?['lastSyncedAt'] != null) {
        final ts = userDoc.data()!['lastSyncedAt'];
        if (ts is Timestamp) {
          latest = ts.toDate();
        }
      }

      return VaultSummary(
        totalBalance: balance,
        transactionCount: txSnapshot.docs
            .where((d) => d.data()['_deleted'] != true)
            .length,
        goalsCount: goalsSnapshot.docs
            .where((d) => d.data()['_deleted'] != true)
            .length,
        lastModified: latest,
      );
    } catch (e) {
      debugPrint('CloudSyncService.fetchCloudSummary error: $e');
      return null;
    }
  }

  /// Explicit conflict choices share the tested engine and bounded writer.
  static Future<bool> restoreFromCloud(String username) =>
      _runSync(username, mode: 'restore');
  static Future<bool> overwriteCloudWithLocal(String username) =>
      uploadFreshData(username);
  static Future<bool> uploadFreshData(String username) =>
      _runSync(username, mode: 'overwrite');
  static Future<bool> mixAndUploadData(String username) =>
      _runSync(username, mode: 'resolve');

  /// Local database mutations are durable; these helpers only request a drain.
  static Future<void> deleteTransactionFromCloud(String txId) =>
      _syncCurrentLedger();
  static Future<void> syncTransactionToCloud(model.Transaction tx) =>
      _syncCurrentLedger();

  static Future<void> _syncCurrentLedger() async {
    requestBackgroundSync();
  }

  /// Local writes are already durable; coalesce their upload with other changes.
  static Future<void> syncAccountsToCloud(List<String> accounts) async {
    requestBackgroundSync();
  }

  static Future<void> deleteGoalFromCloud(String goalId) =>
      _syncCurrentLedger();
  static Future<void> syncGoalsToCloud(List<SavingsGoal> goals) =>
      _syncCurrentLedger();

  /// Queue the already-persisted profile with other local changes.
  static Future<void> syncProfileToCloud(UserProfile profile) async {
    if (profile.username == AppState.currentUser) {
      requestBackgroundSync(profile.username);
    }
  }

  static Future<Map<String, dynamic>> _profileCloudData(
    UserProfile profile,
  ) async {
    final username = AppState.currentUser;
    if (username == null) throw StateError('No active account');
    final checkSession = _sessionGuard(username);
    if (checkSession == null) throw StateError('Cloud account unavailable');
    try {
      String? photoBase64;
      String? photoUrl;

      if (profile.photoPath != null && profile.photoPath!.isNotEmpty) {
        if (profile.photoPath!.startsWith('http://') ||
            profile.photoPath!.startsWith('https://')) {
          photoUrl = profile.photoPath;
        } else {
          try {
            final f = File(profile.photoPath!);
            if (await f.exists()) {
              final bytes = await f.readAsBytes();
              // Store as base64 data string (capped to ~300KB to stay safely within Firestore limits)
              if (bytes.lengthInBytes <= 350000) {
                photoBase64 = base64Encode(bytes);
              }
            }
          } catch (e) {
            debugPrint('CloudSyncService: Avatar read notice: $e');
          }
        }
      }

      final profileMap = <String, dynamic>{
        'email': profile.username,
        'displayName': profile.displayName,
        'bio': profile.bio,
        'currency': profile.currency,
        'primaryColor': profile.primaryColor.toARGB32(),
        'secondaryColor': profile.secondaryColor.toARGB32(),
        'textColor': profile.textColor?.toARGB32(),
        'theme': profile.theme,
        'lastSyncedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      };

      if (photoBase64 != null) {
        profileMap['photoBase64'] = photoBase64;
      }
      if (photoUrl != null) {
        profileMap['photoUrl'] = photoUrl;
      }

      checkSession();
      if (profile.username != username) {
        throw StateError('Profile account mismatch');
      }
      return profileMap;
    } catch (e) {
      debugPrint('CloudSyncService.syncProfileToCloud notice: $e');
      rethrow;
    }
  }

  /// Capture account identity AND session generation; returning to the same user
  /// after a logout still invalidates in-flight work from the old session.
  static void Function()? _sessionGuard(String username) {
    if (!isCloudAvailable || AppState.currentUser != username) return null;
    final user = FirebaseAuth.instance.currentUser!;
    if (!user.emailVerified || AppState.firebaseUid != user.uid) {
      return null;
    }
    final uid = user.uid;
    final generation = AppState.sessionGeneration;
    return () {
      if (AppState.currentUser != username ||
          AppState.sessionGeneration != generation ||
          FirebaseAuth.instance.currentUser?.uid != uid) {
        throw StateError('Account changed during synchronization');
      }
    };
  }

  static Future<void> _restoreMissingAvatar(
    String username,
    DocumentReference<Map<String, dynamic>> user,
    void Function() checkSession,
  ) async {
    final db = AppDatabase.instance;
    final profile = await db.loadProfile(username);
    checkSession();
    if (profile.photoPath != null &&
        !profile.photoPath!.startsWith('http') &&
        await File(profile.photoPath!).exists()) {
      return;
    }
    final cloud = (await user.get(
      const GetOptions(source: Source.server),
    )).data();
    checkSession();
    String? path = cloud?['photoUrl'] as String?;
    final encoded = cloud?['photoBase64'] as String?;
    if (encoded != null && encoded.isNotEmpty) {
      final bytes = base64Decode(encoded);
      if (bytes.length > 350000) {
        throw StateError('Cloud avatar exceeds supported size');
      }
      final directory = await getDatabasesPath();
      checkSession();
      final filename = 'avatar_${sha256.convert(utf8.encode(username))}.jpg';
      final file = File(join(directory, filename));
      await file.writeAsBytes(bytes);
      path = file.path;
    }
    checkSession();
    if (path != null && path.isNotEmpty) {
      await db.saveProfile(profile.copyWith(photoPath: path), queueSync: false);
      checkSession();
      AppState.profilePhotoNotifier.value = path;
    }
  }

  static Future<void> _syncMetadata(
    String username,
    void Function() checkSession, {
    required bool restore,
    required bool merge,
  }) async {
    checkSession();
    final user = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid!);
    final store = MetadataSyncStore(await AppDatabase.instance.database);
    final captured = await store.snapshot(username);
    checkSession();
    final accountsDoc = await user
        .collection('vault')
        .doc('accounts')
        .get(const GetOptions(source: Source.server));
    final budgetsDoc = await user
        .collection('vault')
        .doc('budgets')
        .get(const GetOptions(source: Source.server));
    checkSession();
    if (!captured.revisions.containsKey('profile')) {
      await _restoreMissingAvatar(username, user, checkSession);
    }
    checkSession();
    final db = AppDatabase.instance;
    final localAccounts = captured.accounts;
    final localBudgets = captured.budgets;
    final cloudAccounts =
        (accountsDoc.data()?['list'] as List?)?.cast<String>() ?? <String>[];
    final cloudBudgets = ((budgetsDoc.data()?['categories'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    );
    final accounts = restore
        ? cloudAccounts
        : (!merge || captured.revisions.containsKey('accounts')
              ? localAccounts
              : captured.baselines.containsKey('accounts') && accountsDoc.exists
              ? cloudAccounts
              : {...cloudAccounts, ...localAccounts}.toList());
    final budgets = restore
        ? cloudBudgets
        : (!merge || captured.revisions.containsKey('budgets')
              ? localBudgets
              : captured.baselines.containsKey('budgets') && budgetsDoc.exists
              ? cloudBudgets
              : {...cloudBudgets, ...localBudgets});
    checkSession();
    if (!restore) {
      final batch = user.firestore.batch();
      batch.set(user.collection('vault').doc('accounts'), {
        'list': accounts,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      checkSession();
      batch.set(user.collection('vault').doc('budgets'), {
        'categories': budgets,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      checkSession();
      final profile = captured.profile ?? await db.loadProfile(username);
      batch.set(
        user,
        await _profileCloudData(profile),
        SetOptions(merge: true),
      );
      checkSession();
      await batch.commit();
      checkSession();
    }
    await store.complete(
      username,
      captured,
      accounts,
      budgets,
      checkSession,
      profileUploaded: !restore,
    );
    checkSession();
    // Reload after the revision check: preserve edits made during upload.
    final latest = await store.snapshot(username);
    checkSession();
    if (!listEquals(AppState.accountsNotifier.value, latest.accounts)) {
      AppState.accountsNotifier.value = latest.accounts;
    }
    if (!mapEquals(AppState.budgetsNotifier.value, latest.budgets)) {
      AppState.budgetsNotifier.value = latest.budgets;
    }
  }

  /// Reconcile explicit mutations, then pull remote records. Local absence never
  /// deletes cloud data. Unresolved versions require explicit review; queued
  /// edits against the last acknowledged cloud version merge quietly.
  static Future<bool> sync(String username) => _runSync(username);

  static Future<bool> _runSync(String username, {String mode = 'merge'}) {
    final checkSession = _sessionGuard(username);
    if (checkSession == null) return Future.value(false);
    final task = _syncTail.then((_) async {
      try {
        checkSession();
      } catch (_) {
        return false;
      }
      return _performSync(username, mode, checkSession);
    });
    _syncTail = task.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return task;
  }

  static Future<bool> _performSync(
    String username,
    String mode,
    void Function() checkSession,
  ) async {
    final uid = currentUid!;
    isSyncingNotifier.value = true;
    try {
      syncStatusMessageNotifier.value = 'Synchronizing ledger...';
      final db = await AppDatabase.instance.database;
      checkSession();
      final remote = _FirestoreLedgerRemote(
        FirebaseFirestore.instance.collection('users').doc(uid),
        checkSession,
      );
      final engine = LedgerSyncEngine(
        SqliteLedgerStore(db),
        remote,
        checkSession: checkSession,
        onProgress: (committed) => syncStatusMessageNotifier.value =
            'Committed $committed ledger changes...',
      );
      final complete = switch (mode) {
        'restore' => await engine.restore(username),
        'overwrite' => await engine.overwrite(username),
        _ => await engine.sync(username, detectConflicts: mode == 'merge'),
      };
      checkSession();
      final transactions = await AppDatabase.instance.loadTransactions(
        username,
      );
      final goals = await AppDatabase.instance.loadGoals(username);
      checkSession();
      AppState.transactionsNotifier.value = transactions;
      AppState.goalsNotifier.value = goals;
      await _syncMetadata(
        username,
        checkSession,
        restore: mode == 'restore',
        merge: mode == 'merge' || mode == 'resolve',
      );
      checkSession();
      final pending = await SqliteLedgerStore(db).snapshot(username);
      checkSession();
      final pendingMetadata = await MetadataSyncStore(
        db,
      ).hasPending(username, includeProfile: mode != 'restore');
      checkSession();
      if (!complete || pending.pending.isNotEmpty || pendingMetadata) {
        syncStatusMessageNotifier.value =
            'Saved locally; newer changes are queued for background sync.';
        return false;
      }
      lastSyncTimeNotifier.value = DateTime.now();
      syncStatusMessageNotifier.value = 'Ledger synchronized successfully';
      needsReviewNotifier.value = null;
      _loginConflictHandler = null;
      if (mode != 'merge' && _foreground) {
        if (!_backgroundRunning) {
          startBackgroundSync();
        } else {
          _background?.resume();
        }
      }
      return true;
    } on LedgerConflictException catch (error) {
      try {
        checkSession();
      } catch (_) {
        return false;
      }
      final session = _session!;
      final details = CloudSyncConflict(
        session,
        _summary(error.local.records),
        _summary(error.cloud),
        error.conflicts.length,
      );
      needsReviewNotifier.value = details;
      syncStatusMessageNotifier.value =
          'Conflicting versions need review in Settings.';
      _background?.pause();
      final handler = _loginConflictHandler;
      _loginConflictHandler = null;
      handler?.call(details);
      return false;
    } catch (e) {
      try {
        checkSession();
      } catch (_) {
        return false;
      }
      syncStatusMessageNotifier.value =
          'Sync incomplete; pending changes retained: $e';
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  static VaultSummary _summary(LedgerRecords records) {
    final txs = records['transactions']!.values.where(
      (r) => r['_deleted'] != true,
    );
    return VaultSummary(
      totalBalance: txs.fold<double>(
        0,
        (total, r) =>
            total +
            ((r['isIncome'] as bool? ?? false) ? 1 : -1) *
                (r['amount'] as num).toDouble(),
      ),
      transactionCount: txs.length,
      goalsCount: records['goals']!.values
          .where((r) => r['_deleted'] != true)
          .length,
    );
  }
}

class _FirestoreLedgerRemote implements LedgerRemote {
  final DocumentReference<Map<String, dynamic>> user;
  final void Function() checkSession;
  LedgerRecords? _observed;
  _FirestoreLedgerRemote(this.user, this.checkSession);

  @override
  Future<LedgerRecords> read() async {
    final result = <String, Map<String, Map<String, dynamic>>>{};
    for (final collection in SqliteLedgerStore.collections) {
      checkSession();
      // Do not reconcile against a stale offline cache. Failed reads leave the
      // durable outbox untouched and report incomplete sync.
      final snapshot = await user
          .collection(collection)
          .get(const GetOptions(source: Source.server));
      checkSession();
      result[collection] = {
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };
    }
    _observed = result;
    return result;
  }

  @override
  Future<void> commit(List<LedgerWrite> writes) async {
    checkSession();
    final observed = _observed;
    if (observed == null) {
      throw StateError('Read cloud versions before committing');
    }
    // A mobile transaction protects each bounded chunk from an edit arriving
    // between preflight and commit. Failed chunks leave the outbox untouched.
    await user.firestore.runTransaction((txn) async {
      checkSession();
      final documents = await Future.wait(
        writes.map((w) => txn.get(user.collection(w.collection).doc(w.id))),
      );
      checkSession();
      for (var i = 0; i < writes.length; i++) {
        final write = writes[i];
        final expected = observed[write.collection]?[write.id];
        final actual = documents[i].data();
        if ((expected == null) != (actual == null) ||
            (expected != null &&
                actual != null &&
                syncFingerprint(write.collection, write.id, expected) !=
                    syncFingerprint(write.collection, write.id, actual))) {
          throw const RemoteLedgerChanged();
        }
      }
      for (final write in writes) {
        txn.set(user.collection(write.collection).doc(write.id), {
          ...write.data,
          '_updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
    checkSession();
  }
}
