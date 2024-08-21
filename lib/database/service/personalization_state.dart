import 'package:inspector_gadget/state_mixin.dart';

class PersonalizationState extends StateMixin {
  PersonalizationState() : super(browsingStateLabel) {
    final browsingState = newStartState(browsingStateLabel);

    stateMap = {
      browsingStateLabel: browsingState,
      playingStateLabel: newState(playingStateLabel),
      recordingStateLabel: newState(recordingStateLabel),
      processingStateLabel: newState(processingStateLabel),
      errorStateLabel: newState(errorStateLabel),
    };

    stateIndexMap = {
      browsingStateLabel: 0,
      playingStateLabel: 1,
      recordingStateLabel: 2,
      processingStateLabel: 3,
      errorStateLabel: 4,
    };

    browsingState.enter();
  }

  static const String browsingStateLabel = 'browsing';
  static const String playingStateLabel = 'playing';
  static const String recordingStateLabel = 'recording';
  static const String processingStateLabel = 'processing';
  static const String errorStateLabel = 'error';
}
