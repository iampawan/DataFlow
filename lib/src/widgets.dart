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
///   customLoadingBuilder: (context) {
///     return Center(child: CircularProgressIndicator());
///   },
///   customErrorBuilder: (context, error) {
///     return Center(child: Text('An error occurred: $error'));
///   },
///   enableDefaultWidgets: true,
///   disableDefaultErrorWidget: false,
///   disableDefaultLoadingWidget: false,
/// )
/// ```
class DataSync<T extends DataStore> extends StatefulWidget {
  /// Creates a new [DataSync] instance.
  const DataSync({
    required this.builder,
    required this.actions,
    this.customLoadingBuilder,
    this.customErrorBuilder,
    this.actionNotifier,
    this.enableDefaultWidgets = false,
    this.disableDefaultErrorWidget = false,
    this.disableDefaultLoadingWidget = false,
    super.key,
  })  : assert(
          !(customLoadingBuilder != null && !enableDefaultWidgets),
          'customLoadingBuilder cannot be used unless enableDefaultWidgets is set to true.',
        ),
        assert(
          !(customErrorBuilder != null && !enableDefaultWidgets),
          'customErrorBuilder cannot be used unless enableDefaultWidgets is set to true.',
        ),
        assert(
          !(disableDefaultErrorWidget && !enableDefaultWidgets),
          'disableDefaultErrorWidget cannot be used unless enableDefaultWidgets is set to true.',
        ),
        assert(
          !(disableDefaultLoadingWidget && !enableDefaultWidgets),
          'disableDefaultLoadingWidget cannot be used unless enableDefaultWidgets is set to true.',
        );

  /// The builder for this widget.
  final Widget Function(
    BuildContext context,
    T store,
    // ignore: avoid_positional_boolean_parameters
    bool hasActionExecuted,
  ) builder;

  /// A custom builder function for the loading state widget.
  /// If `enableDefaultWidgets` is true, this will override the default loading widget.
  ///
  /// Example:
  /// ```dart
  /// customLoadingBuilder: (context) {
  ///   return Center(child: CircularProgressIndicator());
  /// },
  /// ```
  final Widget Function(BuildContext context)? customLoadingBuilder;

  /// A custom builder function for the error state widget.
  /// If `enableDefaultWidgets` is true, this will override the default error widget.
  /// Example:
  /// ```dart
  /// customErrorBuilder: (context, error) {
  ///   return Center(child: Text('An error occurred: $error'));
  /// },
  /// ```
  final Widget Function(BuildContext context, String error)? customErrorBuilder;

  /// A map of [DataAction] actions to be notified.
  final Map<Type, ContextCallbackWithStatus>? actionNotifier;

  /// The actions to listen to.
  final Set<Type>? actions;

  /// Whether to enable default loading and error widgets.
  /// If true, default widgets will be used unless overridden by custom builders.
  /// Defaults to false.
  final bool enableDefaultWidgets;

  /// Whether to disable the default error widget.
  /// Only applicable if `enableDefaultWidgets` is true and no custom error builder is provided.
  final bool disableDefaultErrorWidget;

  /// Whether to disable the default loading widget.
  /// Only applicable if `enableDefaultWidgets` is true and no custom loading builder is provided.
  final bool disableDefaultLoadingWidget;

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
  bool get isAnyActionLoading => allActionsStatus.values.any((e) => e == DataActionStatus.loading);

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
  bool get hasAnyActionError => allActionsStatus.values.any((e) => e == DataActionStatus.error);

  /// Which action has an error
  Type? get whichActionHasError {
    for (final entry in allActionsStatus.entries) {
      if (entry.value == DataActionStatus.error) {
        return entry.key;
      }
    }
    return null;
  }

  // if any action is successful
  bool get isAnyActionSuccessful =>
      allActionsStatus.values.any((e) => e == DataActionStatus.success);

  /// if all actions are successful
  bool get areAllActionsSuccessful =>
      allActionsStatus.values.every((e) => e == DataActionStatus.success);

  /// which action is successful
  Type? get whichActionIsSuccessful {
    for (final entry in allActionsStatus.entries) {
      if (entry.value == DataActionStatus.success) {
        return entry.key;
      }
    }
    return null;
  }

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
              widget.enableDefaultWidgets &&
              !widget.disableDefaultLoadingWidget) {
            if (widget.customLoadingBuilder != null) {
              return widget.customLoadingBuilder!(context);
            }
            return Center(child: CircularProgressIndicator.adaptive());
          } else if (hasAnyActionError &&
              widget.enableDefaultWidgets &&
              !widget.disableDefaultErrorWidget) {
            if (widget.customErrorBuilder != null) {
              return widget.customErrorBuilder!(context, snapshot.data!.error);
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
