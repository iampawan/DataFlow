# DataFlow - Flutter State Management

This document provides context for LLMs (Claude Code, Cursor, Copilot, etc.) to help implement DataFlow in Flutter applications.

## Overview

DataFlow is a reactive state management library for Flutter that uses:
- **DataStore**: Central state container (like Redux store)
- **DataAction**: Executable actions that modify state (like Redux actions + reducers combined)
- **DataSync**: Widget that rebuilds when specific actions complete

## Installation

```yaml
dependencies:
  dataflow: ^2.0.0
```

## Core Concepts

### 1. DataStore - Your App State

Create a class extending `DataStore` to hold your application state:

```dart
import 'package:dataflow/dataflow.dart';

class AppStore extends DataStore {
  // Auth state
  User? currentUser;
  bool isLoading = false;
  String? error;

  // Feature state
  List<Post> posts = [];
  int selectedTab = 0;

  // Override toString() for debugging (shown in inspector)
  @override
  String toString() {
    return '''
AppStore {
  currentUser: ${currentUser?.name ?? 'null'},
  isLoading: $isLoading,
  posts: ${posts.length} items,
}''';
  }
}
```

### 2. DataAction - State Mutations

Actions are classes that extend `DataAction<YourStore>`. They:
- Execute automatically when instantiated (no dispatch needed)
- Have access to `store` via getter
- Can be sync or async
- Automatically track loading/success/error states

```dart
class LoginAction extends DataAction<AppStore> {
  final String email;
  final String password;

  LoginAction({required this.email, required this.password});

  @override
  Future<void> execute() async {
    // Access store via this.store
    store.isLoading = true;
    store.error = null;
    DataFlow.notify(this); // Notify UI of intermediate state change

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      store.currentUser = User(email: email, name: email.split('@').first);
      store.isLoading = false;
      // Success is automatic - no need to notify
    } catch (e) {
      store.error = e.toString();
      store.isLoading = false;
      rethrow; // Rethrow to mark action as failed
    }
  }
}
```

**Dispatching Actions** - Just instantiate them:

```dart
// DO THIS - Actions execute on instantiation
LoginAction(email: 'user@example.com', password: 'password');
LoadPostsAction(refresh: true);

// DON'T DO THIS - There is no dispatch method
// DataFlow.dispatch(LoginAction(...)); // WRONG!
```

### 3. DataSync - Reactive Widgets

`DataSync` rebuilds when specified actions complete:

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {LoginAction}, // Rebuild when LoginAction completes
      builder: (context, store, status) {
        // status contains action states: status[LoginAction]
        final loginStatus = status[LoginAction];

        if (store.currentUser != null) {
          return HomeScreen();
        }

        return Column(
          children: [
            if (store.isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () => LoginAction(
                  email: emailController.text,
                  password: passwordController.text,
                ),
                child: Text('Login'),
              ),
            if (store.error != null)
              Text(store.error!, style: TextStyle(color: Colors.red)),
          ],
        );
      },
    );
  }
}
```

### 4. Initialize DataFlow

In `main.dart`:

```dart
void main() {
  final store = AppStore();
  DataFlow.init(store);
  runApp(MyApp());
}
```

## Action Patterns

### Async Action with Loading State

```dart
class LoadPostsAction extends DataAction<AppStore> {
  final bool refresh;

  LoadPostsAction({this.refresh = false});

  @override
  Future<void> execute() async {
    if (refresh) {
      store.posts = [];
    }

    store.isLoadingPosts = true;
    DataFlow.notify(this); // Update UI immediately

    await Future.delayed(Duration(seconds: 1)); // API call

    store.posts = [...store.posts, ...newPosts];
    store.isLoadingPosts = false;
    // Auto-notifies on completion
  }
}
```

### Action with Error Handling

```dart
class FetchDataAction extends DataAction<AppStore> {
  @override
  Future<void> execute() async {
    try {
      final data = await api.fetchData();
      store.data = data;
    } catch (e) {
      store.error = e.toString();
      rethrow; // Mark action as error
    }
  }

  @override
  void onException(Object e, StackTrace s) {
    // Optional: Custom error handling
    print('FetchDataAction failed: $e');
  }
}
```

### Chained Actions

```dart
class InitAppAction extends DataAction<AppStore> {
  @override
  Future<void> execute() async {
    // These run after this action completes
    next(() => LoadUserAction());
    next(() => LoadSettingsAction());
  }
}
```

### Retryable Actions (for Inspector)

Add `Retryable` mixin to enable retry/replay in the inspector:

```dart
class LoadPostsAction extends DataAction<AppStore> with Retryable<AppStore> {
  final bool refresh;

  LoadPostsAction({this.refresh = false});

  @override
  DataAction<AppStore> retry() => LoadPostsAction(refresh: refresh);

  @override
  Future<void> execute() async {
    // ... implementation
  }
}
```

## DataSync Patterns

### Multiple Actions

```dart
DataSync<AppStore>(
  actions: const {LoadPostsAction, RefreshAction, DeletePostAction},
  builder: (context, store, status) {
    // Rebuilds when ANY of these actions complete
    return PostList(posts: store.posts);
  },
)
```

### Nested DataSync

```dart
// Parent listens to auth
DataSync<AppStore>(
  actions: const {LoginAction, LogoutAction},
  builder: (context, store, status) {
    if (store.currentUser == null) {
      return LoginScreen();
    }
    // Child listens to posts
    return DataSync<AppStore>(
      actions: const {LoadPostsAction},
      builder: (context, store, status) {
        return PostList(posts: store.posts);
      },
    );
  },
)
```

### Check Action Status

```dart
DataSync<AppStore>(
  actions: const {LoginAction},
  builder: (context, store, status) {
    final loginStatus = status[LoginAction];

    if (loginStatus == DataActionStatus.loading) {
      return CircularProgressIndicator();
    }
    if (loginStatus == DataActionStatus.error) {
      return Text('Login failed');
    }
    if (loginStatus == DataActionStatus.success) {
      return Text('Welcome!');
    }
    return LoginForm();
  },
)
```

## Inspector (Debug Mode)

Wrap your `MaterialApp` with `DataFlowInspector` for visual debugging:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DataFlowInspector(
      enabled: true, // Set to false in production
      child: MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}
```

**Inspector Features:**
- **Actions Panel**: See all dispatched actions with status (loading/success/error)
- **Time Travel**: Step through state snapshots after each action
- **Insights**: Warnings for slow actions, rapid-fire calls, repeated failures
- **Retry/Replay**: Re-run failed or successful actions (requires `Retryable` mixin)
- **Bug Report**: Capture screenshot + state + action history

## Listening to Action Streams

```dart
// Listen to all actions
DataFlow.events.listen((action) {
  print('Action: ${action.runtimeType}, Status: ${action.status}');
});

// Listen to specific action type
DataFlow.streamOf(LoginAction).listen((action) {
  if (action.status == DataActionStatus.success) {
    Navigator.pushReplacement(context, HomeRoute());
  }
});
```

## Middleware

```dart
class LoggingMiddleware extends DataMiddleware {
  @override
  bool preDataAction(DataAction action) {
    print('Starting: ${action.runtimeType}');
    return true; // Return false to cancel action
  }

  @override
  void postDataAction(DataAction action) {
    print('Finished: ${action.runtimeType} - ${action.status}');
  }
}

// Register middleware
DataFlow.init(AppStore(), middlewares: [LoggingMiddleware()]);
```

## Best Practices

### DO:
```dart
// ✅ Instantiate actions directly
LoginAction(email: email, password: password);

// ✅ Use DataFlow.notify() for intermediate updates
store.isLoading = true;
DataFlow.notify(this);

// ✅ Access store via this.store in actions
store.posts = newPosts;

// ✅ Rethrow exceptions to mark action as failed
catch (e) {
  store.error = e.toString();
  rethrow;
}

// ✅ Override toString() in your store for debugging
@override
String toString() => 'AppStore { ... }';
```

### DON'T:
```dart
// ❌ Don't try to dispatch - just instantiate
DataFlow.dispatch(LoginAction(...)); // WRONG - no dispatch method

// ❌ Don't pass store to execute()
Future<void> execute(AppStore store) // WRONG - use this.store

// ❌ Don't forget to notify for intermediate state changes
store.isLoading = true;
// Missing DataFlow.notify(this) - UI won't update until action completes

// ❌ Don't swallow exceptions silently
catch (e) {
  store.error = e.toString();
  // Missing rethrow - action will show as success
}
```

## Action Status Enum

```dart
enum DataActionStatus {
  idle,      // Not started
  loading,   // In progress
  success,   // Completed successfully
  error,     // Failed with exception
  cancelled, // Cancelled via action.cancel()
}
```

## Full Example

```dart
// store.dart
class AppStore extends DataStore {
  User? user;
  List<Todo> todos = [];
  bool isLoading = false;
  String? error;
}

// actions.dart
class LoadTodosAction extends DataAction<AppStore> with Retryable<AppStore> {
  @override
  DataAction<AppStore> retry() => LoadTodosAction();

  @override
  Future<void> execute() async {
    store.isLoading = true;
    store.error = null;
    DataFlow.notify(this);

    try {
      final todos = await TodoApi.fetchAll();
      store.todos = todos;
    } catch (e) {
      store.error = 'Failed to load todos';
      rethrow;
    } finally {
      store.isLoading = false;
    }
  }
}

class AddTodoAction extends DataAction<AppStore> {
  final String title;
  AddTodoAction(this.title);

  @override
  Future<void> execute() async {
    final todo = Todo(id: uuid(), title: title);
    store.todos = [...store.todos, todo];
    await TodoApi.create(todo);
  }
}

// main.dart
void main() {
  DataFlow.init(AppStore());
  runApp(
    DataFlowInspector(
      child: MaterialApp(home: TodoScreen()),
    ),
  );
}

// todo_screen.dart
class TodoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {LoadTodosAction, AddTodoAction},
      builder: (context, store, status) {
        return Scaffold(
          body: store.isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: store.todos.length,
                  itemBuilder: (_, i) => ListTile(title: Text(store.todos[i].title)),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => AddTodoAction('New Todo'),
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
```

## Summary

| Concept | Purpose | Usage |
|---------|---------|-------|
| `DataStore` | Hold app state | `class AppStore extends DataStore` |
| `DataAction<T>` | Modify state | `class MyAction extends DataAction<AppStore>` |
| `DataSync<T>` | Rebuild on action completion | `DataSync<AppStore>(actions: {MyAction}, builder: ...)` |
| `DataFlow.init()` | Initialize with store | `DataFlow.init(AppStore())` |
| `DataFlow.notify()` | Trigger UI update mid-action | `DataFlow.notify(this)` |
| `DataFlow.getStore<T>()` | Access store anywhere | `final store = DataFlow.getStore<AppStore>()` |
| `Retryable<T>` | Enable retry/replay in inspector | `with Retryable<AppStore>` |
| `DataFlowInspector` | Visual debugging | Wrap `MaterialApp` |
