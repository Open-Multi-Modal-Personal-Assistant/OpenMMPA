import 'package:inspector_gadget/state_mixin.dart';

class InteractionState extends StateMixin {
  InteractionState() : super(waitingStateLabel) {
    final waitingState = newStartState(waitingStateLabel);

    stateMap = {
      waitingStateLabel: waitingState,
      recordingStateLabel: newState(recordingStateLabel),
      sttStateLabel: newState(sttStateLabel),
      llmStateLabel: newState(llmStateLabel),
      ttsStateLabel: newState(ttsStateLabel),
      playingStateLabel: newState(playingStateLabel),
      doneStateLabel: newState(doneStateLabel),
      errorStateLabel: newState(errorStateLabel),
    };

    stateIndexMap = {
      waitingStateLabel: 0,
      recordingStateLabel: 1,
      sttStateLabel: 2,
      llmStateLabel: 3,
      ttsStateLabel: 4,
      playingStateLabel: 5,
      doneStateLabel: 6,
      errorStateLabel: 7,
    };

    waitingState.enter();
  }

  static const String dummyStateLabel = 'dummy';
  static const String waitingStateLabel = 'waiting';
  static const String recordingStateLabel = 'recording';
  static const String sttStateLabel = 'stt';
  static const String llmStateLabel = 'llm';
  static const String ttsStateLabel = 'tts';
  static const String playingStateLabel = 'playing';
  static const String doneStateLabel = 'done';
  static const String errorStateLabel = 'error';
}
