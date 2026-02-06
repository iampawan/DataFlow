import 'dart:async';

import 'package:dataflow/dataflow.dart';
import 'package:example/actions.dart';
import 'package:example/store.dart';
import 'package:flutter_test/flutter_test.dart';

// Test-specific actions for basic DataFlow testing
class TestStore extends DataStore {
  int count = 0;
}

class Increment extends DataAction<TestStore> {
  @override
  void execute() {
    store.count++;
  }
}

class IncrementLaterAction extends DataAction<TestStore> {
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

class AsyncIncrementAction extends DataAction<TestStore> {
  final Completer comp = Completer();

  @override
  void execute() async {
    await Future.delayed(const Duration(milliseconds: 10));
    store.count++;
    comp.complete();
  }
}

class ExceptionAction extends DataAction<TestStore> {
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
  group("Basic actions with TestStore", () {
    setUp(() {
      DataFlow.init(TestStore());
    });

    test('incrementing count', () {
      final store = DataFlow.getStore<TestStore>();
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
      final store = DataFlow.getStore<TestStore>();
      IncrementLaterAction();
      expect(store.count, 2);
    });

    test('async execution', () async {
      final store = DataFlow.getStore<TestStore>();

      final mut = AsyncIncrementAction();
      expect(store.count, 0);
      await mut.comp.future;
      expect(store.count, 1);
    });

    test('interceptor execution', () async {
      final actCount = ActionCounter();
      DataFlow.init(TestStore(), middlewares: [actCount]);
      expect(actCount.finished, 0);
      Increment();
      expect(actCount.finished, 1);
    });

    test('interceptor rejection', () async {
      final actReject = ActionRejector();
      final store = TestStore();
      DataFlow.init(store, middlewares: [actReject]);
      expect(actReject.rejected, 0);
      expect(store.count, 0);
      Increment();
      expect(actReject.rejected, 1);
      expect(store.count, 0);
    });
  });

  group('AppStore LoginAction', () {
    setUp(() {
      DataFlow.init(AppStore());
    });

    test('successful login sets currentUser', () async {
      final store = DataFlow.getStore<AppStore>();
      expect(store.currentUser, isNull);
      expect(store.isAuthenticating, false);

      LoginAction(email: 'test@example.com', password: 'password123');

      // Wait for async operation to complete
      await Future.delayed(const Duration(milliseconds: 2100));

      expect(store.currentUser, isNotNull);
      expect(store.currentUser!.email, 'test@example.com');
      expect(store.isAuthenticating, false);
    });

    test('login with empty email fails', () async {
      final store = DataFlow.getStore<AppStore>();

      LoginAction(email: '', password: 'password123');

      // Wait for async operation to complete
      await Future.delayed(const Duration(milliseconds: 2100));

      expect(store.currentUser, isNull);
      expect(store.authError, isNotNull);
      expect(store.authError, 'Email and password required');
    });

    test('login with short password fails', () async {
      final store = DataFlow.getStore<AppStore>();

      LoginAction(email: 'test@example.com', password: '123');

      // Wait for async operation to complete
      await Future.delayed(const Duration(milliseconds: 2100));

      expect(store.currentUser, isNull);
      expect(store.authError, 'Password must be at least 6 characters');
    });
  });

  group('AppStore LogoutAction', () {
    setUp(() async {
      DataFlow.init(AppStore());
      // First login
      LoginAction(email: 'test@example.com', password: 'password123');
      await Future.delayed(const Duration(milliseconds: 2100));
    });

    test('logout clears currentUser', () async {
      final store = DataFlow.getStore<AppStore>();
      expect(store.currentUser, isNotNull);

      LogoutAction();
      await Future.delayed(const Duration(milliseconds: 600));

      expect(store.currentUser, isNull);
      expect(store.posts, isEmpty);
      expect(store.notifications, isEmpty);
    });
  });

  group('AppStore ChangeTabAction', () {
    setUp(() {
      DataFlow.init(AppStore());
    });

    test('changes selected tab', () async {
      final store = DataFlow.getStore<AppStore>();
      expect(store.selectedTabIndex, 0);

      ChangeTabAction(index: 2);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(store.selectedTabIndex, 2);
    });
  });

  group('AppStore SearchPostsAction', () {
    setUp(() async {
      DataFlow.init(AppStore());
      // Load some posts first
      LoadPostsAction(refresh: true);
      await Future.delayed(const Duration(milliseconds: 1200));
    });

    test('searches posts by title', () async {
      final store = DataFlow.getStore<AppStore>();
      // Posts should be loaded
      expect(store.posts.isNotEmpty, true);

      SearchPostsAction(query: 'Flutter');
      await Future.delayed(const Duration(milliseconds: 600));

      expect(store.searchQuery, 'Flutter');
      // Some posts contain "Flutter" in title
      expect(store.searchResults, isNotEmpty);
    });

    test('empty query clears search results', () async {
      final store = DataFlow.getStore<AppStore>();

      SearchPostsAction(query: '');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(store.searchQuery, '');
      expect(store.searchResults, isEmpty);
      expect(store.isSearching, false);
    });
  });

  group('AppStore UpdateSettingsAction', () {
    setUp(() async {
      DataFlow.init(AppStore());
      // First login
      LoginAction(email: 'test@example.com', password: 'password123');
      await Future.delayed(const Duration(milliseconds: 2100));
    });

    test('updates dark mode setting', () async {
      final store = DataFlow.getStore<AppStore>();
      expect(store.currentUser!.settings.darkMode, false);

      UpdateSettingsAction(darkMode: true);
      await Future.delayed(const Duration(milliseconds: 400));

      expect(store.currentUser!.settings.darkMode, true);
    });

    test('updates notification setting', () async {
      final store = DataFlow.getStore<AppStore>();
      expect(store.currentUser!.settings.notifications, true);

      UpdateSettingsAction(notifications: false);
      await Future.delayed(const Duration(milliseconds: 400));

      expect(store.currentUser!.settings.notifications, false);
    });

    test('updates language setting', () async {
      final store = DataFlow.getStore<AppStore>();
      expect(store.currentUser!.settings.language, 'en');

      UpdateSettingsAction(language: 'es');
      await Future.delayed(const Duration(milliseconds: 400));

      expect(store.currentUser!.settings.language, 'es');
    });
  });
}
