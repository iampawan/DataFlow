import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-end test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login
    await tester.enterText(find.byType(TextField).first, 'user');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify we're on the TodoScreen
    expect(find.text('Todo List'), findsOneWidget);

    // Add a new todo
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Integration Test Todo');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify the new todo is added
    expect(find.text('Integration Test Todo'), findsOneWidget);
  });
}
