import 'package:bloc/bloc.dart';
import 'package:statemachine/statemachine.dart';

class MainCubit extends Cubit<State<String>> {
  MainCubit() : super(Machine<String>().newState('dummy')) {
    // TODO(MrcsabaToth): define valid transitions
    stateMachine.start();

    final waitingState = stateMachine.newStartState(waitingStateLabel);
    // final recordingState = stateMachine.newState(recordingStateLabel);
    // final sttState = stateMachine.newState(sttStateLabel);
    // final llmState = stateMachine.newState(llmStateLabel);
    // final ttsState = stateMachine.newState(ttsStateLabel);
    // final playingState = stateMachine.newState(playingStateLabel);
    //
    // stateMap = {
    //   waitingStateLabel: waitingState,
    //   recordingStateLabel: recordingState,
    //   sttStateLabel: sttState,
    //   llmStateLabel: llmState,
    //   ttsStateLabel: ttsState,
    //   playingStateLabel: playingState,
    // };

    stateMap = {
      waitingStateLabel: waitingState,
      recordingStateLabel: stateMachine.newState(recordingStateLabel),
      sttStateLabel: stateMachine.newState(sttStateLabel),
      llmStateLabel: stateMachine.newState(llmStateLabel),
      ttsStateLabel: stateMachine.newState(ttsStateLabel),
      playingStateLabel: stateMachine.newState(playingStateLabel),
    };

    waitingState.enter();
  }

  Machine<String> stateMachine = Machine<String>();
  static const String waitingStateLabel = 'waiting';
  static const String recordingStateLabel = 'recording';
  static const String sttStateLabel = 'stt';
  static const String llmStateLabel = 'llm';
  static const String ttsStateLabel = 'tts';
  static const String playingStateLabel = 'playing';

  Map<String, State<String>> stateMap = {};
  Map<String, int> stateIndexMap = {
    waitingStateLabel: 0,
    recordingStateLabel: 1,
    sttStateLabel: 2,
    llmStateLabel: 3,
    ttsStateLabel: 4,
    playingStateLabel: 5,
  };

  String setState(String stateName) {
    final newState = stateMap[stateName];
    newState?.enter();
    if (newState != null) {
      emit(newState);
      return newState.name;
    }

    return stateMachine.current?.name ?? waitingStateLabel;
  }

  int getStateIndex() {
    return stateIndexMap[stateMachine.current?.name] ?? 0;
  }
}
