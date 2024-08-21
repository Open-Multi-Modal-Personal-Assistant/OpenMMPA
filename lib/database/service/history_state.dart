import 'package:inspector_gadget/state_mixin.dart';

class HistoryState extends StateMixin {
  HistoryState() : super(browsingStateLabel) {
    final browsingState = newStartState(browsingStateLabel);

    stateMap = {
      browsingStateLabel: browsingState,
      playingStateLabel: newState(playingStateLabel),
    };

    stateIndexMap = {
      browsingStateLabel: 0,
      playingStateLabel: 1,
    };

    browsingState.enter();
  }

  static const String browsingStateLabel = 'browsing';
  static const String playingStateLabel = 'playing';
}
