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
abstract class DataAction<T extends DataStore> {
  /// Constructs a new instance of [DataAction].
  ///
  /// Sets the initial status to [DataActionStatus.idle] and starts the
  /// flow execution.
  DataAction() {
    _status = DataActionStatus.idle;
    _run();
  }

  /// The error message associated with the DataAction.
  String error = 'An error occurred';

  /// The DataStore associated with this DataAction.
  T get store => DataFlow.getStore<T>();

  /// The current status of the DataAction.
  DataActionStatus get status => _status;

  late DataActionStatus _status;

  final List<DataActionBuilder> _postDataActions = [];

  Future<void> _run() async {
    for (final i in DataFlow._middlewares) {
      if (!i.preDataAction(this)) {
        return;
      }
    }

    try {
      dynamic result = execute();
      if (result is Future) {
        _status = DataActionStatus.loading;
        await Future.delayed(Duration.zero);
        DataFlow.notify(this);
        result = await result;
      }

      if (result != null && this is DataChain) {
        final dynamic out = (this as DataChain).fork(result);
        if (out is Future) {
          await out;
        }
      }

      _setStatus(DataActionStatus.success);

      for (final dataAction in _postDataActions) {
        dataAction();
      }
    } on Exception catch (e, s) {
      error = '$e';
      onException(e, s);
      _setStatus(DataActionStatus.error);
    }

    for (final i in DataFlow._middlewares) {
      i.postDataAction(this);
    }
  }

  /// Moves to the next DataAction in the DataAction.
  ///
  /// The [DataActionBuilder] is a function that returns the next DataAction.
  void next(DataActionBuilder dataActionBuilder) {
    _postDataActions.add(dataActionBuilder);
  }

  /// Executes the DataAction.
  dynamic execute();

  /// Handles the exception that occurs during the execution of the DataAction.
  void onException(dynamic e, StackTrace s) {
    var isAssertOn = false;
    assert(isAssertOn = true);
    if (isAssertOn) {
      dev.log(
        '${e.toString()}',
        name: '$runtimeType',
      );
    }
  }

  void _setStatus(DataActionStatus status) {
    _status = status;
    DataFlow.getStore().setStatus(runtimeType, status);
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

class DataException implements Exception {
  DataException(this.message);

  final String message;

  @override
  String toString() => message;
}
