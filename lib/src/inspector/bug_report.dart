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
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:dataflow/src/engine.dart';
import 'package:dataflow/src/inspector/tracker.dart';
import 'package:dataflow/src/inspector/config.dart';

/// Captures a bug report including screenshot, state, and action history.
class BugReportCapture {
  BugReportCapture._();

  static final BugReportCapture instance = BugReportCapture._();

  GlobalKey? _repaintBoundaryKey;

  /// Sets the repaint boundary key for screenshot capture.
  void setRepaintBoundaryKey(GlobalKey key) {
    _repaintBoundaryKey = key;
  }

  /// Captures a bug report.
  Future<BugReport> capture({String? description}) async {
    final timestamp = DateTime.now();
    Uint8List? screenshot;

    // Capture screenshot if possible
    if (_repaintBoundaryKey?.currentContext != null) {
      try {
        screenshot = await _captureScreenshot();
      } catch (e) {
        // Screenshot capture failed, continue without it
      }
    }

    // Get action history
    final actions = InspectorTracker.instance.actionHistory
        .map((a) => a.toJson())
        .toList();

    // Get store state
    Map<String, dynamic>? storeState;
    try {
      final store = DataFlow.getStore();
      storeState = {
        'type': store.runtimeType.toString(),
        'toString': store.toString(),
      };
    } catch (e) {
      storeState = {'error': 'Unable to get store state'};
    }

    // Get widget tracking data
    final widgets = InspectorTracker.instance.widgets.map(
      (key, value) => MapEntry(key, {
        'name': value.widgetName,
        'rebuildCount': value.rebuildCount,
        'rebuildRate': value.rebuildRate,
        'actions': value.actions.map((a) => a.toString()).toList(),
      }),
    );

    return BugReport(
      timestamp: timestamp,
      description: description,
      screenshot: screenshot,
      actions: actions,
      storeState: storeState,
      widgets: widgets,
      deviceInfo: await _getDeviceInfo(),
    );
  }

  Future<Uint8List?> _captureScreenshot() async {
    final boundary = _repaintBoundaryKey?.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 1.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': defaultTargetPlatform.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Represents a captured bug report.
class BugReport {
  final DateTime timestamp;
  final String? description;
  final Uint8List? screenshot;
  final List<Map<String, dynamic>> actions;
  final Map<String, dynamic>? storeState;
  final Map<String, Map<String, dynamic>> widgets;
  final Map<String, dynamic> deviceInfo;

  BugReport({
    required this.timestamp,
    this.description,
    this.screenshot,
    required this.actions,
    this.storeState,
    required this.widgets,
    required this.deviceInfo,
  });

  /// Exports the bug report as JSON (without screenshot).
  String toJson() {
    return jsonEncode({
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'actions': actions,
      'storeState': storeState,
      'widgets': widgets,
      'deviceInfo': deviceInfo,
    });
  }

  /// Gets a summary of the bug report.
  String get summary {
    final errorCount = actions.where((a) => a['status'] == 'error').length;
    final totalActions = actions.length;

    return '''
Bug Report - ${timestamp.toIso8601String()}
${'-' * 50}
Description: ${description ?? 'No description'}
Total Actions: $totalActions
Errors: $errorCount
Widgets Tracked: ${widgets.length}
${'-' * 50}
''';
  }
}

/// Dialog for viewing and sharing bug reports.
class BugReportDialog extends StatefulWidget {
  final BugReport report;
  final InspectorTheme theme;
  final VoidCallback? onClose;

  const BugReportDialog({
    super.key,
    required this.report,
    this.theme = InspectorTheme.dark,
    this.onClose,
  });

  @override
  State<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<BugReportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            _buildHeader(theme),
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.secondaryTextColor,
              indicatorColor: theme.primaryColor,
              tabs: const [
                Tab(text: 'Screenshot'),
                Tab(text: 'Actions'),
                Tab(text: 'State'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildScreenshotTab(theme),
                  _buildActionsTab(theme),
                  _buildStateTab(theme),
                ],
              ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InspectorTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.borderRadius),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bug_report, color: theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bug Report',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _formatTimestamp(widget.report.timestamp),
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.secondaryTextColor),
            onPressed: () => widget.onClose?.call(),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotTab(InspectorTheme theme) {
    if (widget.report.screenshot == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: theme.secondaryTextColor,
            ),
            const SizedBox(height: 8),
            Text(
              'No screenshot available',
              style: TextStyle(color: theme.secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          widget.report.screenshot!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildActionsTab(InspectorTheme theme) {
    final actions = widget.report.actions;

    if (actions.isEmpty) {
      return Center(
        child: Text(
          'No actions recorded',
          style: TextStyle(color: theme.secondaryTextColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final status = action['status'] as String?;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              _buildStatusIcon(status, theme),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action['actionType'] as String? ?? 'Unknown',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                  ),
                ),
              ),
              if (action['duration'] != null)
                Text(
                  '${action['duration']}ms',
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(String? status, InspectorTheme theme) {
    switch (status) {
      case 'loading':
        return Icon(Icons.hourglass_empty, color: theme.primaryColor, size: 16);
      case 'success':
        return Icon(Icons.check_circle, color: theme.successColor, size: 16);
      case 'error':
        return Icon(Icons.error, color: theme.errorColor, size: 16);
      case 'cancelled':
        return Icon(Icons.cancel, color: theme.warningColor, size: 16);
      default:
        return Icon(Icons.circle_outlined,
            color: theme.secondaryTextColor, size: 16);
    }
  }

  Widget _buildStateTab(InspectorTheme theme) {
    final state = widget.report.storeState;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Store State',
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              state != null
                  ? const JsonEncoder.withIndent('  ').convert(state)
                  : 'No state available',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Device Info',
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ')
                  .convert(widget.report.deviceInfo),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(InspectorTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(theme.borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: _copyToClipboard,
            icon: Icon(Icons.copy, size: 18, color: theme.secondaryTextColor),
            label: Text(
              'Copy JSON',
              style: TextStyle(color: theme.secondaryTextColor),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.report.toJson()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bug report copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _share() {
    // For now, just copy to clipboard
    // In a real implementation, you could use share_plus package
    _copyToClipboard();
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}

/// Shows the bug report dialog using Overlay (no MaterialLocalizations needed).
Future<void> showBugReportDialog(BuildContext context,
    {InspectorTheme theme = InspectorTheme.dark}) async {
  final report = await BugReportCapture.instance.capture();

  if (!context.mounted) return;

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            // Dismiss background
            Positioned.fill(
              child: GestureDetector(
                onTap: () => entry.remove(),
                child: Container(color: Colors.black54),
              ),
            ),
            // Dialog
            Center(
              child: BugReportDialog(
                report: report,
                theme: theme,
                onClose: () => entry.remove(),
              ),
            ),
          ],
        ),
      );
    },
  );

  overlay.insert(entry);
}
