// app_store.dart
import 'package:dataflow/dataflow.dart';

class AppStore extends DataStore {
  int count = 0;
  bool isLoggedIn = false;
  List<String> todos = [];

  /// Override toString for better debugging in DataFlow Inspector
  @override
  String toString() {
    return '''AppStore {
  count: $count,
  isLoggedIn: $isLoggedIn,
  todos: $todos
}''';
  }
}
