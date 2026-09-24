import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'cloud_sync_service.dart';
import 'state.dart';
import 'database/app_database.dart';

class GoogleUserData {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  const GoogleUserData({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

class GoogleAuthService {
  static const String _prefLastGoogleEmailKey = 'tally_last_google_email';
  static const String _prefLastGoogleNameKey = 'tally_last_google_name';

  // Pre-extracted Android Debug Keystore Fingerprints for Firebase Console
  static const String androidPackageName = 'com.areeb.balance_tracker';
  static const String androidSha1 = 'B7:71:9D:F2:CA:FE:82:46:4A:B9:91:40:59:C1:72:0B:8E:96:BD:CB';
  static const String androidSha256 = '82:E4:2C:AE:78:94:99:F4:F9:7D:3A:8B:16:D9:CB:F9:71:5D:F5:0A:A7:D4:77:E8:FF:1E:67:6C:41:21:EA:99';

  /// Checks if the currently active user in AppState is bound to a Google Account.
  static bool get isCurrentGoogleUser {
    final user = AppState.currentUser;
    return user != null && user.contains('@');
  }

  /// Retrieves the saved Google email from preferences if available.
  static Future<String?> getSavedGoogleEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefLastGoogleEmailKey);
    } catch (_) {
      return null;
    }
  }

  /// Initiates authentic Google Sign-In powered by Firebase Authentication
  /// across Android, iOS, Web, and Windows desktop.
  static Future<GoogleUserData?> signIn(BuildContext context) async {
    GoogleUserData? googleUser;

    // Ensure Firebase config is loaded
    if (!DefaultFirebaseOptions.isConfigured) {
      await DefaultFirebaseOptions.loadSavedConfig();
    }

    if (DefaultFirebaseOptions.isConfigured && Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (e) {
        debugPrint('Firebase initializeApp notice: $e');
      }
    }

    // 1. If Firebase is initialized, run real Google Sign-In
    if (Firebase.apps.isNotEmpty) {
      try {
        if (!kIsWeb && Platform.isAndroid) {
          // Native Android Google Play Services flow
          final gAccount = await GoogleSignIn.instance.authenticate();
          final gAuth = gAccount.authentication;
          final credential = GoogleAuthProvider.credential(
            idToken: gAuth.idToken,
          );
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          final fbUser = userCred.user;
          if (fbUser != null && fbUser.email != null) {
            googleUser = GoogleUserData(
              id: fbUser.uid,
              email: fbUser.email!,
              displayName: fbUser.displayName ?? fbUser.email!.split('@').first,
              photoUrl: fbUser.photoURL,
            );
          }
        } else {
          // Windows Desktop, Web, macOS, Linux flow
          final googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          googleProvider.addScope('profile');
          final userCred = await FirebaseAuth.instance.signInWithProvider(googleProvider);
          final fbUser = userCred.user;
          if (fbUser != null && fbUser.email != null) {
            googleUser = GoogleUserData(
              id: fbUser.uid,
              email: fbUser.email!,
              displayName: fbUser.displayName ?? fbUser.email!.split('@').first,
              photoUrl: fbUser.photoURL,
            );
          }
        }
      } catch (e) {
        debugPrint('Firebase Google Sign-In error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Sign-In failed: $e'),
              backgroundColor: Colors.redAccent.shade700,
            ),
          );
        }
      }
    } else {
      // 2. Firebase is not yet configured. Open the Firebase Setup Modal
      if (context.mounted) {
        googleUser = await _showFirebaseSetupModal(context);
      }
    }

    if (googleUser != null) {
      // 3. Bind to SQLite Database
      await AppDatabase.instance.authenticateOrRegisterGoogleUser(
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );

      // Save preference for quick account switching
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefLastGoogleEmailKey, googleUser.email);
        await prefs.setString(_prefLastGoogleNameKey, googleUser.displayName);
      } catch (_) {}

      // Trigger cloud synchronization in the background
      CloudSyncService.sync(googleUser.email);
    }

    return googleUser;
  }

  /// Signs out of the Google and Firebase session
  static Future<void> signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
      if (kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS))) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
  }

  /// Authentic Firebase Configuration modal allowing instant setup
  /// with pre-extracted SHA-1, package name, and input fields.
  static Future<GoogleUserData?> _showFirebaseSetupModal(BuildContext context) async {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final apiKeyCtrl = TextEditingController(text: DefaultFirebaseOptions.apiKey);
    final projectIdCtrl = TextEditingController(text: DefaultFirebaseOptions.projectId);
    final appIdCtrl = TextEditingController(text: DefaultFirebaseOptions.appId);

    if (!context.mounted) return null;

    final configured = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: onSurface.withValues(alpha: 0.12), width: 1.2),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect Real Google Account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      Text(
                        'Firebase Authentication Setup',
                        style: TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To authenticate your actual Google Account, connect your free Firebase project credentials below:',
                    style: TextStyle(
                      fontSize: 13,
                      color: onSurface.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pre-extracted Credentials Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 16, color: primary),
                            const SizedBox(width: 8),
                            Text(
                              'Your App Fingerprints (Copy for Firebase):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildCopyRow(
                          ctx,
                          label: 'Package Name',
                          value: androidPackageName,
                          onSurface: onSurface,
                        ),
                        const SizedBox(height: 8),
                        _buildCopyRow(
                          ctx,
                          label: 'SHA-1 Fingerprint',
                          value: androidSha1,
                          onSurface: onSurface,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input fields
                  Text(
                    'Firebase Project Configuration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: projectIdCtrl,
                    style: TextStyle(fontSize: 14, color: onSurface),
                    decoration: InputDecoration(
                      labelText: 'Project ID',
                      hintText: 'e.g. tally-finance-app',
                      prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: apiKeyCtrl,
                    style: TextStyle(fontSize: 14, color: onSurface),
                    decoration: InputDecoration(
                      labelText: 'Web API Key',
                      hintText: 'AIzaSy...',
                      prefixIcon: const Icon(Icons.key, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: appIdCtrl,
                    style: TextStyle(fontSize: 14, color: onSurface),
                    decoration: InputDecoration(
                      labelText: 'App ID (Optional)',
                      hintText: '1:123456789:web:abcdef',
                      prefixIcon: const Icon(Icons.apps_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Found in Firebase Console > Project Settings > General.',
                          style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.55)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Save & Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newApiKey = apiKeyCtrl.text.trim();
                  final newProjectId = projectIdCtrl.text.trim();
                  final newAppId = appIdCtrl.text.trim();

                  if (newApiKey.isEmpty || newProjectId.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter both Project ID and Web API Key.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  await DefaultFirebaseOptions.saveConfig(
                    newApiKey: newApiKey,
                    newProjectId: newProjectId,
                    newAppId: newAppId.isNotEmpty ? newAppId : null,
                  );

                  try {
                    await Firebase.initializeApp(
                      options: DefaultFirebaseOptions.currentPlatform,
                    );
                  } catch (e) {
                    debugPrint('Firebase init on save: $e');
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx, true);
                  }
                },
              ),
            ],
          );
        },
      ),
    );

    // If configured successfully, proceed directly to real Google Sign-In!
    if (configured == true && context.mounted) {
      return await signIn(context);
    }

    return null;
  }

  static Widget _buildCopyRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color onSurface,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 16),
          tooltip: 'Copy $label',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied to clipboard!'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}
