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
    // Strictly isolate cloud sync to the authenticated Google/Firebase user.
    // If the active app user is a local password user or differs from the Firebase account, prevent sync bleed.
    if (currentAppUser == null || currentAppUser.isEmpty) return false;
    if (fbUser.email == null ||
        fbUser.email!.toLowerCase() != currentAppUser.toLowerCase()) {
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
  static Future<bool> mixAndUploadData(String username) => _runSync(username);

  /// Local database mutations are durable; these helpers only request a drain.
  static Future<void> deleteTransactionFromCloud(String txId) =>
      _syncCurrentLedger();
  static Future<void> syncTransactionToCloud(model.Transaction tx) =>
      _syncCurrentLedger();

  static Future<void> _syncCurrentLedger() async {
    final username = AppState.currentUser;
    if (username != null) await sync(username);
  }

  /// Immediately updates accounts in Firestore vault.
  static Future<void> syncAccountsToCloud(List<String> accounts) async {
    final username = AppState.currentUser;
    if (username == null) return;
    final checkSession = _sessionGuard(username);
    if (checkSession == null) return;
    final uid = currentUid!;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('accounts')
          .set({'list': accounts, 'updatedAt': FieldValue.serverTimestamp()});
      debugPrint(
        'CloudSyncService: Synced ${accounts.length} accounts to cloud',
      );
    } catch (e) {
      debugPrint('CloudSyncService.syncAccountsToCloud notice: $e');
    }
  }

  static Future<void> deleteGoalFromCloud(String goalId) =>
      _syncCurrentLedger();
  static Future<void> syncGoalsToCloud(List<SavingsGoal> goals) =>
      _syncCurrentLedger();

  /// Immediately syncs user profile and uploaded avatar to Firestore.
  static Future<void> syncProfileToCloud(
    UserProfile profile, {
    bool propagateErrors = false,
  }) async {
    final username = AppState.currentUser;
    if (username == null) return;
    final checkSession = _sessionGuard(username);
    if (checkSession == null) return;
    final uid = currentUid!;
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);

      String? photoBase64;
      String? photoUrl;

      if (profile.photoPath != null && profile.photoPath!.isNotEmpty) {
        if (profile.photoPath!.startsWith('http://') ||
            profile.photoPath!.startsWith('https://')) {
          photoUrl = profile.photoPath;
        } else {
          try {
            final f = File(profile.photoPath!);
            if (f.existsSync()) {
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
      await userRef.set(profileMap, SetOptions(merge: true));
      debugPrint(
        'CloudSyncService: Profile and avatar synced to cloud for ${profile.username}',
      );
    } catch (e) {
      debugPrint('CloudSyncService.syncProfileToCloud notice: $e');
      if (propagateErrors) rethrow;
    }
  }

  /// Capture account identity AND session generation; returning to the same user
  /// after a logout still invalidates in-flight work from the old session.
  static void Function()? _sessionGuard(String username) {
    if (!isCloudAvailable || AppState.currentUser != username) return null;
    final user = FirebaseAuth.instance.currentUser!;
    if (user.email == null ||
        user.email!.toLowerCase() != username.toLowerCase()) {
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
      await db.saveProfile(profile.copyWith(photoPath: path));
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
    final accountsDoc = await user
        .collection('vault')
        .doc('accounts')
        .get(const GetOptions(source: Source.server));
    final budgetsDoc = await user
        .collection('vault')
        .doc('budgets')
        .get(const GetOptions(source: Source.server));
    checkSession();
    await _restoreMissingAvatar(username, user, checkSession);
    checkSession();
    final db = AppDatabase.instance;
    final localAccounts = await db.loadAccounts(username);
    final localBudgets = await db.loadBudgets(username);
    final cloudAccounts =
        (accountsDoc.data()?['list'] as List?)?.cast<String>() ?? <String>[];
    final cloudBudgets = ((budgetsDoc.data()?['categories'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    );
    final accounts = restore
        ? cloudAccounts
        : (merge
              ? {...cloudAccounts, ...localAccounts}.toList()
              : localAccounts);
    final budgets = restore
        ? cloudBudgets
        : (merge ? {...cloudBudgets, ...localBudgets} : localBudgets);
    checkSession();
    await db.saveAccounts(username, accounts);
    await db.saveBudgets(username, budgets);
    checkSession();
    AppState.accountsNotifier.value = accounts;
    AppState.budgetsNotifier.value = budgets;
    if (!restore) {
      await user.collection('vault').doc('accounts').set({
        'list': accounts,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      checkSession();
      await user.collection('vault').doc('budgets').set({
        'categories': budgets,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      checkSession();
      await syncProfileToCloud(
        await db.loadProfile(username),
        propagateErrors: true,
      );
      checkSession();
    }
  }

  /// Reconcile explicit mutations, then pull remote records. Local absence never
  /// deletes cloud data. Unedited legacy conflicts prefer the remote record;
  /// pending explicit local edits use last successful commit wins.
  static Future<bool> sync(String username) => _runSync(username);

  static Future<bool> _runSync(String username, {String mode = 'merge'}) async {
    final checkSession = _sessionGuard(username);
    if (checkSession == null || isSyncingNotifier.value) return false;
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
        _ => await engine.sync(username),
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
        merge: mode == 'merge',
      );
      checkSession();
      final pending = await SqliteLedgerStore(db).snapshot(username);
      checkSession();
      if (!complete || pending.pending.isNotEmpty) {
        syncStatusMessageNotifier.value =
            'Ledger saved; newer local changes are pending. Sync again.';
        return false;
      }
      lastSyncTimeNotifier.value = DateTime.now();
      syncStatusMessageNotifier.value = 'Ledger synchronized successfully';
      return true;
    } catch (e) {
      syncStatusMessageNotifier.value =
          'Sync incomplete; pending changes retained: $e';
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }
}

class _FirestoreLedgerRemote implements LedgerRemote {
  final DocumentReference<Map<String, dynamic>> user;
  final void Function() checkSession;
  const _FirestoreLedgerRemote(this.user, this.checkSession);

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
    return result;
  }

  @override
  Future<void> commit(List<LedgerWrite> writes) async {
    checkSession();
    final batch = user.firestore.batch();
    for (final write in writes) {
      batch.set(user.collection(write.collection).doc(write.id), {
        ...write.data,
        '_updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    checkSession();
  }
}
