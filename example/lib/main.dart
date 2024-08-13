// main.dart
import 'package:dataflow/dataflow.dart';
import 'package:example/store.dart';
import 'package:flutter/material.dart';

import 'login_widget.dart';
import 'todo_widget.dart';

void main() {
  final store = AppStore();
  DataFlow.init(store);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DataFlow.getStore<AppStore>();
    return MaterialApp(
      home: store.isLoggedIn ? TodoScreen() : LoginScreen(),
    );
  }
}
