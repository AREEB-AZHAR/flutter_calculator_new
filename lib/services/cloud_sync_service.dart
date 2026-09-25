import 'dart:convert';
import 'dart:io';
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

/// Secure Cloud Data Synchronization Engine for Tally.
///
/// Coordinates two-way synchronization between on-device encrypted SQLite
/// and Google Cloud Firestore under strictly isolated per-user vault paths:
/// `/users/{userId}/...`.
class CloudSyncService {
  CloudSyncService._();

  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<DateTime?> lastSyncTimeNotifier = ValueNotifier<DateTime?>(null);
  static final ValueNotifier<String?> syncStatusMessageNotifier = ValueNotifier<String?>(null);

  /// Returns true if the user is authenticated with Firebase and cloud sync is available.
  static bool get isCloudAvailable {
    if (Firebase.apps.isEmpty) return false;
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Current authenticated Firebase User UID
  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Checks whether cloud Firestore already has any data stored for the current Firebase UID or user.
  static Future<bool> hasCloudData([String? targetUid]) async {
    if (!isCloudAvailable) return false;
    final uid = targetUid ?? currentUid;
    if (uid == null) return false;
    try {
      final firestore = FirebaseFirestore.instance;
      final txSnapshot = await firestore.collection('users').doc(uid).collection('transactions').limit(1).get();
      if (txSnapshot.docs.isNotEmpty) return true;
      final goalsSnapshot = await firestore.collection('users').doc(uid).collection('goals').limit(1).get();
      if (goalsSnapshot.docs.isNotEmpty) return true;
      final vaultDoc = await firestore.collection('users').doc(uid).collection('vault').doc('budgets').get();
      if (vaultDoc.exists) return true;
    } catch (e) {
      debugPrint('CloudSyncService.hasCloudData check error: $e');
    }
    return false;
  }

  /// Immediately deletes a transaction document from Firestore.
  static Future<void> deleteTransactionFromCloud(String txId) async {
    if (!isCloudAvailable) return;
    final uid = currentUid;
    if (uid == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).collection('transactions').doc(txId).delete();
      debugPrint('CloudSyncService: Deleted transaction $txId from cloud');
    } catch (e) {
      debugPrint('CloudSyncService.deleteTransactionFromCloud notice: $e');
    }
  }

  /// Immediately syncs a single transaction document to Firestore.
  static Future<void> syncTransactionToCloud(model.Transaction tx) async {
    if (!isCloudAvailable) return;
    final uid = currentUid;
    if (uid == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).collection('transactions').doc(tx.id).set(
        tx.toJson(),
        SetOptions(merge: true),
      );
      debugPrint('CloudSyncService: Synced transaction ${tx.id} to cloud');
    } catch (e) {
      debugPrint('CloudSyncService.syncTransactionToCloud notice: $e');
    }
  }

  /// Immediately updates accounts in Firestore vault.
  static Future<void> syncAccountsToCloud(List<String> accounts) async {
    if (!isCloudAvailable) return;
    final uid = currentUid;
    if (uid == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).collection('vault').doc('accounts').set({
        'list': accounts,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('CloudSyncService: Synced ${accounts.length} accounts to cloud');
    } catch (e) {
      debugPrint('CloudSyncService.syncAccountsToCloud notice: $e');
    }
  }

  /// Immediately deletes a savings goal from Firestore.
  static Future<void> deleteGoalFromCloud(String goalId) async {
    if (!isCloudAvailable) return;
    final uid = currentUid;
    if (uid == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).collection('goals').doc(goalId).delete();
      debugPrint('CloudSyncService: Deleted goal $goalId from cloud');
    } catch (e) {
      debugPrint('CloudSyncService.deleteGoalFromCloud notice: $e');
    }
  }

  /// Immediately syncs savings goals to Firestore.
  static Future<void> syncGoalsToCloud(List<SavingsGoal> goals) async {
    if (!isCloudAvailable) return;
    final uid = currentUid;
    if (uid == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final goalsCollection = firestore.collection('users').doc(uid).collection('goals');
      final batch = firestore.batch();
      for (var g in goals) {
        batch.set(goalsCollection.doc(g.id), g.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('CloudSyncService: Synced ${goals.length} goals to cloud');
    } catch (e) {
      debugPrint('CloudSyncService.syncGoalsToCloud notice: $e');
    }
  }

  /// Immediately syncs user profile and uploaded avatar to Firestore.
  static Future<void> syncProfileToCloud(UserProfile profile) async {
    if (!isCloudAvailable) return;
    final uid = currentUid;
    if (uid == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);

      String? photoBase64;
      String? photoUrl;

      if (profile.photoPath != null && profile.photoPath!.isNotEmpty) {
        if (profile.photoPath!.startsWith('http://') || profile.photoPath!.startsWith('https://')) {
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

      await userRef.set(profileMap, SetOptions(merge: true));
      debugPrint('CloudSyncService: Profile and avatar synced to cloud for ${profile.username}');
    } catch (e) {
      debugPrint('CloudSyncService.syncProfileToCloud notice: $e');
    }
  }

  /// Performs an intelligent two-way synchronization between SQLite and Firestore.
  static Future<bool> sync(String username) async {
    if (!isCloudAvailable) {
      debugPrint('CloudSyncService: Firebase Auth user not present, skipping cloud sync.');
      return false;
    }

    final uid = currentUid;
    if (uid == null) return false;

    if (isSyncingNotifier.value) return false;

    isSyncingNotifier.value = true;
    syncStatusMessageNotifier.value = 'Connecting to Google Cloud Vault...';

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);

      // 1. Sync Profile & Uploaded Avatar
      syncStatusMessageNotifier.value = 'Syncing profile & avatar...';
      final profile = await AppDatabase.instance.loadProfile(username);
      
      // Fetch cloud user doc to check if cloud has newer avatar or fields
      final cloudUserDoc = await userRef.get();
      if (cloudUserDoc.exists) {
        final cData = cloudUserDoc.data();
        if (cData != null) {
          // If cloud has an uploaded photoBase64 and local photoPath is missing or non-existent
          final cloudPhotoBase64 = cData['photoBase64'] as String?;
          final cloudPhotoUrl = cData['photoUrl'] as String?;
          final localFileExists = profile.photoPath != null && 
              !profile.photoPath!.startsWith('http') && 
              File(profile.photoPath!).existsSync();

          if (!localFileExists && cloudPhotoBase64 != null && cloudPhotoBase64.isNotEmpty) {
            try {
              final bytes = base64Decode(cloudPhotoBase64);
              final dbDir = await getDatabasesPath();
              final safeName = username.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
              final localAvatarFile = File(join(dbDir, 'avatar_$safeName.jpg'));
              await localAvatarFile.writeAsBytes(bytes);
              
              final updatedProfile = profile.copyWith(photoPath: localAvatarFile.path);
              await AppDatabase.instance.saveProfile(updatedProfile);
              AppState.profilePhotoNotifier.value = localAvatarFile.path;
            } catch (e) {
              debugPrint('Error restoring avatar from cloud: $e');
            }
          } else if (!localFileExists && cloudPhotoUrl != null && cloudPhotoUrl.isNotEmpty) {
            final updatedProfile = profile.copyWith(photoPath: cloudPhotoUrl);
            await AppDatabase.instance.saveProfile(updatedProfile);
            AppState.profilePhotoNotifier.value = cloudPhotoUrl;
          }
        }
      }

      // Upload local profile & avatar to Firestore
      await syncProfileToCloud(profile);

      // 2. Sync Accounts (Authoritative local-to-cloud sync; never resurrect deleted accounts)
      final localAccounts = await AppDatabase.instance.loadAccounts(username);
      final accountsDoc = await userRef.collection('vault').doc('accounts').get();
      if (accountsDoc.exists && localAccounts.isEmpty) {
        // Fresh device with no local accounts -> pull from cloud
        final data = accountsDoc.data();
        if (data != null && data['list'] is List) {
          final cloudAccounts = (data['list'] as List).cast<String>();
          if (cloudAccounts.isNotEmpty) {
            await AppDatabase.instance.saveAccounts(username, cloudAccounts);
            AppState.loadAccounts(username);
          }
        }
      } else {
        // Local has accounts -> push local state to cloud so deletions are accurately captured
        await userRef.collection('vault').doc('accounts').set({
          'list': localAccounts,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Sync Budgets
      final localBudgets = await AppDatabase.instance.loadBudgets(username);
      await userRef.collection('vault').doc('budgets').set({
        'categories': localBudgets,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Sync Transactions with Deletion Reconciliation
      syncStatusMessageNotifier.value = 'Securing transactions...';
      final localTxs = await AppDatabase.instance.loadTransactions(username);
      final txCollection = userRef.collection('transactions');

      if (localTxs.isNotEmpty) {
        final localIdSet = localTxs.map((t) => t.id).toSet();
        final cloudSnapshot = await txCollection.get();
        final batch = firestore.batch();

        // Delete cloud transactions that were deleted locally
        for (var doc in cloudSnapshot.docs) {
          if (!localIdSet.contains(doc.id)) {
            batch.delete(doc.reference);
          }
        }

        // Upsert all local transactions
        int count = 0;
        for (var tx in localTxs) {
          final doc = txCollection.doc(tx.id);
          batch.set(doc, tx.toJson(), SetOptions(merge: true));
          count++;
          if (count >= 400) break; // stay within Firestore batch limits
        }
        await batch.commit();
      } else {
        // Local is empty (e.g. freshly reinstalled app or new device) -> Restore from Firestore
        final cloudSnapshot = await txCollection.get();
        if (cloudSnapshot.docs.isNotEmpty) {
          final restoredTxs = cloudSnapshot.docs.map((doc) => model.Transaction.fromJson(doc.data())).toList();
          await AppDatabase.instance.saveTransactions(username, restoredTxs);
          await AppState.loadTransactions(username);
        }
      }

      // 5. Sync Savings Goals
      syncStatusMessageNotifier.value = 'Syncing savings goals...';
      final localGoals = await AppDatabase.instance.loadGoals(username);
      final goalsCollection = userRef.collection('goals');

      if (localGoals.isNotEmpty) {
        final localGoalIdSet = localGoals.map((g) => g.id).toSet();
        final cloudGoalsSnapshot = await goalsCollection.get();
        final batch = firestore.batch();

        // Delete goals in cloud that were removed locally
        for (var doc in cloudGoalsSnapshot.docs) {
          if (!localGoalIdSet.contains(doc.id)) {
            batch.delete(doc.reference);
          }
        }

        for (var g in localGoals) {
          batch.set(goalsCollection.doc(g.id), g.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
      } else {
        final cloudGoalsSnapshot = await goalsCollection.get();
        if (cloudGoalsSnapshot.docs.isNotEmpty) {
          final restoredGoals = cloudGoalsSnapshot.docs.map((d) => SavingsGoal.fromJson(d.data())).toList();
          await AppDatabase.instance.saveGoals(username, restoredGoals);
          await AppState.loadGoals(username);
        }
      }

      lastSyncTimeNotifier.value = DateTime.now();
      syncStatusMessageNotifier.value = 'Vault synchronized successfully';
      debugPrint('CloudSyncService: Vault sync completed for $username (uid: $uid)');
      return true;
    } catch (e) {
      debugPrint('CloudSyncService error: $e');
      syncStatusMessageNotifier.value = 'Sync notice: $e';
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }
}
