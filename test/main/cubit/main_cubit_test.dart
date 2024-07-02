import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:statemachine/statemachine.dart';

void main() {
  group('MainCubit', () {
    test('initial state is initialState', () {
      expect(MainCubit().state.name, equals(MainCubit.dummyStateLabel));
    });

    blocTest<MainCubit, State<String>>(
      'emits waiting when setState is called with waiting',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.waitingStateLabel),
      expect: () => [
        isA<State<String>>()
            .having((s0) => s0.name, 'name', MainCubit.waitingStateLabel),
      ],
    );

    blocTest<MainCubit, State<String>>(
      'emits recording when setState is called with recording',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.recordingStateLabel),
      expect: () => [
        isA<State<String>>()
            .having((s0) => s0.name, 'name', MainCubit.recordingStateLabel),
      ],
    );

    blocTest<MainCubit, State<String>>(
      'emits stt when setState is called with stt',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.sttStateLabel),
      expect: () => [
        isA<State<String>>()
            .having((s0) => s0.name, 'name', MainCubit.sttStateLabel),
      ],
    );

    blocTest<MainCubit, State<String>>(
      'emits llm when setState is called with llm',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.llmStateLabel),
      expect: () => [
        isA<State<String>>()
            .having((s0) => s0.name, 'name', MainCubit.llmStateLabel),
      ],
    );

    blocTest<MainCubit, State<String>>(
      'emits tts when setState is called with tts',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.ttsStateLabel),
      expect: () => [
        isA<State<String>>()
            .having((s0) => s0.name, 'name', MainCubit.ttsStateLabel),
      ],
    );

    blocTest<MainCubit, State<String>>(
      'emits playing when setState is called with playing',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.playingStateLabel),
      expect: () => [
        isA<State<String>>()
            .having((s0) => s0.name, 'name', MainCubit.playingStateLabel),
      ],
    );

    blocTest<MainCubit, State<String>>(
      'emits error when setState is called with error',
      build: MainCubit.new,
      act: (cubit) => cubit.setState(MainCubit.errorStateLabel),
      expect: () => [
        isA<State<String>>()
            .having((s0) => s0.name, 'name', MainCubit.errorStateLabel),
      ],
    );
  });
}
