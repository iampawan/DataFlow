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
/// loadingBuilder: (context) {
///   return Center(child: CircularProgressIndicator());
/// },
/// errorBuilder: (context, error) {
///   return Center(child: Text('An error occurred: $error'));
/// },
/// useDefaultWidgets: true,
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
    super.key,
  });

  /// The builder for this widget.
  final Widget Function(
    BuildContext context,
    T store,
    Map<Type, DataActionStatus> statuses,
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
  final Map<Type, ContextCallbackWithStatus<T>>? actionNotifier;

  /// The actions to listen to.
  final Set<Type>? actions;

  /// Whether to use the default loading and error widgets.
  /// Defaults to false.
  /// If set to true, the default loading and error widgets will be used.
  final bool useDefaultWidgets;

  @override
  // ignore: library_private_types_in_public_api
  _DataSyncState createState() => _DataSyncState<T>();
}

class _DataSyncState<T extends DataStore> extends State<DataSync<T>> {
  StreamSubscription<DataAction>? eventSub;
  final Map<Type, DataActionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    if (widget.actionNotifier != null) {
      final actions = widget.actionNotifier!.keys.toSet();
      final stream = DataFlow.events.where(
        (e) => actions.contains(e.runtimeType),
      );
      eventSub = stream.listen((e) {
        final status = e.status;
        widget.actionNotifier![e.runtimeType]?.call(context, e.store as T, status);
      });
    }
  }

  @override
  void dispose() {
    eventSub?.cancel();
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
          final action = snapshot.data as DataAction;
          _statuses[action.runtimeType] = action.status;

          if (_statuses.values.any((status) => status == DataActionStatus.loading)) {
            if (!widget.useDefaultWidgets && widget.loadingBuilder != null) {
              return widget.loadingBuilder!(context);
            }
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (_statuses.values.any((status) => status == DataActionStatus.error)) {
            final error = action.error ?? 'An error occurred';
            if (!widget.useDefaultWidgets && widget.errorBuilder != null) {
              return widget.errorBuilder!(context, error);
            }
            return Center(child: Text(error));
          }
        }

        final store = DataFlow.getStore() as T;
        return widget.builder(context, store, _statuses);
      },
    );
  }
}

/// A function that is called when a [DataAction] action occurs.
typedef ContextCallbackWithStatus<T> = void Function(
  BuildContext context,
  T store,
  DataActionStatus status,
);

/// A function that is called when a [DataAction] action occurs.
typedef ContextCallback = void Function(
  BuildContext context,
  DataAction action,
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
      widget.actions[e.runtimeType]?.call(context, e.store, status);
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
