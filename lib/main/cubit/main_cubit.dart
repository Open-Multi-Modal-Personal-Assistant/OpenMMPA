import 'package:bloc/bloc.dart';
import 'package:statemachine/statemachine.dart';

class MainCubit extends Cubit<State<String>> {
  MainCubit() : super(initialState) {
    stateMap['initial'] = initialState;
    waitingState = stateMachine.newState('waiting');
    stateMap['waiting'] = waitingState;
    recordingState = stateMachine.newState('recording');
    stateMap['recording'] = recordingState;
    sttState = stateMachine.newState('stt');
    stateMap['stt'] = sttState;
    llmState = stateMachine.newState('llm');
    stateMap['llm'] = llmState;
    ttsState = stateMachine.newState('tts');
    stateMap['tts'] = ttsState;
    playingState = stateMachine.newState('playing');
    stateMap['playing'] = playingState;
    // TODO(MrcsabaToth): define valid transitions
    stateMachine.start();
  }

  static Machine<String> stateMachine = Machine<String>();
  static State<String> initialState = stateMachine.newStartState('initial');
  late State<String> waitingState;
  late State<String> recordingState;
  late State<String> sttState;
  late State<String> llmState;
  late State<String> ttsState;
  late State<String> playingState;

  // late Machine<String> stateMachine;
  Map<String, State<String>> stateMap = {};

  void setState(String stateName) {
    final newState = stateMap[stateName];
    newState?.enter();
    if (newState != null) {
      emit(newState);
    }
  }

  State<String> getState() {
    return stateMachine.current ?? initialState;
  }
}
