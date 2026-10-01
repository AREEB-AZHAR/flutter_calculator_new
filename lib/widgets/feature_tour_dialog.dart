import 'package:flutter/material.dart';
import '../services/tour_service.dart';

class TourStep {
  final IconData icon;
  final String title;
  final String description;
  final String? proTip;
  final String? badgeText;

  const TourStep({
    required this.icon,
    required this.title,
    required this.description,
    this.proTip,
    this.badgeText,
  });
}

bool _isTourOpen = false;

Future<void> showFeatureTour(
  BuildContext context, {
  required String tourTitle,
  required List<TourStep> steps,
  required String tourKey,
  VoidCallback? onCompleted,
}) async {
  if (steps.isEmpty) return;
  if (_isTourOpen) return;
  _isTourOpen = true;

  try {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FeatureTourDialog(
        tourTitle: tourTitle,
        steps: steps,
        tourKey: tourKey,
        onCompleted: onCompleted,
      ),
    );
  } finally {
    _isTourOpen = false;
  }
}

/// Step-by-step Home / Dashboard screen tour for new users
Future<void> showHomeDashboardTour(BuildContext context, {VoidCallback? onCompleted}) async {
  await showFeatureTour(
    context,
    tourTitle: 'HOME TOUR',
    tourKey: TourService.tourHome,
    onCompleted: onCompleted,
    steps: const [
      TourStep(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Welcome to Tally Ledger',
        description: 'Tally gives you an offline, privacy-first financial ledger with live balances, cash flow tracking, and category breakdowns.',
        proTip: 'All your financial records are kept safe in an encrypted, user-isolated SQLite vault right on your phone.',
      ),
      TourStep(
        icon: Icons.add_circle_outline_rounded,
        title: 'Quick Transaction Logging',
        description: 'Tap the floating "+" button anywhere on the dashboard to log your expenses or income. Choose between accounts and custom dates with ease.',
        proTip: '💡 Pro-Tip: You can leave the "Title" field completely empty! Tally will automatically auto-fill the title using your chosen category name.',
      ),
      TourStep(
        icon: Icons.swap_horiz_rounded,
        title: 'Smart Category Switching',
        description: 'When you tap "Income", Tally automatically switches the category to "Salary" for lightning-fast logging. Selecting "Expense" reverts back to daily spending.',
        proTip: 'Explore over 15+ curated expense and income categories with custom visual icons.',
      ),
      TourStep(
        icon: Icons.pie_chart_rounded,
        title: 'Interactive Visual Analytics',
        description: 'Switch between Weekly, Monthly, and Yearly charts. Tap any chart slice or bar to filter category breakdowns and inspect transaction trends.',
      ),
      TourStep(
        icon: Icons.notifications_active_rounded,
        title: 'Budget Alerts & Monitoring',
        description: 'Set spending limits for key categories. Tally automatically alerts you when you reach 80% and 100% of your budget threshold.',
      ),
    ],
  );
}

/// Step-by-step Accounts & Wallets screen tour for new users
Future<void> showAccountsTour(BuildContext context, {VoidCallback? onCompleted}) async {
  await showFeatureTour(
    context,
    tourTitle: 'ACCOUNTS TOUR',
    tourKey: TourService.tourAccounts,
    onCompleted: onCompleted,
    steps: const [
      TourStep(
        icon: Icons.account_balance_rounded,
        title: 'Multi-Wallet & Account Hub',
        description: 'Organize and monitor all your finances across Bank Accounts, Cash, Savings, Crypto, or Credit Cards in one unified place.',
        proTip: 'Tap any wallet card to filter the entire screen, chart, and transaction history to that specific account.',
      ),
      TourStep(
        icon: Icons.add_card_rounded,
        title: 'How to Add New Account Types',
        description: 'Need to track a new bank, wallet, or emergency fund? Tap "+ Add Account" or the Settings icon (⚙️) in the top-right corner of this screen, enter your account name, and press "Add".',
        proTip: '💡 Pro-Tip: Newly created accounts immediately appear in your transaction logging dropdowns and charts!',
      ),
      TourStep(
        icon: Icons.auto_graph_rounded,
        title: 'Global & Isolated Insights',
        description: 'Select "🌐 All Accounts" to see your aggregate net worth and cash flow, or select a single account to inspect isolated balances and spending velocity.',
      ),
    ],
  );
}

class _FeatureTourDialog extends StatefulWidget {
  final String tourTitle;
  final List<TourStep> steps;
  final String tourKey;
  final VoidCallback? onCompleted;

  const _FeatureTourDialog({
    required this.tourTitle,
    required this.steps,
    required this.tourKey,
    this.onCompleted,
  });

  @override
  State<_FeatureTourDialog> createState() => _FeatureTourDialogState();
}

class _FeatureTourDialogState extends State<_FeatureTourDialog> {
  int _currentIndex = 0;

  void _finish() {
    TourService.markTourCompleted(widget.tourKey);
    Navigator.of(context).pop();
    widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final step = widget.steps[_currentIndex];
    final isLast = _currentIndex == widget.steps.length - 1;

    return AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: onSurface.withValues(alpha: 0.12), width: 1.2),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.tourTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_currentIndex + 1} of ${widget.steps.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Step Icon with theme-colored glowing badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.12),
                  border: Border.all(color: primary.withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(step.icon, size: 36, color: primary),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: onSurface.withValues(alpha: 0.72),
                ),
              ),

              // Pro-Tip Callout
              if (step.proTip != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step.proTip!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.steps.length, (idx) {
                  final isSelected = idx == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? primary : onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentIndex > 0)
              TextButton(
                onPressed: () => setState(() => _currentIndex--),
                child: Text('Back', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
              )
            else
              TextButton(
                onPressed: _finish,
                child: Text('Skip', style: TextStyle(color: onSurface.withValues(alpha: 0.45))),
              ),
            ElevatedButton(
              onPressed: () {
                if (isLast) {
                  _finish();
                } else {
                  setState(() => _currentIndex++);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
              child: Text(
                isLast ? 'Got it!' : 'Next',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
