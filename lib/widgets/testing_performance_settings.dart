import 'package:flutter/material.dart';
import '../services/display_rate_service.dart';
import '../services/monetization_service.dart';

class TestingPerformanceSettings extends StatelessWidget {
  const TestingPerformanceSettings({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Display & testing',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Refresh-rate preference (not a guaranteed frame rate). High refresh can use more battery.',
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              DisplayRateService.preference,
              DisplayRateService.supported,
              DisplayRateService.status,
            ]),
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final hz in [0, 60, 120])
                      ChoiceChip(
                        label: Text(hz == 0 ? 'System' : '$hz Hz'),
                        selected: DisplayRateService.preference.value == hz,
                        onSelected:
                            hz != 0 &&
                                !DisplayRateService.supported.value.contains(hz)
                            ? null
                            : (_) =>
                                  DisplayRateService.instance.setPreference(hz),
                      ),
                  ],
                ),
                Text(DisplayRateService.status.value),
              ],
            ),
          ),
          if (MonetizationService.testingVipCodeEnabled)
            ValueListenableBuilder<bool>(
              valueListenable: MonetizationService.testingVipNotifier,
              builder: (context, active, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active
                        ? 'FREEVIP testing active on this device — Pro, no ads.'
                        : 'Temporary VIP testing: enter FREEVIP to hide ads and unlock Pro.',
                  ),
                  TextButton(
                    onPressed: () =>
                        MonetizationService.showPromoCodeDialog(context),
                    child: const Text('Enter testing code'),
                  ),
                  if (active)
                    TextButton(
                      onPressed: MonetizationService.disableTestingVip,
                      child: const Text('Disable FREEVIP'),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
