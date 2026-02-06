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

/// DataFlow Inspector - Visual debugging for DataFlow
///
/// Wrap your app with [DataFlowInspector] to enable visual debugging:
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
/// Features:
/// - Floating action timeline showing all actions
/// - Widget pulse effects on state changes
/// - Long-press any DataSync widget to see its state
/// - Smart insights for performance issues
/// - One-tap bug report capture
///
/// The inspector is automatically disabled in release mode.
library dataflow_inspector;

export 'config.dart';
export 'inspector.dart';
export 'tracker.dart' show TrackedAction, TrackedWidget, ActionStats, InspectorInsight, InsightType;
export 'action_timeline.dart' show ActionTimeline, ActionBadge;
export 'insights_panel.dart' show InsightsPanel, InsightsBadge;
export 'bug_report.dart' show BugReport, BugReportCapture, showBugReportDialog;
export 'pulse_effect.dart' show PulseEffect, GlowingBorder, PulseEffectExtension;
export 'state_popup.dart' show StatePopup, showStatePopup;
