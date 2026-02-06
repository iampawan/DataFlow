/*
 * Copyright (c) 2024 Pawan Kumar. All rights reserved.
 *
 *  * Licensed under the Apache License, Version 2.0 (the "License");
 *  * you may not use this file except in compliance with the License.
 *  * You may obtain a copy of the License at
 *  * http://www.apache.org/licenses/LICENSE-2.0
 *  * Unless required by applicable law or agreed to in writing, software
 *  * distributed under the License is distributed on an "AS IS" BASIS,
 *  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  * See the License for the specific language governing permissions and
 *  * limitations under the License.
 */

import 'dart:async';
import 'dart:developer' as dev;

import 'package:rxdart/subjects.dart';

part 'action.dart';

/// An enum representing the status of a DataAction.
enum DataActionStatus {
  /// Represents the idle state.
  ///
  /// Example:
  /// ```
  /// DataActionStatus status = DataActionStatus.idle;
  /// ```
  idle,

  /// Represents the loading state.
  ///
  /// Example:
  /// ```
  /// DataActionStatus status = DataActionStatus.loading;
  /// ```
  loading,

  /// Represents the success state.
  ///
  /// Example:
  /// ```
  /// DataActionStatus status = DataActionStatus.success;
  /// ```
  success,

  /// Represents the error state.
  ///
  /// Example:
  /// ```
  /// DataActionStatus status = DataActionStatus.error;
  /// ```
  error,

  /// Represents the cancelled state.
  /// Added in v2.0 for action cancellation support.
  ///
  /// Example:
  /// ```
  /// DataActionStatus status = DataActionStatus.cancelled;
  /// ```
  cancelled,
}

/// An abstract class representing a DataStore.
abstract class DataStore {}

/// A class representing a DataFlow.
class DataFlow {
  DataFlow._();

  static BehaviorSubject<DataAction<DataStore>> _controller =
      BehaviorSubject<DataAction<DataStore>>();
  static final _middlewares = <DataMiddleware>[];

  /// The store/storage for this engine.
  static DataStore? _store;

  /// The events of this engine.
  static Stream<DataAction<DataStore>> get events => _controller.stream;

  /// Whether the DataFlow has been disposed.
  static bool get isDisposed => _controller.isClosed;

  /// Filters the main event stream with the action
  /// given as parameter. This can be used to perform some callbacks inside
  /// widgets after some action executed.
  static Stream<DataAction> streamOf(Type action) {
    return _controller.stream.where((e) => e.runtimeType == action);
  }

  /// Initializes the engine with the given store and middlewares.
  ///
  /// Note: Calling init multiple times will replace the store and
  /// add to existing middlewares. Use [reset] to fully reinitialize.
  static void init<T extends DataStore>(
    T store, {
    List<DataMiddleware>? middlewares,
  }) {
    _store = store;
    if (middlewares != null) {
      _middlewares.addAll(middlewares);
    }
  }

  /// Resets the DataFlow to its initial state.
  ///
  /// This clears the store, all middlewares, and creates a new controller.
  /// Use this when you need to fully reinitialize DataFlow (e.g., on logout).
  static void reset<T extends DataStore>(
    T store, {
    List<DataMiddleware>? middlewares,
  }) {
    // Close existing controller if not already closed
    if (!_controller.isClosed) {
      _controller.close();
    }
    // Create new controller
    _controller = BehaviorSubject<DataAction<DataStore>>();
    // Clear middlewares
    _middlewares.clear();
    // Initialize with new store
    _store = store;
    if (middlewares != null) {
      _middlewares.addAll(middlewares);
    }
  }

  /// Removes a specific middleware from this engine.
  static void removeMiddleware(DataMiddleware middleware) {
    _middlewares.remove(middleware);
  }

  /// Clears all middlewares from this engine.
  static void clearMiddlewares() {
    _middlewares.clear();
  }

  /// Gets the store of the given type.
  static T getStore<T extends DataStore>() {
    if (_store == null) {
      throw StateError(
        'DataFlow store not initialized. Call DataFlow.init() before using.',
      );
    }
    return _store! as T;
  }

  /// Adds a middleware to this engine.
  static void addMiddleware(DataMiddleware middleware) {
    _middlewares.add(middleware);
  }

  /// Notifies the engine of the given DataAction.
  static void notify(DataAction dataAction) {
    _controller.add(dataAction);
  }

  /// Disposes of this engine.
  static void dispose() {
    _controller.close();
  }
}
