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
import 'package:flutter/material.dart';
import 'package:dataflow/src/engine.dart';
import 'package:dataflow/src/inspector/tracker.dart';
import 'package:dataflow/src/inspector/config.dart';

/// A floating panel that shows the action timeline.
class ActionTimeline extends StatefulWidget {
  final InspectorTheme theme;
  final VoidCallback? onClose;
  final Function(TrackedAction)? onActionTap;

  const ActionTimeline({
    super.key,
    this.theme = InspectorTheme.dark,
    this.onClose,
    this.onActionTap,
  });

  @override
  State<ActionTimeline> createState() => _ActionTimelineState();
}

class _ActionTimelineState extends State<ActionTimeline> {
  List<TrackedAction> _actions = [];
  StreamSubscription<TrackedAction>? _subscription;
  bool _isExpanded = true;
  String? _selectedActionType;

  @override
  void initState() {
    super.initState();
    _actions = InspectorTracker.instance.actionHistory.reversed.take(50).toList();
    _subscription = InspectorTracker.instance.actionStream.listen(_onAction);
  }

  void _onAction(TrackedAction action) {
    setState(() {
      // Check if this action already exists (by ID) - update it instead of adding
      final existingIndex = _actions.indexWhere((a) => a.id == action.id);
      if (existingIndex != -1) {
        // Update existing entry
        _actions[existingIndex] = action;
      } else {
        // Add new entry at the beginning
        _actions.insert(0, action);
        if (_actions.length > 50) {
          _actions.removeLast();
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 350,
          maxHeight: _isExpanded ? 400 : 50,
        ),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withOpacity(theme.panelOpacity),
          borderRadius: BorderRadius.circular(theme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme),
            // Content
            if (_isExpanded) ...[
              const Divider(height: 1),
              // Filter chips
              _buildFilterChips(theme),
              const Divider(height: 1),
              // Action list
              Expanded(child: _buildActionList(theme)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InspectorTheme theme) {
    final loadingCount =
        _actions.where((a) => a.status == DataActionStatus.loading).length;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(theme.borderRadius),
            bottom: _isExpanded ? Radius.zero : Radius.circular(theme.borderRadius),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timeline,
              color: theme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Actions',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_actions.length}',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (loadingCount > 0) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primaryColor,
                ),
              ),
            ],
            const Spacer(),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.secondaryTextColor,
            ),
            if (widget.onClose != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onClose,
                child: Icon(
                  Icons.close,
                  color: theme.secondaryTextColor,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(InspectorTheme theme) {
    final actionTypes = _actions.map((a) => a.actionType).toSet().toList();

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _selectedActionType == null,
            theme: theme,
            onTap: () => setState(() => _selectedActionType = null),
          ),
          ...actionTypes.map((type) => _FilterChip(
                label: _shortenActionName(type),
                isSelected: _selectedActionType == type,
                theme: theme,
                onTap: () => setState(() => _selectedActionType = type),
              )),
        ],
      ),
    );
  }

  Widget _buildActionList(InspectorTheme theme) {
    final filteredActions = _selectedActionType == null
        ? _actions
        : _actions.where((a) => a.actionType == _selectedActionType).toList();

    if (filteredActions.isEmpty) {
      return Center(
        child: Text(
          'No actions yet',
          style: TextStyle(color: theme.secondaryTextColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filteredActions.length,
      itemBuilder: (context, index) {
        final action = filteredActions[index];
        return _ActionTile(
          action: action,
          theme: theme,
          onTap: () => widget.onActionTap?.call(action),
        );
      },
    );
  }

  String _shortenActionName(String name) {
    // Remove 'Action' suffix if present
    if (name.endsWith('Action')) {
      name = name.substring(0, name.length - 6);
    }
    // Truncate if too long
    if (name.length > 12) {
      return '${name.substring(0, 10)}..';
    }
    return name;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final InspectorTheme theme;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.secondaryTextColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.secondaryTextColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final TrackedAction action;
  final InspectorTheme theme;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.action,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildStatusIcon(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shortenActionName(action.actionType),
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  if (action.error != null)
                    Text(
                      action.error.toString(),
                      style: TextStyle(
                        color: theme.errorColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(action.timestamp),
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
                if (action.duration != null)
                  Text(
                    _formatDuration(action.duration!),
                    style: TextStyle(
                      color: theme.secondaryTextColor,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (action.status) {
      case DataActionStatus.loading:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primaryColor,
          ),
        );
      case DataActionStatus.success:
        return Icon(
          Icons.check_circle,
          color: theme.successColor,
          size: 18,
        );
      case DataActionStatus.error:
        return Icon(
          Icons.error,
          color: theme.errorColor,
          size: 18,
        );
      case DataActionStatus.cancelled:
        return Icon(
          Icons.cancel,
          color: theme.warningColor,
          size: 18,
        );
      default:
        return Icon(
          Icons.circle_outlined,
          color: theme.secondaryTextColor,
          size: 18,
        );
    }
  }

  String _shortenActionName(String name) {
    if (name.endsWith('Action')) {
      return name.substring(0, name.length - 6);
    }
    return name;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
  }
}

/// A compact badge showing action count and status.
class ActionBadge extends StatefulWidget {
  final InspectorTheme theme;
  final VoidCallback? onTap;

  const ActionBadge({
    super.key,
    this.theme = InspectorTheme.dark,
    this.onTap,
  });

  @override
  State<ActionBadge> createState() => _ActionBadgeState();
}

class _ActionBadgeState extends State<ActionBadge> {
  int _count = 0;
  int _loadingCount = 0;
  int _errorCount = 0;
  StreamSubscription<TrackedAction>? _subscription;

  @override
  void initState() {
    super.initState();
    _updateCounts();
    _subscription = InspectorTracker.instance.actionStream.listen((_) {
      _updateCounts();
    });
  }

  void _updateCounts() {
    final actions = InspectorTracker.instance.actionHistory;
    setState(() {
      _count = actions.length;
      _loadingCount =
          actions.where((a) => a.status == DataActionStatus.loading).length;
      _errorCount =
          actions.where((a) => a.status == DataActionStatus.error).length;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withOpacity(theme.panelOpacity),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              color: theme.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              '$_count',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (_loadingCount > 0) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primaryColor,
                ),
              ),
            ],
            if (_errorCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.errorColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_errorCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
