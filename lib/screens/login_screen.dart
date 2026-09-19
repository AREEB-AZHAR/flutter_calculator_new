import 'package:flutter/material.dart';
import 'main_nav_screen.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';

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
    FocusScope.of(context).unfocus();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    
    if (username.isEmpty || password.isEmpty) {
       setState(() => _error = 'Please fill all fields');
       return;
    }

    setState(() { _isLoading = true; _error = ''; });

    try {
      if (_isLogin) {
        final success = await AppDatabase.instance.authenticateUser(username, password);
        if (success) {
          await AppState.loadAllUserData(username);
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));
        } else {
          if (!mounted) return;
          setState(() { _error = 'Invalid username or password'; _isLoading = false; });
        }
      } else {
        final registered = await AppDatabase.instance.registerUser(username, password);
        if (registered) {
          await AppState.loadAllUserData(username);
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));
        } else {
          if (!mounted) return;
          setState(() { _error = 'User already exists'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'An error occurred during authentication. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       body: Center(
         child: SingleChildScrollView(
           keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                 keyboardType: TextInputType.text,
                 autocorrect: false,
                 enableSuggestions: false,
                 textInputAction: TextInputAction.next,
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
                 enableSuggestions: false,
                 autocorrect: false,
                 textInputAction: TextInputAction.done,
                 onSubmitted: (_) => _submit(),
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
                 Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
               ],
               const SizedBox(height: 30),
               ElevatedButton(
                 onPressed: _isLoading ? null : _submit,
                 style: ElevatedButton.styleFrom(
                   minimumSize: const Size(double.infinity, 55), 
                   backgroundColor: Theme.of(context).colorScheme.primary,
                   disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                 ),
                 child: _isLoading 
                   ? const SizedBox(
                       width: 24,
                       height: 24,
                       child: CircularProgressIndicator(
                         strokeWidth: 2.5,
                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                       ),
                     )
                   : Text(_isLogin ? 'Login' : 'Register', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
               ),
               const SizedBox(height: 15),
               TextButton(
                 onPressed: _isLoading ? null : () => setState(() { _isLogin = !_isLogin; _error = ''; }),
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
