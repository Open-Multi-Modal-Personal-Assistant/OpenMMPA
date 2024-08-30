import 'package:inspector_gadget/base_state.dart';

class InteractionState extends StateBase {
  InteractionState() : super(StateBase.waitingStateLabel) {
    final waitingState = newStartState(StateBase.waitingStateLabel);

    stateMap = {
      StateBase.waitingStateLabel: waitingState,
      StateBase.recordingStateLabel: newState(StateBase.recordingStateLabel),
      StateBase.sttStateLabel: newState(StateBase.sttStateLabel),
      StateBase.llmStateLabel: newState(StateBase.llmStateLabel),
      StateBase.ttsStateLabel: newState(StateBase.ttsStateLabel),
      StateBase.playingStateLabel: newState(StateBase.playingStateLabel),
      StateBase.doneStateLabel: newState(StateBase.doneStateLabel),
      StateBase.errorStateLabel: newState(StateBase.errorStateLabel),
    };

    stateIndexMap = {
      StateBase.waitingStateLabel: 0,
      StateBase.recordingStateLabel: 1,
      StateBase.sttStateLabel: 2,
      StateBase.llmStateLabel: 3,
      StateBase.ttsStateLabel: 4,
      StateBase.playingStateLabel: 5,
      StateBase.doneStateLabel: 6,
      StateBase.errorStateLabel: 7,
    };

    waitingState.enter();
  }
}
