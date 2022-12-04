import 'package:flutter/widgets.dart';
import 'package:tutorial_coach_mark/src/target/target_focus.dart';
import 'package:tutorial_coach_mark/src/target/target_position.dart';

enum ShapeLightFocus { circle, rRect }

TargetPosition? getTargetCurrent(TargetFocus target) {
  if (target.keyTarget != null) {
    final key = target.keyTarget!;

    try {
      Offset offset = Offset.zero;
      Size size = Size.zero;

      final RenderBox? renderBoxRed =
          key.currentContext!.findRenderObject() as RenderBox?;

      if (renderBoxRed != null) {
        size = renderBoxRed.size;

        final state =
            key.currentContext!.findAncestorStateOfType<NavigatorState>();
        if (state != null) {
          offset = renderBoxRed.localToGlobal(
            Offset.zero,
            ancestor: state.context.findRenderObject(),
          );
        } else {
          offset = renderBoxRed.localToGlobal(Offset.zero);
        }
      }

      return TargetPosition(size, offset);
    } catch (e) {
      print(
        'TutorialCoachMark (ERROR): It was not possible to obtain target position.',
      );

      return null;
    }
  } else {
    return target.targetPosition;
  }
}

abstract class TutorialCoachMarkController {
  void next();
  void previous();
  void skip();
}

extension StateExt on State {
  void safeSetState(VoidCallback call) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(call);
    }
  }
}
