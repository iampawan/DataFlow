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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dataflow/src/engine.dart';
import 'package:dataflow/src/inspector/config.dart';
import 'package:dataflow/src/inspector/tracker.dart';

/// Shows a popup with state information for a DataSync widget.
class StatePopup extends StatelessWidget {
  final String widgetName;
  final DataStore store;
  final Set<Type> actions;
  final Map<Type, DataActionStatus> actionStatuses;
  final TrackedWidget? trackedWidget;
  final InspectorTheme theme;
  final VoidCallback? onClose;

  const StatePopup({
    super.key,
    required this.widgetName,
    required this.store,
    required this.actions,
    required this.actionStatuses,
    this.trackedWidget,
    this.theme = InspectorTheme.dark,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 320,
          maxHeight: 400,
        ),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withOpacity(theme.panelOpacity),
          borderRadius: BorderRadius.circular(theme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Widget Info', _buildWidgetInfo()),
                    const SizedBox(height: 12),
                    _buildSection('Actions', _buildActionsInfo()),
                    const SizedBox(height: 12),
                    _buildSection('Store State', _buildStoreState()),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.borderRadius),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.data_object,
            color: theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widgetName,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                color: theme.secondaryTextColor,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        content,
      ],
    );
  }

  Widget _buildWidgetInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildInfoRow('Type', 'DataSync<${store.runtimeType}>'),
          if (trackedWidget != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow('Rebuilds', '${trackedWidget!.rebuildCount}'),
            const SizedBox(height: 6),
            _buildInfoRow(
              'Rebuild Rate',
              '${trackedWidget!.rebuildRate.toStringAsFixed(1)}/s',
              valueColor: trackedWidget!.rebuildRate > 1
                  ? theme.warningColor
                  : theme.successColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? theme.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsInfo() {
    if (actions.isEmpty) {
      return Text(
        'No actions configured',
        style: TextStyle(
          color: theme.secondaryTextColor,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: actions.map((action) {
          final status = actionStatuses[action] ?? DataActionStatus.idle;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.backgroundColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildStatusIcon(status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _shortenActionName(action.toString()),
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  status.name,
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusIcon(DataActionStatus status) {
    switch (status) {
      case DataActionStatus.loading:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primaryColor,
          ),
        );
      case DataActionStatus.success:
        return Icon(Icons.check_circle, color: theme.successColor, size: 14);
      case DataActionStatus.error:
        return Icon(Icons.error, color: theme.errorColor, size: 14);
      case DataActionStatus.cancelled:
        return Icon(Icons.cancel, color: theme.warningColor, size: 14);
      default:
        return Icon(Icons.circle_outlined,
            color: theme.secondaryTextColor, size: 14);
    }
  }

  Color _getStatusColor(DataActionStatus status) {
    switch (status) {
      case DataActionStatus.loading:
        return theme.primaryColor;
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

  Widget _buildStoreState() {
    final storeJson = _serializeStore(store);

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
            store.runtimeType.toString(),
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildJsonTree(storeJson),
        ],
      ),
    );
  }

  Widget _buildJsonTree(Map<String, dynamic> json, {int depth = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: json.entries.map((entry) {
        final value = entry.value;
        final isComplex = value is Map || value is List;

        return Padding(
          padding: EdgeInsets.only(left: depth * 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key}: ',
                style: TextStyle(
                  color: theme.secondaryTextColor,
                  fontSize: 11,
                ),
              ),
              Expanded(
                child: Text(
                  isComplex
                      ? (value is List ? '[${value.length} items]' : '{...}')
                      : _formatValue(value),
                  style: TextStyle(
                    color: _getValueColor(value),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    return value.toString();
  }

  Color _getValueColor(dynamic value) {
    if (value == null) return theme.secondaryTextColor;
    if (value is String) return const Color(0xFFCE9178);
    if (value is bool) return const Color(0xFF569CD6);
    if (value is num) return const Color(0xFFB5CEA8);
    return theme.textColor;
  }

  Map<String, dynamic> _serializeStore(DataStore store) {
    try {
      final storeString = store.toString();

      // Check if it's the default "Instance of 'ClassName'" format
      if (storeString.startsWith("Instance of '")) {
        return {
          '_hint': 'Override toString() in your store for better debugging',
        };
      }

      // Try to parse key: value pairs from the toString output
      final json = <String, dynamic>{};
      final lines = storeString.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        // Skip empty lines, braces, and class name lines
        if (trimmed.isEmpty ||
            trimmed == '{' ||
            trimmed == '}' ||
            trimmed.endsWith('{')) continue;

        // Remove trailing comma
        final cleanLine = trimmed.endsWith(',')
            ? trimmed.substring(0, trimmed.length - 1)
            : trimmed;

        // Try to extract key: value
        final colonIndex = cleanLine.indexOf(':');
        if (colonIndex > 0) {
          final key = cleanLine.substring(0, colonIndex).trim();
          final value = cleanLine.substring(colonIndex + 1).trim();
          json[key] = value;
        }
      }

      if (json.isEmpty) {
        json['_raw'] = storeString;
      }

      return json;
    } catch (e) {
      return {'_error': 'Unable to serialize store: $e'};
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _FooterButton(
            icon: Icons.copy,
            label: 'Copy',
            theme: theme,
            onTap: () => _copyToClipboard(context),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final data = {
      'widget': widgetName,
      'storeType': store.runtimeType.toString(),
      'actions': actions.map((a) => a.toString()).toList(),
      'actionStatuses':
          actionStatuses.map((k, v) => MapEntry(k.toString(), v.name)),
      'rebuilds': trackedWidget?.rebuildCount,
    };

    Clipboard.setData(ClipboardData(text: jsonEncode(data)));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('State copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _shortenActionName(String name) {
    if (name.endsWith('Action')) {
      return name.substring(0, name.length - 6);
    }
    return name;
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final InspectorTheme theme;
  final VoidCallback onTap;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.secondaryTextColor, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a state popup at the given position.
void showStatePopup({
  required BuildContext context,
  required Offset position,
  required String widgetName,
  required DataStore store,
  required Set<Type> actions,
  required Map<Type, DataActionStatus> actionStatuses,
  TrackedWidget? trackedWidget,
  InspectorTheme theme = InspectorTheme.dark,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          // Dismiss area
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Popup
          Positioned(
            left: position.dx.clamp(16, MediaQuery.of(context).size.width - 336),
            top: position.dy.clamp(16, MediaQuery.of(context).size.height - 416),
            child: StatePopup(
              widgetName: widgetName,
              store: store,
              actions: actions,
              actionStatuses: actionStatuses,
              trackedWidget: trackedWidget,
              theme: theme,
              onClose: () => entry.remove(),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
}
