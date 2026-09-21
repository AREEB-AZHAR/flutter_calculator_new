import 'package:flutter/material.dart';
import '../services/state.dart';
import '../widgets/tally_brand_painters.dart';
import 'login_screen.dart';
import 'main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Stage 1: Icon strokes drawing
  late Animation<double> _s1Anim;
  late Animation<double> _s2Anim;
  late Animation<double> _s3Anim;
  late Animation<double> _s4Anim;
  late Animation<double> _slashAnim;

  // Stage 2: Icon shrink & Wordmark typing + uwash
  late Animation<double> _iconSizeAnim;
  late Animation<double> _spacingAnim;
  late Animation<double> _wordmarkOpacityAnim;
  late Animation<double> _typeProgressAnim;
  late Animation<double> _uwashProgressAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );

    // Stage 1 (0.00 - 0.44): Draw the 4 strokes and the slash
    _s1Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.15, curve: Curves.easeOut),
    );
    _s2Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.23, curve: Curves.easeOut),
    );
    _s3Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 0.31, curve: Curves.easeOut),
    );
    _s4Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.24, 0.38, curve: Curves.easeOut),
    );
    _slashAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.48, curve: Curves.easeOutCubic),
    );

    // Stage 2 (0.46 - 0.85): Shrink icon from 130 to 80, expand spacing, and reveal wordmark
    _iconSizeAnim = Tween<double>(begin: 130.0, end: 80.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.65, curve: Curves.easeInOutCubic),
      ),
    );

    _spacingAnim = Tween<double>(begin: 0.0, end: 24.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.65, curve: Curves.easeInOutCubic),
      ),
    );

    _wordmarkOpacityAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.62, curve: Curves.easeIn),
    );

    _typeProgressAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 0.72, curve: Curves.easeOut),
    );

    _uwashProgressAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 0.88, curve: Curves.easeInOutCubic),
    );

    _controller.forward();

    // Stage 3: Smooth navigation to LoginScreen with Hero transition
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    if (!mounted) return;
    final destination = AppState.currentUser != null ? const MainNavScreen() : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default theme background: clean paper cream/white
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated App Icon (draws, then shrinks smoothly)
                SizedBox(
                  width: _iconSizeAnim.value,
                  height: _iconSizeAnim.value,
                  child: CustomPaint(
                    painter: TallyIconPainter(
                      stroke1Progress: _s1Anim.value,
                      stroke2Progress: _s2Anim.value,
                      stroke3Progress: _s3Anim.value,
                      stroke4Progress: _s4Anim.value,
                      slashProgress: _slashAnim.value,
                      bgColor: const Color(0xFF17493B),
                      strokeColor: const Color(0xFFF6F0E1),
                      slashColor: const Color(0xFFE4572E),
                    ),
                  ),
                ),

                SizedBox(height: _spacingAnim.value),

                // Wordmark with Hero for seamless glide to LoginScreen
                Opacity(
                  opacity: _wordmarkOpacityAnim.value,
                  child: Hero(
                    tag: 'tally_wordmark',
                    child: Material(
                      color: Colors.transparent,
                      child: TallyWordmarkWidget(
                        fontSize: 38,
                        textColor: const Color(0xFF152A22),
                        uwashColor: const Color(0xFFE4572E),
                        typeProgress: _typeProgressAnim.value,
                        uwashProgress: _uwashProgressAnim.value,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
