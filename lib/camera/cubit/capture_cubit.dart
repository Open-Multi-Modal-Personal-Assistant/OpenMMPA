import 'package:bloc/bloc.dart';
import 'package:statemachine/statemachine.dart';

class CaptureCubit extends Cubit<State<String>> {
  CaptureCubit() : super(Machine<String>().newState(dummyStateLabel)) {
    // TODO(MrcsabaToth): define valid transitions
    stateMachine.start();

    final previewState = stateMachine.newStartState(previewStateLabel);

    stateMap = {
      previewStateLabel: previewState,
      capturingStateLabel: stateMachine.newState(capturingStateLabel),
      capturedStateLabel: stateMachine.newState(capturedStateLabel),
    };

    previewState.enter();
  }

  Machine<String> stateMachine = Machine<String>();
  static const String dummyStateLabel = 'dummy';
  static const String previewStateLabel = 'preview';
  static const String capturingStateLabel = 'capturing';
  static const String capturedStateLabel = 'captured';

  Map<String, State<String>> stateMap = {};
  Map<String, int> stateIndexMap = {
    previewStateLabel: 0,
    capturingStateLabel: 1,
    capturedStateLabel: 2,
  };

  String setState(String stateName) {
    final newState = stateMap[stateName];
    newState?.enter();
    if (newState != null) {
      emit(newState);
      return newState.name;
    }

    return stateMachine.current?.name ?? previewStateLabel;
  }

  int getStateIndex() {
    return stateIndexMap[stateMachine.current?.name] ?? 0;
  }
}
