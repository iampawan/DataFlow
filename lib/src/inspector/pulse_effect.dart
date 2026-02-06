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
import 'package:dataflow/src/engine.dart';
import 'package:dataflow/src/inspector/config.dart';

/// A widget that wraps its child and shows a pulse effect on state changes.
class PulseEffect extends StatefulWidget {
  final Widget child;
  final DataActionStatus? status;
  final InspectorConfig config;
  final bool enabled;

  const PulseEffect({
    super.key,
    required this.child,
    this.status,
    this.config = const InspectorConfig(),
    this.enabled = true,
  });

  @override
  State<PulseEffect> createState() => _PulseEffectState();
}

class _PulseEffectState extends State<PulseEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Color _pulseColor = Colors.transparent;
  DataActionStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.config.pulseDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(covariant PulseEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.enabled) return;

    // Trigger pulse on status change
    if (widget.status != null && widget.status != _lastStatus) {
      _lastStatus = widget.status;

      switch (widget.status) {
        case DataActionStatus.success:
          _pulseColor = widget.config.successPulseColor;
          _controller.forward(from: 0);
          break;
        case DataActionStatus.error:
          _pulseColor = widget.config.errorPulseColor;
          _controller.forward(from: 0);
          break;
        case DataActionStatus.loading:
          _pulseColor = widget.config.loadingPulseColor;
          _controller.forward(from: 0);
          break;
        case DataActionStatus.cancelled:
          _pulseColor = Colors.orange;
          _controller.forward(from: 0);
          break;
        default:
          break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _animation.value > 0
                ? [
                    BoxShadow(
                      color: _pulseColor.withValues(alpha:0.6 * _animation.value),
                      blurRadius: 20 * _animation.value,
                      spreadRadius: 5 * _animation.value,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A widget that shows a glowing border effect.
class GlowingBorder extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool isGlowing;
  final double glowRadius;
  final Duration duration;

  const GlowingBorder({
    super.key,
    required this.child,
    this.glowColor = Colors.blue,
    this.isGlowing = false,
    this.glowRadius = 10,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<GlowingBorder> createState() => _GlowingBorderState();
}

class _GlowingBorderState extends State<GlowingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isGlowing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GlowingBorder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isGlowing && !oldWidget.isGlowing) {
      _controller.repeat(reverse: true);
    } else if (!widget.isGlowing && oldWidget.isGlowing) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: widget.isGlowing
                ? Border.all(
                    color: widget.glowColor.withValues(alpha:0.3 + 0.4 * _animation.value),
                    width: 2,
                  )
                : null,
            boxShadow: widget.isGlowing
                ? [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha:0.3 * _animation.value),
                      blurRadius: widget.glowRadius * _animation.value,
                      spreadRadius: 2 * _animation.value,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Extension to easily add pulse effect to any widget.
extension PulseEffectExtension on Widget {
  Widget withPulse({
    DataActionStatus? status,
    InspectorConfig config = const InspectorConfig(),
    bool enabled = true,
  }) {
    return PulseEffect(
      status: status,
      config: config,
      enabled: enabled,
      child: this,
    );
  }
}
