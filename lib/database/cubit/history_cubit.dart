import 'package:bloc/bloc.dart';
import 'package:statemachine/statemachine.dart';

class HistoryCubit extends Cubit<State<String>> {
  HistoryCubit() : super(Machine<String>().newState(dummyStateLabel)) {
    // TODO(MrcsabaToth): define valid transitions
    stateMachine.start();

    final browsingState = stateMachine.newStartState(browsingStateLabel);

    stateMap = {
      browsingStateLabel: browsingState,
      playingStateLabel: stateMachine.newState(playingStateLabel),
    };

    browsingState.enter();
  }

  Machine<String> stateMachine = Machine<String>();
  static const String dummyStateLabel = 'dummy';
  static const String browsingStateLabel = 'browsing';
  static const String playingStateLabel = 'playing';

  Map<String, State<String>> stateMap = {};
  Map<String, int> stateIndexMap = {
    browsingStateLabel: 0,
    playingStateLabel: 1,
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
