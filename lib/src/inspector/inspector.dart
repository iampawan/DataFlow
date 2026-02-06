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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dataflow/src/inspector/config.dart';
import 'package:dataflow/src/inspector/tracker.dart';
import 'package:dataflow/src/inspector/action_timeline.dart';
import 'package:dataflow/src/inspector/insights_panel.dart';
import 'package:dataflow/src/inspector/bug_report.dart';

/// The main DataFlow Inspector widget.
///
/// Wrap your app with this widget to enable visual debugging.
///
/// ```dart
/// void main() {
///   DataFlow.init(AppStore());
///   runApp(
///     DataFlowInspector(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// The inspector is automatically disabled in release mode for safety.
class DataFlowInspector extends StatefulWidget {
  /// The child widget (your app).
  final Widget child;

  /// Whether the inspector is enabled.
  /// Defaults to true only in debug mode.
  final bool enabled;

  /// Configuration for the inspector.
  final InspectorConfig config;

  const DataFlowInspector({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
    this.config = const InspectorConfig(),
  });

  @override
  State<DataFlowInspector> createState() => DataFlowInspectorState();

  /// Gets the inspector state from context.
  static DataFlowInspectorState? of(BuildContext context) {
    return context.findAncestorStateOfType<DataFlowInspectorState>();
  }
}

class DataFlowInspectorState extends State<DataFlowInspector> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isVisible = false;
  bool _showTimeline = false;
  bool _showInsights = false;
  bool _showBugReport = false;
  BugReport? _bugReport;
  bool _positionsInitialized = false;
  Offset _buttonPosition = const Offset(16, 100); // Safe default
  Offset _timelinePosition = const Offset(16, 160);
  Offset _insightsPosition = const Offset(16, 400);

  // TODO: Shake detection requires sensors package - planned for future release

  @override
  void initState() {
    super.initState();

    // Triple safety check - never enable in release mode
    if (kReleaseMode || !widget.enabled) {
      return;
    }

    // Initialize tracker
    InspectorTracker.instance.initialize(
      maxHistory: widget.config.maxActionHistory,
    );

    // Set up bug report capture
    BugReportCapture.instance.setRepaintBoundaryKey(_repaintBoundaryKey);

    // Calculate initial positions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePositions();
    });
  }

  void _updatePositions() {
    if (_positionsInitialized) return;

    final size = MediaQuery.of(context).size;
    if (size.width == 0 || size.height == 0) return;

    setState(() {
      switch (widget.config.buttonPosition) {
        case InspectorButtonPosition.topLeft:
          _buttonPosition = const Offset(16, 100);
          _timelinePosition = const Offset(16, 160);
          _insightsPosition = Offset(16, size.height - 400);
        case InspectorButtonPosition.topRight:
          _buttonPosition = Offset(size.width - 70, 100);
          _timelinePosition = Offset(size.width - 366, 160);
          _insightsPosition = Offset(size.width - 336, size.height - 400);
        case InspectorButtonPosition.bottomLeft:
          _buttonPosition = Offset(16, size.height - 70);
          _timelinePosition = const Offset(16, 160);
          _insightsPosition = Offset(16, size.height - 450);
        case InspectorButtonPosition.bottomRight:
          _buttonPosition = Offset(size.width - 70, size.height - 70);
          _timelinePosition = Offset(size.width - 366, 160);
          _insightsPosition = Offset(size.width - 336, size.height - 450);
      }
      _positionsInitialized = true;
    });
  }

  /// Shows the inspector overlay.
  void show() {
    if (kReleaseMode) return;
    setState(() {
      _isVisible = true;
      _showTimeline = true;
    });
  }

  /// Hides the inspector overlay.
  void hide() {
    setState(() {
      _isVisible = false;
      _showTimeline = false;
      _showInsights = false;
    });
  }

  /// Toggles the inspector visibility.
  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  /// Shows the bug report dialog.
  void showBugReport() async {
    final report = await BugReportCapture.instance.capture();
    setState(() {
      _bugReport = report;
      _showBugReport = true;
    });
  }

  void _hideBugReport() {
    setState(() {
      _showBugReport = false;
      _bugReport = null;
    });
  }

  InspectorTheme _getTheme() {
    return widget.config.theme ?? InspectorTheme.dark;
  }

  @override
  Widget build(BuildContext context) {
    // Triple safety check - ALWAYS return just the child in release mode
    if (kReleaseMode) {
      return widget.child;
    }

    if (!widget.enabled) {
      return widget.child;
    }

    // This should never happen, but extra safety
    if (!kDebugMode) {
      return widget.child;
    }

    final theme = _getTheme();

    // Wrap with Directionality since we're above MaterialApp
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: Stack(
          children: [
            // App content
            widget.child,

            // Inspector overlay elements (not Positioned.fill to avoid blocking touches)
            if (widget.config.showFloatingButton || _isVisible)
              ..._buildOverlayElements(theme),

            // Bug report dialog
            if (_showBugReport && _bugReport != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _hideBugReport,
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // Prevent tap through
                        // Wrap with Localizations for Material widgets (TabBar, etc.)
                        child: Localizations(
                          locale: const Locale('en', 'US'),
                          delegates: const [
                            DefaultMaterialLocalizations.delegate,
                            DefaultWidgetsLocalizations.delegate,
                          ],
                          child: BugReportDialog(
                            report: _bugReport!,
                            theme: theme,
                            onClose: _hideBugReport,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOverlayElements(InspectorTheme theme) {
    return [
      // Floating action button
      if (widget.config.showFloatingButton)
        Positioned(
          left: _buttonPosition.dx,
          top: _buttonPosition.dy,
          child: _buildFloatingButton(theme),
        ),

      // Action timeline panel
      if (_showTimeline)
        Positioned(
          left: _timelinePosition.dx,
          top: _timelinePosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _timelinePosition += details.delta;
              });
            },
            child: ActionTimeline(
              theme: theme,
              onClose: () => setState(() => _showTimeline = false),
            ),
          ),
        ),

      // Insights panel
      if (_showInsights)
        Positioned(
          left: _insightsPosition.dx,
          top: _insightsPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _insightsPosition += details.delta;
              });
            },
            child: InsightsPanel(
              theme: theme,
              onClose: () => setState(() => _showInsights = false),
            ),
          ),
        ),

      // Insights badge (shows when panel is closed)
      if (!_showInsights && _isVisible)
        Positioned(
          right: 16,
          top: 100,
          child: InsightsBadge(
            theme: theme,
            onTap: () => setState(() => _showInsights = true),
          ),
        ),
    ];
  }

  Widget _buildFloatingButton(InspectorTheme theme) {
    return GestureDetector(
      onTap: toggle,
      onLongPress: showBugReport,
      onPanUpdate: (details) {
        setState(() {
          _buttonPosition += details.delta;
        });
      },
      child: _InspectorFab(theme: theme, isActive: _isVisible),
    );
  }

  @override
  void dispose() {
    if (!kReleaseMode && widget.enabled) {
      InspectorTracker.instance.disable();
    }
    super.dispose();
  }
}

class _InspectorFab extends StatelessWidget {
  final InspectorTheme theme;
  final bool isActive;

  const _InspectorFab({
    required this.theme,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isActive
            ? theme.primaryColor
            : theme.backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: (isActive ? theme.primaryColor : Colors.black)
                .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.developer_mode,
            color: isActive ? Colors.white : theme.primaryColor,
            size: 26,
          ),
          // Animated ring when active
          if (isActive)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  width: 54 * value,
                  height: 54 * value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27 * value),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.5 * (1 - value)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Extension to easily access inspector from context.
extension InspectorContextExtension on BuildContext {
  /// Gets the DataFlow Inspector state.
  DataFlowInspectorState? get inspector => DataFlowInspector.of(this);

  /// Shows the inspector.
  void showInspector() => inspector?.show();

  /// Hides the inspector.
  void hideInspector() => inspector?.hide();

  /// Toggles the inspector.
  void toggleInspector() => inspector?.toggle();

  /// Shows the bug report dialog.
  void showBugReport() => inspector?.showBugReport();
}
