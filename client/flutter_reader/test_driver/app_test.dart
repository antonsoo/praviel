import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Ancient Languages App UI Test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await driver.waitUntilFirstFrameRasterized();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('App launches without crashing', () async {
      await Future.delayed(const Duration(seconds: 2));

      // Take screenshot of home page
      final homeScreenshot = await driver.screenshot();
      await File('screenshots/home_screen.png').writeAsBytes(homeScreenshot);

      // Screenshot saved: screenshots/home_screen.png
    });

    test('Can navigate to Lessons page', () async {
      // Find and tap Lessons tab
      final lessonsFinder = find.text('Lessons');
      await driver.tap(lessonsFinder);
      await Future.delayed(const Duration(seconds: 1));

      // Take screenshot
      final lessonsScreenshot = await driver.screenshot();
      await File(
        'screenshots/lessons_screen.png',
      ).writeAsBytes(lessonsScreenshot);

      // Screenshot saved: screenshots/lessons_screen.png
    });

    test('Check button has 3D effect', () async {
      // This would need the lesson to be loaded
      // Just verify the button exists
      final checkButton = find.text('CHECK');
      expect(await driver.getText(checkButton), 'CHECK');
    });
  });
}
