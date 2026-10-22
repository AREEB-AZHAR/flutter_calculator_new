import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:balance_tracker/services/database/app_database.dart';

/// Each test-file isolate owns a database directory. Parallel files must never
/// share finance_vault.db (or read/write a developer's real desktop ledger).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  late Directory directory;
  setUpAll(() async {
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp('tally-test-');
    await databaseFactoryFfi.setDatabasesPath(directory.path);
    databaseFactory = databaseFactoryFfi;
  });
  tearDownAll(() async {
    await AppDatabase.instance.close();
    // Flutter/native plugin callbacks may retain handles until the test isolate
    // exits on Windows. These uniquely named OS-temp fixtures may be removed
    // after the runner exits; never race native callbacks by deleting them here.
  });
  await testMain();
}
