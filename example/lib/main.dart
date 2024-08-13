// main.dart
import 'package:dataflow/dataflow.dart';
import 'package:example/store.dart';
import 'package:flutter/material.dart';

import 'actions.dart';
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Login and Todo App')),
        body: DataSync<AppStore>(
          useDefaultWidgets: true,
          actionNotifier: {
            LoginAction: (context, action, status) {
              if (status == DataActionStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(action.error),
                  ),
                );
              }
            },
          },
          builder: (context, store, hasData) {
            return store.isLoggedIn ? TodoScreen() : LoginScreen();
          },
          actions: const {LoginAction},
        ),
      ),
    );
  }
}
