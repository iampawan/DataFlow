import 'package:dataflow/dataflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DataFlow.init(MyStore());
  group('DataFlow', () {
    test('status is loading after execute is called', () async {
      final flow = FetchUsersAction();
      expect(flow.status, equals(DataActionStatus.loading));
    });

    test('status is success after execute completes', () async {
      final action = FetchUsersAction();
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Wait for execute to complete.
      expect(action.status, equals(DataActionStatus.success));
    });
  });

  group('DataFlow ', () {
    test('store is initially null', () {
      expect(DataFlow.getStore(), isA<MyStore>());
    });

    test('action is updated after a flow is executed', () async {
      FetchUsersAction();
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Wait for execute to complete.
      expect(DataFlow.getStore(), isNotNull);
      expect(DataFlow.getStore(), isA<MyStore>());
      expect((DataFlow.getStore() as MyStore).users, isNotEmpty);
    });
  });
}

class MyStore extends DataStore {
  int value = 0;
  List<User>? users;
}

class User {
  User({required this.name});

  final String name;
}

class FetchUsersAction extends DataAction<MyStore> {
  @override
  dynamic execute() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay.

    store.users = [
      User(name: 'Alice'),
      User(name: 'Bob'),
      User(name: 'Charlie'),
    ];
  }
}
