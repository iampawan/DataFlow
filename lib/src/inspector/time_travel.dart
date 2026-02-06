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

/// Time travel debugging panel.
class TimeTravelPanel extends StatefulWidget {
  final InspectorTheme theme;
  final VoidCallback? onClose;

  const TimeTravelPanel({
    super.key,
    this.theme = InspectorTheme.dark,
    this.onClose,
  });

  @override
  State<TimeTravelPanel> createState() => _TimeTravelPanelState();
}

class _TimeTravelPanelState extends State<TimeTravelPanel> {
  List<TrackedAction> _completedActions = [];
  int _selectedIndex = -1; // -1 means current state
  StreamSubscription<TrackedAction>? _subscription;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadActions();
    _subscription = InspectorTracker.instance.actionStream.listen((_) {
      _loadActions();
    });
  }

  void _loadActions() {
    setState(() {
      // Get only completed actions (with snapshots)
      _completedActions = InspectorTracker.instance.actionHistory
          .where((a) =>
              a.status != DataActionStatus.loading &&
              a.status != DataActionStatus.idle &&
              a.storeSnapshot != null)
          .toList();
      // Reset to current if selected index is out of bounds
      if (_selectedIndex >= _completedActions.length) {
        _selectedIndex = -1;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  TrackedAction? get _selectedAction {
    if (_selectedIndex < 0 || _selectedIndex >= _completedActions.length) {
      return null;
    }
    return _completedActions[_completedActions.length - 1 - _selectedIndex];
  }

  String get _currentStateLabel {
    if (_selectedIndex < 0) return 'Current State';
    final action = _selectedAction;
    if (action == null) return 'Current State';
    return 'After ${_shortenActionName(action.actionType)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 350,
          maxHeight: _isExpanded ? 450 : 50,
        ),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: theme.panelOpacity),
          borderRadius: BorderRadius.circular(theme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            if (_isExpanded) ...[
              const Divider(height: 1),
              _buildSlider(theme),
              const Divider(height: 1),
              Expanded(child: _buildStateView(theme)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InspectorTheme theme) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(theme.borderRadius),
            bottom:
                _isExpanded ? Radius.zero : Radius.circular(theme.borderRadius),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history,
              color: theme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Time Travel',
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
                color: theme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_completedActions.length}',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

  Widget _buildSlider(InspectorTheme theme) {
    if (_completedActions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No state snapshots yet. Execute some actions!',
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Time label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentStateLabel,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_selectedIndex >= 0)
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = -1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Go to Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Custom Slider (no Overlay required)
          Row(
            children: [
              Icon(Icons.first_page, color: theme.secondaryTextColor, size: 18),
              Expanded(
                child: _buildCustomSlider(theme),
              ),
              Icon(Icons.last_page, color: theme.primaryColor, size: 18),
            ],
          ),
          // Action markers
          _buildActionMarkers(theme),
        ],
      ),
    );
  }

  Widget _buildCustomSlider(InspectorTheme theme) {
    final totalSteps = _completedActions.length;
    final currentValue = _selectedIndex < 0
        ? totalSteps.toDouble()
        : (totalSteps - 1 - _selectedIndex).toDouble();
    final maxValue = totalSteps.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final progress = maxValue > 0 ? currentValue / maxValue : 0.0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (maxValue <= 0) return;
            final newProgress =
                (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
            final newValue = (newProgress * maxValue).roundToDouble();
            setState(() {
              if (newValue >= totalSteps) {
                _selectedIndex = -1;
              } else {
                _selectedIndex = totalSteps - 1 - newValue.toInt();
              }
            });
          },
          onTapDown: (details) {
            if (maxValue <= 0) return;
            final newProgress =
                (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
            final newValue = (newProgress * maxValue).roundToDouble();
            setState(() {
              if (newValue >= totalSteps) {
                _selectedIndex = -1;
              } else {
                _selectedIndex = totalSteps - 1 - newValue.toInt();
              }
            });
          },
          child: Container(
            height: 32,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Track background
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Active track
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: (trackWidth * progress) - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionMarkers(InspectorTheme theme) {
    if (_completedActions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _completedActions.length + 1, // +1 for current state
        itemBuilder: (context, index) {
          final isCurrentState = index == _completedActions.length;
          final isSelected = isCurrentState
              ? _selectedIndex < 0
              : index == (_completedActions.length - 1 - _selectedIndex);

          if (isCurrentState) {
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = -1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : theme.surfaceColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : theme.secondaryTextColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'NOW',
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.secondaryTextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          final action = _completedActions[index];
          return GestureDetector(
            onTap: () => setState(
                () => _selectedIndex = _completedActions.length - 1 - index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getStatusColor(action.status, theme)
                    : theme.surfaceColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? _getStatusColor(action.status, theme)
                      : theme.secondaryTextColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusDot(action.status, theme, isSelected),
                  const SizedBox(width: 4),
                  Text(
                    _shortenActionName(action.actionType),
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : theme.secondaryTextColor,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusDot(
      DataActionStatus status, InspectorTheme theme, bool isSelected) {
    final color = isSelected ? Colors.white : _getStatusColor(status, theme);
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor(DataActionStatus status, InspectorTheme theme) {
    switch (status) {
      case DataActionStatus.success:
        return theme.successColor;
      case DataActionStatus.error:
        return theme.errorColor;
      case DataActionStatus.cancelled:
        return theme.warningColor;
      default:
        return theme.secondaryTextColor;
    }
  }

  Widget _buildStateView(InspectorTheme theme) {
    String stateText;
    String label;

    if (_selectedIndex < 0 || _selectedAction == null) {
      // Show current state
      try {
        final store = DataFlow.getStore();
        stateText = store.toString();
        label = 'Current Store State';
      } catch (e) {
        stateText = 'Unable to get current state';
        label = 'Error';
      }
    } else {
      // Show historical state
      final action = _selectedAction!;
      stateText = action.storeSnapshot ?? 'No snapshot available';
      label =
          'State after ${_shortenActionName(action.actionType)} (${_formatTime(action.timestamp)})';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _selectedIndex < 0 ? Icons.play_arrow : Icons.history,
                color: theme.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: _selectedIndex >= 0
                  ? Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Text(
              stateText,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
          if (_selectedIndex >= 0 && _selectedAction != null) ...[
            const SizedBox(height: 12),
            _buildActionDetails(theme, _selectedAction!),
          ],
        ],
      ),
    );
  }

  Widget _buildActionDetails(InspectorTheme theme, TrackedAction action) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Details',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildDetailRow('Action', action.actionType, theme),
          _buildDetailRow('Status', action.status.name, theme,
              color: _getStatusColor(action.status, theme)),
          _buildDetailRow('Time', _formatTime(action.timestamp), theme),
          if (action.duration != null)
            _buildDetailRow(
                'Duration', '${action.duration!.inMilliseconds}ms', theme),
          if (action.error != null)
            _buildDetailRow('Error', action.error.toString(), theme,
                color: theme.errorColor),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, InspectorTheme theme,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? theme.textColor,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortenActionName(String name) {
    if (name.endsWith('Action')) {
      return name.substring(0, name.length - 6);
    }
    return name;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
