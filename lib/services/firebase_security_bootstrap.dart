import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseSecurityBootstrap {
  static bool _attestationActivated = false;
  static Future<void> initialize() async {
    await DefaultFirebaseOptions.loadSavedConfig();
    if (!DefaultFirebaseOptions.isConfigured) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (!_attestationActivated && !kIsWeb && Platform.isAndroid) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kReleaseMode
            ? const AndroidPlayIntegrityProvider()
            : const AndroidDebugProvider(),
      );
      _attestationActivated = true;
    }
  }
}
