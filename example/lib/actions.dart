// add_todo_action.dart
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

  LoginAction(this.username, this.password);

  @override
  Future<void> execute() async {
    // Simulating login
    await Future.delayed(const Duration(seconds: 1));
    if (username == 'user' && password == 'password') {
      store.isLoggedIn = true;
    } else {
      throw Exception('Invalid credentials');
    }
  }
}
