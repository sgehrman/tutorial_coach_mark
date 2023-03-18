import 'package:flutter/widgets.dart';
import 'package:tutorial_coach_mark/src/target/target_focus.dart';
import 'package:tutorial_coach_mark/src/target/target_position.dart';

enum ShapeLightFocus { circle, rRect }

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

// ===============================================================

class TargetManager {
  TargetManager(List<TargetFocus> targets) {
    for (final t in targets) {
      if (_isValidTarget(t)) {
        _targets.add(t);
      } else {
        print('target skipped: $t');
      }
    }
  }

  final List<TargetFocus> _targets = [];
  int _index = 0;

  static TargetPosition? getTargetPosition(TargetFocus target) {
    if (target.keyTarget != null) {
      final key = target.keyTarget!;

      if (key.currentContext != null) {
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
            'TutorialCoachMark (ERROR): It was not possible to obtain target position. $e',
          );

          return null;
        }
      }
    } else {
      return target.targetPosition;
    }

    return null;
  }

  TargetFocus currentFocus() {
    final TargetFocus? result = _targetForIndex(_index);

    // return BS since the code isn't structured well for null values
    return result ?? TargetFocus();
  }

  bool next() {
    final int index = _index + 1;

    if (index >= 0 && index < _targets.length) {
      _index = index;

      return true;
    }

    return false;
  }

  bool prev() {
    final int index = _index - 1;

    if (index >= 0 && index < _targets.length) {
      _index = index;

      return true;
    }

    return false;
  }

  // ===============================================================

  TargetFocus? _targetForIndex(int index) {
    if (index >= 0 && index < _targets.length) {
      return _targets[index];
    }

    return null;
  }

  static bool _isValidTarget(TargetFocus? focus) {
    if (focus == null) {
      return false;
    }

    final position = getTargetPosition(focus);

    return position != null;
  }
}
