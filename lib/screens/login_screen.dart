import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'main_nav_screen.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';
import '../services/biometric_service.dart';
import '../services/google_auth_service.dart';
import '../utils/password_validator.dart';
import '../widgets/tally_brand_painters.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _error = '';
  bool _isLoading = false;
  bool _canUseBiometrics = false;
  String? _biometricUser;

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
    _checkBiometricAvailability();

    // Rebuild for real-time password requirement checklist
    _passwordCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (!_isLogin && mounted) {
      setState(() {});
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final enabled = await BiometricService.isBiometricEnabled();
    final savedUser = await BiometricService.getSavedBiometricUser();
    final supported = await BiometricService.isDeviceSupported();
    if (mounted && enabled && savedUser != null && savedUser.isNotEmpty && supported) {
      setState(() {
        _canUseBiometrics = true;
        _biometricUser = savedUser;
        if (_usernameCtrl.text.isEmpty) {
          _usernameCtrl.text = savedUser;
        }
      });
      // Seamlessly prompt mobile screen lock after entrance transition completes
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _canUseBiometrics && _isLogin && !_isLoading) {
          _unlockWithBiometrics();
        }
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final googleUser = await GoogleAuthService.signIn(context);
      if (googleUser != null) {
        if (await BiometricService.isBiometricEnabled(username: googleUser.email)) {
          await BiometricService.setBiometricEnabled(true, username: googleUser.email);
        }
        await AppState.loadAllUserData(googleUser.email);
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Google Sign-In failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (_biometricUser == null || _biometricUser!.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final success = await BiometricService.authenticate(
        reason: 'Scan fingerprint or Face ID to unlock Tally',
      );
      if (success) {
        await AppState.loadAllUserData(_biometricUser!);
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final identifier = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (_isLogin) {
      if (identifier.isEmpty || password.isEmpty) {
        setState(() => _error = 'Please enter your username/email and password');
        return;
      }

      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        final success = await AppDatabase.instance.authenticateUser(identifier, password);
        if (success) {
          final canonicalUsername = await AppDatabase.instance.getUsernameForIdentifier(identifier) ?? identifier;
          if (await BiometricService.isBiometricEnabled(username: canonicalUsername)) {
            await BiometricService.setBiometricEnabled(true, username: canonicalUsername);
          }
          await AppState.loadAllUserData(canonicalUsername);
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
            _error = 'Invalid email/username or password';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = 'An error occurred during authentication. Please try again.';
          _isLoading = false;
        });
      }
    } else {
      // Registration flow
      final email = _emailCtrl.text.trim();
      final username = _usernameCtrl.text.trim();
      final confirmPassword = _confirmPasswordCtrl.text;

      if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        setState(() => _error = 'Please fill all required fields');
        return;
      }

      if (!PasswordValidator.isValidEmail(email)) {
        setState(() => _error = 'Please enter a valid email address');
        return;
      }

      // Strong password validation
      final validation = PasswordValidator.validate(password);
      if (!validation.isValid) {
        setState(() => _error = 'Password does not meet security requirements:\n• ${validation.missingRequirements.join('\n• ')}');
        return;
      }

      if (password != confirmPassword) {
        setState(() => _error = 'Passwords do not match');
        return;
      }

      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        final registered = await AppDatabase.instance.registerUser(
          username: username,
          password: password,
          email: email,
        );
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
            _error = 'Username or email already exists. Try signing in.';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = 'An error occurred during account creation. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Opens the interactive password reset dialog for forgotten passwords
  Future<void> _showForgotPasswordDialog() async {
    final emailResetCtrl = TextEditingController(text: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : _usernameCtrl.text);
    final codeCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmNewPassCtrl = TextEditingController();

    bool isVerifying = false;
    int resetStep = 0; // 0: enter email, 1: verify security code, 2: set new password
    String? dialogError;
    String? resolvedEmail;
    String? generatedSecurityCode;
    DateTime? codeGeneratedAt;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          final surface = theme.colorScheme.surface;
          final onSurface = theme.colorScheme.onSurface;
          final primary = theme.colorScheme.primary;

          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(
                  resetStep == 2 ? Icons.verified_user_rounded : (resetStep == 1 ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded),
                  color: primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  resetStep == 0
                      ? 'Reset Password'
                      : (resetStep == 1 ? 'Verify Email Code' : 'Set New Password'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (resetStep == 0) ...[
                    Text(
                      'Enter your registered or bound email address to receive a 6-digit verification code:',
                      style: TextStyle(fontSize: 12.5, color: onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailResetCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Registered Email',
                        hintText: 'user@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ] else if (resetStep == 1) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: primary, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Verification code sent to:',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: onSurface),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            resolvedEmail ?? '',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Enter the 6-digit verification code sent to your inbox:',
                      style: TextStyle(fontSize: 12.5, color: onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: '6-Digit Verification Code',
                        hintText: '123456',
                        prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Resend Code', style: TextStyle(fontSize: 12)),
                        onPressed: isVerifying
                            ? null
                            : () async {
                                setDialogState(() {
                                  isVerifying = true;
                                  dialogError = null;
                                });
                                final newCode = (100000 + Random.secure().nextInt(900000)).toString();
                                generatedSecurityCode = newCode;
                                codeGeneratedAt = DateTime.now();
                                try {
                                  if (Firebase.apps.isNotEmpty) {
                                    final callable = FirebaseFunctions.instance.httpsCallable('sendOtpEmail');
                                    await callable.call({'email': resolvedEmail!, 'otp': newCode});
                                  }
                                } catch (e) {
                                  debugPrint('Cloud Function sendOtpEmail resend note: $e');
                                }
                                setDialogState(() {
                                  isVerifying = false;
                                  dialogError = 'New verification code sent! Valid for 10 minutes.';
                                });
                              },
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email ownership verified successfully!',
                              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Set a new strong password for $resolvedEmail:',
                      style: TextStyle(fontSize: 12.5, color: onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: true,
                      onChanged: (_) => setDialogState(() {}),
                      style: TextStyle(color: onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'New Strong Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    _buildPasswordRequirements(newPassCtrl.text, theme),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmNewPassCtrl,
                      obscureText: true,
                      style: TextStyle(color: onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],

                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      style: TextStyle(
                        color: dialogError!.contains('generated!') || dialogError!.contains('sent!') ? Colors.green : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (resetStep == 1)
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      resetStep = 0;
                      dialogError = null;
                      codeCtrl.clear();
                    });
                  },
                  child: const Text('Change Email'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
                onPressed: isVerifying
                    ? null
                    : () async {
                        setDialogState(() {
                          isVerifying = true;
                          dialogError = null;
                        });

                        if (resetStep == 0) {
                          // Step 0: Validate email & send Firebase reset email / generate 6-digit OTP
                          final emailInput = emailResetCtrl.text.trim();
                          if (!PasswordValidator.isValidEmail(emailInput)) {
                            setDialogState(() {
                              isVerifying = false;
                              dialogError = 'Please enter a valid email format';
                            });
                            return;
                          }

                          final user = await AppDatabase.instance.getUserByEmail(emailInput);
                          if (user == null) {
                            setDialogState(() {
                              isVerifying = false;
                              dialogError = 'No account found with this email address.';
                            });
                            return;
                          }

                          final secureOtp = (100000 + Random.secure().nextInt(900000)).toString();
                          generatedSecurityCode = secureOtp;
                          codeGeneratedAt = DateTime.now();

                          // Send OTP verification code via Cloud Function
                          try {
                            if (Firebase.apps.isNotEmpty) {
                              final callable = FirebaseFunctions.instance.httpsCallable('sendOtpEmail');
                              await callable.call({'email': emailInput, 'otp': secureOtp});
                            }
                          } catch (e) {
                            debugPrint('Cloud Function sendOtpEmail note: $e');
                          }

                          setDialogState(() {
                            isVerifying = false;
                            resolvedEmail = emailInput;
                            resetStep = 1;
                          });
                        } else if (resetStep == 1) {
                          // Step 1: Validate verification code
                          final inputCode = codeCtrl.text.trim();
                          if (inputCode.isEmpty) {
                            setDialogState(() {
                              isVerifying = false;
                              dialogError = 'Please enter the verification code.';
                            });
                            return;
                          }

                          bool isCodeMatched = false;

                          // Check generated 6-digit OTP (expires in 10 minutes)
                          if (generatedSecurityCode != null &&
                              codeGeneratedAt != null &&
                              DateTime.now().difference(codeGeneratedAt!).inMinutes < 10 &&
                              inputCode == generatedSecurityCode) {
                            isCodeMatched = true;
                          }

                          if (!isCodeMatched) {
                            setDialogState(() {
                              isVerifying = false;
                              dialogError = 'Invalid or expired verification code. Please check your email or tap Resend.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isVerifying = false;
                            resetStep = 2;
                            dialogError = null;
                          });
                        } else {
                          // Step 2: Set New Password
                          final newPass = newPassCtrl.text;
                          final confirmPass = confirmNewPassCtrl.text;

                          final valid = PasswordValidator.validate(newPass);
                          if (!valid.isValid) {
                            setDialogState(() {
                              isVerifying = false;
                              dialogError = 'New password does not meet security requirements:\n• ${valid.missingRequirements.join('\n• ')}';
                            });
                            return;
                          }

                          if (newPass != confirmPass) {
                            setDialogState(() {
                              isVerifying = false;
                              dialogError = 'Passwords do not match';
                            });
                            return;
                          }


                          final updated = await AppDatabase.instance.updatePasswordByEmail(resolvedEmail!, newPass);
                          if (updated) {
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              _usernameCtrl.text = resolvedEmail!;
                              _passwordCtrl.clear();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 Password updated securely! Please log in with your new password.'),
                                    backgroundColor: Colors.teal,
                                  ),
                                );
                              }
                            }
                          } else {
                            setDialogState(() {
                              isVerifying = false;
                              dialogError = 'Failed to update password. Please try again.';
                            });
                          }
                        }
                      },
                child: Text(
                  resetStep == 0
                      ? 'Send Code'
                      : (resetStep == 1 ? 'Verify Code' : 'Update Password'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPasswordRequirements(String password, ThemeData theme) {
    final res = PasswordValidator.validate(password);
    final onSurface = theme.colorScheme.onSurface;

    Widget item(bool met, String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: met ? Colors.greenAccent.shade700 : onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
                color: met ? onSurface : onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASSWORD SECURITY CRITERIA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (res.isValid)
                const Text(
                  'STRONG',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
            ],
          ),
          const SizedBox(height: 6),
          item(res.hasMinLength, 'At least 10 characters long (${password.length}/10)'),
          item(res.hasUppercase, 'At least 1 uppercase letter (A-Z)'),
          item(res.hasLowercase, 'At least 1 lowercase letter (a-z)'),
          item(res.hasSpecialChar, 'At least 1 special character (!@#\$%^&*...)'),
          item(res.hasThreeDigits, 'At least 3 numbers (found ${res.digitCount}/3)'),
        ],
      ),
    );
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
            keyboardDismissBehavior: kIsWeb ? ScrollViewKeyboardDismissBehavior.manual : ScrollViewKeyboardDismissBehavior.onDrag,
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
                              _isLogin ? 'Sign in to access your ledger & budget' : 'Bind a recovery email & create your secure ledger',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: inkColor.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            // In registration mode: Ask for Email first
                            if (!_isLogin) ...[
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: inkColor, fontSize: 15),
                                decoration: InputDecoration(
                                  labelText: 'Email Address (Bound Recovery Email)',
                                  labelStyle: TextStyle(color: inkColor.withValues(alpha: 0.6)),
                                  filled: true,
                                  fillColor: inputBg,
                                  prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
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
                            ],

                            // Username / Identifier input
                            TextField(
                              controller: _usernameCtrl,
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(color: inkColor, fontSize: 15),
                              decoration: InputDecoration(
                                labelText: _isLogin ? 'Email or Username' : 'Username',
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
                              obscureText: _obscurePassword,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                              onSubmitted: (_) => _isLogin ? _submit() : null,
                              style: TextStyle(color: inkColor, fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: inkColor.withValues(alpha: 0.6)),
                                filled: true,
                                fillColor: inputBg,
                                prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: inkColor.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
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

                            // Real-time password requirement checklist in registration mode
                            if (!_isLogin) ...[
                              _buildPasswordRequirements(_passwordCtrl.text, theme),
                              const SizedBox(height: 10),

                              // Confirm Password input
                              TextField(
                                controller: _confirmPasswordCtrl,
                                obscureText: _obscureConfirmPassword,
                                enableSuggestions: false,
                                autocorrect: false,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                style: TextStyle(color: inkColor, fontSize: 15),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: TextStyle(color: inkColor.withValues(alpha: 0.6)),
                                  filled: true,
                                  fillColor: inputBg,
                                  prefixIcon: Icon(Icons.lock_clock_outlined, color: theme.colorScheme.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: inkColor.withValues(alpha: 0.5),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
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
                            ],

                            // Forgot Password link for login mode
                            if (_isLogin) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : _showForgotPasswordDialog,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],

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

                            const SizedBox(height: 20),

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

                            if (_canUseBiometrics && _isLogin) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _unlockWithBiometrics,
                                icon: Icon(Icons.fingerprint, color: theme.colorScheme.primary, size: 20),
                                label: Text(
                                  'Unlock with Screen Lock ($_biometricUser)',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: inkColor.withValues(alpha: 0.15))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'OR CONNECT WITH',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: inkColor.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: inkColor.withValues(alpha: 0.15))),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Google Sign-In Button
                            OutlinedButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: cardBg,
                                foregroundColor: inkColor,
                                side: BorderSide(color: inkColor.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      color: inkColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Switch mode button
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() {
                                        _isLogin = !_isLogin;
                                        _error = '';
                                      }),
                              child: Text(
                                _isLogin ? 'Need an account? Register with Email' : 'Already registered? Login here',
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
    _passwordCtrl.removeListener(_onPasswordChanged);
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }
}
