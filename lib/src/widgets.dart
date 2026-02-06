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
    this.disableErrorBuilder = false,
    this.disableLoadingBuilder = false,
    super.key,
  });

  /// The builder for this widget.
  final Widget Function(
    BuildContext context,
    T store,
    // ignore: avoid_positional_boolean_parameters
    bool hasActionExecuted,
  ) builder;

  /// A custom builder function for the loading state widget.
  ///
  /// Example:
  /// ```dart
  /// loadingBuilder: (context) {
  ///   return Center(child: CircularProgressIndicator());
  /// },
  /// ```
  final Widget Function(BuildContext context)? loadingBuilder;

  /// A custom builder function for the error state widget.
  /// Example:
  /// ```dart
  /// errorBuilder: (context, error) {
  ///   return Center(child: Text('An error occurred: $error'));
  /// },
  /// ```
  final Widget Function(BuildContext context, Exception error)? errorBuilder;

  /// A map of [DataAction] actions to be notified.
  final Map<Type, ContextCallbackWithStatus>? actionNotifier;

  /// The actions to listen to.
  final Set<Type>? actions;

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
  final Map<Type, Exception> _allActionsErrors = {};

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

  /// Gets the error from the first failed action
  Exception? get firstActionError {
    final errorType = whichActionHasError;
    return errorType != null ? _allActionsErrors[errorType] : null;
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

  /// Resets the status of a specific action type to idle.
  /// Also clears any stored error for that action.
  void resetStatus(Type actionType) {
    allActionsStatus[actionType] = DataActionStatus.idle;
    _allActionsErrors.remove(actionType);
  }

  /// Resets all action statuses to idle and clears all errors.
  void resetAllStatuses() {
    for (final key in allActionsStatus.keys) {
      allActionsStatus[key] = DataActionStatus.idle;
    }
    _allActionsErrors.clear();
  }

  /// Gets the error for a specific action type, if any.
  Exception? getError(Type actionType) {
    return _allActionsErrors[actionType];
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
        // Store error when action fails, remove when it succeeds
        if (status == DataActionStatus.error && e.error != null) {
          _allActionsErrors[e.runtimeType] = e.error!;
        } else if (status == DataActionStatus.success) {
          _allActionsErrors.remove(e.runtimeType);
        }
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
  void didUpdateWidget(covariant DataSync<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-subscribe to actions if they changed
    final actionsChanged = !_setsEqual(widget.actions, oldWidget.actions);
    if (actionsChanged) {
      eventSubAct?.cancel();
      allActionsStatus.clear();
      _allActionsErrors.clear();
      if (widget.actions != null) {
        final actions = widget.actions!.toSet();
        final stream = DataFlow.events.where(
          (e) => actions.contains(e.runtimeType),
        );
        eventSubAct = stream.listen((e) {
          final status = e.status;
          allActionsStatus[e.runtimeType] = status;
          if (status == DataActionStatus.error && e.error != null) {
            _allActionsErrors[e.runtimeType] = e.error!;
          } else if (status == DataActionStatus.success) {
            _allActionsErrors.remove(e.runtimeType);
          }
        });
      }
    }

    // Re-subscribe to actionNotifier if keys changed
    final notifierKeysChanged = !_setsEqual(
      widget.actionNotifier?.keys.toSet(),
      oldWidget.actionNotifier?.keys.toSet(),
    );
    if (notifierKeysChanged) {
      eventSubNot?.cancel();
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
  }

  /// Helper to compare two sets for equality.
  bool _setsEqual(Set<Type>? a, Set<Type>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  void dispose() {
    allActionsStatus.clear();
    _allActionsErrors.clear();
    eventSubAct?.cancel();
    eventSubNot?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions == null) {
      throw StateError(
        'DataSync.actions cannot be null. '
        'Provide a Set of action types to listen to.',
      );
    }
    final stream = DataFlow.events.where(
      (e) => widget.actions!.contains(e.runtimeType),
    );
    return StreamBuilder<DataAction>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (isAnyActionLoading && !widget.disableLoadingBuilder) {
            if (widget.loadingBuilder != null) {
              return widget.loadingBuilder!(context);
            }
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (hasAnyActionError && !widget.disableErrorBuilder) {
            final error = firstActionError;
            if (error != null) {
              if (widget.errorBuilder != null) {
                return widget.errorBuilder!(context, error);
              }
              return Center(child: Text(error.toString()));
            }
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
    _subscribeToActions();
  }

  void _subscribeToActions() {
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
  void didUpdateWidget(covariant DataSyncNotifier oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-subscribe if action keys changed
    final oldKeys = oldWidget.actions.keys.toSet();
    final newKeys = widget.actions.keys.toSet();
    if (!_setsEqual(oldKeys, newKeys)) {
      eventSub?.cancel();
      _subscribeToActions();
    }
  }

  bool _setsEqual(Set<Type> a, Set<Type> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
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
  /// Throws if no DataSync ancestor is found.
  DataSyncState<T> dataSync<T extends DataStore>() {
    final state = findAncestorStateOfType<DataSyncState<T>>();
    if (state == null) {
      throw StateError(
        'No DataSync<$T> ancestor found. '
        'Make sure this context is a descendant of DataSync<$T>.',
      );
    }
    return state;
  }

  /// Gets the access to state class of DataSync, or null if not found.
  /// Use this when you're not sure if a DataSync ancestor exists.
  DataSyncState<T>? tryDataSync<T extends DataStore>() {
    return findAncestorStateOfType<DataSyncState<T>>();
  }

  /// Gets the store of the current [DataFlow].
  T getStore<T extends DataStore>() {
    return DataFlow.getStore<T>();
  }
}
