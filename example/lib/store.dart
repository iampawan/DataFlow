// app_store.dart
import 'package:dataflow/dataflow.dart';

class AppStore extends DataStore {
  bool isLoggedIn = false;
  List<String> todos = [];
}
