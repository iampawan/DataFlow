// add_todo_action.dart
import 'dart:async';

import 'package:dataflow/dataflow.dart';
import 'package:example/store.dart';

class AddTodoAction extends DataAction<AppStore> {
  final String todo;

  AddTodoAction(this.todo);

  @override
  Future<void> execute() async {
    store.todos.add(todo);
  }
}

// login_action.dart
class LoginAction extends DataAction<AppStore> {
  final String username;
  final String password;
  final Completer comp = Completer();
  bool caught = false;

  LoginAction(this.username, this.password);

  @override
  Future<void> execute() async {
    // Simulating login
    await Future.delayed(const Duration(seconds: 1));
    if (username == 'user' && password == 'password') {
      store.isLoggedIn = true;
      comp.complete();
    } else {
      comp.complete();
      throw Exception('Invalid credentials');
    }
  }

  @override
  void onException(e, StackTrace s) {
    caught = true;
    super.onException(e, s);
  }
}
