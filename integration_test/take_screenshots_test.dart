import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:in_the_biz_ai/main.dart' as app;
import 'dart:io';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Take Store Screenshots', () {
    testWidgets('1. Dashboard Screenshot', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await binding.takeScreenshot('dashboard');
      await tester.pumpAndSettle();
    });

    testWidgets('2. Add Shift Screenshot', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Add Shift
      final addButton = find.byIcon(Icons.add);
      await tester.tap(addButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await binding.takeScreenshot('add_shift');
    });

    testWidgets('3. Calendar Screenshot', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Calendar
      final calendarButton = find.text('Calendar');
      await tester.tap(calendarButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await binding.takeScreenshot('calendar');
    });

    testWidgets('4. Stats Screenshot', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Stats
      final statsButton = find.text('Stats');
      await tester.tap(statsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await binding.takeScreenshot('stats');
    });

    testWidgets('5. Settings Screenshot', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Settings
      final settingsButton = find.text('Settings');
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await binding.takeScreenshot('settings');
    });

    testWidgets('6. AI Chat Screenshot', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to AI Chat
      final chatButton = find.byIcon(Icons.chat_bubble);
      await tester.tap(chatButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await binding.takeScreenshot('ai_chat');
    });
  });
}
