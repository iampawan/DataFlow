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
        builder: (context, store, hasData) {
          if (hasData && store.todos.isNotEmpty) {
            return ListView.builder(
              itemCount: store.todos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(store.todos[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      RemoveTodoAction(index);
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: Text('No todos'));
        },
        actions: const {AddTodoAction, RemoveTodoAction},
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
                    todoController.clear();
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
