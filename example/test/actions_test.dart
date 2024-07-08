import 'package:dataflow/dataflow.dart';
import 'package:example/actions.dart';
import 'package:example/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockAppStore extends Mock implements AppStore {}

void main() {
  group('AddTodoAction', () {
    setUp(() {
      DataFlow.init(AppStore());
    });

    test('adds todo to the list', () async {
      final action = AddTodoAction('Test Todo');
      await action.execute();
      expect(DataFlow.getStore<AppStore>().todos, contains('Test Todo'));
    });
  });

  group('LoginAction', () {
    setUp(() {
      DataFlow.init(AppStore());
    });

    test('successful login', () async {
      final action = LoginAction('user', 'password');
      await action.execute();
      expect(DataFlow.getStore<AppStore>().isLoggedIn, true);
    });

    test('failed login', () async {
      final action = LoginAction('wrong', 'wrong');
      expect(() async => await action.execute(), throwsException);
    });
  });
}
