import 'package:dataflow/dataflow.dart';
import 'package:example/store.dart';
import 'package:flutter/material.dart';

import 'actions.dart';

class TodoScreen extends StatelessWidget {
  final todoController = TextEditingController();

  TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: DataSync<AppStore>(
        builder: (context, store, status) {
          return ListView.builder(
            itemCount: store.todos.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(store.todos[index]));
            },
          );
        },
        actions: const {AddTodoAction},
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Todo'),
              content: TextField(controller: todoController),
              actions: [
                TextButton(
                  onPressed: () {
                    AddTodoAction(todoController.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
