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
/// ## Migration from v1.x:
/// - `actions` is now required and non-nullable
/// - `errorBuilder` now receives `Object` instead of `Exception`
/// - Stream is now cached (performance improvement)
///
/// Example:
/// ```dart
/// DataSync<MyStore>(
///   actions: {FetchDataAction}, // Required in v2.0
///   builder: (context, store, hasActionExecuted) {
///     // Build UI based on store
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
    required this.actions, // Now required in v2.0
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
  ///
  /// **v2.0 Change:** Now receives `Object` instead of `Exception` to handle all error types.
  ///
  /// Example:
  /// ```dart
  /// errorBuilder: (context, error) {
  ///   return Center(child: Text('An error occurred: $error'));
  /// },
  /// ```
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// A map of [DataAction] actions to be notified.
  final Map<Type, ContextCallbackWithStatus>? actionNotifier;

  /// The actions to listen to.
  /// **v2.0 Change:** Now required and non-nullable.
  final Set<Type> actions;

  /// Whether to disable the error builder.
  final bool disableErrorBuilder;

  /// Whether to disable the loading builder.
  final bool disableLoadingBuilder;

  @override
  // ignore: library_private_types_in_public_api
  DataSyncState createState() => DataSyncState<T>();
}

/// The state for [DataSync] widget.
///
/// Provides access to action statuses and errors through various getters and methods.
class DataSyncState<T extends DataStore> extends State<DataSync<T>> {
  StreamSubscription<DataAction>? _eventSubAct;
  StreamSubscription<DataAction>? _eventSubNot;
  Stream<DataAction>? _cachedStream;

  final Map<Type, DataActionStatus> allActionsStatus = {};
  final Map<Type, Object> _allActionsErrors = {};
  final Map<Type, StackTrace> _allActionsStackTraces = {};

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
  Object? get firstActionError {
    final errorType = whichActionHasError;
    return errorType != null ? _allActionsErrors[errorType] : null;
  }

  /// Gets the stack trace from the first failed action
  StackTrace? get firstActionStackTrace {
    final errorType = whichActionHasError;
    return errorType != null ? _allActionsStackTraces[errorType] : null;
  }

  /// if any action is successful
  bool get isAnyActionSuccessful =>
      allActionsStatus.values.any((e) => e == DataActionStatus.success);

  /// if all actions are successful
  ///
  /// **v2.0 Change:** Returns false if no actions have been tracked yet.
  /// Previously returned true for empty collection.
  bool get areAllActionsSuccessful =>
      allActionsStatus.isNotEmpty &&
      allActionsStatus.values.every((e) => e == DataActionStatus.success);

  /// if any action was cancelled
  bool get isAnyActionCancelled =>
      allActionsStatus.values.any((e) => e == DataActionStatus.cancelled);

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
    _allActionsStackTraces.remove(actionType);
  }

  /// Resets all action statuses to idle and clears all errors.
  void resetAllStatuses() {
    for (final key in allActionsStatus.keys) {
      allActionsStatus[key] = DataActionStatus.idle;
    }
    _allActionsErrors.clear();
    _allActionsStackTraces.clear();
  }

  /// Gets the error for a specific action type, if any.
  Object? getError(Type actionType) {
    return _allActionsErrors[actionType];
  }

  /// Gets the stack trace for a specific action type, if any.
  StackTrace? getStackTrace(Type actionType) {
    return _allActionsStackTraces[actionType];
  }

  void _setupSubscriptions() {
    final actions = widget.actions.toSet();
    _cachedStream = DataFlow.events.where(
      (e) => actions.contains(e.runtimeType),
    );
    _eventSubAct = _cachedStream!.listen(_handleActionEvent);

    if (widget.actionNotifier != null) {
      final notifierActions = widget.actionNotifier!.keys.toSet();
      final notifierStream = DataFlow.events.where(
        (e) => notifierActions.contains(e.runtimeType),
      );
      _eventSubNot = notifierStream.listen((e) {
        final status = e.status;
        widget.actionNotifier![e.runtimeType]?.call(context, e, status);
      });
    }
  }

  void _handleActionEvent(DataAction e) {
    final status = e.status;
    allActionsStatus[e.runtimeType] = status;
    // Store error when action fails, remove when it succeeds
    if (status == DataActionStatus.error && e.error != null) {
      _allActionsErrors[e.runtimeType] = e.error!;
      if (e.errorStackTrace != null) {
        _allActionsStackTraces[e.runtimeType] = e.errorStackTrace!;
      }
    } else if (status == DataActionStatus.success ||
        status == DataActionStatus.cancelled) {
      _allActionsErrors.remove(e.runtimeType);
      _allActionsStackTraces.remove(e.runtimeType);
    }
  }

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
  }

  @override
  void didUpdateWidget(covariant DataSync<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-subscribe to actions if they changed
    final actionsChanged = !_setsEqual(widget.actions, oldWidget.actions);
    if (actionsChanged) {
      _eventSubAct?.cancel();
      allActionsStatus.clear();
      _allActionsErrors.clear();
      _allActionsStackTraces.clear();

      final actions = widget.actions.toSet();
      _cachedStream = DataFlow.events.where(
        (e) => actions.contains(e.runtimeType),
      );
      _eventSubAct = _cachedStream!.listen(_handleActionEvent);
    }

    // Re-subscribe to actionNotifier if keys changed
    final notifierKeysChanged = !_setsEqual(
      widget.actionNotifier?.keys.toSet(),
      oldWidget.actionNotifier?.keys.toSet(),
    );
    if (notifierKeysChanged) {
      _eventSubNot?.cancel();
      if (widget.actionNotifier != null) {
        final actions = widget.actionNotifier!.keys.toSet();
        final stream = DataFlow.events.where(
          (e) => actions.contains(e.runtimeType),
        );
        _eventSubNot = stream.listen((e) {
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
    _allActionsStackTraces.clear();
    _eventSubAct?.cancel();
    _eventSubNot?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use cached stream instead of creating new one on every build
    return StreamBuilder<DataAction>(
      stream: _cachedStream,
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
