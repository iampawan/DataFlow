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

import 'package:flutter/material.dart';

/// Configuration for the DataFlow Inspector.
class InspectorConfig {
  /// Whether to enable shake gesture to toggle inspector.
  final bool enableShakeToToggle;

  /// Whether to enable widget pulse effect on state changes.
  final bool enableWidgetPulse;

  /// Whether to enable performance heatmap.
  final bool enableHeatmap;

  /// Whether to enable smart insights.
  final bool enableSmartInsights;

  /// Whether to show the floating action button.
  final bool showFloatingButton;

  /// Color for success pulse effect.
  final Color successPulseColor;

  /// Color for error pulse effect.
  final Color errorPulseColor;

  /// Color for loading pulse effect.
  final Color loadingPulseColor;

  /// Duration of pulse animation.
  final Duration pulseDuration;

  /// Maximum number of actions to keep in history.
  final int maxActionHistory;

  /// Threshold for rebuild warning (rebuilds per 10 seconds).
  final int rebuildWarningThreshold;

  /// Position of the floating button.
  final InspectorButtonPosition buttonPosition;

  /// Custom theme for inspector panels.
  final InspectorTheme? theme;

  const InspectorConfig({
    this.enableShakeToToggle = true,
    this.enableWidgetPulse = true,
    this.enableHeatmap = true,
    this.enableSmartInsights = true,
    this.showFloatingButton = true,
    this.successPulseColor = const Color(0xFF10B981),
    this.errorPulseColor = const Color(0xFFEF4444),
    this.loadingPulseColor = const Color(0xFF00D9FF),
    this.pulseDuration = const Duration(milliseconds: 400),
    this.maxActionHistory = 100,
    this.rebuildWarningThreshold = 10,
    this.buttonPosition = InspectorButtonPosition.bottomRight,
    this.theme,
  });

  InspectorConfig copyWith({
    bool? enableShakeToToggle,
    bool? enableWidgetPulse,
    bool? enableHeatmap,
    bool? enableSmartInsights,
    bool? showFloatingButton,
    Color? successPulseColor,
    Color? errorPulseColor,
    Color? loadingPulseColor,
    Duration? pulseDuration,
    int? maxActionHistory,
    int? rebuildWarningThreshold,
    InspectorButtonPosition? buttonPosition,
    InspectorTheme? theme,
  }) {
    return InspectorConfig(
      enableShakeToToggle: enableShakeToToggle ?? this.enableShakeToToggle,
      enableWidgetPulse: enableWidgetPulse ?? this.enableWidgetPulse,
      enableHeatmap: enableHeatmap ?? this.enableHeatmap,
      enableSmartInsights: enableSmartInsights ?? this.enableSmartInsights,
      showFloatingButton: showFloatingButton ?? this.showFloatingButton,
      successPulseColor: successPulseColor ?? this.successPulseColor,
      errorPulseColor: errorPulseColor ?? this.errorPulseColor,
      loadingPulseColor: loadingPulseColor ?? this.loadingPulseColor,
      pulseDuration: pulseDuration ?? this.pulseDuration,
      maxActionHistory: maxActionHistory ?? this.maxActionHistory,
      rebuildWarningThreshold:
          rebuildWarningThreshold ?? this.rebuildWarningThreshold,
      buttonPosition: buttonPosition ?? this.buttonPosition,
      theme: theme ?? this.theme,
    );
  }
}

/// Position for the inspector floating button.
enum InspectorButtonPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Theme configuration for inspector panels.
class InspectorTheme {
  final Color backgroundColor;
  final Color surfaceColor;
  final Color primaryColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final double borderRadius;
  final double panelOpacity;

  const InspectorTheme({
    this.backgroundColor = const Color(0xFF1A1A2E),
    this.surfaceColor = const Color(0xFF16213E),
    this.primaryColor = const Color(0xFF00D9FF),
    this.textColor = const Color(0xFFFFFFFF),
    this.secondaryTextColor = const Color(0xFF94A3B8),
    this.successColor = const Color(0xFF10B981),
    this.errorColor = const Color(0xFFEF4444),
    this.warningColor = const Color(0xFFF59E0B),
    this.borderRadius = 12.0,
    this.panelOpacity = 0.95,
  });

  /// Dark theme preset.
  static const InspectorTheme dark = InspectorTheme();

  /// Light theme preset.
  static const InspectorTheme light = InspectorTheme(
    backgroundColor: Color(0xFFF8FAFC),
    surfaceColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF0891B2),
    textColor: Color(0xFF1E293B),
    secondaryTextColor: Color(0xFF64748B),
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFF59E0B),
  );
}
