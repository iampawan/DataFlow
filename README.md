# DataFlow

<img src="https://secure-res.craft.do/v2/2DrwLqJ8ZnZ7zSsdsGQj8CaxvYk4RDhgPT4ML2mxu3JuGB9CmQhuF3zu5bUTRk7y8TndwUeiFwK2L2FUZP32qaLSRq2mYQhfUCVa9ZyKyCJzgw66JvXrBjKc1hPeTcnKfkHt28Y2GJkqkHJkWZT4DXd8wWAzbFcfAcCgQfKMyp2YJ7K7zfTUTcgNS4nfuAwJNCqdU61qD8ByWHRr7KHLHDywFMAMRdML7gaRzaoW2V6Q5SZ5K">

### [Documentation](https://learn.codepur.dev/dataflow)

For detailed documentation, please visit [DataFlow Documentation](https://learn.codepur.dev/dataflow).

## Introduction

> DataFlow is a powerful and flexible state management library for Flutter applications. It provides a simple and intuitive way to manage the flow of data and handle asynchronous operations in your app. With DataFlow, you can easily define actions, track their status, and update your UI accordingly.

> DataFlow is designed to be lightweight, efficient, and easy to use. It leverages the power of Dart streams and follows a reactive programming paradigm to ensure smooth data flow and seamless UI updates.

## Key Features

- **DataStore**: Centralized state management for your application.
- **DataAction**: Define asynchronous operations as actions with customizable execution logic.
- **DataSync**: A widget that rebuilds its descendants based on the state of a DataStore.
- **DataSyncNotifier**: A widget that notifies listeners when specific DataActions occur.
- **Middleware**: Intercept and modify actions before and after execution.
- **DataChain**: You execute one action and based on its result you execute something else.

### Comparison Table

| **Feature/Library**              | **DataFlow**     | **Flutter Bloc**  | **Provider**                 | **Riverpod**                | **Signal**                 | **GetX**  |
| -------------------------------- | ---------------- | ----------------- | ---------------------------- | --------------------------- | -------------------------- | --------- |
| **Centralized State Management** | Yes              | Yes               | No                           | Yes                         | No                         | Yes       |
| **Asynchronous Operations**      | Yes (DataAction) | Yes (Bloc)        | No (requires FutureProvider) | Yes (StateNotifierProvider) | No                         | Yes       |
| **Reactive UI Updates**          | Yes (DataSync)   | Yes (BlocBuilder) | Yes (Consumer)               | Yes (ConsumerWidget)        | Yes (Reactive Programming) | Yes (Obx) |
| **Middleware Support**           | Yes              | Yes               | No                           | No                          | No                         | No        |
| **Ease of Use**                  | High             | Medium            | High                         | Medium                      | Medium                     | High      |
| **Learning Curve**               | Low              | High              | Low                          | Medium                      | Medium                     | Low       |
| **Boilerplate Code**             | Low              | High              | Low                          | Medium                      | Low                        | Low       |
| **Built for Flutter**            | Yes              | Yes               | Yes                          | Yes                         | Yes                        | Yes       |
| **Community Support**            | Growing          | High              | High                         | Growing                     | Growing                    | High      |
| **Performance**                  | High             | High              | High                         | High                        | High                       | \-        |

## Getting Started

To start using DataFlow in your Flutter project, follow these steps:

1. Add the `dataflow` package to your `pubspec.yaml` file:

```dart
dependencies:
  dataflow: ^1.4.0
```

2. Import the package in your Dart code:

```dart
import 'package:dataflow/dataflow.dart';
```

3. Initialize DataFlow with a DataStore:

```dart
void main() {
  DataFlow.init(MyDataStore());
  runApp(MyApp());
}
```

4. Define your DataActions:

```dart
class FetchDataAction extends DataAction<MyDataStore> {
  @override
   execute() async {
    // Your data fetching logic here
    await Future.delayed(Duration(seconds: 2));
    print('Fetched Data');
  }
}
```

5. Use DataSync in your widgets:

```dart
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DataFlow Example')),
      body: DataSync<MyDataStore>(
        actions: {FetchDataAction},
        loadingBuilder: (context) {
            return const Center(child: CircularProgressIndicator());
          },
        errorBuilder: (context, error) {
            return Center(child: Text('An error occurred: $error'));
          },
        builder: (context, store, hasData) {
          return LoginScreen();
        },
      ),
    );
  }
}
```

6. Trigger actions from your UI:

```dart
ElevatedButton(
  onPressed: () {
    FetchDataAction();
  },
  child: Text('Fetch Data'),
),
```

## DataAction

A DataAction represents an asynchronous operation in your application. It encapsulates the execution logic and provides a way to track the status of the action.

To define a DataAction, create a class that extends the `DataAction` class and implement the `execute` method:

```dart
class FetchDataAction extends DataAction {
  @override
  dynamic execute() async {
    // Your data fetching logic here
    await Future.delayed(Duration(seconds: 2));
    print('Fetched Data');
  }
}
```

The `execute` method contains the actual logic for the action. It can perform any asynchronous operation, such as making API calls, querying a database, or processing data.

You can trigger a DataAction by calling it directly like:

```dart
FetchDataAction();
```

DataActions can also be chained together using the `next` method:

```dart
FetchDataAction().next(() => ProcessDataAction());
```

## DataStore

A DataStore is a centralized repository for managing the state of your application. It extends the `DataStore` class and can hold any data relevant to your app.

To create a DataStore, define a class that extends `DataStore`:

```dart
class MyDataStore extends DataStore {
  // Your application state here
  String data = '';
}
```

You can access the DataStore from anywhere in your app using the `DataFlow.getStore` method:

```dart
final store = DataFlow.getStore<MyDataStore>();
or
final store = context.getStore<MyDataStore>();
```

## DataFlow

DataFlow is the core class that manages the flow of actions and notifies listeners of state changes. It is initialized with a DataStore and optional middleware.

To initialize DataFlow, call the `DataFlow.init` method with your DataStore:

```dart
void main() {
  DataFlow.init(MyDataStore());
  runApp(MyApp());
}
```

DataFlow provides a stream of actions through the `DataFlow.events` property. You can listen to this stream to react to action events:

```dart
DataFlow.events.listen((action) {
  // Handle action events here
});
```

## DataSync

DataSync is a widget that rebuilds its descendants based on the state of a DataStore. It listens to specific actions and updates the UI accordingly.

To use DataSync, wrap your widget tree with the `DataSync` widget and provide a builder function:

```dart
      DataSync<AppStore>(
          useDefaultWidgets: true,
          loadingBuilder: (context) {
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error) {
            return Center(child: Text('An error occurred: $error'));
          },
          builder: (context, store, hasData) {
            return store.isLoggedIn ? TodoScreen() : LoginScreen();
          },
          actions: const {LoginAction},
        );
```

The builder function receives the current context, the DataStore, and the status of the actions. You can use this information to build your UI based on the state of the actions or you can use _::useDefaultWidgets::_ property.

## DataSyncNotifier

DataSyncNotifier is a widget that notifies listeners when specific DataActions occur. It is useful for performing side effects or triggering additional actions based on the status of an action.

To use DataSyncNotifier, wrap your widget tree with the `DataSyncNotifier` widget and provide a map of actions and their corresponding listeners:

```dart
DataSyncNotifier(
  actions: {
    FetchDataAction: (context, store, status) {
      // Handle the action status here
      if (status == DataActionStatus.success) {
        // Perform additional actions or side effects
      }
    },
  },
  child: MyChildWidget(),
),
```

The listeners will be called whenever the specified actions occur, allowing you to react to action status changes.

## Middleware

Middleware allows you to intercept and modify actions before and after their execution. It provides a way to add custom logic, logging, or error handling to your actions.

To create a middleware, define a class that extends `DataMiddleware` and implement the `preDataAction` and `postDataAction` methods:

```dart
class LoggingMiddleware extends DataMiddleware {
  @override
  bool preDataAction(DataAction dataAction) {
    print('Starting action: ${dataAction.runtimeType}');
    return true;
  }

  @override
  void postDataAction(DataAction dataAction) {
    print('Finished action: ${dataAction.runtimeType} with status ${dataAction.status}');
  }
}
```

The `preDataAction` method is called before the action is executed, and the `postDataAction` method is called after the action is executed.

To add middleware to DataFlow, pass a list of middleware instances to the `DataFlow.init` method:

```dart
void main() {
  DataFlow.init(MyDataStore(), middlewares: [LoggingMiddleware()]);
  runApp(MyApp());
}
```

## Error Handling

DataFlow provides built-in error handling for actions. If an exception occurs during the execution of an action, the action's status will be set to `DataActionStatus.error`, and the error will be available through the `error` property.

You can handle errors in your UI by checking the action status and displaying appropriate error messages:

```dart
DataSync<MyDataStore>(
  actions: {FetchDataAction},
  builder: (context, store, hasData) {
    if (context.dataSync().hasAnyActionError) {
         return const Center(child: Text('An error occurred'));
      }
    // Rest of your UI
  },
),
```

You can also handle errors in middleware by implementing custom error handling logic in the `postDataAction` method:

```dart
class ErrorHandlingMiddleware extends DataMiddleware {
  @override
  void postDataAction(DataAction dataAction) {
    if (dataAction.status == DataActionStatus.error) {
      // Handle the error here
      print('Error: ${dataAction.error}');
    }
  }
}
```

## Best Practices

Here are some best practices to follow when using DataFlow:

- Keep your DataActions focused and single-purpose. Each action should represent a specific operation or task.
- Use meaningful names for your DataActions and DataStores to improve code readability.
- Leverage middleware for cross-cutting concerns like logging, error handling, or authentication.
- Use DataSync to rebuild your UI based on action status changes, and DataSyncNotifier for side effects and additional actions.
- Handle errors gracefully and provide meaningful error messages to the user.
- Avoid excessive nesting of actions using the `next` method. Keep the action flow simple and linear.

## License

## This project is licensed under the MIT License.

The above comparison table provides an overview of how DataFlow stacks up against other popular state management libraries for Flutter. For more detailed information and advanced usage, please refer to the official documentation.

## Conclusion

DataFlow provides a powerful and flexible way to manage the state and data flow in your Flutter applications. By defining actions, using a centralized store, and leveraging widgets like DataSync and DataSyncNotifier, you can create reactive and responsive UIs with ease.

This documentation covers the core concepts and usage of DataFlow. For more advanced scenarios and detailed API reference, please refer to the official documentation.

Happy coding with DataFlow!
