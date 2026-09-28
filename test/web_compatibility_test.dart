import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balance_tracker/widgets/tally_brand_painters.dart';
import 'package:balance_tracker/services/notification_service.dart';
import 'package:balance_tracker/services/biometric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Web Compatibility & Render Resilience Tests', () {
    testWidgets('TallyWordmarkWidget renders inside tight constraints without subpixel overflow', (WidgetTester tester) async {
      // Test the exact constrained dimensions where floating-point overflow previously occurred:
      // constraints: BoxConstraints(w=168.0, h=70.2)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 168.0,
                height: 70.2,
                child: TallyWordmarkWidget(
                  fontSize: 38,
                  textColor: Colors.black,
                  uwashColor: Colors.deepOrange,
                  typeProgress: 1.0,
                  uwashProgress: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow exception was thrown
      expect(tester.takeException(), isNull);
      expect(find.byType(TallyWordmarkWidget), findsOneWidget);
    });

    test('NotificationService web guards prevent zonedSchedule exceptions', () async {
      // Verify calling scheduling methods does not crash or throw unhandled exceptions
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleAllDailyReminders();
      await NotificationService.instance.cancelAllReminders();
      await NotificationService.instance.showInstantFriendlyReminder();
      await NotificationService.instance.showInstantAlert(title: 'Test', body: 'Test Body');
    });

    test('BiometricService web guards return safe false / empty values', () async {
      // On non-supported platforms, it should return false/empty safely
      final isSupported = await BiometricService.isDeviceSupported();
      expect(isSupported, isA<bool>());

      final biometrics = await BiometricService.getAvailableBiometrics();
      expect(biometrics, isA<List>());
    });
  });
}
