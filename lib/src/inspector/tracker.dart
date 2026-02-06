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
import 'package:flutter/foundation.dart';
import 'package:dataflow/src/engine.dart';

/// Represents a tracked action with metadata.
class TrackedAction {
  final String actionType;
  final DataActionStatus status;
  final DateTime timestamp;
  final Duration? duration;
  final Object? error;
  final StackTrace? stackTrace;
  final String id;

  TrackedAction({
    required this.actionType,
    required this.status,
    required this.timestamp,
    this.duration,
    this.error,
    this.stackTrace,
    String? id,
  }) : id = id ?? '${timestamp.millisecondsSinceEpoch}_$actionType';

  TrackedAction copyWith({
    DataActionStatus? status,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return TrackedAction(
      actionType: actionType,
      status: status ?? this.status,
      timestamp: timestamp,
      duration: duration ?? this.duration,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      id: id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'error': error?.toString(),
    };
  }
}

/// Represents a tracked widget with rebuild statistics.
class TrackedWidget {
  final String widgetName;
  final String? key;
  final Set<Type> actions;
  int rebuildCount;
  DateTime lastRebuild;
  final DateTime firstSeen;
  final List<DateTime> _rebuildTimestamps;

  TrackedWidget({
    required this.widgetName,
    this.key,
    required this.actions,
    this.rebuildCount = 0,
    DateTime? lastRebuild,
    DateTime? firstSeen,
  })  : lastRebuild = lastRebuild ?? DateTime.now(),
        firstSeen = firstSeen ?? DateTime.now(),
        _rebuildTimestamps = [];

  void recordRebuild() {
    rebuildCount++;
    lastRebuild = DateTime.now();
    _rebuildTimestamps.add(lastRebuild);

    // Keep only last 100 timestamps for memory efficiency
    if (_rebuildTimestamps.length > 100) {
      _rebuildTimestamps.removeAt(0);
    }
  }

  /// Returns rebuilds in the last N seconds.
  int rebuildsInLast(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _rebuildTimestamps.where((t) => t.isAfter(cutoff)).length;
  }

  /// Returns the rebuild rate (rebuilds per second) in the last 10 seconds.
  double get rebuildRate {
    final count = rebuildsInLast(const Duration(seconds: 10));
    return count / 10.0;
  }
}

/// Singleton tracker for all DataFlow activity.
class InspectorTracker {
  InspectorTracker._();
  static final InspectorTracker instance = InspectorTracker._();

  final List<TrackedAction> _actionHistory = [];
  final Map<String, TrackedWidget> _widgets = {};
  final List<InspectorInsight> _insights = [];

  final _actionController = StreamController<TrackedAction>.broadcast();
  final _widgetController = StreamController<TrackedWidget>.broadcast();
  final _insightController = StreamController<InspectorInsight>.broadcast();

  int _maxHistory = 100;
  bool _isEnabled = false;

  /// Stream of tracked actions.
  Stream<TrackedAction> get actionStream => _actionController.stream;

  /// Stream of widget updates.
  Stream<TrackedWidget> get widgetStream => _widgetController.stream;

  /// Stream of insights.
  Stream<InspectorInsight> get insightStream => _insightController.stream;

  /// All tracked actions.
  List<TrackedAction> get actionHistory => List.unmodifiable(_actionHistory);

  /// All tracked widgets.
  Map<String, TrackedWidget> get widgets => Map.unmodifiable(_widgets);

  /// All insights.
  List<InspectorInsight> get insights => List.unmodifiable(_insights);

  /// Whether tracking is enabled.
  bool get isEnabled => _isEnabled;

  /// Initialize the tracker.
  void initialize({int maxHistory = 100}) {
    if (kReleaseMode) return; // Safety check

    _maxHistory = maxHistory;
    _isEnabled = true;
    _subscribeToDataFlow();
  }

  StreamSubscription<DataAction>? _subscription;

  void _subscribeToDataFlow() {
    _subscription?.cancel();
    _subscription = DataFlow.events.listen(_onAction);
  }

  void _onAction(DataAction action) {
    if (!_isEnabled) return;

    final actionType = action.runtimeType.toString();
    final now = DateTime.now();

    if (action.status == DataActionStatus.loading) {
      // Action started - add new entry
      final actionId = '${now.millisecondsSinceEpoch}_${action.hashCode}';

      final tracked = TrackedAction(
        actionType: actionType,
        status: action.status,
        timestamp: now,
        id: actionId,
      );
      _addAction(tracked);
    } else {
      // Action completed (success, error, or cancelled)
      // Find the LAST loading entry for this action type and update it
      final existingIndex = _actionHistory.lastIndexWhere(
        (a) => a.actionType == actionType && a.status == DataActionStatus.loading,
      );

      if (existingIndex != -1) {
        // Found a loading entry - update it
        final existing = _actionHistory[existingIndex];
        final duration = now.difference(existing.timestamp);

        final tracked = TrackedAction(
          actionType: actionType,
          status: action.status,
          timestamp: existing.timestamp,
          duration: duration,
          error: action.error,
          stackTrace: action.errorStackTrace,
          id: existing.id,
        );

        _actionHistory[existingIndex] = tracked;
        _actionController.add(tracked);

        // Generate insights
        _checkForInsights(tracked);
      } else {
        // No loading entry found - add as new entry
        final tracked = TrackedAction(
          actionType: actionType,
          status: action.status,
          timestamp: now,
          error: action.error,
          stackTrace: action.errorStackTrace,
        );
        _addAction(tracked);
        _checkForInsights(tracked);
      }
    }
  }

  void _addAction(TrackedAction action) {
    _actionHistory.add(action);

    // Enforce max history
    while (_actionHistory.length > _maxHistory) {
      _actionHistory.removeAt(0);
    }

    _actionController.add(action);
  }

  /// Register a widget for tracking.
  void registerWidget(String id, String widgetName, Set<Type> actions,
      {String? key}) {
    if (!_isEnabled) return;

    _widgets[id] = TrackedWidget(
      widgetName: widgetName,
      key: key,
      actions: actions,
    );
  }

  /// Unregister a widget.
  void unregisterWidget(String id) {
    _widgets.remove(id);
  }

  /// Adds an insight to history and emits it.
  void _addInsight(InspectorInsight insight) {
    _insights.add(insight);
    // Keep only last 50 insights
    while (_insights.length > 50) {
      _insights.removeAt(0);
    }
    _insightController.add(insight);
  }

  /// Record a widget rebuild.
  void recordRebuild(String id) {
    if (!_isEnabled) return;

    final widget = _widgets[id];
    if (widget != null) {
      widget.recordRebuild();
      _widgetController.add(widget);

      // Check for excessive rebuilds
      if (widget.rebuildsInLast(const Duration(seconds: 10)) > 10) {
        _addInsight(InspectorInsight(
          type: InsightType.warning,
          title: 'Excessive Rebuilds',
          message:
              '${widget.widgetName} rebuilt ${widget.rebuildsInLast(const Duration(seconds: 10))} times in 10s',
          widgetId: id,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  void _checkForInsights(TrackedAction action) {
    // Check for repeated failures
    final recentFailures = _actionHistory
        .where((a) =>
            a.actionType == action.actionType &&
            a.status == DataActionStatus.error &&
            a.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 1))))
        .length;

    if (recentFailures >= 3) {
      _addInsight(InspectorInsight(
        type: InsightType.error,
        title: 'Repeated Failures',
        message: '${action.actionType} failed $recentFailures times in 1 minute',
        actionType: action.actionType,
        timestamp: DateTime.now(),
      ));
    }

    // Check for slow actions
    if (action.duration != null && action.duration!.inSeconds > 5) {
      _addInsight(InspectorInsight(
        type: InsightType.warning,
        title: 'Slow Action',
        message:
            '${action.actionType} took ${action.duration!.inSeconds}s to complete',
        actionType: action.actionType,
        timestamp: DateTime.now(),
      ));
    }

    // Check for rapid-fire actions (same action called many times quickly)
    final recentCalls = _actionHistory
        .where((a) =>
            a.actionType == action.actionType &&
            a.status == DataActionStatus.loading &&
            a.timestamp.isAfter(DateTime.now().subtract(const Duration(seconds: 5))))
        .length;

    if (recentCalls >= 5) {
      _addInsight(InspectorInsight(
        type: InsightType.warning,
        title: 'Rapid Action Calls',
        message:
            '${action.actionType} called $recentCalls times in 5s. Consider debouncing.',
        actionType: action.actionType,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Get actions filtered by type.
  List<TrackedAction> getActionsOfType(String actionType) {
    return _actionHistory.where((a) => a.actionType == actionType).toList();
  }

  /// Get recent actions within a duration.
  List<TrackedAction> getRecentActions(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _actionHistory.where((a) => a.timestamp.isAfter(cutoff)).toList();
  }

  /// Get statistics for an action type.
  ActionStats getActionStats(String actionType) {
    final actions = getActionsOfType(actionType);
    if (actions.isEmpty) {
      return ActionStats(
        actionType: actionType,
        totalCalls: 0,
        successCount: 0,
        errorCount: 0,
        cancelledCount: 0,
        averageDuration: Duration.zero,
      );
    }

    final successCount =
        actions.where((a) => a.status == DataActionStatus.success).length;
    final errorCount =
        actions.where((a) => a.status == DataActionStatus.error).length;
    final cancelledCount =
        actions.where((a) => a.status == DataActionStatus.cancelled).length;

    final durations = actions
        .where((a) => a.duration != null)
        .map((a) => a.duration!.inMilliseconds)
        .toList();

    final avgDuration = durations.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds: durations.reduce((a, b) => a + b) ~/ durations.length);

    return ActionStats(
      actionType: actionType,
      totalCalls: actions.length, // Each entry now represents one action
      successCount: successCount,
      errorCount: errorCount,
      cancelledCount: cancelledCount,
      averageDuration: avgDuration,
    );
  }

  /// Clear all history.
  void clear() {
    _actionHistory.clear();
    _widgets.clear();
    _insights.clear();
  }

  /// Disable tracking.
  void disable() {
    _isEnabled = false;
    _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose of resources.
  void dispose() {
    disable();
    clear();
    _actionController.close();
    _widgetController.close();
    _insightController.close();
  }

  /// Export data for bug report.
  Map<String, dynamic> exportData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'actions': _actionHistory.map((a) => a.toJson()).toList(),
      'widgets': _widgets.map((k, v) => MapEntry(k, {
            'name': v.widgetName,
            'rebuildCount': v.rebuildCount,
            'actions': v.actions.map((a) => a.toString()).toList(),
          })),
      'insights': [], // Will be populated by insights stream
    };
  }
}

/// Statistics for an action type.
class ActionStats {
  final String actionType;
  final int totalCalls;
  final int successCount;
  final int errorCount;
  final int cancelledCount;
  final Duration averageDuration;

  ActionStats({
    required this.actionType,
    required this.totalCalls,
    required this.successCount,
    required this.errorCount,
    required this.cancelledCount,
    required this.averageDuration,
  });

  double get successRate =>
      totalCalls > 0 ? successCount / totalCalls * 100 : 0;
  double get errorRate => totalCalls > 0 ? errorCount / totalCalls * 100 : 0;
}

/// Represents an insight generated by the tracker.
class InspectorInsight {
  final InsightType type;
  final String title;
  final String message;
  final String? actionType;
  final String? widgetId;
  final DateTime timestamp;

  InspectorInsight({
    required this.type,
    required this.title,
    required this.message,
    this.actionType,
    this.widgetId,
    required this.timestamp,
  });
}

/// Type of insight.
enum InsightType {
  info,
  warning,
  error,
  success,
}
