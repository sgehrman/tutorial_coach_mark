import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/src/paint/light_paint.dart';
import 'package:tutorial_coach_mark/src/paint/light_paint_rect.dart';
import 'package:tutorial_coach_mark/src/target/target_focus.dart';
import 'package:tutorial_coach_mark/src/target/target_position.dart';
import 'package:tutorial_coach_mark/src/util.dart';

class AnimatedFocusLight extends StatefulWidget {
  final List<TargetFocus> targets;
  final Function(TargetFocus)? focus;
  final FutureOr<void> Function(TargetFocus)? clickTarget;
  final FutureOr<void> Function(TargetFocus, TapDownDetails)?
      clickTargetWithTapPosition;
  final FutureOr<void> Function(TargetFocus)? clickOverlay;
  final void Function()? removeFocus;
  final Function()? finish;
  final double paddingFocus;
  final Color colorShadow;
  final double opacityShadow;
  final Duration? focusAnimationDuration;
  final Duration? unFocusAnimationDuration;
  final Duration? pulseAnimationDuration;
  final Tween<double>? pulseVariation;
  final bool pulseEnable;

  const AnimatedFocusLight({
    required this.targets,
    this.focus,
    this.finish,
    this.removeFocus,
    this.clickTarget,
    this.clickTargetWithTapPosition,
    this.clickOverlay,
    this.paddingFocus = 10,
    this.colorShadow = Colors.black,
    this.opacityShadow = 0.8,
    this.focusAnimationDuration,
    this.unFocusAnimationDuration,
    this.pulseAnimationDuration,
    this.pulseVariation,
    this.pulseEnable = true,
    Key? key,
  })  : assert(targets.length > 0, 'no targets'),
        super(key: key);

  @override
  State<AnimatedFocusLight> createState() => _AnimatedPulseFocusLightState();
}

abstract class AnimatedFocusLightState extends State<AnimatedFocusLight>
    with TickerProviderStateMixin {
  final borderRadiusDefault = 10.0;
  final defaultFocusAnimationDuration = const Duration(milliseconds: 600);
  late AnimationController _controller;
  late CurvedAnimation _curvedAnimation;

  late TargetFocus _targetFocus;
  Offset _positioned = Offset.zero;
  TargetPosition? _targetPosition;

  double _sizeCircle = 100;
  int _currentFocus = 0;
  double _progressAnimated = 0;
  bool _goNext = true;

  @override
  void initState() {
    super.initState();
    _targetFocus = widget.targets[_currentFocus];
    _controller = AnimationController(
      vsync: this,
      duration: _targetFocus.focusAnimationDuration ??
          widget.focusAnimationDuration ??
          defaultFocusAnimationDuration,
    )..addStatusListener(_listener);

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.ease,
    );

    Future.delayed(Duration.zero, _runFocus);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void next() => _tapHandler();

  void previous() => _tapHandler(goNext: false);

  Future<void> _tapHandler({
    bool goNext = true,
    bool targetTap = false,
    bool overlayTap = false,
  }) async {
    if (targetTap) {
      await widget.clickTarget?.call(_targetFocus);
    }
    if (overlayTap) {
      await widget.clickOverlay?.call(_targetFocus);
    }
  }

  Future<void> _tapHandlerForPosition(TapDownDetails tapDetails) async {
    await widget.clickTargetWithTapPosition?.call(_targetFocus, tapDetails);
  }

  void _runFocus();

  void _nextFocus() {
    if (_currentFocus >= widget.targets.length - 1) {
      _finish();

      return;
    }
    _currentFocus++;

    _runFocus();
  }

  void _previousFocus() {
    if (_currentFocus <= 0) {
      _finish();

      return;
    }
    _currentFocus--;
    _runFocus();
  }

  void _finish() {
    safeSetState(() => _currentFocus = 0);
    widget.finish!();
  }

  void _listener(AnimationStatus status);

  CustomPainter _getPainter(TargetFocus? target) {
    if (target?.shape == ShapeLightFocus.rRect) {
      return LightPaintRect(
        colorShadow: target?.color ?? widget.colorShadow,
        progress: _progressAnimated,
        offset: _getPaddingFocus(),
        target: _targetPosition ?? TargetPosition(Size.zero, Offset.zero),
        radius: target?.radius ?? 0,
        borderSide: target?.borderSide,
        opacityShadow: widget.opacityShadow,
      );
    } else {
      return LightPaint(
        _progressAnimated,
        _positioned,
        _sizeCircle,
        colorShadow: target?.color ?? widget.colorShadow,
        borderSide: target?.borderSide,
        opacityShadow: widget.opacityShadow,
      );
    }
  }

  double _getPaddingFocus() {
    return _targetFocus.paddingFocus ?? (widget.paddingFocus);
  }

  BorderRadius _betBorderRadiusTarget() {
    final double radius = _targetFocus.shape == ShapeLightFocus.circle
        ? _targetPosition?.size.width ?? borderRadiusDefault
        : _targetFocus.radius ?? borderRadiusDefault;

    return BorderRadius.circular(radius);
  }
}

class _AnimatedPulseFocusLightState extends AnimatedFocusLightState {
  final defaultPulseAnimationDuration = const Duration(milliseconds: 500);
  final defaultPulseVariation = Tween<double>(begin: 1, end: 0.99);
  late AnimationController _controllerPulse;
  late Animation<double> _tweenPulse;

  bool _finishFocus = false;
  bool _initReverse = false;

  @override
  void initState() {
    super.initState();
    _controllerPulse = AnimationController(
      vsync: this,
      duration: widget.pulseAnimationDuration ?? defaultPulseAnimationDuration,
    );

    _tweenPulse = _createTweenAnimation(
      _targetFocus.pulseVariation ??
          widget.pulseVariation ??
          defaultPulseVariation,
    );

    _controllerPulse.addStatusListener(_listenerPulse);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _targetFocus.enableOverlayTab
          ? () => _tapHandler(overlayTap: true)
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          _progressAnimated = _curvedAnimation.value;

          return AnimatedBuilder(
            animation: _controllerPulse,
            builder: (_, child) {
              if (_finishFocus) {
                _progressAnimated = _tweenPulse.value;
              }

              return Stack(
                children: <Widget>[
                  // on flutter web there is a one pixel border that peeks though
                  Positioned(
                    top: -1,
                    right: -1,
                    left: -1,
                    bottom: -1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.fromBorderSide(
                          BorderSide(
                            width: 2,
                            color: _targetFocus.color ?? widget.colorShadow,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.maxFinite,
                    height: double.maxFinite,
                    child: CustomPaint(
                      painter: _getPainter(_targetFocus),
                    ),
                  ),
                  Positioned(
                    left: (_targetPosition?.offset.dx ?? 0) -
                        _getPaddingFocus() * 2,
                    top: (_targetPosition?.offset.dy ?? 0) -
                        _getPaddingFocus() * 2,
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      borderRadius: _betBorderRadiusTarget(),
                      onTap: _targetFocus.enableTargetTab
                          ? () => _tapHandler(targetTap: true)

                          /// Essential for collecting [TapDownDetails]. Do not make [null]
                          : () {},
                      onTapDown: (details) {
                        _tapHandlerForPosition(details);
                      },
                      child: Container(
                        color: Colors.transparent,
                        width: (_targetPosition?.size.width ?? 0) +
                            _getPaddingFocus() * 4,
                        height: (_targetPosition?.size.height ?? 0) +
                            _getPaddingFocus() * 4,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  void _runFocus() {
    if (_currentFocus < 0) {
      return;
    }

    _targetFocus = widget.targets[_currentFocus];

    _controller.duration = _targetFocus.focusAnimationDuration ??
        widget.focusAnimationDuration ??
        defaultFocusAnimationDuration;

    _tweenPulse = _createTweenAnimation(
      _targetFocus.pulseVariation ??
          widget.pulseVariation ??
          defaultPulseVariation,
    );

    final targetPosition = getTargetCurrent(_targetFocus);

    if (targetPosition == null) {
      _finish();

      return;
    }

    safeSetState(() {
      _finishFocus = false;
      _targetPosition = targetPosition;

      _positioned = Offset(
        targetPosition.offset.dx + (targetPosition.size.width / 2),
        targetPosition.offset.dy + (targetPosition.size.height / 2),
      );

      if (targetPosition.size.height > targetPosition.size.width) {
        _sizeCircle = targetPosition.size.height * 0.6 + _getPaddingFocus();
      } else {
        _sizeCircle = targetPosition.size.width * 0.6 + _getPaddingFocus();
      }
    });

    _controller.forward();
    _controller.duration = widget.unFocusAnimationDuration ??
        _targetFocus.focusAnimationDuration ??
        widget.focusAnimationDuration ??
        defaultFocusAnimationDuration;
  }

  @override
  Future<void> _tapHandler({
    bool goNext = true,
    bool targetTap = false,
    bool overlayTap = false,
  }) async {
    await super._tapHandler(
      goNext: goNext,
      targetTap: targetTap,
      overlayTap: overlayTap,
    );
    if (mounted) {
      safeSetState(() {
        _goNext = goNext;
        _initReverse = true;
      });
    }

    await _controllerPulse.reverse(from: _controllerPulse.value);
  }

  @override
  Future<void> _tapHandlerForPosition(TapDownDetails tapDetails) async {
    await super._tapHandlerForPosition(tapDetails);
  }

  @override
  void dispose() {
    _controllerPulse.dispose();
    super.dispose();
  }

  @override
  void _listener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      safeSetState(() => _finishFocus = true);

      widget.focus?.call(_targetFocus);

      _controllerPulse.forward();
    }
    if (status == AnimationStatus.dismissed) {
      safeSetState(() {
        _finishFocus = false;
        _initReverse = false;
      });
      if (_goNext) {
        _nextFocus();
      } else {
        _previousFocus();
      }
    }

    if (status == AnimationStatus.reverse) {
      widget.removeFocus!();
    }
  }

  void _listenerPulse(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controllerPulse.reverse();
    }

    if (status == AnimationStatus.dismissed) {
      if (_initReverse) {
        safeSetState(() => _finishFocus = false);
        _controller.reverse();
      } else if (_finishFocus) {
        _controllerPulse.forward();
      }
    }
  }

  Animation<double> _createTweenAnimation(Tween<double> tween) {
    return tween.animate(
      CurvedAnimation(parent: _controllerPulse, curve: Curves.ease),
    );
  }
}
