import 'dart:io';
import 'package:flutter/material.dart';
import '../models/saved_account_info.dart';
import '../services/database/app_database.dart';
import '../services/biometric_service.dart';
import '../services/google_auth_service.dart';
import '../services/state.dart';
import '../services/language_service.dart';
import 'main_nav_screen.dart';

/// Dedicated Saved Accounts Screen on Lock Screen.
/// Displays all accounts remembered on this device and provides instant 1-tap login
/// via Biometrics, Google, or Password auto-fill.
class SavedAccountsScreen extends StatefulWidget {
  const SavedAccountsScreen({super.key});

  @override
  State<SavedAccountsScreen> createState() => _SavedAccountsScreenState();
}

class _SavedAccountsScreenState extends State<SavedAccountsScreen> {
  List<SavedAccountInfo> _accounts = [];
  bool _isLoading = true;
  String _authenticatingUser = '';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final list = await AppDatabase.instance.getAllSavedAccounts();
    if (mounted) {
      setState(() {
        _accounts = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAccountTap(SavedAccountInfo account) async {
    if (_authenticatingUser.isNotEmpty) return;

    // 1. Biometric Unlock
    if (account.isBiometricEnabled) {
      setState(() => _authenticatingUser = account.username);
      try {
        final success = await BiometricService.authenticate(
          reason: 'Scan fingerprint or Face ID to unlock ${account.displayName}',
        );
        if (success && mounted) {
          BiometricService.isExplicitLogout = false;
          await BiometricService.syncUserSession(account.username);
          await AppState.loadAllUserData(account.username);
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim, secAnim) => const MainNavScreen(),
              transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
            (route) => false,
          );
          return;
        }
      } catch (e) {
        debugPrint('Biometric quick login error: $e');
      } finally {
        if (mounted) setState(() => _authenticatingUser = '');
      }
    }

    // 2. Google Account
    if (account.isGoogleAccount) {
      if (!mounted) return;
      setState(() => _authenticatingUser = account.username);
      try {
        final googleUser = await GoogleAuthService.signIn(context);
        if (googleUser != null && mounted) {
          BiometricService.isExplicitLogout = false;
          await BiometricService.syncUserSession(googleUser.email);
          await AppState.loadAllUserData(googleUser.email);
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim, secAnim) => const MainNavScreen(),
              transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
            (route) => false,
          );
          return;
        }
      } catch (e) {
        debugPrint('Google quick login error: $e');
      } finally {
        if (mounted) setState(() => _authenticatingUser = '');
      }
      return;
    }

    // 3. Password Account -> Pop back to LoginScreen with username selected
    if (mounted) {
      Navigator.pop(context, account.username);
    }
  }

  Future<void> _confirmRemoveAccount(SavedAccountInfo account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(LanguageService.tr('remove_account')),
          ],
        ),
        content: Text(
          LanguageService.tr('confirm_remove_account'),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LanguageService.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(LanguageService.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppDatabase.instance.deleteSavedAccount(account.username);
      await _loadAccounts();
    }
  }

  Widget _buildAvatar(SavedAccountInfo account) {
    if (account.photoPath != null && account.photoPath!.isNotEmpty) {
      if (account.photoPath!.startsWith('http')) {
        return CircleAvatar(
          radius: 26,
          backgroundImage: NetworkImage(account.photoPath!),
          backgroundColor: Color(account.primaryColor).withValues(alpha: 0.2),
        );
      } else {
        final f = File(account.photoPath!);
        if (f.existsSync()) {
          return CircleAvatar(
            radius: 26,
            backgroundImage: FileImage(f),
            backgroundColor: Color(account.primaryColor).withValues(alpha: 0.2),
          );
        }
      }
    }

    final initial = account.displayName.isNotEmpty
        ? account.displayName[0].toUpperCase()
        : account.username[0].toUpperCase();

    return CircleAvatar(
      radius: 26,
      backgroundColor: Color(account.primaryColor),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, currentLang, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.tr('saved_accounts_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _accounts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.manage_accounts_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LanguageService.tr('no_saved_accounts', fallback: 'No Saved Accounts'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LanguageService.tr('saved_accounts_empty_desc', fallback: 'Accounts you sign into on this device will appear here for fast one-tap access.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(LanguageService.tr('return_to_login', fallback: 'Return to Login')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.speed_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                LanguageService.tr('saved_accounts_desc'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._accounts.map((account) {
                        final isAuthenticatingThis = _authenticatingUser == account.username;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isAuthenticatingThis ? null : () => _handleAccountTap(account),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _buildAvatar(account),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            account.email ?? account.username,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              if (account.isBiometricEnabled)
                                                _buildBadge(
                                                  icon: Icons.fingerprint,
                                                  label: LanguageService.tr('biometric_enabled'),
                                                  color: Colors.teal,
                                                ),
                                              if (account.isGoogleAccount)
                                                _buildBadge(
                                                  icon: Icons.g_mobiledata,
                                                  label: LanguageService.tr('google_account'),
                                                  color: Colors.blueAccent,
                                                ),
                                              if (!account.isBiometricEnabled && !account.isGoogleAccount)
                                                _buildBadge(
                                                  icon: Icons.lock_outline,
                                                  label: LanguageService.tr('password_saved'),
                                                  color: Colors.amber.shade800,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isAuthenticatingThis)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.5),
                                      )
                                    else
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        onSelected: (val) {
                                          if (val == 'remove') {
                                            _confirmRemoveAccount(account);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'remove',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  LanguageService.tr('remove_account'),
                                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(LanguageService.tr('add_another_account')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
      },
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
