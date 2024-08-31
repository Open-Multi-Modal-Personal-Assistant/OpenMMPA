import 'package:inspector_gadget/common/base_state.dart';

class PersonalizationState extends StateBase {
  PersonalizationState() : super(StateBase.browsingStateLabel) {
    final browsingState = newStartState(StateBase.browsingStateLabel);

    stateMap = {
      StateBase.browsingStateLabel: browsingState,
      StateBase.playingStateLabel: newState(StateBase.playingStateLabel),
      StateBase.recordingStateLabel: newState(StateBase.recordingStateLabel),
      StateBase.llmStateLabel: newState(StateBase.llmStateLabel),
      StateBase.errorStateLabel: newState(StateBase.errorStateLabel),
    };

    stateIndexMap = {
      StateBase.browsingStateLabel: 0,
      StateBase.playingStateLabel: 1,
      StateBase.recordingStateLabel: 2,
      StateBase.llmStateLabel: 3,
      StateBase.errorStateLabel: 4,
    };

    browsingState.enter();
  }
}
