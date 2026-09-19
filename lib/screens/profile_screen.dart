import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/state.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _logout() {
    AppState.currentUser = null;
    AppState.transactionsNotifier.value = [];
    AppState.goalsNotifier.value = [];
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx, rootNavigator: true);
              final messenger = ScaffoldMessenger.of(context);
              final prefs = await SharedPreferences.getInstance();
              final String? usersStr = prefs.getString('users');

              if (usersStr == null || AppState.currentUser == null) {
                return;
              }

              final Map<String, dynamic> users = jsonDecode(usersStr);
              final username = AppState.currentUser!;

              if (users[username] == currentPassword && newPassword.isNotEmpty) {
                users[username] = newPassword;
                await prefs.setString('users', jsonEncode(users));
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Password changed successfully')),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Incorrect current password')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ValueListenableBuilder<Color>(
              valueListenable: AppState.avatarColorNotifier,
              builder: (context, avatarColor, _) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: const Text('Pick Avatar Color'),
                        content: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: Colors.primaries.map((color) {
                            return GestureDetector(
                              onTap: () {
                                AppState.avatarColorNotifier.value = color;
                                if (AppState.currentUser != null) AppState.saveAvatarColor(AppState.currentUser!, color);
                                Navigator.pop(ctx);
                              },
                              child: CircleAvatar(backgroundColor: color, radius: 20),
                            );
                          }).toList(),
                        ),
                      )
                    );
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: avatarColor,
                    child: Text(
                      AppState.currentUser?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                );
              }
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(AppState.currentUser ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 40),
          
          const Text('Appearance', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          ValueListenableBuilder<String>(
            valueListenable: AppState.themeNameNotifier,
            builder: (context, themeName, _) {
              return Card(
                color: Theme.of(context).colorScheme.surface,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Theme Preset', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: themePresets.map((preset) {
                          final isSelected = themeName == preset.name;
                          return GestureDetector(
                            onTap: () {
                              AppState.themeNameNotifier.value = preset.name;
                              if (AppState.currentUser != null) AppState.saveTheme(AppState.currentUser!, preset.name);
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: preset.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? preset.primary : Colors.white24, width: isSelected ? 2 : 1),
                              ),
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: preset.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          
          const SizedBox(height: 30),
          const Text('Account', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          Card(
            color: Theme.of(context).colorScheme.surface,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Change Password', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: _changePassword,
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: Icon(Icons.currency_exchange, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Currency', style: TextStyle(color: Colors.white)),
                  trailing: ValueListenableBuilder<String>(
                    valueListenable: AppState.currencyNotifier,
                    builder: (context, curr, _) {
                      return DropdownButton<String>(
                        value: curr,
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        items: ['\$', '€', '£', '¥', '₹'].map((String c) {
                          return DropdownMenuItem<String>(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) AppState.currencyNotifier.value = val;
                        },
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _logout,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
