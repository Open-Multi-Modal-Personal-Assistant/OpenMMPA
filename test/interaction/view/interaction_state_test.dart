import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/interaction/service/interaction_state.dart';

void main() {
  group('Interaction State', () {
    test('Uninitialized state is the default (waiting)', () {
      expect(
        InteractionState().current!.name,
        equals(InteractionState.waitingStateLabel),
      );
    });

    test('Dummy state superseded by default (waiting) after creation', () {
      final state = InteractionState()
        ..setState(InteractionState.dummyStateLabel);

      expect(state.current!.name, equals(InteractionState.waitingStateLabel));
    });

    for (final label in [
      InteractionState.waitingStateLabel,
      InteractionState.recordingStateLabel,
      InteractionState.sttStateLabel,
      InteractionState.llmStateLabel,
      InteractionState.ttsStateLabel,
      InteractionState.playingStateLabel,
      InteractionState.doneStateLabel,
      InteractionState.errorStateLabel,
    ]) {
      test('State $label can be set', () {
        final state = InteractionState()..setState(label);

        expect(state.current!.name, equals(label));
      });
    }
  });
}
