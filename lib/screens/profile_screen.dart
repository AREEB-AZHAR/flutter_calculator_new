import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';
import '../services/notification_service.dart';
import '../services/app_icon_service.dart';
import '../services/biometric_service.dart';
import '../services/tour_service.dart';
import '../widgets/feature_tour_dialog.dart';
import '../services/monetization_service.dart';
import '../services/google_auth_service.dart';
import '../utils/constants.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/tally_brand_painters.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  int _devToggleCount = 0;

  void _logout() {
    AppState.currentUser = null;
    AppState.transactionsNotifier.value = [];
    AppState.goalsNotifier.value = [];
    AppState.activeTabNotifier.value = 0;
    BiometricService.resetSessionPrompt();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _linkGoogleAccount() async {
    try {
      final googleUser = await GoogleAuthService.signIn(context);
      if (googleUser != null && mounted) {
        final previousUser = AppState.currentUser;
        if (previousUser != null && previousUser != googleUser.email) {
          await AppDatabase.instance.authenticateOrRegisterGoogleUser(
            email: googleUser.email,
            displayName: googleUser.displayName,
            photoUrl: googleUser.photoUrl,
          );
        }
        await AppState.loadAllUserData(googleUser.email);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Bound to Google Account: ${googleUser.email}'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google binding failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null && AppState.currentUser != null) {
        final username = AppState.currentUser!;
        final profile = await AppDatabase.instance.loadProfile(username);
        await AppState.saveProfile(profile.copyWith(photoPath: image.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _editProfileText() {
    final nameCtrl = TextEditingController(text: AppState.displayNameNotifier.value);
    final bioCtrl = TextEditingController(text: AppState.bioNotifier.value);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Edit Profile Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 2,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'Bio / Personal Motto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              if (AppState.currentUser != null) {
                final username = AppState.currentUser!;
                final profile = await AppDatabase.instance.loadProfile(username);
                await AppState.saveProfile(profile.copyWith(
                  displayName: nameCtrl.text.trim(),
                  bio: bioCtrl.text.trim(),
                ));
              }
              nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    String currentPassword = '';
    String newPassword = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'Current Password'),
              onChanged: (v) => currentPassword = v,
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'New Password'),
              onChanged: (v) => newPassword = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              if (AppState.currentUser == null) return;

              final success = await AppDatabase.instance.changePassword(
                AppState.currentUser!,
                currentPassword,
                newPassword,
              );

              if (success) {
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Password changed successfully')),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Incorrect current password')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSqlBackup() async {
    if (AppState.currentUser == null) return;
    final sqlContent = await AppDatabase.instance.exportToSql(AppState.currentUser!);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storage, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('SQL Database Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete SQLite dump of your accounts, transactions, and settings. Only accessible by your credentials.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    sqlContent,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.greenAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.copy, size: 16, color: Theme.of(context).colorScheme.onPrimary),
            label: Text('Copy SQL Script', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sqlContent));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SQL Ledger script copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSettingsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: AppState.themeNameNotifier,
        builder: (context, themeName, _) {
          return ValueListenableBuilder<Color>(
            valueListenable: AppState.customPrimaryColorNotifier,
            builder: (context, primaryColor, _) {
              return ValueListenableBuilder<Color>(
                valueListenable: AppState.customSecondaryColorNotifier,
                builder: (context, secondaryColor, _) {
                  return ValueListenableBuilder<Color?>(
                    valueListenable: AppState.customTextColorNotifier,
                    builder: (context, textColor, _) {
                      final activeTheme = buildDynamicTheme(
                        primary: primaryColor,
                        secondary: secondaryColor,
                        textColor: textColor,
                        themeName: themeName,
                      );
                      final surface = activeTheme.colorScheme.surface;
                      final onSurface = activeTheme.colorScheme.onSurface;
                      final cardBg = activeTheme.scaffoldBackgroundColor;
                      final primary = activeTheme.colorScheme.primary;

                      return Theme(
                        data: activeTheme,
                        child: Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          child: DraggableScrollableSheet(
                            initialChildSize: 0.75,
                            maxChildSize: 0.92,
                            minChildSize: 0.5,
                            expand: false,
                            builder: (c, scrollController) => ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(24),
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: onSurface.withValues(alpha: 0.24),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'App & Account Settings',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
                                ),
                                const SizedBox(height: 16),

                                // Features & Settings Guide Banner Card
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primary.withValues(alpha: 0.16),
                                        primary.withValues(alpha: 0.04),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.auto_stories_rounded, color: primary, size: 22),
                                    ),
                                    title: Text(
                                      'What Each Setting Does',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 14.5),
                                    ),
                                    subtitle: Text(
                                      'Explore all features, offline vault, biometrics & guides',
                                      style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 11.5),
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primary),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _showAllFeaturesGuide(context);
                                    },
                                  ),
                                ),

                                // Interactive Onboarding Tours
                                _settingsSectionTitle('INTERACTIVE ONBOARDING TOURS', onSurface.withValues(alpha: 0.6)),
                                Card(
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    leading: const Icon(Icons.replay_rounded, color: Colors.cyanAccent),
                                    title: Text('Replay Feature Tours', style: TextStyle(color: onSurface)),
                                    subtitle: Text('Relaunch Home & Accounts walkthroughs anytime', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12)),
                                    trailing: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.54)),
                                    onTap: () async {
                                      await TourService.resetAllTours();
                                      if (context.mounted) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Tours reset! Switching to Home and launching walkthrough...'),
                                            backgroundColor: Colors.teal,
                                          ),
                                        );
                                        AppState.activeTabNotifier.value = 0;
                                        showHomeDashboardTour(context);
                                      }
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Pro & Ad-Free Membership Section
                                _settingsSectionTitle('PRO & AD-FREE MEMBERSHIP', onSurface.withValues(alpha: 0.6)),
                                Card(
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      // 1. Tally Pro Membership
                                      ValueListenableBuilder<bool>(
                                        valueListenable: MonetizationService.isProUnlockedNotifier,
                                        builder: (context, isPro, _) {
                                          return ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                                            ),
                                            title: Row(
                                              children: [
                                                Text(
                                                  'Tally Pro Membership',
                                                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 8),
                                                if (isPro)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text('ACTIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ),
                                              ],
                                            ),
                                            subtitle: Text(
                                              isPro
                                                  ? 'All features unlocked: Insights, Theme Studio, Custom Icons & Ad-Free.'
                                                  : 'Unlock Insights, Theme Studio, Launcher Icons & Ad-Free (\$4.99)',
                                              style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 12),
                                            ),
                                            trailing: isPro
                                                ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                                                : ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.amber.shade700,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    ),
                                                    onPressed: () {
                                                      MonetizationService.showPaywallModal(
                                                        context,
                                                        featureTitle: 'Tally Pro All-Access',
                                                        featureDescription: 'Unlock predictive velocity, spending comparisons, custom themes, app icons, and remove all ads.',
                                                      );
                                                    },
                                                    child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ),
                                          );
                                        },
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),

                                      // 2. Separate Remove Ads Option
                                      ValueListenableBuilder<bool>(
                                        valueListenable: MonetizationService.isAdsRemovedNotifier,
                                        builder: (context, isAdsRemoved, _) {
                                          return ValueListenableBuilder<bool>(
                                            valueListenable: MonetizationService.isProUnlockedNotifier,
                                            builder: (context, isPro, _) {
                                              final adFree = isPro || isAdsRemoved;
                                              return ListTile(
                                                leading: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent.withValues(alpha: 0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.block_rounded, color: Colors.blueAccent, size: 20),
                                                ),
                                                title: Row(
                                                  children: [
                                                    Text(
                                                      'Remove Ads (Separate Option)',
                                                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (adFree)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text('AD-FREE', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                      ),
                                                  ],
                                                ),
                                                subtitle: Text(
                                                  adFree
                                                      ? 'All banner advertisements are disabled across the app.'
                                                      : 'Remove all banners permanently without full Pro bundle (\$1.99)',
                                                  style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 12),
                                                ),
                                                trailing: adFree
                                                    ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                                                    : OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          side: const BorderSide(color: Colors.blueAccent),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        onPressed: () async {
                                                          await MonetizationService.removeAds();
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('🎉 Ads removed successfully! Enjoy clean banner-free budgeting.'),
                                                                backgroundColor: Colors.teal,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: const Text('Buy (\$1.99)', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                                      ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),

                                      // 3. Redeem Promo Code & Unlock Function
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.purpleAccent.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.redeem_rounded, color: Colors.purpleAccent, size: 20),
                                        ),
                                        title: Text(
                                          'Redeem Promo / Unlock Code',
                                          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          'Enter a VIP unlock code (e.g. PROVIP or NOADS)',
                                          style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 12),
                                        ),
                                        trailing: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.54)),
                                        onTap: () {
                                          MonetizationService.showPromoCodeDialog(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Brand Palettes
                                _settingsSectionTitle('BRAND PALETTES (INSTANT IN-APP)', onSurface.withValues(alpha: 0.6)),
                                Card(
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      _brandPaletteTile(
                                        name: 'Ledger',
                                        tagline: 'Forest Green & Slash Coral (Classic White Paper)',
                                        bgColor: const Color(0xFF17493B),
                                        strokeColor: const Color(0xFFF6F0E1),
                                        slashColor: const Color(0xFFE4572E),
                                        preset: themePresets[0],
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),
                                      _brandPaletteTile(
                                        name: 'Paper',
                                        tagline: 'Cream Paper & Forest Green (Vintage Editorial)',
                                        bgColor: const Color(0xFFF6F0E1),
                                        strokeColor: const Color(0xFF17493B),
                                        slashColor: const Color(0xFFE4572E),
                                        preset: themePresets[1],
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),
                                      _brandPaletteTile(
                                        name: 'Ink',
                                        tagline: 'Carbon Black & Amber Slash (Ink Typography)',
                                        bgColor: const Color(0xFF191915),
                                        strokeColor: const Color(0xFFF3EDE0),
                                        slashColor: const Color(0xFFE8A13C),
                                        preset: themePresets[2],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Launcher App Icon with Restart Notice
                                _settingsSectionTitle('LAUNCHER APP ICON (REQUIRES RESTART)', onSurface.withValues(alpha: 0.6)),
                                _launcherIconCard(cardBg, surface, onSurface, primary),

                                const SizedBox(height: 20),

                                // Theme Studio Tile
                                _settingsSectionTitle('CUSTOM PALETTES & STUDIO', onSurface.withValues(alpha: 0.6)),
                                Card(
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    leading: const Icon(Icons.palette, color: Colors.purpleAccent),
                                    title: Text('Graphic Theme Studio', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                                    subtitle: Text('Custom RGB/HSV color picker & live preview', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!MonetizationService.isPro) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.lock_outline, size: 10, color: Colors.amber),
                                                SizedBox(width: 3),
                                                Text('PRO', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                                        ),
                                        Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.54)),
                                      ],
                                    ),
                                    onTap: () {
                                      if (!MonetizationService.isPro) {
                                        MonetizationService.showPaywallModal(
                                          context,
                                          featureTitle: 'Graphic Theme Studio',
                                          featureDescription: 'Unlock custom RGB/HSV sliders, custom text coloring, and bespoke brand palettes with Tally Pro.',
                                        );
                                        return;
                                      }
                                      Navigator.pop(ctx);
                                      ColorPickerDialog.show(context);
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Profile Customization
                                _settingsSectionTitle('PROFILE & IDENTITY', onSurface.withValues(alpha: 0.6)),
                                Card(
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.add_a_photo, color: Colors.blueAccent),
                                        title: Text('Upload Profile Photo', style: TextStyle(color: onSurface)),
                                        subtitle: Text('Select an image from device gallery', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12)),
                                        trailing: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.54)),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _pickProfilePhoto();
                                        },
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),
                                      ListTile(
                                        leading: const Icon(Icons.badge_outlined, color: Colors.tealAccent),
                                        title: Text('Edit Display Name & Bio', style: TextStyle(color: onSurface)),
                                        trailing: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.54)),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _editProfileText();
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Notifications & Reminders
                                _settingsSectionTitle('NOTIFICATIONS & REMINDERS', onSurface.withValues(alpha: 0.6)),
                                Card(
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: StatefulBuilder(
                                    builder: (context, setCardState) {
                                      return FutureBuilder<bool>(
                                        future: NotificationService.instance.areRemindersEnabled(),
                                        builder: (context, snapshot) {
                                          final isEnabled = snapshot.data ?? true;
                                          return SwitchListTile(
                                            secondary: const Icon(Icons.notifications_active, color: Colors.indigoAccent),
                                            title: Text('3-Hour Tally Reminders', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                                            subtitle: Text('Active 9:00 AM – 11:00 PM (Quiet hours at night)', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12)),
                                            activeThumbColor: primary,
                                            value: isEnabled,
                                            onChanged: (val) async {
                                              _devToggleCount++;
                                              await NotificationService.instance.setRemindersEnabled(val);
                                              setCardState(() {});
                                              if (_devToggleCount >= 10) {
                                                _devToggleCount = 0;
                                                await NotificationService.instance.showInstantFriendlyReminder();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('🕵️ Secret Dev Mode Unlocked! Test reminder sent.'),
                                                      backgroundColor: Colors.indigoAccent,
                                                      duration: Duration(seconds: 3),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Preferences & Security
                                _settingsSectionTitle('LEDGER ARCHITECTURE & DATA', onSurface.withValues(alpha: 0.6)),
                                Card(
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.currency_exchange, color: Colors.amberAccent),
                                        title: Text('Currency Symbol', style: TextStyle(color: onSurface)),
                                        subtitle: ValueListenableBuilder<String>(
                                          valueListenable: AppState.currencyNotifier,
                                          builder: (context, cur, _) {
                                            final match = currencyOptions.entries.firstWhere((e) => e.value == cur, orElse: () => currencyOptions.entries.first);
                                            return Text(match.key, style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12));
                                          },
                                        ),
                                        trailing: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.54)),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (inner) => ValueListenableBuilder<String>(
                                              valueListenable: AppState.currencyNotifier,
                                              builder: (context, activeCurrency, _) {
                                                return SimpleDialog(
                                                  backgroundColor: surface,
                                                  title: Text('Select Currency', style: TextStyle(color: onSurface)),
                                                  children: currencyOptions.entries.map((e) {
                                                    final isSelected = activeCurrency == e.value;
                                                    return SimpleDialogOption(
                                                      onPressed: () {
                                                        AppState.setCurrency(e.value);
                                                        Navigator.pop(inner);
                                                      },
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            e.key,
                                                            style: TextStyle(
                                                              color: isSelected ? primary : onSurface,
                                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                            ),
                                                          ),
                                                          if (isSelected)
                                                            Icon(Icons.check, size: 18, color: primary),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),
                                      ListTile(
                                        leading: const Icon(Icons.lock_reset, color: Colors.orangeAccent),
                                        title: Text('Change Password', style: TextStyle(color: onSurface)),
                                        trailing: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.54)),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _changePassword();
                                        },
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),
                                      StatefulBuilder(
                                        builder: (context, setTileState) {
                                          return FutureBuilder<bool>(
                                            future: BiometricService.isBiometricEnabled(),
                                            builder: (context, snapshot) {
                                              final isEnabled = snapshot.data ?? false;
                                              return SwitchListTile(
                                                secondary: const Icon(Icons.fingerprint, color: Colors.tealAccent),
                                                title: Text('Screen Lock / Biometrics', style: TextStyle(color: onSurface)),
                                                subtitle: Text(
                                                  isEnabled
                                                      ? 'Quick unlock with Face ID, Fingerprint, or PIN'
                                                      : 'Use mobile screen lock to unlock Tally',
                                                  style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12),
                                                ),
                                                value: isEnabled,
                                                activeThumbColor: primary,
                                                onChanged: (val) async {
                                                  if (val) {
                                                    final supported = await BiometricService.isDeviceSupported();
                                                    if (!supported) {
                                                      if (!context.mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Screen lock or biometrics are not configured on this device.'),
                                                          backgroundColor: Colors.redAccent,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    final authSuccess = await BiometricService.authenticate(
                                                      reason: 'Confirm your screen lock to enable fast unlock',
                                                    );
                                                    if (authSuccess) {
                                                      await BiometricService.setBiometricEnabled(true, username: AppState.currentUser);
                                                      setTileState(() {});
                                                      if (!context.mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Biometric / screen lock unlock enabled!'),
                                                          backgroundColor: Colors.teal,
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    await BiometricService.setBiometricEnabled(false);
                                                    setTileState(() {});
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Biometric unlock disabled'),
                                                      ),
                                                    );
                                                  }
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),
                                      ListTile(
                                        leading: const Icon(Icons.download_for_offline, color: Colors.greenAccent),
                                        title: Text('Export SQL Ledger (.sql)', style: TextStyle(color: onSurface)),
                                        subtitle: Text('Local SQLite backup with strict user isolation', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12)),
                                        trailing: Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.54)),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _exportSqlBackup();
                                        },
                                      ),
                                      Divider(height: 1, color: onSurface.withValues(alpha: 0.1)),
                                      ListTile(
                                        leading: const Icon(Icons.cloud_sync, color: Colors.blue),
                                        title: Text('Cloud Sync (Firebase Ready)', style: TextStyle(color: onSurface)),
                                        subtitle: Text('Hybrid offline-first architecture', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12)),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                          child: const Text('READY', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              backgroundColor: surface,
                                              title: Row(
                                                children: [
                                                  const Icon(Icons.cloud_done, color: Colors.blue),
                                                  const SizedBox(width: 8),
                                                  Text('Firebase Sync Architecture', style: TextStyle(color: onSurface)),
                                                ],
                                              ),
                                              content: Text(
                                                'Your data is safely stored in a local SQLite file isolated per user.\n\n'
                                                'To enable multi-device real-time sync, run "flutterfire configure" and link your Firebase project credentials. The repository layer is fully wired to sync SQLite with Firestore automatically.',
                                                style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 13),
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c), child: Text('Got it', style: TextStyle(color: primary))),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // Logout Button
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.logout, color: Colors.white),
                                  label: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _logout();
                                  },
                                ),

                                const SizedBox(height: 24),

                                // App Version & Security Architecture Footer
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Tally v1.8.0 (Build 10)',
                                        style: TextStyle(
                                          color: onSurface.withValues(alpha: 0.7),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Offline-First • Local Encrypted Vault',
                                        style: TextStyle(
                                          color: onSurface.withValues(alpha: 0.4),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _settingsSectionTitle(String title, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  void _showAllFeaturesGuide(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (c, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Features & Settings Guide',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          Text(
                            'Everything Tally has to offer & what each setting does',
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    _guideItem(
                      icon: Icons.palette_outlined,
                      title: 'Brand Palettes & Themes',
                      badge: 'Instant Styling',
                      description:
                          'Switch seamlessly between 3 curated design systems:\n'
                          '• Ledger: Classic Dark Emerald & Slash Coral on White Paper.\n'
                          '• Paper: Vintage editorial Warm Cream Paper.\n'
                          '• Ink: Deep OLED Carbon Black & Warm Amber.\n'
                          'Changes take effect instantly across the whole app, charts, and login screen.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.app_shortcut_rounded,
                      title: 'Launcher App Icons',
                      badge: 'Home Screen Icon',
                      description:
                          'Change your physical Android / iOS home screen app icon to match your preferred theme (Ledger, Paper, or Ink). Requires an app restart to reload OS launcher shortcuts safely.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.color_lens_outlined,
                      title: 'Theme Studio (Custom Colors)',
                      badge: 'Personalize',
                      description:
                          'Customize your primary accent color, secondary accent color, and typography font color using the interactive color wheel.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric & Screen Lock Unlock',
                      badge: 'Quick Security',
                      description:
                          'Enable instant, effortless vault access with Fingerprint, Face ID, or your phone’s screen lock PIN. Kept 100% on your device for absolute privacy.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.storage_rounded,
                      title: 'Offline SQLite Vault & SQL Export',
                      badge: 'Privacy-First',
                      description:
                          'All accounts, transactions, and preferences are stored in an encrypted local SQLite database isolated per user. You can export a full .sql dump anytime for permanent backups.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Cloud Sync (Firebase Ready)',
                      badge: 'Sync Architecture',
                      description:
                          'Sync your SQLite database to Google Firebase Firestore across multiple devices. The hybrid repository layer coordinates offline and online sync seamlessly.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.notifications_active_outlined,
                      title: 'Daily Reminders & Notifications',
                      badge: 'Habits',
                      description:
                          'Set scheduled local reminders so you never forget to log your daily expenses and maintain financial accountability.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.currency_exchange_rounded,
                      title: 'Currency Switcher',
                      badge: 'Global Units',
                      description:
                          'Select your currency symbol (\$, €, £, ¥, ₹, ₩, etc.). The entire app updates all balances, cards, and graphs instantly without needing a relaunch.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Transaction Auto-Fill & Category Switching',
                      badge: 'Smart Entry',
                      description:
                          '• Empty Title Auto-Fill: Leave the Title field empty and Tally automatically names the transaction using your selected category!\n'
                          '• Income Auto-Switch: Choosing "Income" automatically switches the category to "Salary".\n'
                          '• Custom Dates: Tap the calendar button to record past or future transaction dates.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    _guideItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Multi-Account & Custom Wallets',
                      badge: 'Accounts Hub',
                      description:
                          'Track cash, bank accounts, and credit cards separately. In the Accounts tab, tap "+ Add Account" or the Settings icon to create unlimited custom wallet types.',
                      primary: primary,
                      onSurface: onSurface,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideItem({
    required IconData icon,
    required String title,
    required String badge,
    required String description,
    required Color primary,
    required Color onSurface,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: 12.5, height: 1.45, color: onSurface.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.auto_stories_rounded, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Features & Settings Guide',
            onPressed: () => _showAllFeaturesGuide(context),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Settings & Theming',
            onPressed: _showSettingsPopup,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: AppState.transactionsNotifier,
        builder: (context, transactions, _) {
          return _buildSpendingBehaviorSummary(transactions, primaryColor);
        },
      ),
    );
  }

  Widget _buildSpendingBehaviorSummary(List<Transaction> transactions, Color primaryColor) {
    final currency = AppState.currencyNotifier.value;

    double totalIncome = 0;
    double totalExpense = 0;
    double largestExpense = 0;
    String largestExpenseTitle = 'None';
    final Map<String, double> categoryTotals = {};

    // Essential categories (Needs) vs Discretionary (Wants)
    const essentialCategories = {'Housing & Rent', 'Food & Dining', 'Utilities', 'Healthcare', 'Transportation', 'Education'};
    double essentialSpending = 0;
    double discretionarySpending = 0;

    for (var t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;

        if (t.amount > largestExpense) {
          largestExpense = t.amount;
          largestExpenseTitle = '${t.title} (${t.category})';
        }

        if (essentialCategories.contains(t.category)) {
          essentialSpending += t.amount;
        } else {
          discretionarySpending += t.amount;
        }
      }
    }

    final double netSavings = totalIncome - totalExpense;
    final double savingsRate = totalIncome > 0 ? ((netSavings / totalIncome) * 100).clamp(-100.0, 100.0) : 0.0;

    // Spending Persona Classification
    String personaTitle;
    String personaDescription;
    IconData personaIcon;
    Color personaColor;

    if (savingsRate >= 40) {
      personaTitle = 'Master Wealth Builder';
      personaDescription = 'Exceptional financial discipline. You consistently retain over 40% of all cash inflow.';
      personaIcon = Icons.military_tech;
      personaColor = const Color(0xFF10B981);
    } else if (savingsRate >= 20) {
      personaTitle = 'Balanced Strategist';
      personaDescription = 'Healthy equilibrium between enjoying life today and building solid future reserves.';
      personaIcon = Icons.balance;
      personaColor = const Color(0xFF3B82F6);
    } else if (savingsRate >= 5) {
      personaTitle = 'Active Cashflower';
      personaDescription = 'Consistent revenue flow with moderate savings. Setting automated budgets will unlock greater growth.';
      personaIcon = Icons.trending_up;
      personaColor = const Color(0xFFF59E0B);
    } else {
      personaTitle = 'Lifestyle Maximizer';
      personaDescription = 'High consumption velocity. Review discretionary expenses to prevent negative cashflow drift.';
      personaIcon = Icons.local_fire_department;
      personaColor = const Color(0xFFEF4444);
    }

    // Top Categories sorted
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // User Identity Card with Custom Photo & Bio
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickProfilePhoto,
                child: Stack(
                  children: [
                    ValueListenableBuilder<String?>(
                      valueListenable: AppState.profilePhotoNotifier,
                      builder: (context, photoPath, _) {
                        final hasFile = photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync();
                        return CircleAvatar(
                          radius: 46,
                          backgroundColor: primaryColor.withValues(alpha: 0.2),
                          backgroundImage: hasFile ? FileImage(File(photoPath)) : null,
                          child: !hasFile
                              ? ValueListenableBuilder<String>(
                                  valueListenable: AppState.displayNameNotifier,
                                  builder: (context, name, _) {
                                    final initial = name.isNotEmpty ? name[0].toUpperCase() : (AppState.currentUser?[0].toUpperCase() ?? 'U');
                                    return Text(initial, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor));
                                  },
                                )
                              : null,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, size: 14, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: AppState.displayNameNotifier,
                builder: (context, name, _) {
                  return Text(
                    name.isNotEmpty ? name : (AppState.currentUser ?? 'User'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  );
                },
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<String>(
                valueListenable: AppState.bioNotifier,
                builder: (context, bio, _) {
                  return Text(
                    bio.isNotEmpty ? bio : 'Managing wealth with style and precision.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Google Account Binding Status Badge
              if (GoogleAuthService.isCurrentGoogleUser)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Bound to Google: ${AppState.currentUser}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: _linkGoogleAccount,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.14)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Link Google Account (Cloud Binding)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Persona Classification Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: personaColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: personaColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(personaIcon, color: personaColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('SPENDING PERSONA: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), letterSpacing: 0.8)),
                        Text('${savingsRate.toStringAsFixed(0)}% Savings Rate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: personaColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(personaTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: personaColor)),
                    const SizedBox(height: 4),
                    Text(personaDescription, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Financial Vital Signs Grid
        Text('EXECUTIVE FINANCIAL VITALS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), letterSpacing: 1)),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _vitalCard(
              title: 'Lifetime Inflow',
              value: '+$currency${totalIncome.toStringAsFixed(0)}',
              subtitle: 'All recorded revenue',
              color: Colors.greenAccent,
              icon: Icons.south_west,
            ),
            _vitalCard(
              title: 'Lifetime Outflow',
              value: '-$currency${totalExpense.toStringAsFixed(0)}',
              subtitle: 'All recorded spending',
              color: Colors.redAccent,
              icon: Icons.north_east,
            ),
            _vitalCard(
              title: 'Retained Wealth',
              value: '$currency${netSavings.toStringAsFixed(0)}',
              subtitle: 'Accumulated net surplus',
              color: netSavings >= 0 ? Theme.of(context).colorScheme.onSurface : Colors.redAccent,
              icon: Icons.account_balance,
            ),
            _vitalCard(
              title: 'Needs vs Wants',
              value: totalExpense > 0 ? '${((essentialSpending / totalExpense) * 100).toStringAsFixed(0)}% Needs' : '100% Needs',
              subtitle: totalExpense > 0 ? '${((discretionarySpending / totalExpense) * 100).toStringAsFixed(0)}% Wants' : '0% Wants',
              color: primaryColor,
              icon: Icons.pie_chart,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Top Spending Drivers Leaderboard
        Text('TOP SPENDING DRIVERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), letterSpacing: 1)),
        const SizedBox(height: 12),

        if (topCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text('No expense transactions recorded yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: topCategories.map((cat) {
                final pct = totalExpense > 0 ? (cat.value / totalExpense) : 0.0;
                final icon = categoryIcons[cat.key] ?? Icons.category;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18, color: primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(cat.key, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                          ),
                          Text(
                            '$currency${cat.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 20),

        // Largest Single Expense Callout
        if (largestExpense > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Peak Single Outflow', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(largestExpenseTitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Text('-$currency${largestExpense.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Quick Settings Button
        OutlinedButton.icon(
          icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.onSurface),
          label: Text('Open Customization & App Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _showSettingsPopup,
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _vitalCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.4)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _brandPaletteTile({
    required String name,
    required String tagline,
    required Color bgColor,
    required Color strokeColor,
    required Color slashColor,
    required AppThemePreset preset,
  }) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.themeNameNotifier,
      builder: (context, currentTheme, _) {
        final isSelected = currentTheme == name;
        final primary = Theme.of(context).colorScheme.primary;
        final onSurface = Theme.of(context).colorScheme.onSurface;

        return ListTile(
          leading: Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isSelected ? primary : onSurface.withValues(alpha: 0.24),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: CustomPaint(
              painter: TallyIconPainter(
                bgColor: bgColor,
                strokeColor: strokeColor,
                slashColor: slashColor,
              ),
            ),
          ),
          title: Text(
            name,
            style: TextStyle(
              color: isSelected ? primary : onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(tagline, style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 11.5)),
          trailing: isSelected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.install_mobile_rounded, size: 20),
                      tooltip: 'Set as Home Screen Icon',
                      color: primary,
                      onPressed: () => _promptChangeLauncherIcon(context, name),
                    ),
                    Icon(Icons.check_circle, color: primary, size: 20),
                  ],
                )
              : IconButton(
                  icon: Icon(Icons.install_mobile_outlined, size: 20, color: onSurface.withValues(alpha: 0.4)),
                  tooltip: 'Set as Home Screen Icon',
                  onPressed: () => _promptChangeLauncherIcon(context, name),
                ),
          onTap: () async {
            await AppState.persistThemePreset(preset);

            if (AppState.currentUser != null) {
              final username = AppState.currentUser!;
              final profile = await AppDatabase.instance.loadProfile(username);
              await AppState.saveProfile(profile.copyWith(
                primaryColor: preset.primary,
                secondaryColor: preset.secondary,
                clearTextColor: true,
              ));
              await AppState.saveTheme(username, preset.name);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched in-app theme to $name'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _promptChangeLauncherIcon(BuildContext ctx, String iconName) {
    if (!MonetizationService.isPro) {
      MonetizationService.showPaywallModal(
        ctx,
        featureTitle: 'Custom Dynamic Launcher Icons',
        featureDescription: 'Unlock custom dynamic home screen icons ($iconName, Paper, Ledger) with Tally Pro.',
      );
      return;
    }

    final theme = Theme.of(ctx);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Change Launcher Icon?',
                style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Android requires restarting the app to update the home screen launcher icon to "$iconName".',
              style: TextStyle(color: onSurface.withValues(alpha: 0.85), fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tally will close and apply your new "$iconName" icon on your device home screen immediately.\n\nWhen you re-open Tally, the new icon will be active.',
                      style: TextStyle(color: onSurface.withValues(alpha: 0.85), fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await AppIconService.setAppIcon(iconName);
            },
            child: const Text('Change & Restart', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _launcherIconCard(Color cardBg, Color surface, Color onSurface, Color primary) {
    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 20, color: primary),
                const SizedBox(width: 8),
                Text(
                  'Set Android Home Screen Icon',
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 8),
                if (!MonetizationService.isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 10, color: Colors.amber),
                        SizedBox(width: 3),
                        Text('PRO', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choose an icon for your phone home screen launcher. Android requires restarting the app to update.',
              style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _launcherIconItem(
                    name: 'Ledger',
                    bgColor: const Color(0xFF17493B),
                    strokeColor: const Color(0xFFF6F0E1),
                    slashColor: const Color(0xFFE4572E),
                    surface: surface,
                    onSurface: onSurface,
                    primary: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _launcherIconItem(
                    name: 'Paper',
                    bgColor: const Color(0xFFF6F0E1),
                    strokeColor: const Color(0xFF17493B),
                    slashColor: const Color(0xFFE4572E),
                    surface: surface,
                    onSurface: onSurface,
                    primary: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _launcherIconItem(
                    name: 'Ink',
                    bgColor: const Color(0xFF191915),
                    strokeColor: const Color(0xFFF3EDE0),
                    slashColor: const Color(0xFFE8A13C),
                    surface: surface,
                    onSurface: onSurface,
                    primary: primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _launcherIconItem({
    required String name,
    required Color bgColor,
    required Color strokeColor,
    required Color slashColor,
    required Color surface,
    required Color onSurface,
    required Color primary,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _promptChangeLauncherIcon(context, name),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onSurface.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: TallyIconPainter(
                  bgColor: bgColor,
                  strokeColor: strokeColor,
                  slashColor: slashColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MonetizationService.isPro ? primary.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!MonetizationService.isPro) ...[
                    const Icon(Icons.lock_outline, size: 10, color: Colors.amber),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    MonetizationService.isPro ? 'Set Icon' : 'Pro',
                    style: TextStyle(
                      color: MonetizationService.isPro ? primary : Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
