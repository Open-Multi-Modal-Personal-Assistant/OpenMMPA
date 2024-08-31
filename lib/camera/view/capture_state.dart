import 'package:inspector_gadget/common/base_state.dart';

class CaptureState extends StateBase {
  CaptureState() : super(previewStateLabel) {
    final previewState = newStartState(previewStateLabel);

    stateMap = {
      previewStateLabel: previewState,
      capturingStateLabel: newState(capturingStateLabel),
      capturedStateLabel: newState(capturedStateLabel),
    };

    stateIndexMap = {
      previewStateLabel: 0,
      capturingStateLabel: 1,
      capturedStateLabel: 2,
    };

    previewState.enter();
  }

  static const String previewStateLabel = 'preview';
  static const String capturingStateLabel = 'capturing';
  static const String capturedStateLabel = 'captured';
}
