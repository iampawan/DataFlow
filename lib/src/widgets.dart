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

import 'package:dataflow/src/engine.dart';
import 'package:flutter/material.dart';

/// A widget that builds its descendants based on the state of a [DataStore].
///
/// Example:
/// ```dart
/// DataSync<MyStore>(
///   builder: (context, tank) {
///     //= Build UI based on tank and status
///   },
///   loadingBuilder: (context) {
///     return Center(child: CircularProgressIndicator());
///   },
///   errorBuilder: (context, error) {
///     return Center(child: Text('An error occurred: $error'));
///   },
///   useDefaultWidgets: true,
///   disableErrorBuilder: false,
///   disableLoadingBuilder: false,
/// )
/// ```
class DataSync<T extends DataStore> extends StatefulWidget {
  /// Creates a new [DataSync] instance.
  const DataSync({
    required this.builder,
    required this.actions,
    this.loadingBuilder,
    this.errorBuilder,
    this.actionNotifier,
    this.useDefaultWidgets = false,
    this.disableErrorBuilder = false,
    this.disableLoadingBuilder = false,
    super.key,
  });

  /// The builder for this widget.
  final Widget Function(
    BuildContext context,
    T store,
    // ignore: avoid_positional_boolean_parameters
    bool hasData,
  ) builder;

  /// A builder function that returns a widget to display
  /// when the state is loading.
  ///
  /// Example:
  /// ```dart
  /// loadingBuilder: (context) {
  ///   return Center(child: CircularProgressIndicator());
  /// },
  /// ```
  final Widget Function(BuildContext context)? loadingBuilder;

  /// A builder function that returns a widget to display when an error occurs.
  ///
  /// Example:
  /// ```dart
  /// errorBuilder: (context, error) {
  ///   return Center(child: Text('An error occurred: $error'));
  /// },
  /// ```
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// A map of [DataAction] actions to be notified.
  final Map<Type, ContextCallbackWithStatus>? actionNotifier;

  /// The actions to listen to.
  final Set<Type>? actions;

  /// Whether to use the default loading and error widgets.
  /// Defaults to false.
  /// If set to true, the default loading and error widgets will be used.
  final bool useDefaultWidgets;

  /// Whether to disable the error builder.
  final bool disableErrorBuilder;

  /// Whether to disable the loading builder.
  final bool disableLoadingBuilder;

  @override
  // ignore: library_private_types_in_public_api
  DataSyncState createState() => DataSyncState<T>();
}

class DataSyncState<T extends DataStore> extends State<DataSync<T>> {
  StreamSubscription<DataAction>? eventSubAct;
  StreamSubscription<DataAction>? eventSubNot;
  final Map<Type, DataActionStatus> allActionsStatus = {};

  /// Gets the status of the given action type.
  DataActionStatus getStatus(Type actionType) {
    return allActionsStatus[actionType] ?? DataActionStatus.idle;
  }

  /// If any actions is loading
  bool get isAnyActionLoading =>
      allActionsStatus.values.any((e) => e == DataActionStatus.loading);

  /// Which action is loading
  Type? get whichActionIsLoading {
    for (final entry in allActionsStatus.entries) {
      if (entry.value == DataActionStatus.loading) {
        return entry.key;
      }
    }
    return null;
  }

  /// if any action has an error
  bool get hasAnyActionError =>
      allActionsStatus.values.any((e) => e == DataActionStatus.error);

  /// Which action has an error
  Type? get whichActionHasError {
    for (final entry in allActionsStatus.entries) {
      if (entry.value == DataActionStatus.error) {
        return entry.key;
      }
    }
    return null;
  }

  /// if all actions are successful
  bool get areAllActionsSuccessful =>
      allActionsStatus.values.every((e) => e == DataActionStatus.success);

  @override
  void initState() {
    super.initState();
    if (widget.actions != null) {
      final actions = widget.actions!.toSet();
      final stream = DataFlow.events.where(
        (e) => actions.contains(e.runtimeType),
      );
      eventSubAct = stream.listen((e) {
        final status = e.status;
        allActionsStatus[e.runtimeType] = status;
      });
    }
    if (widget.actionNotifier != null) {
      final actions = widget.actionNotifier!.keys.toSet();
      final stream = DataFlow.events.where(
        (e) => actions.contains(e.runtimeType),
      );
      eventSubNot = stream.listen((e) {
        final status = e.status;
        widget.actionNotifier![e.runtimeType]?.call(context, e, status);
      });
    }
  }

  @override
  void dispose() {
    allActionsStatus.clear();
    eventSubAct?.cancel();
    eventSubNot?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = DataFlow.events.where(
      (e) => widget.actions!.contains(e.runtimeType),
    );
    return StreamBuilder<DataAction>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (isAnyActionLoading &&
              widget.useDefaultWidgets &&
              !widget.disableLoadingBuilder) {
            if (widget.loadingBuilder != null) {
              return widget.loadingBuilder!(context);
            }
            return Center(child: CircularProgressIndicator.adaptive());
          } else if (hasAnyActionError &&
              widget.useDefaultWidgets &&
              !widget.disableErrorBuilder) {
            if (widget.errorBuilder != null) {
              return widget.errorBuilder!(context, snapshot.data!.error);
            }
            return Center(child: Text(snapshot.data!.error));
          }

          final store = DataFlow.getStore() as T;
          return widget.builder(context, store, true);
        } else {
          return widget.builder(context, DataFlow.getStore() as T, false);
        }
      },
    );
  }
}

/// A function that is called when a [DataAction] action occurs.
typedef ContextCallbackWithStatus = void Function(
  BuildContext context,
  DataAction action,
  DataActionStatus status,
);

/// A widget that notifies listeners when specific [DataAction] actions occur.
///
/// Example:
/// ```dart
/// DataSyncNotifier(
///   actions: {
///     MyAction: (context, action, status) {
///       // Handle the action and status here
///     },
///   },
///   child: MyChildWidget(),
/// )
/// ```
class DataSyncNotifier extends StatefulWidget {
  /// Creates a new [DataSyncNotifier] instance.
  const DataSyncNotifier({required this.actions, super.key, this.child});

  /// The child widget.
  final Widget? child;

  /// The actions to listen to.
  final Map<Type, ContextCallbackWithStatus> actions;

  @override
  // ignore: library_private_types_in_public_api
  _DataSyncNotifierState createState() => _DataSyncNotifierState();
}

class _DataSyncNotifierState extends State<DataSyncNotifier> {
  StreamSubscription<dynamic>? eventSub;

  @override
  void initState() {
    super.initState();
    final actions = widget.actions.keys.toSet();
    final stream = DataFlow.events.where(
      (e) => actions.contains(e.runtimeType),
    );
    eventSub = stream.listen((e) {
      final status = e.status;
      widget.actions[e.runtimeType]?.call(context, e, status);
    });
  }

  @override
  void dispose() {
    eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox();
  }
}

extension DataFlowContextExtension on BuildContext {
  /// Gets the access to state class of DataSync.
  DataSyncState<T> dataSync<T extends DataStore>() {
    return findAncestorStateOfType<DataSyncState<T>>()!;
  }

  /// Gets the store of the current [DataFlow].
  T getStore<T extends DataStore>() {
    return DataFlow.getStore<T>();
  }
}
