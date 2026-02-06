import 'package:dataflow/dataflow.dart';
import 'package:example/store.dart' as store_models;
import 'package:example/store.dart' show AppStore, User, UserSettings;
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginScreen shows login form', (WidgetTester tester) async {
    DataFlow.init(AppStore());

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Check login form elements exist
    expect(find.text('DataFlow Demo'), findsOneWidget);
    expect(find.text('Complex real-world example'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email and password fields
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('LoginScreen performs login', (WidgetTester tester) async {
    DataFlow.init(AppStore());

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Find and fill the text fields
    final emailField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).last;

    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'password123');

    // Tap login button
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Should show loading state
    final store = DataFlow.getStore<AppStore>();
    expect(store.isAuthenticating, true);

    // Wait for login to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // User should be logged in
    expect(store.currentUser, isNotNull);
  });

  testWidgets('AuthWrapper shows LoginScreen when not logged in', (WidgetTester tester) async {
    DataFlow.init(AppStore());

    await tester.pumpWidget(const MaterialApp(home: AuthWrapper()));

    // Should show login screen
    expect(find.text('DataFlow Demo'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('AuthWrapper shows HomeScreen when logged in', (WidgetTester tester) async {
    final store = AppStore();
    store.currentUser = User(
      id: 'test_user',
      name: 'Test User',
      email: 'test@example.com',
      settings: UserSettings(),
    );
    DataFlow.init(store);

    await tester.pumpWidget(const MaterialApp(home: AuthWrapper()));
    await tester.pumpAndSettle();

    // Should show home screen with navigation bar
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('HomeScreen tab navigation works', (WidgetTester tester) async {
    final store = AppStore();
    store.currentUser = User(
      id: 'test_user',
      name: 'Test User',
      email: 'test@example.com',
      settings: UserSettings(),
    );
    DataFlow.init(store);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Initially on Feed tab (index 0)
    expect(store.selectedTabIndex, 0);

    // Tap Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(store.selectedTabIndex, 3);
  });

  testWidgets('ProfileTab shows user info', (WidgetTester tester) async {
    final store = AppStore();
    store.currentUser = User(
      id: 'test_user',
      name: 'Test User',
      email: 'test@example.com',
      settings: UserSettings(darkMode: false, notifications: true, language: 'en'),
    );
    DataFlow.init(store);

    await tester.pumpWidget(const MaterialApp(home: ProfileTab()));
    await tester.pumpAndSettle();

    // Check user info is displayed
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('ProfileTab settings toggles work', (WidgetTester tester) async {
    final store = AppStore();
    store.currentUser = User(
      id: 'test_user',
      name: 'Test User',
      email: 'test@example.com',
      settings: UserSettings(darkMode: false, notifications: true, language: 'en'),
    );
    DataFlow.init(store);

    await tester.pumpWidget(const MaterialApp(home: ProfileTab()));
    await tester.pumpAndSettle();

    // Initially dark mode is off
    expect(store.currentUser!.settings.darkMode, false);

    // Find and tap the dark mode switch
    final darkModeSwitch = find.byType(Switch).first;
    await tester.tap(darkModeSwitch);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    // Dark mode should be on now
    expect(store.currentUser!.settings.darkMode, true);
  });

  testWidgets('SearchTab shows search field', (WidgetTester tester) async {
    DataFlow.init(AppStore());

    await tester.pumpWidget(const MaterialApp(home: SearchTab()));
    await tester.pumpAndSettle();

    // Check search field exists
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search for posts by title'), findsOneWidget);
  });

  testWidgets('FeedTab shows loading state initially', (WidgetTester tester) async {
    DataFlow.init(AppStore());

    await tester.pumpWidget(const MaterialApp(home: FeedTab()));
    await tester.pump();

    // Should show loading indicator when posts are being loaded
    expect(find.text('Feed'), findsOneWidget);
  });

  testWidgets('NotificationsTab shows empty state', (WidgetTester tester) async {
    DataFlow.init(AppStore());

    await tester.pumpWidget(const MaterialApp(home: NotificationsTab()));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No notifications'), findsOneWidget);
  });

  testWidgets('NotificationsTab shows notifications when loaded', (WidgetTester tester) async {
    final store = AppStore();
    store.notifications = [
      store_models.Notification(
        id: 'n1',
        title: 'Welcome!',
        message: 'Thanks for joining!',
        isRead: false,
        timestamp: DateTime.now(),
      ),
      store_models.Notification(
        id: 'n2',
        title: 'New activity',
        message: 'Someone liked your post',
        isRead: true,
        timestamp: DateTime.now(),
      ),
    ];
    store.unreadCount = 1;
    DataFlow.init(store);

    await tester.pumpWidget(const MaterialApp(home: NotificationsTab()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Thanks for joining!'), findsOneWidget);
    expect(find.text('New activity'), findsOneWidget);
  });
}
