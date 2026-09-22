import 'package:flutter/material.dart';
import 'main_nav_screen.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';
import '../widgets/tally_brand_painters.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  String _error = '';
  bool _isLoading = false;

  late AnimationController _formAnimController;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    // Entrance animation: Login material flies up from the bottom of the screen
    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimController,
      curve: Curves.easeOutCubic,
    ));

    _formFadeAnimation = CurvedAnimation(
      parent: _formAnimController,
      curve: Curves.easeIn,
    );

    _formAnimController.forward();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (_isLogin) {
        final success = await AppDatabase.instance.authenticateUser(username, password);
        if (success) {
          await AppState.loadAllUserData(username);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MainNavScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          );
        } else {
          if (!mounted) return;
          setState(() {
            _error = 'Invalid username or password';
            _isLoading = false;
          });
        }
      } else {
        final registered = await AppDatabase.instance.registerUser(username, password);
        if (registered) {
          await AppState.loadAllUserData(username);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MainNavScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          );
        } else {
          if (!mounted) return;
          setState(() {
            _error = 'User already exists';
            _isLoading = false;
          });
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
    final theme = Theme.of(context);
    final inkColor = theme.colorScheme.onSurface;
    final cardBg = theme.colorScheme.surface;
    final inputBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Continuous Hero Wordmark received from SplashScreen
                  Hero(
                    tag: 'tally_wordmark',
                    child: Material(
                      color: Colors.transparent,
                      child: TallyWordmarkWidget(
                        fontSize: 40,
                        textColor: inkColor,
                        uwashColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Login material flies up from the bottom
                  SlideTransition(
                    position: _formSlideAnimation,
                    child: FadeTransition(
                      opacity: _formFadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: inkColor.withValues(alpha: 0.12),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? 'Welcome Back' : 'Create Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: inkColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isLogin ? 'Sign in to access your ledger & budget' : 'Start tracking your wealth with zero cloud tracking',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: inkColor.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            // Username input
                            TextField(
                              controller: _usernameCtrl,
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(color: inkColor, fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: inkColor.withValues(alpha: 0.6)),
                                filled: true,
                                fillColor: inputBg,
                                prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: inkColor.withValues(alpha: 0.12)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: inkColor.withValues(alpha: 0.12)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password input
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              style: TextStyle(color: inkColor, fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: inkColor.withValues(alpha: 0.6)),
                                filled: true,
                                fillColor: inputBg,
                                prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: inkColor.withValues(alpha: 0.12)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: inkColor.withValues(alpha: 0.12)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                ),
                              ),
                            ),

                            if (_error.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _error,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Submit Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Login to Tally' : 'Create Ledger Account',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                            ),

                            const SizedBox(height: 14),

                            // Switch mode button
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() {
                                        _isLogin = !_isLogin;
                                        _error = '';
                                      }),
                              child: Text(
                                _isLogin ? 'Need an account? Register here' : 'Already registered? Login here',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _formAnimController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
