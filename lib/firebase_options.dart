import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:shared_preferences/shared_preferences.dart';

/// Default [FirebaseOptions] for use with your Firebase apps in Tally.
///
/// Can be configured via Firebase Console or dynamically via Tally's in-app
/// Firebase setup dialog.
class DefaultFirebaseOptions {
  static const String _prefFirebaseApiKey = 'tally_firebase_api_key';
  static const String _prefFirebaseAppId = 'tally_firebase_app_id';
  static const String _prefFirebaseProjectId = 'tally_firebase_project_id';
  static const String _prefFirebaseSenderId = 'tally_firebase_messaging_sender_id';
  static const String _prefFirebaseAuthDomain = 'tally_firebase_auth_domain';

  // Configured project constants (can be populated directly from Firebase Console)
  static String apiKey = 'AIzaSyCW-hZvcyqH3OlEEDnCaD8gCpG_XBtcxxw';
  static String appId = '1:494819662703:android:1eed08eedd66202a07e69a';
  static String messagingSenderId = '494819662703';
  static String projectId = 'tally-b3652';
  static String authDomain = 'tally-b3652.firebaseapp.com';
  static String storageBucket = 'tally-b3652.firebasestorage.app';

  /// Checks if Firebase credentials have been configured
  static bool get isConfigured {
    return apiKey.isNotEmpty && projectId.isNotEmpty;
  }

  /// Initializes credentials from SharedPreferences if saved
  static Future<void> loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApiKey = prefs.getString(_prefFirebaseApiKey);
      final savedProjectId = prefs.getString(_prefFirebaseProjectId);
      final savedAppId = prefs.getString(_prefFirebaseAppId);
      final savedSenderId = prefs.getString(_prefFirebaseSenderId);
      final savedAuthDomain = prefs.getString(_prefFirebaseAuthDomain);

      if (savedApiKey != null && savedApiKey.isNotEmpty) apiKey = savedApiKey;
      if (savedProjectId != null && savedProjectId.isNotEmpty) projectId = savedProjectId;
      if (savedAppId != null && savedAppId.isNotEmpty) appId = savedAppId;
      if (savedSenderId != null && savedSenderId.isNotEmpty) messagingSenderId = savedSenderId;
      if (savedAuthDomain != null && savedAuthDomain.isNotEmpty) authDomain = savedAuthDomain;
    } catch (_) {}
  }

  /// Saves runtime configuration
  static Future<void> saveConfig({
    required String newApiKey,
    required String newProjectId,
    String? newAppId,
    String? newSenderId,
    String? newAuthDomain,
  }) async {
    apiKey = newApiKey.trim();
    projectId = newProjectId.trim();
    if (newAppId != null) appId = newAppId.trim();
    if (newSenderId != null) messagingSenderId = newSenderId.trim();
    if (newAuthDomain != null && newAuthDomain.isNotEmpty) {
      authDomain = newAuthDomain.trim();
    } else {
      authDomain = '$projectId.firebaseapp.com';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFirebaseApiKey, apiKey);
      await prefs.setString(_prefFirebaseProjectId, projectId);
      await prefs.setString(_prefFirebaseAppId, appId);
      await prefs.setString(_prefFirebaseSenderId, messagingSenderId);
      await prefs.setString(_prefFirebaseAuthDomain, authDomain);
    } catch (_) {}
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: apiKey.isNotEmpty ? apiKey : 'placeholder_android_key',
        appId: appId.isNotEmpty ? appId : '1:000000000000:android:0000000000000000',
        messagingSenderId: messagingSenderId.isNotEmpty ? messagingSenderId : '000000000000',
        projectId: projectId.isNotEmpty ? projectId : 'tally-finance-app',
        storageBucket: storageBucket.isNotEmpty ? storageBucket : '$projectId.appspot.com',
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: apiKey.isNotEmpty ? apiKey : 'placeholder_windows_key',
        appId: appId.isNotEmpty ? appId : '1:000000000000:web:0000000000000000',
        messagingSenderId: messagingSenderId.isNotEmpty ? messagingSenderId : '000000000000',
        projectId: projectId.isNotEmpty ? projectId : 'tally-finance-app',
        authDomain: authDomain.isNotEmpty ? authDomain : '$projectId.firebaseapp.com',
        storageBucket: storageBucket.isNotEmpty ? storageBucket : '$projectId.appspot.com',
      );

  static FirebaseOptions get web => windows;
  static FirebaseOptions get ios => android;
  static FirebaseOptions get macos => windows;
  static FirebaseOptions get linux => windows;
}
