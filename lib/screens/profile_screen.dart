import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transaction.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';
import '../utils/constants.dart';
import '../widgets/color_picker_dialog.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  void _logout() {
    AppState.currentUser = null;
    AppState.transactionsNotifier.value = [];
    AppState.goalsNotifier.value = [];
    AppState.activeTabNotifier.value = 0;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Current Password'),
              onChanged: (v) => currentPassword = v,
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
              const Text(
                'Complete SQLite dump of your accounts, transactions, and settings. Only accessible by your credentials.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0E14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
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
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: const Text('Copy SQL Script', style: TextStyle(color: Colors.white)),
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
      backgroundColor: const Color(0xFF151A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'App & Account Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Theme Studio Tile
            _settingsSectionTitle('APPEARANCE & THEME'),
            Card(
              color: const Color(0xFF0B0E14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.palette, color: Colors.purpleAccent),
                title: const Text('Graphic Theme Studio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Custom RGB/HSV color picker & live preview', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: AppState.customPrimaryColorNotifier.value, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: AppState.customSecondaryColorNotifier.value, shape: BoxShape.circle),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ColorPickerDialog.show(context);
                },
              ),
            ),

            const SizedBox(height: 20),

            // Profile Customization
            _settingsSectionTitle('PROFILE & IDENTITY'),
            Card(
              color: const Color(0xFF0B0E14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_a_photo, color: Colors.blueAccent),
                    title: const Text('Upload Profile Photo', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Select an image from device gallery', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickProfilePhoto();
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined, color: Colors.tealAccent),
                    title: const Text('Edit Display Name & Bio', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {
                      Navigator.pop(ctx);
                      _editProfileText();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Preferences & Security
            _settingsSectionTitle('PREFERENCES & DATA VAULT'),
            Card(
              color: const Color(0xFF0B0E14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.currency_exchange, color: Colors.amberAccent),
                    title: const Text('Currency Symbol', style: TextStyle(color: Colors.white)),
                    subtitle: ValueListenableBuilder<String>(
                      valueListenable: AppState.currencyNotifier,
                      builder: (context, curr, _) {
                        final match = currencyOptions.entries.firstWhere((e) => e.value == curr, orElse: () => MapEntry(curr, curr));
                        return Text(match.key, style: const TextStyle(color: Colors.white54, fontSize: 12));
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (inner) => ValueListenableBuilder<String>(
                          valueListenable: AppState.currencyNotifier,
                          builder: (context, activeCurrency, _) {
                            return SimpleDialog(
                              backgroundColor: const Color(0xFF151A22),
                              title: const Text('Select Currency'),
                              children: currencyOptions.entries.map((e) {
                                final isSelected = activeCurrency == e.value;
                                return SimpleDialogOption(
                                  onPressed: () {
                                    if (AppState.currentUser != null) {
                                      AppState.saveCurrency(AppState.currentUser!, e.value);
                                    } else {
                                      AppState.currencyNotifier.value = e.value;
                                    }
                                    Navigator.pop(inner);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        e.key,
                                        style: TextStyle(
                                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
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
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.lock_reset, color: Colors.orangeAccent),
                    title: const Text('Change Password', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {
                      Navigator.pop(ctx);
                      _changePassword();
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.download_for_offline, color: Colors.greenAccent),
                    title: const Text('Export SQL Ledger (.sql)', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Local SQLite backup with strict user isolation', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {
                      Navigator.pop(ctx);
                      _exportSqlBackup();
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync, color: Colors.blue),
                    title: const Text('Cloud Sync (Firebase Ready)', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Hybrid offline-first architecture', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text('READY', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: const Color(0xFF151A22),
                          title: const Row(
                            children: [
                              Icon(Icons.cloud_done, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Firebase Sync Architecture'),
                            ],
                          ),
                          content: const Text(
                            'Your data is safely stored in a local SQLite file isolated per user.\n\n'
                            'To enable multi-device real-time sync, run "flutterfire configure" and link your Firebase project credentials. The repository layer is fully wired to sync SQLite with Firestore automatically.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Got it')),
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

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _settingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
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
            icon: const Icon(Icons.settings, color: Colors.white),
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
                          border: Border.all(color: const Color(0xFF151A22), width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Persona Classification Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                personaColor.withValues(alpha: 0.25),
                const Color(0xFF151A22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                        const Text('SPENDING PERSONA: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.8)),
                        Text('${savingsRate.toStringAsFixed(0)}% Savings Rate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: personaColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(personaTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: personaColor)),
                    const SizedBox(height: 4),
                    Text(personaDescription, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Financial Vital Signs Grid
        const Text('EXECUTIVE FINANCIAL VITALS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
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
              color: netSavings >= 0 ? Colors.white : Colors.redAccent,
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
        const Text('TOP SPENDING DRIVERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
        const SizedBox(height: 12),

        if (topCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text('No expense transactions recorded yet.', style: TextStyle(color: Colors.white54, fontSize: 13)),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                            child: Text(cat.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          ),
                          Text(
                            '$currency${cat.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.white10,
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
              color: const Color(0xFF0B0E14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Peak Single Outflow', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(largestExpenseTitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
          icon: const Icon(Icons.tune, color: Colors.white),
          label: const Text('Open Customization & App Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white38), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}
