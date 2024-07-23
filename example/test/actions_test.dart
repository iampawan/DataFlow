import 'dart:async';

import 'package:dataflow/dataflow.dart';
import 'package:example/actions.dart';
import 'package:example/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockAppStore extends Mock implements AppStore {}

class Increment extends DataAction<AppStore> {
  @override
  void execute() {
    store.count++;
  }
}

class IncrementLaterAction extends DataAction<AppStore> {
  @override
  void execute() {
    next(() => Increment());
    next(() => Increment());
  }
}

class ActionRejector extends DataMiddleware {
  int rejected = 0;

  @override
  bool preDataAction(DataAction action) {
    if (action is Increment) {
      rejected++;
      return false;
    }
    return true;
  }

  @override
  void postDataAction(DataAction action) {}
}

class ActionCounter extends DataMiddleware {
  int finished = 0;

  @override
  bool preDataAction(DataAction action) {
    return true;
  }

  @override
  void postDataAction(DataAction action) {
    finished++;
  }
}

class AsyncIncrementAction extends DataAction<AppStore> {
  final Completer comp = Completer();

  @override
  void execute() async {
    await Future.delayed(const Duration(milliseconds: 10));
    store.count++;
    comp.complete();
  }
}

class ExceptionAction extends DataAction<AppStore> {
  bool caught = false;

  @override
  void execute() {
    throw Exception();
  }

  @override
  void onException(dynamic e, StackTrace s) {
    caught = true;
  }
}

void main() {
  group("Basic actions", () {
    setUp(() {
      DataFlow.init(AppStore());
    });

    test('incrementing count', () {
      final store = DataFlow.getStore<AppStore>();
      expect(store.count, 0);
      Increment();
      expect(store.count, 1);
    });

    test('stream of events', () {
      final stream = DataFlow.events;
      expectLater(stream.first, completion(isA<Increment>()));
      Increment();
    });

    test('stream of actions events', () {
      final stream = DataFlow.streamOf(Increment);
      expectLater(stream.first, completion(isA<Increment>()));
      Increment();
    });

    test('exception catching', () {
      final em = ExceptionAction();
      expect(em.caught, true);
    });

    test('lazy execution', () async {
      final store = DataFlow.getStore<AppStore>();
      IncrementLaterAction();
      expect(store.count, 2);
    });

    test('async execution', () async {
      final store = DataFlow.getStore<AppStore>();

      final mut = AsyncIncrementAction();
      expect(store.count, 0);
      await mut.comp.future;
      expect(store.count, 1);
    });

    test('interceptor execution', () async {
      final actCount = ActionCounter();
      DataFlow.init(AppStore(), middlewares: [actCount]);
      expect(actCount.finished, 0);
      Increment();
      expect(actCount.finished, 1);
    });

    test('interceptor rejection', () async {
      final actReject = ActionRejector();
      final store = AppStore();
      DataFlow.init(store, middlewares: [actReject]);
      expect(actReject.rejected, 0);
      expect(store.count, 0);
      Increment();
      expect(actReject.rejected, 1);
      expect(store.count, 0);
    });
  });
  group('AddTodoAction', () {
    setUp(() {
      DataFlow.init(AppStore());
    });

    test('adds todo to the list', () {
      AddTodoAction('Test Todo');
      expect(DataFlow.getStore<AppStore>().todos, contains('Test Todo'));
    });
  });

  group('LoginAction', () {
    setUp(() {
      DataFlow.init(AppStore());
    });

    test('successful login', () async {
      final action = LoginAction('user', 'password');
      await action.comp.future;
      expect(DataFlow.getStore<AppStore>().isLoggedIn, true);
    });

    test('failed login', () async {
      final action = LoginAction('wrong', 'wrong');
      await action.comp.future;
      expectLater(action.caught, true);
    });
  });
}
