import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart' as model;
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

      // 1. Sync Profile & Preferences
      syncStatusMessageNotifier.value = 'Syncing profile & settings...';
      final profile = await AppDatabase.instance.loadProfile(username);
      await userRef.set({
        'email': username,
        'displayName': profile.displayName,
        'bio': profile.bio,
        'currency': profile.currency,
        'primaryColor': profile.primaryColor.toARGB32(),
        'secondaryColor': profile.secondaryColor.toARGB32(),
        'textColor': profile.textColor?.toARGB32(),
        'theme': profile.theme,
        'lastSyncedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      }, SetOptions(merge: true));

      // 2. Sync Accounts
      final localAccounts = await AppDatabase.instance.loadAccounts(username);
      final accountsDoc = await userRef.collection('vault').doc('accounts').get();
      if (accountsDoc.exists && localAccounts.length <= 4) {
        final data = accountsDoc.data();
        if (data != null && data['list'] is List) {
          final cloudAccounts = (data['list'] as List).cast<String>();
          if (cloudAccounts.length > localAccounts.length) {
            await AppDatabase.instance.saveAccounts(username, cloudAccounts);
            AppState.loadAccounts(username);
          }
        }
      } else {
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

      // 4. Sync Transactions
      syncStatusMessageNotifier.value = 'Securing transactions...';
      final localTxs = await AppDatabase.instance.loadTransactions(username);
      final txCollection = userRef.collection('transactions');

      if (localTxs.isNotEmpty) {
        // Upload local transactions to Firestore in batches
        final batch = firestore.batch();
        int count = 0;
        for (var tx in localTxs) {
          final doc = txCollection.doc(tx.id);
          batch.set(doc, tx.toJson(), SetOptions(merge: true));
          count++;
          if (count >= 400) break; // stay within Firestore 500 batch limit
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
        final batch = firestore.batch();
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
