import 'package:inspector_gadget/common/base_state.dart';

class HistoryState extends StateBase {
  HistoryState() : super(StateBase.browsingStateLabel) {
    final browsingState = newStartState(StateBase.browsingStateLabel);

    stateMap = {
      StateBase.browsingStateLabel: browsingState,
      StateBase.playingStateLabel: newState(StateBase.playingStateLabel),
      StateBase.errorStateLabel: newState(StateBase.errorStateLabel),
    };

    stateIndexMap = {
      StateBase.browsingStateLabel: 0,
      StateBase.ttsStateLabel: 1,
      StateBase.playingStateLabel: 2,
      StateBase.errorStateLabel: 3,
    };

    browsingState.enter();
  }
}
