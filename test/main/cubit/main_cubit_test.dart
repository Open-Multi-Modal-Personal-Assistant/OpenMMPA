import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:statemachine/statemachine.dart';

void main() {
  group('MainCubit', () {
    test('initial state is initialState', () {
      expect(MainCubit().state.name, equals(MainCubit.waitingStateLabel));
    });

    blocTest<MainCubit, State<String>>(
      'emits waiting when setState is called with waiting',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.waitingStateLabel),
      expect: () => [equals(MainCubit.waitingStateLabel)],
    );

    blocTest<MainCubit, State<String>>(
      'emits recording when setState is called with recording',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.recordingStateLabel),
      expect: () => [equals(MainCubit.recordingStateLabel)],
    );

    blocTest<MainCubit, State<String>>(
      'emits stt when setState is called with stt',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.sttStateLabel),
      expect: () => [equals(MainCubit.sttStateLabel)],
    );

    blocTest<MainCubit, State<String>>(
      'emits llm when setState is called with llm',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.llmStateLabel),
      expect: () => [equals(MainCubit.llmStateLabel)],
    );

    blocTest<MainCubit, State<String>>(
      'emits tts when setState is called with tts',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.ttsStateLabel),
      expect: () => [equals(MainCubit.ttsStateLabel)],
    );

    blocTest<MainCubit, State<String>>(
      'emits playing when setState is called with playing',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.playingStateLabel),
      expect: () => [equals(MainCubit.playingStateLabel)],
    );
  });
}
