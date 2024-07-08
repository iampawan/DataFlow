import 'package:dataflow/dataflow.dart';
import 'package:example/login_widget.dart';
import 'package:example/store.dart';
import 'package:example/todo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginScreen widget test', (WidgetTester tester) async {
    DataFlow.init(AppStore());

    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    await tester.enterText(find.byType(TextField).first, 'user');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final store = DataFlow.getStore<AppStore>();
    // Verify the login action was triggered
    expect(store.isLoggedIn, isTrue);
  });

  testWidgets('TodoScreen widget test', (WidgetTester tester) async {
    final store = AppStore();
    store.todos.add('Existing Todo');
    DataFlow.init(store);

    await tester.pumpWidget(MaterialApp(home: TodoScreen()));

    expect(find.text('Existing Todo'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New Todo');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New Todo'), findsOneWidget);
  });
}
