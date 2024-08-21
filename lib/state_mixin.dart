import 'package:flutter/foundation.dart';
import 'package:statemachine/statemachine.dart';

class StateMixin extends Machine<String> with ChangeNotifier {
  StateMixin(String defaultLabel) {
    StateMixin.defaultStateLabel = defaultLabel;
    start();
  }

  static const String dummyStateLabel = 'dummy';
  static String defaultStateLabel = dummyStateLabel;

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

  int get stateIndex => stateIndexMap[current?.name] ?? 0;
}
