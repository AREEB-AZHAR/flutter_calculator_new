import 'dart:async';
import 'package:flutter/material.dart';

/// Fullscreen Non-Skippable 30-Second Rewarded Ad Dialog.
///
/// Provides an authentic 30-second non-skippable advertising experience with
/// an unskippable countdown timer, live progress indicator, exit-prevention
/// warning modal, and celebratory reward granting on full completion.
///
/// Designed to work on all Flutter platforms (Android, iOS, Windows, macOS, Web)
/// ensuring reliable 1-time theme unlock testing and execution anywhere.
class Fullscreen30SecAdDialog extends StatefulWidget {
  final VoidCallback onRewardEarned;
  final VoidCallback? onAdDismissed;

  const Fullscreen30SecAdDialog({
    super.key,
    required this.onRewardEarned,
    this.onAdDismissed,
  });

  /// Displays the 30-second non-skippable fullscreen ad.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRewardEarned,
    VoidCallback? onAdDismissed,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (ctx) => Fullscreen30SecAdDialog(
        onRewardEarned: onRewardEarned,
        onAdDismissed: onAdDismissed,
      ),
    );
  }

  @override
  State<Fullscreen30SecAdDialog> createState() => _Fullscreen30SecAdDialogState();
}

class _Fullscreen30SecAdDialogState extends State<Fullscreen30SecAdDialog>
    with SingleTickerProviderStateMixin {
  static const int totalDurationSeconds = 30;
  int _secondsRemaining = totalDurationSeconds;
  Timer? _timer;
  bool _rewardGranted = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: totalDurationSeconds),
    )..forward();

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          _rewardGranted = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    widget.onAdDismissed?.call();
    super.dispose();
  }

  Future<bool> _promptConfirmExit() async {
    if (_rewardGranted) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 28),
            SizedBox(width: 10),
            Text(
              'Leave Ad Early?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'If you exit now, you will NOT earn your 1-Time Theme Change Pass. Only $_secondsRemaining seconds remaining!',
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Resume Ad', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit & Forfeit'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _completeAndClaim() {
    widget.onRewardEarned();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return PopScope(
      canPop: _rewardGranted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _promptConfirmExit();
        if (!mounted) return;
        if (shouldExit) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1D),
        body: SafeArea(
          child: Column(
            children: [
              // Top 30-Second Progress Bar
              AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: _rewardGranted ? 1.0 : _animCtrl.value,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _rewardGranted ? const Color(0xFF10B981) : const Color(0xFFE4572E),
                    ),
                  );
                },
              ),

              // Header with Non-Skippable Timer & Status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sponsor Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF38BDF8)),
                          SizedBox(width: 6),
                          Text(
                            'Sponsored Offer • AdMob Video',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Countdown Badge / Close Button
                    if (!_rewardGranted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_clock, size: 14, color: Color(0xFFF87171)),
                            const SizedBox(width: 6),
                            Text(
                              'Reward in ${_secondsRemaining}s',
                              style: const TextStyle(
                                color: Color(0xFFF87171),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _completeAndClaim,
                        icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                        label: const Text('Claim Reward', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              // Main Sponsored Ad Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Sponsor Brand Visual
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Apex High-Yield Cash Vault',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          '5.25% APY • ZERO FEES • FDIC INSURED',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Partner Feature Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          children: [
                            _adFeatureBullet(
                              icon: Icons.trending_up,
                              title: 'Grow Your Liquid Savings',
                              desc: 'Earn 10x the national average on your emergency fund.',
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _adFeatureBullet(
                              icon: Icons.shield_outlined,
                              title: 'Bank-Grade Security',
                              desc: 'Government-backed FDIC insurance up to \$2,000,000 via sweep network.',
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _adFeatureBullet(
                              icon: Icons.sync_alt_rounded,
                              title: 'Seamless Tally Integration',
                              desc: 'Link in seconds to track interest income directly in your Tally cashflow.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reward Status Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _rewardGranted
                                ? [const Color(0xFF065F46), const Color(0xFF047857)]
                                : [const Color(0xFF312E81), const Color(0xFF1E1B4B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _rewardGranted
                                ? const Color(0xFF34D399)
                                : const Color(0xFF818CF8).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _rewardGranted ? Icons.stars_rounded : Icons.palette_rounded,
                                color: _rewardGranted ? const Color(0xFFFDE047) : Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _rewardGranted ? '🎉 Reward Ready!' : 'Theme Change Reward',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _rewardGranted
                                        ? 'Tap below to claim your 1-Time Theme Change Pass and apply your new theme!'
                                        : 'Watch this 30-second video to completion to unlock 1 free theme change.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _rewardGranted ? _completeAndClaim : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rewardGranted ? const Color(0xFF10B981) : Colors.white12,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                      disabledForegroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: _rewardGranted ? 4 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _rewardGranted ? Icons.check_circle_rounded : Icons.timer_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _rewardGranted
                              ? 'Claim 1-Time Theme Unlock & Apply'
                              : 'Please wait: ${_secondsRemaining}s remaining (Non-Skippable)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    );
  }

  Widget _adFeatureBullet({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
