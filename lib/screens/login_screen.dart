import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_nav_screen.dart';
import '../services/state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  String _error = '';
  bool _isLoading = false;

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    
    if (username.isEmpty || password.isEmpty) {
       setState(() => _error = 'Please fill all fields');
       return;
    }

    setState(() { _isLoading = true; _error = ''; });

    final prefs = await SharedPreferences.getInstance();
    final String? usersStr = prefs.getString('users');
    Map<String, dynamic> users = usersStr != null ? jsonDecode(usersStr) : {};

    if (_isLogin) {
      if (users.containsKey(username) && users[username] == password) {
         AppState.currentUser = username;
         AppState.transactionsNotifier.value = await AppState.loadTransactions(username);
         AppState.goalsNotifier.value = await AppState.loadGoals(username);
         AppState.budgetsNotifier.value = await AppState.loadBudgets(username);
         AppState.accountsNotifier.value = await AppState.loadAccounts(username);
         AppState.themeNameNotifier.value = await AppState.loadTheme(username);
         AppState.avatarColorNotifier.value = await AppState.loadAvatarColor(username);
         if (!mounted) return;
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));
      } else {
         setState(() { _error = 'Invalid credentials'; _isLoading = false; });
      }
    } else {
      if (users.containsKey(username)) {
         setState(() { _error = 'User already exists'; _isLoading = false; });
      } else {
         users[username] = password;
         await prefs.setString('users', jsonEncode(users));
         AppState.currentUser = username;
         AppState.transactionsNotifier.value = [];
         AppState.goalsNotifier.value = [];
         AppState.budgetsNotifier.value = {'Food & Dining': 500.0, 'Housing & Rent': 1500.0, 'Transportation': 300.0, 'Entertainment': 200.0};
         AppState.accountsNotifier.value = ['Main', 'Cash', 'Credit Card', 'Digital Wallet'];
         AppState.themeNameNotifier.value = 'Violet Night';
         AppState.avatarColorNotifier.value = const Color(0xFF8B5CF6);
         if (!mounted) return;
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       body: Center(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(32.0),
           child: ConstrainedBox(
             constraints: const BoxConstraints(maxWidth: 400),
             child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   gradient: RadialGradient(
                     colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), Colors.transparent],
                   )
                 ),
                 child: Icon(Icons.account_balance_wallet, size: 80, color: Theme.of(context).colorScheme.primary),
               ),
               const SizedBox(height: 20),
               Text(_isLogin ? 'Welcome Back' : 'Create Account', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
               const SizedBox(height: 40),
               TextField(
                 controller: _usernameCtrl,
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(
                   labelText: 'Username', 
                   labelStyle: const TextStyle(color: Colors.white54),
                   filled: true, 
                   fillColor: Theme.of(context).colorScheme.surface,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                 ),
               ),
               const SizedBox(height: 15),
               TextField(
                 controller: _passwordCtrl,
                 obscureText: true,
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(
                   labelText: 'Password', 
                   labelStyle: const TextStyle(color: Colors.white54),
                   filled: true, 
                   fillColor: Theme.of(context).colorScheme.surface,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                 ),
               ),
               if (_error.isNotEmpty) ...[
                 const SizedBox(height: 15),
                 Text(_error, style: const TextStyle(color: Colors.redAccent)),
               ],
               const SizedBox(height: 30),
               _isLoading 
                 ? const CircularProgressIndicator()
                 : ElevatedButton(
                     onPressed: _submit,
                     style: ElevatedButton.styleFrom(
                       minimumSize: const Size(double.infinity, 55), 
                       backgroundColor: Theme.of(context).colorScheme.primary,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                     ),
                     child: Text(_isLogin ? 'Login' : 'Register', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                   ),
               const SizedBox(height: 15),
               TextButton(
                 onPressed: () => setState(() { _isLogin = !_isLogin; _error = ''; }),
                 child: Text(
                   _isLogin ? 'Need an account? Register' : 'Already have an account? Login',
                   style: const TextStyle(color: Colors.white70),
                 ),
               )
             ],
           ),
           ),
         ),
       ),
     );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
