import 'package:bloc/bloc.dart';
import 'package:statemachine/statemachine.dart';

class MainCubit extends Cubit<State<String>> {
  MainCubit() : super(waitingState) {
    // TODO(MrcsabaToth): define valid transitions
    stateMachine.start();
  }

  static Machine<String> stateMachine = Machine<String>();
  static const String waitingStateLabel = 'waiting';
  static const String recordingStateLabel = 'recording';
  static const String sttStateLabel = 'stt';
  static const String llmStateLabel = 'llm';
  static const String ttsStateLabel = 'tts';
  static const String playingStateLabel = 'playing';
  static State<String> waitingState =
      stateMachine.newStartState(waitingStateLabel);
  static State<String> recordingState =
      stateMachine.newStartState(recordingStateLabel);
  static State<String> sttState = stateMachine.newStartState(sttStateLabel);
  static State<String> llmState = stateMachine.newStartState(llmStateLabel);
  static State<String> ttsState = stateMachine.newStartState(ttsStateLabel);
  static State<String> playingState =
      stateMachine.newStartState(playingStateLabel);

  // late Machine<String> stateMachine;
  Map<String, State<String>> stateMap = {
    waitingStateLabel: waitingState,
    recordingStateLabel: recordingState,
    sttStateLabel: sttState,
    llmStateLabel: llmState,
    ttsStateLabel: ttsState,
    playingStateLabel: playingState,
  };

  void setState(String stateName) {
    final newState = stateMap[stateName];
    newState?.enter();
    if (newState != null) {
      emit(newState);
    }
  }

  State<String> getState() {
    return stateMachine.current ?? waitingState;
  }
}
