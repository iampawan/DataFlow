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
  error
}

/// An abstract class representing a DataStore.
abstract class DataStore {
  final Map<Type, DataActionStatus> _actionStatuses = {};

  DataActionStatus getStatus(Type actionType) {
    return _actionStatuses[actionType] ?? DataActionStatus.idle;
  }

  void setStatus(Type actionType, DataActionStatus status) {
    _actionStatuses[actionType] = status;
  }
}

/// A class representing a DataFlow.
class DataFlow {
  DataFlow._();

  static final _controller = StreamController<DataAction<DataStore>>.broadcast(sync: true);
  static final _middlewares = <DataMiddleware>[];

  /// The store/storage for this engine.
  static DataStore? _store;

  /// The events of this engine.
  static Stream<DataAction<DataStore>> get events => _controller.stream;

  /// Filters the main event stream with the action
  /// given as parameter. This can be used to perform some callbacks inside
  /// widgets after some action executed.
  static Stream<DataAction> streamOf(Type action) {
    return _controller.stream.where((e) => e.runtimeType == action);
  }

  /// Initializes the engine with the given store and middlewares.
  static void init<T extends DataStore>(
    T store, {
    List<DataMiddleware>? middlewares,
  }) {
    _store = store;
    if (middlewares != null) {
      _middlewares.addAll(middlewares);
    }
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
