import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/ai/ai.dart';
import 'package:inspector_gadget/camera/cubit/image_cubit.dart';
import 'package:inspector_gadget/database/cubit/database_cubit.dart';
import 'package:inspector_gadget/database/object_box.dart';
import 'package:inspector_gadget/l10n/cubit/locale_cubit.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/main/cubit/main_cubit.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_cubit.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/stt/cubit/stt_state.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pref/pref.dart';
import 'package:statemachine/statemachine.dart' as sm;

import 'helpers.dart';

class MockState extends Mock implements sm.State<String> {}

class MockMainCubit extends MockCubit<sm.State<String>> implements MainCubit {}

class MockPreferencesState extends Mock implements PreferencesState {}

class MockPreferencesCubit extends MockCubit<PreferencesState>
    implements PreferencesCubit {}

class MockSttState extends Mock implements SttState {}

class MockSttCubit extends MockCubit<SttState> implements SttCubit {}

class MockTtsState extends Mock implements TtsState {}

class MockTtsCubit extends MockCubit<TtsState> implements TtsCubit {}

class MockAiCubit extends MockCubit<int> implements AiCubit {}

class MockDatabaseCubit extends MockCubit<ObjectBox?>
    implements DatabaseCubit {}

class MockLocaleCubit extends MockCubit<Locale> implements LocaleCubit {}

class MockImageCubit extends MockCubit<String> implements ImageCubit {}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    PreferencesState.prefService = MockPrefService();

    final sm.State<String> mainState = MockState();
    when(() => mainState.name).thenReturn(MainCubit.waitingStateLabel);
    final MainCubit mainCubit = MockMainCubit();
    when(() => mainCubit.state).thenReturn(mainState);
    when(() => mainCubit.setState(MainCubit.recordingStateLabel))
        .thenReturn(MainCubit.recordingStateLabel);
    when(mainCubit.getStateIndex).thenReturn(0);
    final PreferencesState preferencesState = MockPreferencesState();
    when(() => preferencesState.llmDebugMode).thenReturn(true);
    when(() => preferencesState.areSpeechServicesNative).thenReturn(true);
    when(() => preferencesState.appLocale)
        .thenReturn(PreferencesState.appLocaleDefault);
    final PreferencesCubit preferencesCubit = MockPreferencesCubit();
    when(() => preferencesCubit.state).thenReturn(preferencesState);
    final SttState sttState = MockSttState();
    when(() => sttState.localeNames).thenReturn([]);
    when(() => sttState.hasSpeech).thenReturn(true);
    final SttCubit sttCubit = MockSttCubit();
    when(() => sttCubit.state).thenReturn(sttState);
    final TtsState ttsState = MockTtsState();
    when(() => ttsState.languages).thenReturn([]);
    final TtsCubit ttsCubit = MockTtsCubit();
    when(() => ttsCubit.state).thenReturn(ttsState);
    final AiCubit aiCubit = MockAiCubit();
    final DatabaseCubit dbCubit = MockDatabaseCubit();
    final LocaleCubit localeCubit = MockLocaleCubit();
    final ImageCubit imageCubit = MockImageCubit();

    return pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => mainCubit),
          BlocProvider(create: (_) => preferencesCubit),
          BlocProvider(create: (_) => sttCubit),
          BlocProvider(create: (_) => ttsCubit),
          BlocProvider(create: (_) => aiCubit),
          BlocProvider(create: (_) => dbCubit),
          BlocProvider(create: (_) => localeCubit),
          BlocProvider(create: (_) => imageCubit),
        ],
        child: PrefService(
          service: PreferencesState.prefService!,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: /*BlocProvider.value(
            value: mainCubit,
            child: BlocProvider.value(
              value: preferencesCubit,
              child: BlocProvider.value(
                value: sttCubit,
                child: BlocProvider.value(
                  value: ttsCubit,
                  child:*/
                widget,
            //       ),
            //     ),
            //   ),
            // ),
          ),
        ),
      ),
    );
  }
}
