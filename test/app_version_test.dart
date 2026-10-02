import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance_tracker/services/app_version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppVersion.reset();
  });

  group('AppVersion Service Tests', () {
    test('Default fallback version matches 1.8.6 and build 16', () {
      expect(AppVersion.version, equals('1.8.6'));
      expect(AppVersion.buildNumber, equals('16'));
      expect(AppVersion.appName, equals('Tally'));
      expect(AppVersion.displayString, equals('Tally v1.8.6 (Build 16)'));
    });

    test('Mock values update getters and display string dynamically', () {
      AppVersion.setMockValues(
        version: '1.8.7',
        buildNumber: '17',
        appName: 'Tally Pro',
      );

      expect(AppVersion.version, equals('1.8.7'));
      expect(AppVersion.buildNumber, equals('17'));
      expect(AppVersion.appName, equals('Tally Pro'));
      expect(AppVersion.displayString, equals('Tally Pro v1.8.7 (Build 17)'));

      AppVersion.reset();
      expect(AppVersion.version, equals('1.8.6'));
      expect(AppVersion.buildNumber, equals('16'));
    });

    test('pubspec.yaml single-source-of-truth matches AppVersion fallback', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue, reason: 'pubspec.yaml must exist');

      final content = pubspecFile.readAsStringSync();
      final versionMatch = RegExp(r'^version:\s*([^\s+]+)\+([^\s]+)', multiLine: true).firstMatch(content);

      expect(versionMatch, isNotNull, reason: 'pubspec.yaml must define version: X.Y.Z+B');
      final pubspecVersion = versionMatch!.group(1);
      final pubspecBuild = versionMatch.group(2);

      expect(pubspecVersion, equals(AppVersion.version));
      expect(pubspecBuild, equals(AppVersion.buildNumber));
    });

    testWidgets('AppVersion displayString renders cleanly in widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                AppVersion.displayString,
                key: const Key('app_version_footer'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('app_version_footer')), findsOneWidget);
      expect(find.text('Tally v1.8.6 (Build 16)'), findsOneWidget);
    });
  });
}
