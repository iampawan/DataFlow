// app_store.dart
import 'package:dataflow/dataflow.dart';

class AppStore extends DataStore {
  int count = 0;
  bool isLoggedIn = false;
  List<String> todos = [];
}
