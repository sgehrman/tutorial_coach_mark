import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tutorial_coach_mark/light_paint.dart';
import 'package:tutorial_coach_mark/light_paint_rect.dart';
import 'package:tutorial_coach_mark/target_focus.dart';
import 'package:tutorial_coach_mark/target_position.dart';
import 'package:tutorial_coach_mark/util.dart';

enum ShapeLightFocus { Circle, RRect }

class AnimatedFocusLight extends StatefulWidget {
  final List<TargetFocus> targets;
  final Function(TargetFocus) focus;
  final Function(TargetFocus) clickTarget;
  final Function removeFocus;
  final Function() finish;
  final double paddingFocus;
  final Color colorShadow;
  final double opacityShadow;

  const AnimatedFocusLight({
    Key key,
    this.targets,
    this.focus,
    this.finish,
    this.removeFocus,
    this.clickTarget,
    this.paddingFocus = 10,
    this.colorShadow = Colors.black,
    this.opacityShadow = 0.8,
  }) : super(key: key);

  @override
  AnimatedFocusLightState createState() => AnimatedFocusLightState();
}

class AnimatedFocusLightState extends State<AnimatedFocusLight>
    with TickerProviderStateMixin {
  AnimationController _controller;
  AnimationController _controllerPulse;
  CurvedAnimation _curvedAnimation;
  Animation tweenPulse;
  Offset positioned = Offset(0.0, 0.0);
  TargetPosition targetPosition;

  double sizeCircle = 100;
  int currentFocus = -1;
  bool finishFocus = false;
  bool initReverse = false;
  double progressAnimated = 0;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            finishFocus = true;
          });
          widget?.focus(widget.targets[currentFocus]);

          _controllerPulse.forward();
        }
        if (status == AnimationStatus.dismissed) {
          setState(() {
            finishFocus = false;
            initReverse = false;
          });
          _nextFocus();
        }

        if (status == AnimationStatus.reverse) {
          widget?.removeFocus();
        }
      });

    _curvedAnimation = CurvedAnimation(parent: _controller, curve: Curves.ease);

    _controllerPulse =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _controllerPulse.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controllerPulse.reverse();
      }

      if (status == AnimationStatus.dismissed) {
        if (initReverse) {
          setState(() {
            finishFocus = false;
          });
          _controller.reverse();
        } else if (finishFocus) {
          _controllerPulse.forward();
        }
      }
    });

    tweenPulse = Tween(begin: 1.0, end: 0.99)
        .animate(CurvedAnimation(parent: _controllerPulse, curve: Curves.ease));

    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        progressAnimated = _curvedAnimation.value;
        return AnimatedBuilder(
          animation: _controllerPulse,
          builder: (_, child) {
            if (finishFocus) {
              progressAnimated = tweenPulse.value;
            }
            return Container(
              width: double.maxFinite,
              height: double.maxFinite,
              child: currentFocus != -1
                  ? CustomPaint(
                      painter: widget?.targets[currentFocus]?.shape ==
                              ShapeLightFocus.RRect
                          ? LightPaintRect(
                              colorShadow: widget.colorShadow,
                              progress: progressAnimated,
                              offset: widget.paddingFocus,
                              target: targetPosition,
                              radius:
                                  widget?.targets[currentFocus]?.radius ?? 0,
                              opacityShadow: widget.opacityShadow,
                            )
                          : LightPaint(
                              progressAnimated,
                              positioned,
                              sizeCircle,
                              colorShadow: widget.colorShadow,
                              opacityShadow: widget.opacityShadow,
                            ),
                    )
                  : SizedBox.shrink(),
            );
          },
        );
      },
    );
  }

  void tapHandler() {
    setState(() {
      initReverse = true;
      _controllerPulse.reverse(from: _controllerPulse.value);
    });
    if (currentFocus > -1) {
      widget?.clickTarget(widget.targets[currentFocus]);
    }
  }

  void _nextFocus() {
    if (currentFocus >= widget.targets.length - 1) {
      this._finish();
      return;
    }

    currentFocus++;

    var targetPosition = getTargetCurrent(widget.targets[currentFocus]);
    if (targetPosition == null) {
      this._finish();
      return;
    }

    setState(() {
      finishFocus = false;
      this.targetPosition = targetPosition;

      positioned = Offset(
        targetPosition.offset.dx + (targetPosition.size.width / 2),
        targetPosition.offset.dy + (targetPosition.size.height / 2),
      );

      if (targetPosition.size.height > targetPosition.size.width) {
        sizeCircle = targetPosition.size.height * 0.6 + widget.paddingFocus;
      } else {
        sizeCircle = targetPosition.size.width * 0.6 + widget.paddingFocus;
      }
    });

    _controller.forward();
  }

  void _finish() {
    setState(() {
      currentFocus = -1;
    });

    widget.finish();
  }

  @override
  void dispose() {
    _controllerPulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _afterLayout(Duration timeStamp) {
    _nextFocus();
  }
}
