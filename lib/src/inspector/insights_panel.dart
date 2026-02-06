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
import 'package:dataflow/src/inspector/tracker.dart';
import 'package:dataflow/src/inspector/config.dart';

/// Panel that displays smart insights about app behavior.
class InsightsPanel extends StatefulWidget {
  final InspectorTheme theme;
  final VoidCallback? onClose;

  const InsightsPanel({
    super.key,
    this.theme = InspectorTheme.dark,
    this.onClose,
  });

  @override
  State<InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends State<InsightsPanel> {
  final List<InspectorInsight> _insights = [];
  StreamSubscription<InspectorInsight>? _subscription;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // Load existing insights
    _insights.addAll(InspectorTracker.instance.insights.reversed);
    _subscription = InspectorTracker.instance.insightStream.listen(_onInsight);
  }

  void _onInsight(InspectorInsight insight) {
    setState(() {
      _insights.insert(0, insight);
      // Keep only last 20 insights
      if (_insights.length > 20) {
        _insights.removeLast();
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
          maxWidth: 320,
          maxHeight: _isExpanded ? 350 : 50,
        ),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha:theme.panelOpacity),
          borderRadius: BorderRadius.circular(theme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.3),
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
              Expanded(child: _buildInsightsList(theme)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InspectorTheme theme) {
    final errorCount = _insights.where((i) => i.type == InsightType.error).length;
    final warningCount = _insights.where((i) => i.type == InsightType.warning).length;

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
              Icons.lightbulb_outline,
              color: theme.warningColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Insights',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            if (errorCount > 0) ...[
              _buildCountBadge(errorCount, theme.errorColor),
              const SizedBox(width: 4),
            ],
            if (warningCount > 0) _buildCountBadge(warningCount, theme.warningColor),
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

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInsightsList(InspectorTheme theme) {
    if (_insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: theme.successColor,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'All good!',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'No issues detected',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _insights.length,
      itemBuilder: (context, index) {
        final insight = _insights[index];
        return _InsightTile(insight: insight, theme: theme);
      },
    );
  }
}

class _InsightTile extends StatelessWidget {
  final InspectorInsight insight;
  final InspectorTheme theme;

  const _InsightTile({
    required this.insight,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor().withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(insight.timestamp),
                  style: TextStyle(
                    color: theme.secondaryTextColor.withValues(alpha:0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (insight.type) {
      case InsightType.error:
        icon = Icons.error;
        color = theme.errorColor;
        break;
      case InsightType.warning:
        icon = Icons.warning;
        color = theme.warningColor;
        break;
      case InsightType.success:
        icon = Icons.check_circle;
        color = theme.successColor;
      case InsightType.info:
        icon = Icons.info;
        color = theme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Color _getBorderColor() {
    switch (insight.type) {
      case InsightType.error:
        return theme.errorColor;
      case InsightType.warning:
        return theme.warningColor;
      case InsightType.success:
        return theme.successColor;
      case InsightType.info:
        return theme.primaryColor;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// A compact badge showing insight counts.
class InsightsBadge extends StatefulWidget {
  final InspectorTheme theme;
  final VoidCallback? onTap;

  const InsightsBadge({
    super.key,
    this.theme = InspectorTheme.dark,
    this.onTap,
  });

  @override
  State<InsightsBadge> createState() => _InsightsBadgeState();
}

class _InsightsBadgeState extends State<InsightsBadge> {
  int _errorCount = 0;
  int _warningCount = 0;
  StreamSubscription<InspectorInsight>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = InspectorTracker.instance.insightStream.listen(_onInsight);
  }

  void _onInsight(InspectorInsight insight) {
    setState(() {
      if (insight.type == InsightType.error) {
        _errorCount++;
      } else if (insight.type == InsightType.warning) {
        _warningCount++;
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
    if (_errorCount == 0 && _warningCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = widget.theme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _errorCount > 0
              ? theme.errorColor.withValues(alpha:0.9)
              : theme.warningColor.withValues(alpha:0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_errorCount > 0 ? theme.errorColor : theme.warningColor)
                  .withValues(alpha:0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _errorCount > 0 ? Icons.error : Icons.warning,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _errorCount > 0
                  ? '$_errorCount error${_errorCount > 1 ? 's' : ''}'
                  : '$_warningCount warning${_warningCount > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
