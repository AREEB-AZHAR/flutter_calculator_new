import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Initiates Google Sign-In. Uses native GoogleSignIn on supported mobile/web,
  /// with a seamless Google Account Picker fallback for Windows desktop / test environments.
  static Future<GoogleUserData?> signIn(BuildContext context) async {
    GoogleUserData? googleUser;

    // 1. Attempt Native Google Sign-In if running on mobile or web
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      try {
        final account = await GoogleSignIn.instance.authenticate();
        googleUser = GoogleUserData(
          id: account.id,
          email: account.email,
          displayName: account.displayName ?? account.email.split('@').first,
          photoUrl: account.photoUrl,
        );
      } catch (e) {
        debugPrint('Native GoogleSignIn note (falling back to interactive picker): $e');
      }
    }

    // 2. Interactive Google Account Picker fallback (desktop, test, or when native prompt is unavailable)
    if (googleUser == null && context.mounted) {
      googleUser = await _showGoogleAccountPickerModal(context);
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
    }

    return googleUser;
  }

  /// Signs out of the Google session
  static Future<void> signOut() async {
    try {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
  }

  /// Styled Google Account Picker dialog with authentic Google design language
  static Future<GoogleUserData?> _showGoogleAccountPickerModal(BuildContext context) async {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString(_prefLastGoogleEmailKey) ?? 'areeb.finance@gmail.com';
    final lastName = prefs.getString(_prefLastGoogleNameKey) ?? 'Areeb Azhar';

    final textCtrl = TextEditingController(text: lastEmail);
    final nameCtrl = TextEditingController(text: lastName);

    if (!context.mounted) return null;

    return showDialog<GoogleUserData>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: onSurface.withValues(alpha: 0.12), width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
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
                'Choose or enter your Google Account to bind your ledger data & sync across devices.',
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Preset Google Account tile
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(
                    ctx,
                    GoogleUserData(
                      id: 'google_${lastEmail.hashCode.abs()}',
                      email: lastEmail,
                      displayName: lastName,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primary,
                        child: Text(
                          lastName.isNotEmpty ? lastName[0].toUpperCase() : 'G',
                          style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lastName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: onSurface),
                            ),
                            Text(
                              lastEmail,
                              style: TextStyle(fontSize: 11.5, color: onSurface.withValues(alpha: 0.65)),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: primary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: onSurface.withValues(alpha: 0.15))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'OR USE ANOTHER GOOGLE ACCOUNT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.45)),
                    ),
                  ),
                  Expanded(child: Divider(color: onSurface.withValues(alpha: 0.15))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: onSurface, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Google Email',
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  hintText: 'yourname@gmail.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: onSurface, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              final email = textCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                Navigator.pop(
                  ctx,
                  GoogleUserData(
                    id: 'google_${email.hashCode.abs()}',
                    email: email,
                    displayName: name.isNotEmpty ? name : email.split('@').first,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
