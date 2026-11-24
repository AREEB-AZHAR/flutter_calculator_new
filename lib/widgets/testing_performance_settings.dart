import 'package:flutter/material.dart';
import '../services/monetization_service.dart';

class TestingPerformanceSettings extends StatelessWidget {
  const TestingPerformanceSettings({super.key});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.redeem_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Display & testing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Redeem a promo code to unlock Tally Pro features and an ad-free experience.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: MonetizationService.isProUnlockedNotifier,
            builder: (context, isPro, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: MonetizationService.testingVipNotifier,
                builder: (context, isVip, _) {
                  final active = isPro || isVip;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (active) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Pro / VIP Access Active — Ad-Free',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ElevatedButton.icon(
                        icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                        label: const Text('Redeem Promo Code'),
                        onPressed: () => MonetizationService.showPromoCodeDialog(context),
                      ),
                      if (isVip)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton(
                            onPressed: MonetizationService.disableTestingVip,
                            child: const Text('Disable VIP Mode'),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    ),
  );
}
