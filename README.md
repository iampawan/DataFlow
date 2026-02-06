# DataFlow

<img src="https://secure-res.craft.do/v2/2DrwLqJ8ZnZ7zSsdsGQj8CaxvYk4RDhgPT4ML2mxu3JuGB9CmQhuF3zu5bUTRk7y8TndwUeiFwK2L2FUZP32qaLSRq2mYQhfUCVa9ZyKyCJzgw66JvXrBjKc1hPeTcnKfkHt28Y2GJkqkHJkWZT4DXd8wWAzbFcfAcCgQfKMyp2YJ7K7zfTUTcgNS4nfuAwJNCqdU61qD8ByWHRr7KHLHDywFMAMRdML7gaRzaoW2V6Q5SZ5K">

[![Pub Version](https://img.shields.io/pub/v/dataflow)](https://pub.dev/packages/dataflow)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

> A reactive state management library for Flutter with a simple and intuitive API which allows you to build Flutter applications with ease.

### [Documentation](https://learn.codepur.dev/dataflow)

---

## Table of Contents

- [Why DataFlow?](#why-dataflow)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
  - [DataStore](#datastore)
  - [DataAction](#dataaction)
  - [DataSync](#datasync)
  - [DataSyncNotifier](#datasyncnotifier)
  - [DataSyncState](#datasyncstate)
- [Step-by-Step Guides](#step-by-step-guides)
  - [Building a Todo App](#building-a-todo-app)
  - [Authentication Flow](#authentication-flow)
  - [Pagination Example](#pagination-example)
- [Advanced Features](#advanced-features)
  - [Middleware](#middleware)
  - [Action Chaining](#action-chaining)
  - [Action Cancellation](#action-cancellation)
  - [DataFlow Reset](#dataflow-reset)
- [Comparison with Other Libraries](#comparison-with-other-libraries)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Migration Guide](#migration-guide)
- [FAQ](#faq)
- [License](#license)

---

## Why DataFlow?

DataFlow was designed with these principles in mind:

| Principle | Description |
|-----------|-------------|
| **Minimal Boilerplate** | No code generation, no complex setup. Just extend a class and go. |
| **Action-Centric** | Every async operation is an Action with built-in status tracking. |
| **Reactive by Default** | UI automatically updates when actions complete. |
| **Error Handling Built-in** | Actions catch errors automatically with stack traces. |
| **Flexible** | Works for simple apps and scales to complex ones. |

---

## Quick Start

### Step 1: Add Dependency

```yaml
dependencies:
  dataflow: ^2.0.0-beta.1
```

### Step 2: Create Your Store

```dart
import 'package:dataflow/dataflow.dart';

class AppStore extends DataStore {
  List<String> todos = [];
  bool isLoggedIn = false;
  String? username;
}
```

### Step 3: Create Your First Action

```dart
class AddTodoAction extends DataAction<AppStore> {
  final String todo;

  AddTodoAction(this.todo);

  @override
  dynamic execute() {
    store.todos.add(todo);
  }
}
```

### Step 4: Initialize and Use

```dart
void main() {
  DataFlow.init(AppStore());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DataSync<AppStore>(
        actions: const {AddTodoAction},
        builder: (context, store, hasData) {
          return TodoListScreen(todos: store.todos);
        },
      ),
    );
  }
}

// Trigger the action from anywhere
ElevatedButton(
  onPressed: () => AddTodoAction('Buy groceries'),
  child: Text('Add Todo'),
)
```

That's it! The UI automatically updates when the action completes.

---

## Core Concepts

### DataStore

The **DataStore** is your single source of truth. It holds all application state.

```dart
class AppStore extends DataStore {
  // User state
  User? currentUser;
  bool isLoggedIn = false;

  // Todo state
  List<Todo> todos = [];
  bool isLoadingTodos = false;

  // App state
  ThemeMode themeMode = ThemeMode.system;
  String? errorMessage;
}
```

**Accessing the store:**

```dart
// From anywhere in your code
final store = DataFlow.getStore<AppStore>();

// From a BuildContext (extension method)
final store = context.getStore<AppStore>();

// From inside a DataAction
@override
dynamic execute() {
  store.currentUser = user; // 'store' is available automatically
}
```

---

### DataAction

A **DataAction** represents an operation that can be sync or async. It has automatic status tracking: `idle` → `loading` → `success` or `error` or `cancelled`.

#### Basic Action

```dart
class FetchTodosAction extends DataAction<AppStore> {
  @override
  dynamic execute() async {
    final response = await api.getTodos();
    store.todos = response.data;
  }
}

// Trigger it
FetchTodosAction();
```

#### Action with Parameters

```dart
class LoginAction extends DataAction<AppStore> {
  final String email;
  final String password;

  LoginAction(this.email, this.password);

  @override
  dynamic execute() async {
    final user = await authService.login(email, password);
    store.currentUser = user;
    store.isLoggedIn = true;
  }
}

// Trigger with parameters
LoginAction('user@example.com', 'password123');
```

#### Action Status

Every action tracks its status automatically:

```dart
enum DataActionStatus {
  idle,       // Initial state
  loading,    // Execute is running
  success,    // Execute completed without error
  error,      // Execute threw an error
  cancelled,  // Action was cancelled (v2.0+)
}
```

#### Error Handling

Errors are caught automatically:

```dart
class FetchDataAction extends DataAction<AppStore> {
  @override
  dynamic execute() async {
    final data = await api.getData(); // May throw
    store.data = data;
  }

  // Optional: Custom error handling
  @override
  void onException(Object error, StackTrace stackTrace) {
    super.onException(error, stackTrace); // Logs in debug mode
    analytics.logError(error, stackTrace);
  }
}
```

After an error, access it via:
- `action.error` - The error object
- `action.errorStackTrace` - The stack trace (v2.0+)

#### Awaiting Actions (v2.0+)

```dart
// Wait for action to complete
await LoginAction(email, password).future;

// Now check the result
if (store.isLoggedIn) {
  navigateToHome();
}
```

---

### DataSync

**DataSync** is a widget that rebuilds when specified actions emit events.

#### Basic Usage

```dart
DataSync<AppStore>(
  actions: const {FetchTodosAction},
  builder: (context, store, hasActionExecuted) {
    return ListView.builder(
      itemCount: store.todos.length,
      itemBuilder: (context, index) => TodoTile(store.todos[index]),
    );
  },
)
```

#### With Loading and Error Builders

```dart
DataSync<AppStore>(
  actions: const {FetchTodosAction},
  loadingBuilder: (context) {
    return Center(child: CircularProgressIndicator());
  },
  errorBuilder: (context, error) {
    return Center(
      child: Column(
        children: [
          Text('Error: $error'),
          ElevatedButton(
            onPressed: () => FetchTodosAction(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  },
  builder: (context, store, hasData) {
    return TodoList(todos: store.todos);
  },
)
```

#### Handling Multiple Actions

```dart
DataSync<AppStore>(
  actions: const {FetchUsersAction, FetchPostsAction},
  disableLoadingBuilder: true, // Handle loading manually
  disableErrorBuilder: true,   // Handle errors manually
  builder: (context, store, hasData) {
    final state = context.dataSync<AppStore>();

    // Check specific action status
    if (state.getStatus(FetchUsersAction) == DataActionStatus.loading) {
      return Text('Loading users...');
    }

    // Check for specific errors
    final usersError = state.getError(FetchUsersAction);
    if (usersError != null) {
      return Text('Failed to load users: $usersError');
    }

    return YourWidget();
  },
)
```

#### Action Notifier (Side Effects)

Use `actionNotifier` for navigation, snackbars, or other side effects:

```dart
DataSync<AppStore>(
  actions: const {LoginAction},
  actionNotifier: {
    LoginAction: (context, action, status) {
      if (status == DataActionStatus.success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (status == DataActionStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${action.error}')),
        );
      }
    },
  },
  builder: (context, store, hasData) => LoginForm(),
)
```

---

### DataSyncNotifier

**DataSyncNotifier** is for side effects only - it doesn't rebuild UI.

```dart
DataSyncNotifier(
  actions: {
    LogoutAction: (context, action, status) {
      if (status == DataActionStatus.success) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    },
    PaymentAction: (context, action, status) {
      if (status == DataActionStatus.success) {
        showDialog(
          context: context,
          builder: (_) => PaymentSuccessDialog(),
        );
      }
    },
  },
  child: MyApp(),
)
```

---

### DataSyncState

Access **DataSyncState** for fine-grained control over action statuses.

```dart
// Get the state (throws if not found)
final state = context.dataSync<AppStore>();

// Safe version (returns null if not found)
final state = context.tryDataSync<AppStore>();

// Available methods and properties:
state.getStatus(ActionType)           // Get status of specific action
state.isAnyActionLoading              // Any action loading?
state.whichActionIsLoading            // Which action is loading?
state.hasAnyActionError               // Any action failed?
state.whichActionHasError             // Which action failed?
state.firstActionError                // Get first error
state.firstActionStackTrace           // Get first stack trace (v2.0+)
state.isAnyActionSuccessful           // Any action succeeded?
state.areAllActionsSuccessful         // All actions succeeded?
state.isAnyActionCancelled            // Any action cancelled? (v2.0+)
state.getError(ActionType)            // Get error for specific action
state.getStackTrace(ActionType)       // Get stack trace (v2.0+)
state.resetStatus(ActionType)         // Reset specific action to idle
state.resetAllStatuses()              // Reset all actions to idle
```

---

## Step-by-Step Guides

### Building a Todo App

**1. Define the Store**

```dart
class TodoStore extends DataStore {
  List<Todo> todos = [];
}

class Todo {
  final String id;
  final String title;
  bool isCompleted;

  Todo({required this.id, required this.title, this.isCompleted = false});
}
```

**2. Create Actions**

```dart
class FetchTodosAction extends DataAction<TodoStore> {
  @override
  dynamic execute() async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    store.todos = [
      Todo(id: '1', title: 'Learn DataFlow'),
      Todo(id: '2', title: 'Build an app'),
    ];
  }
}

class AddTodoAction extends DataAction<TodoStore> {
  final String title;
  AddTodoAction(this.title);

  @override
  dynamic execute() {
    store.todos.add(Todo(
      id: DateTime.now().toString(),
      title: title,
    ));
  }
}

class ToggleTodoAction extends DataAction<TodoStore> {
  final String id;
  ToggleTodoAction(this.id);

  @override
  dynamic execute() {
    final todo = store.todos.firstWhere((t) => t.id == id);
    todo.isCompleted = !todo.isCompleted;
  }
}

class DeleteTodoAction extends DataAction<TodoStore> {
  final String id;
  DeleteTodoAction(this.id);

  @override
  dynamic execute() {
    store.todos.removeWhere((t) => t.id == id);
  }
}
```

**3. Build the UI**

```dart
class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Todo App')),
      body: DataSync<TodoStore>(
        actions: const {
          FetchTodosAction,
          AddTodoAction,
          ToggleTodoAction,
          DeleteTodoAction,
        },
        loadingBuilder: (_) => Center(child: CircularProgressIndicator()),
        builder: (context, store, hasData) {
          if (!hasData) {
            // First build - trigger fetch
            FetchTodosAction();
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: store.todos.length,
            itemBuilder: (context, index) {
              final todo = store.todos[index];
              return ListTile(
                leading: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => ToggleTodoAction(todo.id),
                ),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => DeleteTodoAction(todo.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Todo'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AddTodoAction(controller.text);
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
```

---

### Authentication Flow

**1. Store**

```dart
class AuthStore extends DataStore {
  User? currentUser;
  String? authToken;
  bool get isLoggedIn => currentUser != null;
}
```

**2. Actions**

```dart
class LoginAction extends DataAction<AuthStore> {
  final String email;
  final String password;

  LoginAction(this.email, this.password);

  @override
  dynamic execute() async {
    final response = await authApi.login(email, password);
    store.authToken = response.token;
    store.currentUser = response.user;
  }
}

class LogoutAction extends DataAction<AuthStore> {
  @override
  dynamic execute() async {
    await authApi.logout();
    store.authToken = null;
    store.currentUser = null;
  }
}

class CheckAuthAction extends DataAction<AuthStore> {
  @override
  dynamic execute() async {
    final token = await secureStorage.read('token');
    if (token != null) {
      store.authToken = token;
      store.currentUser = await authApi.getProfile(token);
    }
  }
}
```

**3. Auth-Aware App**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DataSync<AuthStore>(
        actions: const {CheckAuthAction, LoginAction, LogoutAction},
        builder: (context, store, hasData) {
          if (!hasData) {
            CheckAuthAction();
            return SplashScreen();
          }
          return store.isLoggedIn ? HomeScreen() : LoginScreen();
        },
        actionNotifier: {
          LoginAction: (context, action, status) {
            if (status == DataActionStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login failed: ${action.error}')),
              );
            }
          },
        },
      ),
    );
  }
}
```

---

### Pagination Example

```dart
class PostStore extends DataStore {
  List<Post> posts = [];
  int currentPage = 0;
  bool hasMore = true;
  bool isLoadingMore = false;
}

class FetchPostsAction extends DataAction<PostStore> {
  final bool refresh;

  FetchPostsAction({this.refresh = false});

  @override
  dynamic execute() async {
    if (refresh) {
      store.currentPage = 0;
      store.posts.clear();
    }

    store.isLoadingMore = true;

    final response = await api.getPosts(page: store.currentPage);
    store.posts.addAll(response.posts);
    store.hasMore = response.hasMore;
    store.currentPage++;
    store.isLoadingMore = false;
  }
}

// In your widget
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 200) {
      final store = context.getStore<PostStore>();
      if (store.hasMore && !store.isLoadingMore) {
        FetchPostsAction();
      }
    }
    return false;
  },
  child: ListView.builder(
    itemCount: store.posts.length + (store.hasMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index == store.posts.length) {
        return Center(child: CircularProgressIndicator());
      }
      return PostCard(store.posts[index]);
    },
  ),
)
```

---

## Advanced Features

### Middleware

Middleware intercepts actions before and after execution.

```dart
class LoggingMiddleware extends DataMiddleware {
  @override
  bool preDataAction(DataAction action) {
    print('▶ Starting: ${action.runtimeType}');
    return true; // Return false to cancel the action
  }

  @override
  void postDataAction(DataAction action) {
    print('✓ Finished: ${action.runtimeType} - ${action.status}');
    if (action.status == DataActionStatus.error) {
      print('  Error: ${action.error}');
    }
  }
}

class AnalyticsMiddleware extends DataMiddleware {
  @override
  bool preDataAction(DataAction action) {
    analytics.trackEvent('action_started', {'action': action.runtimeType.toString()});
    return true;
  }

  @override
  void postDataAction(DataAction action) {
    analytics.trackEvent('action_completed', {
      'action': action.runtimeType.toString(),
      'status': action.status.toString(),
    });
  }
}

// Register middlewares
void main() {
  DataFlow.init(
    AppStore(),
    middlewares: [LoggingMiddleware(), AnalyticsMiddleware()],
  );
  runApp(MyApp());
}

// Dynamic middleware management (v2.0+)
DataFlow.addMiddleware(DebugMiddleware());
DataFlow.removeMiddleware(debugMiddleware);
DataFlow.clearMiddlewares();
```

---

### Action Chaining

Execute actions in sequence:

```dart
class FetchUserAction extends DataAction<AppStore> {
  @override
  dynamic execute() async {
    store.user = await api.getUser();

    // Chain next action
    next(() => FetchUserPostsAction(store.user!.id));
  }
}
```

Or use `DataChain` for cleaner chaining:

```dart
class FetchAndProcessAction extends DataAction<AppStore> with DataChain<User> {
  @override
  dynamic execute() async {
    return await api.getUser(); // Return result for fork
  }

  @override
  dynamic fork(User user) async {
    // Called after execute succeeds with the returned value
    store.userPosts = await api.getUserPosts(user.id);
  }
}
```

---

### Action Cancellation (v2.0+)

Cancel running actions:

```dart
class SearchAction extends DataAction<AppStore> {
  final String query;
  static SearchAction? _current;

  SearchAction(this.query) {
    // Cancel previous search
    _current?.cancel();
    _current = this;
  }

  @override
  dynamic execute() async {
    await Future.delayed(Duration(milliseconds: 300)); // Debounce

    if (isCancelled) return; // Check before expensive operation

    store.searchResults = await api.search(query);
  }
}
```

Check cancellation status:

```dart
final state = context.dataSync<AppStore>();
if (state.isAnyActionCancelled) {
  // Handle cancelled state
}
```

---

### DataFlow Reset (v2.0+)

Fully reinitialize DataFlow (useful for logout):

```dart
void logout() async {
  await LogoutAction().future;

  // Reset everything with a fresh store
  DataFlow.reset(
    AppStore(), // New empty store
    middlewares: [LoggingMiddleware()], // Re-add middlewares if needed
  );

  Navigator.pushReplacementNamed(context, '/login');
}

// Check if DataFlow was disposed
if (DataFlow.isDisposed) {
  DataFlow.reset(AppStore());
}
```

---

## Comparison with Other Libraries

| Feature | DataFlow | Bloc | Provider | Riverpod | GetX |
|---------|----------|------|----------|----------|------|
| **Learning Curve** | Low | High | Low | Medium | Low |
| **Boilerplate** | Minimal | High | Minimal | Medium | Minimal |
| **Code Generation** | None | Optional | None | None | None |
| **Async Built-in** | Yes (DataAction) | Yes (Events) | No | Yes | Yes |
| **Status Tracking** | Automatic | Manual | Manual | Manual | Manual |
| **Error Handling** | Automatic | Manual | Manual | Manual | Manual |
| **Middleware** | Yes | Yes | No | No | No |
| **Action Chaining** | Yes | No | No | No | No |
| **Cancellation** | Yes (v2.0+) | Yes | No | Yes | No |
| **DevTools** | Planned | Yes | Yes | Yes | No |

### When to Use DataFlow

**Choose DataFlow if you want:**
- Minimal setup with no code generation
- Automatic async status tracking
- Built-in error handling with stack traces
- Simple action-based architecture
- Easy middleware integration

**Consider alternatives if you need:**
- Extensive DevTools support (use Bloc)
- Dependency injection built-in (use Riverpod)
- Maximum flexibility (use Provider)
- All-in-one solution (use GetX)

---

## API Reference

### DataFlow (Static Class)

| Method | Description |
|--------|-------------|
| `init<T>(store, {middlewares})` | Initialize with store and optional middlewares |
| `reset<T>(store, {middlewares})` | Fully reinitialize (clears everything) |
| `getStore<T>()` | Get the current store |
| `events` | Stream of all actions |
| `streamOf(Type)` | Stream filtered to specific action type |
| `notify(action)` | Manually emit an action |
| `addMiddleware(middleware)` | Add a middleware |
| `removeMiddleware(middleware)` | Remove a specific middleware |
| `clearMiddlewares()` | Remove all middlewares |
| `dispose()` | Close the event stream |
| `isDisposed` | Check if disposed |

### DataAction

| Property/Method | Description |
|-----------------|-------------|
| `store` | Access the typed DataStore |
| `status` | Current DataActionStatus |
| `error` | Error if status is error |
| `errorStackTrace` | Stack trace if status is error (v2.0+) |
| `isCancelled` | Whether action was cancelled (v2.0+) |
| `future` | Future that completes when action finishes (v2.0+) |
| `execute()` | Override to define action logic |
| `onException(e, s)` | Override to handle errors |
| `next(builder)` | Chain another action |
| `cancel()` | Cancel the action (v2.0+) |

### DataSync Widget

| Property | Description |
|----------|-------------|
| `actions` | Set of action types to listen to (required) |
| `builder` | Widget builder with (context, store, hasActionExecuted) |
| `loadingBuilder` | Widget shown during loading |
| `errorBuilder` | Widget shown on error with (context, error) |
| `actionNotifier` | Map of action types to callbacks for side effects |
| `disableLoadingBuilder` | Don't show loading widget automatically |
| `disableErrorBuilder` | Don't show error widget automatically |

### DataSyncState

| Property/Method | Description |
|-----------------|-------------|
| `allActionsStatus` | Map of all tracked action statuses |
| `getStatus(Type)` | Get status of specific action |
| `isAnyActionLoading` | Any action currently loading |
| `whichActionIsLoading` | Type of loading action |
| `hasAnyActionError` | Any action has error |
| `whichActionHasError` | Type of errored action |
| `firstActionError` | First error encountered |
| `firstActionStackTrace` | Stack trace of first error (v2.0+) |
| `isAnyActionSuccessful` | Any action succeeded |
| `areAllActionsSuccessful` | All actions succeeded |
| `isAnyActionCancelled` | Any action cancelled (v2.0+) |
| `getError(Type)` | Get error for specific action |
| `getStackTrace(Type)` | Get stack trace for specific action (v2.0+) |
| `resetStatus(Type)` | Reset specific action to idle |
| `resetAllStatuses()` | Reset all actions to idle |

### Context Extensions

| Method | Description |
|--------|-------------|
| `context.getStore<T>()` | Get the typed store |
| `context.dataSync<T>()` | Get DataSyncState (throws if not found) |
| `context.tryDataSync<T>()` | Get DataSyncState or null |

---

## Best Practices

### 1. Keep Actions Focused

```dart
// Good: Single responsibility
class FetchUserAction extends DataAction<AppStore> { ... }
class UpdateUserAction extends DataAction<AppStore> { ... }

// Avoid: Multiple responsibilities
class UserAction extends DataAction<AppStore> {
  final String operation; // 'fetch', 'update', 'delete'
  ...
}
```

### 2. Use Meaningful Names

```dart
// Good
class FetchUserProfileAction extends DataAction { ... }
class SubmitContactFormAction extends DataAction { ... }

// Avoid
class Action1 extends DataAction { ... }
class DoStuffAction extends DataAction { ... }
```

### 3. Handle Errors Gracefully

```dart
DataSync<AppStore>(
  actions: const {FetchDataAction},
  errorBuilder: (context, error) {
    return ErrorWidget(
      message: _getErrorMessage(error),
      onRetry: () {
        context.dataSync<AppStore>().resetStatus(FetchDataAction);
        FetchDataAction();
      },
    );
  },
  builder: (context, store, hasData) => ...,
)
```

### 4. Use ActionNotifier for Navigation

```dart
// Good: Side effects in actionNotifier
DataSync<AppStore>(
  actionNotifier: {
    LoginAction: (context, action, status) {
      if (status == DataActionStatus.success) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    },
  },
  builder: (context, store, hasData) => LoginForm(),
)

// Avoid: Navigation in builder
builder: (context, store, hasData) {
  if (store.isLoggedIn) {
    Navigator.pushReplacementNamed(context, '/home'); // Causes issues
  }
  return LoginForm();
}
```

### 5. Reset on Logout

```dart
void logout() async {
  await LogoutAction().future;
  DataFlow.reset(AppStore()); // Fresh start
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## Migration Guide

See [MIGRATION.md](MIGRATION.md) for detailed v1.x to v2.0 migration instructions.

### Quick Migration Checklist

- [ ] Update `actions` parameter (now required, non-nullable)
- [ ] Update `errorBuilder` signature (`Object` instead of `Exception`)
- [ ] Check `areAllActionsSuccessful` behavior (now false for empty)
- [ ] Consider using new features: `cancel()`, `future`, `getStackTrace()`

---

## FAQ

**Q: Do I need code generation?**
A: No, DataFlow works without any code generation.

**Q: Can I use multiple stores?**
A: Currently DataFlow supports a single store. Use composition within your store for complex state.

**Q: How do I test actions?**
A: Actions are plain classes - test `execute()` directly or use `DataFlow.init()` in test setup.

**Q: Is DataFlow production-ready?**
A: v2.0 is in beta. v1.x is stable and used in production apps.

**Q: How do I debug actions?**
A: Use `LoggingMiddleware` to trace all actions and their statuses.

---

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

---

Happy coding with DataFlow!
