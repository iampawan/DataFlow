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

part of 'engine.dart';

/// A function that returns a DataAction.
typedef DataActionBuilder = DataAction Function();

/// An abstract class representing a DataAction.
///
/// ## Migration from v1.x:
/// - `error` is now `Object?` instead of `Exception?` to catch all error types
/// - Loading state is now always emitted, even for synchronous actions
/// - Actions can be cancelled using [cancel]
abstract class DataAction<T extends DataStore> {
  /// Constructs a new instance of [DataAction].
  ///
  /// Sets the initial status to [DataActionStatus.idle] and starts the
  /// flow execution.
  DataAction() {
    _status = DataActionStatus.idle;
    _runFuture = _run();
  }

  /// The error associated with the DataAction.
  /// Changed from Exception? to Object? in v2.0 to catch all error types.
  Object? error;

  /// The stack trace associated with the error, if any.
  StackTrace? errorStackTrace;

  /// The DataStore associated with this DataAction.
  T get store => DataFlow.getStore<T>();

  /// The current status of the DataAction.
  DataActionStatus get status => _status;

  /// Whether this action has been cancelled.
  bool get isCancelled => _isCancelled;

  late DataActionStatus _status;
  bool _isCancelled = false;
  Future<void>? _runFuture;

  final List<DataActionBuilder> _postDataActions = [];

  Future<void> _run() async {
    for (final i in DataFlow._middlewares) {
      if (!i.preDataAction(this)) {
        return;
      }
    }

    // Always emit loading state first (even for sync actions)
    _setStatus(DataActionStatus.loading);

    try {
      if (_isCancelled) {
        _setStatus(DataActionStatus.cancelled);
        return;
      }

      dynamic result = execute();
      if (result is Future) {
        result = await result;
      }

      if (_isCancelled) {
        _setStatus(DataActionStatus.cancelled);
        return;
      }

      _setStatus(DataActionStatus.success);

      if (result != null && this is DataChain) {
        final dynamic out = (this as DataChain).fork(result);
        if (out is Future) {
          await out;
        }
        if (!_isCancelled) {
          _setStatus(DataActionStatus.success);
        }
      }

      // Only execute post actions if not cancelled
      if (!_isCancelled) {
        for (final dataAction in _postDataActions) {
          dataAction();
        }
      }
    } on Object catch (e, s) {
      // Catch Object to handle both Exception and Error types
      error = e;
      errorStackTrace = s;
      onException(e, s);
      _setStatus(DataActionStatus.error);
      // Clear post actions on error to prevent unexpected behavior
      _postDataActions.clear();
    }

    for (final i in DataFlow._middlewares) {
      i.postDataAction(this);
    }
  }

  /// Cancels this action if it's still running.
  ///
  /// Note: This sets a flag that will be checked at various points during
  /// execution. It does not forcibly stop an in-progress async operation.
  void cancel() {
    if (_status == DataActionStatus.loading) {
      _isCancelled = true;
      _setStatus(DataActionStatus.cancelled);
    }
  }

  /// Waits for this action to complete.
  ///
  /// Returns a Future that completes when the action finishes (success, error, or cancelled).
  Future<void> get future => _runFuture ?? Future.value();

  /// Moves to the next DataAction in the DataAction.
  ///
  /// The [DataActionBuilder] is a function that returns the next DataAction.
  void next(DataActionBuilder dataActionBuilder) {
    _postDataActions.add(dataActionBuilder);
  }

  /// Executes the DataAction.
  dynamic execute();

  /// Handles the exception that occurs during the execution of the DataAction.
  ///
  /// Override this method to customize error handling behavior.
  void onException(Object e, StackTrace s) {
    var isAssertOn = false;
    assert(isAssertOn = true);
    if (isAssertOn) {
      dev.log(
        e.toString(),
        name: '$runtimeType',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _setStatus(DataActionStatus status) {
    _status = status;
    DataFlow.notify(this);
  }
}

/// A mixin that allows a DataAction to fork into another DataAction.
mixin DataChain<T> {
  /// Forks the DataAction into another DataAction.
  dynamic fork(T result);
}

/// An abstract class representing a DataMiddleware.
abstract class DataMiddleware {
  /// A function that is called before the execution of a DataAction.
  bool preDataAction(DataAction dataAction);

  /// A function that is called after the execution of a DataAction.
  void postDataAction(DataAction dataAction);
}

/// An exception class for DataFlow-specific errors.
class DataFlowException implements Exception {
  DataFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Base interface for retryable actions (used for runtime type checking).
abstract class RetryableAction {
  /// Creates a new instance of this action with the same parameters for retry.
  DataAction retry();
}

/// A mixin that allows an action to be retried.
///
/// Implement this mixin in your action classes to enable retry functionality
/// in the DataFlow Inspector when an action fails.
///
/// Example:
/// ```dart
/// class LoadPostsAction extends DataAction<AppStore> with Retryable<AppStore> {
///   final bool refresh;
///   LoadPostsAction({this.refresh = false});
///
///   @override
///   DataAction<AppStore> retry() => LoadPostsAction(refresh: refresh);
///
///   @override
///   Future<void> execute() async { ... }
/// }
/// ```
mixin Retryable<T extends DataStore> on DataAction<T> implements RetryableAction {
  /// Creates a new instance of this action with the same parameters for retry.
  @override
  DataAction<T> retry();
}
