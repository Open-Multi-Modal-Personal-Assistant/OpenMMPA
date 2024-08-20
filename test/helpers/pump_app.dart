import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/ai/service/ai_service.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/interaction/service/interaction_state.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pref/pref.dart';
import 'package:statemachine/statemachine.dart' as sm;

import 'helpers.dart';

class MockState extends Mock implements sm.State<String> {}

class MockInteractionState extends Mock implements InteractionState {}

class MockPreferencesService extends Mock implements PreferencesService {}

class MockSttService extends Mock implements SttService {}

class MockTtsService extends Mock implements TtsService {}

class MockAiService extends Mock implements AiService {}

class MockDatabaseService extends Mock implements DatabaseService {}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    final mockPreferences = MockPreferencesService();
    when(() => mockPreferences.themeMode).thenReturn(ThemeMode.system);
    when(() => mockPreferences.llmDebugMode).thenReturn(true);
    when(() => mockPreferences.areSpeechServicesNative).thenReturn(true);
    when(() => mockPreferences.appLocale)
        .thenReturn(PreferencesService.appLocaleDefault);
    final mockPrefService = MockPrefService();
    when(() => mockPreferences.prefService).thenReturn(mockPrefService);
    GetIt.I.registerSingleton<PreferencesService>(mockPreferences);

    final sm.State<String> initialState = MockState();
    when(() => initialState.name)
        .thenReturn(InteractionState.waitingStateLabel);
    final InteractionState interactionState = MockInteractionState();
    when(() => interactionState.current).thenReturn(initialState);
    when(() => interactionState.setState(InteractionState.recordingStateLabel))
        .thenReturn(InteractionState.recordingStateLabel);
    when(() => interactionState.stateIndex).thenReturn(0);
    GetIt.I.registerSingleton<InteractionState>(interactionState);

    final SttService sttService = MockSttService();
    when(() => sttService.localeNames).thenReturn([]);
    when(() => sttService.hasSpeech).thenReturn(true);
    GetIt.I.registerSingleton<SttService>(sttService);

    final TtsService ttsService = MockTtsService();
    when(() => ttsService.languages).thenReturn([]);
    GetIt.I.registerSingleton<TtsService>(ttsService);

    final AiService aiService = MockAiService();
    GetIt.I.registerSingleton<AiService>(aiService);

    final DatabaseService dbService = MockDatabaseService();
    GetIt.I.registerSingleton<DatabaseService>(dbService);

    return pumpWidget(
      PrefService(
        service: mockPreferences.prefService!,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget,
        ),
      ),
    );
  }
}
