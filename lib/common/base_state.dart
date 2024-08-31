import 'package:flutter/foundation.dart';
import 'package:statemachine/statemachine.dart';

abstract class StateBase extends Machine<String> with ChangeNotifier {
  StateBase(String defaultLabel) {
    StateBase.defaultStateLabel = defaultLabel;
    start();
  }

  static const String dummyStateLabel = 'dummy';
  static String defaultStateLabel = dummyStateLabel;
  static const String waitingStateLabel = 'waiting';
  static const String recordingStateLabel = 'recording';
  static const String sttStateLabel = 'stt';
  static const String llmStateLabel = 'llm';
  static const String ttsStateLabel = 'tts';
  static const String playingStateLabel = 'playing';
  static const String doneStateLabel = 'done';
  static const String errorStateLabel = 'error';
  static const String browsingStateLabel = 'browsing';

  Map<String, State<String>> stateMap = {};
  Map<String, int> stateIndexMap = {};

  String setState(String stateName) {
    final newState = stateMap[stateName];
    newState?.enter();
    if (newState != null) {
      notifyListeners();
      return newState.name;
    }

    return current?.name ?? defaultStateLabel;
  }

  String errorState() {
    return setState(errorStateLabel);
  }

  int get stateIndex => stateIndexMap[current?.name] ?? 0;
}
