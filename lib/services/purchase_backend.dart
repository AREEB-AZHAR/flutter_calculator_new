import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class PurchaseSecurityPolicy {
  @visibleForTesting
  static bool? developmentOverride;
  static bool get allowDevelopmentUnlocks =>
      !kReleaseMode && developmentOverride != false;
}

abstract interface class PurchaseBackend {
  Future<Map<String, dynamic>> verify(String productId, String token);
  Future<Map<String, dynamic>> refresh();
}

class FirebasePurchaseBackend implements PurchaseBackend {
  @override
  Future<Map<String, dynamic>> verify(String productId, String token) async {
    final response = await FirebaseFunctions.instance
        .httpsCallable('verifyGooglePlayPurchase')
        .call({
          'productId': productId,
          'token': token,
          'source': 'google_play',
        });
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>> refresh() async {
    final response = await FirebaseFunctions.instance
        .httpsCallable('refreshPurchaseEntitlements')
        .call();
    return Map<String, dynamic>.from(response.data as Map);
  }
}

class PurchaseSession {
  final String uid;
  final String username;
  final int generation;
  const PurchaseSession(this.uid, this.username, this.generation);
  bool matches(PurchaseSession? other) =>
      other != null &&
      uid == other.uid &&
      username == other.username &&
      generation == other.generation;
}

class VerifiedEntitlements {
  final bool pro;
  final bool ads;
  final DateTime? trialExpiry;
  final DateTime leaseExpiry;
  const VerifiedEntitlements(
    this.pro,
    this.ads,
    this.trialExpiry,
    this.leaseExpiry,
  );
  factory VerifiedEntitlements.parse(
    Map<String, dynamic> data,
    String uid,
    DateTime now,
  ) {
    final issued = data['issuedAtMs'];
    final expiry = data['leaseExpiresAtMs'];
    if (data['schema'] != 2 ||
        data['uid'] != uid ||
        issued is! num ||
        expiry is! num ||
        !issued.isFinite ||
        !expiry.isFinite ||
        expiry <= now.millisecondsSinceEpoch ||
        expiry - issued > const Duration(minutes: 15).inMilliseconds ||
        issued > now.millisecondsSinceEpoch + 300000 ||
        data['pro_unlocked'] is! bool ||
        data['ads_removed'] is! bool) {
      throw StateError('The server did not return a valid entitlement lease.');
    }
    final trial = data['trial_expiry'];
    if (trial != null && (trial is! String || DateTime.tryParse(trial) == null)) {
      throw StateError('Invalid trial expiry.');
    }
    return VerifiedEntitlements(
      data['pro_unlocked'] as bool,
      data['ads_removed'] as bool,
      trial == null ? null : DateTime.parse(trial as String),
      DateTime.fromMillisecondsSinceEpoch(expiry.toInt()),
    );
  }
}

/// Delivery and store completion are strictly ordered after backend verification.
class PurchaseCoordinator {
  final PurchaseBackend backend;
  final PurchaseSession? Function() currentSession;
  final Future<void> Function(VerifiedEntitlements, PurchaseSession) deliver;
  final DateTime Function() now;
  PurchaseCoordinator({
    required this.backend,
    required this.currentSession,
    required this.deliver,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<void> process({
    required String productId,
    required String token,
    required String source,
    required Future<void> Function() complete,
  }) async {
    final session = currentSession();
    if (session == null) {
      throw StateError(
        'Sign in with the Google account used for this purchase.',
      );
    }
    if (source != 'google_play' || token.isEmpty) {
      throw StateError('Only Google Play verification is supported.');
    }
    final response = await backend.verify(productId, token);
    if (!session.matches(currentSession())) {
      throw StateError('Account changed during purchase verification.');
    }
    if (response['verified'] != true ||
        response['productId'] != productId ||
        response['tokenHash'] != sha256.convert(utf8.encode(token)).toString()) {
      throw StateError('Purchase verification failed.');
    }
    final lease = VerifiedEntitlements.parse(
      Map<String, dynamic>.from(response['entitlements'] as Map),
      session.uid,
      now(),
    );
    await deliver(lease, session);
    if (response['active'] != true) {
      throw StateError('This purchase is pending, expired or revoked.');
    }
    if (!session.matches(currentSession())) {
      throw StateError('Account changed before purchase completion.');
    }
    await complete();
  }
}
