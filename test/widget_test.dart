// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:belanja_praktis/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  // Ensure the test binding is initialized before any other code runs.
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts and shows LoginScreen', (WidgetTester tester) async {
    // Load .env file
    await dotenv.load(fileName: ".env");
    // Ensure all dependencies are set up before running the test, skipping platform-specific services.
    await setupDependencies(isTest: true);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the LoginScreen is displayed initially.
    // This assumes LoginScreen is the initial route or is shown when not logged in.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Welcome Back!'),
        findsOneWidget); // Assuming this text is on the LoginScreen
  });
}
