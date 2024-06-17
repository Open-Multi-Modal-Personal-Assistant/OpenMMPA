import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:statemachine/statemachine.dart';

void main() {
  group('MainCubit', () {
    test('initial state is initialState', () {
      expect(MainCubit().state, equals(MainCubit.waitingState));
    });

    blocTest<MainCubit, State<String>>(
      'emits waiting when setState is called with waiting',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.waitingStateLabel),
      expect: () => [equals(MainCubit.waitingState)],
    );

    blocTest<MainCubit, State<String>>(
      'emits recording when setState is called with recording',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.recordingStateLabel),
      expect: () => [equals(MainCubit.recordingState)],
    );

    blocTest<MainCubit, State<String>>(
      'emits stt when setState is called with stt',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.sttStateLabel),
      expect: () => [equals(MainCubit.sttState)],
    );

    blocTest<MainCubit, State<String>>(
      'emits llm when setState is called with llm',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.llmStateLabel),
      expect: () => [equals(MainCubit.llmState)],
    );

    blocTest<MainCubit, State<String>>(
      'emits tts when setState is called with tts',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.ttsStateLabel),
      expect: () => [equals(MainCubit.ttsState)],
    );

    blocTest<MainCubit, State<String>>(
      'emits playing when setState is called with playing',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.playingStateLabel),
      expect: () => [equals(MainCubit.playingState)],
    );
  });
}
