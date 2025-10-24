import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global test configuration for flutter_reader.
///
/// This file is automatically loaded by Flutter test framework before any tests run.
/// It sets up SharedPreferences mock to avoid MissingPluginException in tests.
///
/// DO NOT DELETE - this prevents noisy plugin channel errors during tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Must run before any getInstance() call to avoid MissingPluginException
  SharedPreferences.setMockInitialValues({});

  await testMain();
}
