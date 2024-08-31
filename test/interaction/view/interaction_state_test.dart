import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/common/base_state.dart';
import 'package:inspector_gadget/interaction/service/interaction_state.dart';

void main() {
  group('Interaction State', () {
    test('Uninitialized state is the default (waiting)', () {
      expect(
        InteractionState().current!.name,
        equals(StateBase.waitingStateLabel),
      );
    });

    test('Dummy state superseded by default (waiting) after creation', () {
      final state = InteractionState()..setState(StateBase.dummyStateLabel);

      expect(state.current!.name, equals(StateBase.waitingStateLabel));
    });

    for (final label in [
      StateBase.waitingStateLabel,
      StateBase.recordingStateLabel,
      StateBase.sttStateLabel,
      StateBase.llmStateLabel,
      StateBase.ttsStateLabel,
      StateBase.playingStateLabel,
      StateBase.doneStateLabel,
      StateBase.errorStateLabel,
    ]) {
      test('State $label can be set', () {
        final state = InteractionState()..setState(label);

        expect(state.current!.name, equals(label));
      });
    }
  });
}
