import 'package:bloc/bloc.dart';
import 'package:statemachine/statemachine.dart';

class PersonalizationCubit extends Cubit<State<String>> {
  PersonalizationCubit() : super(Machine<String>().newState(dummyStateLabel)) {
    // TODO(MrcsabaToth): define valid transitions
    stateMachine.start();

    final browsingState = stateMachine.newStartState(browsingStateLabel);

    stateMap = {
      browsingStateLabel: browsingState,
      playingStateLabel: stateMachine.newState(playingStateLabel),
      recordingStateLabel: stateMachine.newState(recordingStateLabel),
      processingStateLabel: stateMachine.newState(processingStateLabel),
      errorStateLabel: stateMachine.newState(errorStateLabel),
    };

    browsingState.enter();
  }

  Machine<String> stateMachine = Machine<String>();
  static const String dummyStateLabel = 'dummy';
  static const String browsingStateLabel = 'browsing';
  static const String playingStateLabel = 'playing';
  static const String recordingStateLabel = 'recording';
  static const String processingStateLabel = 'processing';
  static const String errorStateLabel = 'error';

  Map<String, State<String>> stateMap = {};
  Map<String, int> stateIndexMap = {
    browsingStateLabel: 0,
    playingStateLabel: 1,
    recordingStateLabel: 2,
    processingStateLabel: 3,
    errorStateLabel: 4,
  };

  String setState(String stateName) {
    final newState = stateMap[stateName];
    newState?.enter();
    if (newState != null) {
      emit(newState);
      return newState.name;
    }

    return stateMachine.current?.name ?? browsingStateLabel;
  }

  int getStateIndex() {
    return stateIndexMap[stateMachine.current?.name] ?? 0;
  }
}
