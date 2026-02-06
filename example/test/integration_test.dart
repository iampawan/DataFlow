import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-end login flow test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify we're on the login screen
    expect(find.text('DataFlow Demo'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Login with default credentials (pre-filled)
    await tester.tap(find.text('Login'));
    await tester.pump(); // Start the action

    // Should show loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for login to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify we're on the home screen with navigation bar
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Tab navigation test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login first
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Initially on Feed tab
    expect(find.text('Feed'), findsWidgets);

    // Navigate to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify profile elements are visible
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    // Navigate to Search tab
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    // Verify search elements
    expect(find.text('Search for posts by title'), findsOneWidget);

    // Navigate to Alerts tab
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();

    // Verify notifications tab
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('Logout flow test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login first
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Navigate to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Tap logout
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Should be back at login screen
    expect(find.text('DataFlow Demo'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
