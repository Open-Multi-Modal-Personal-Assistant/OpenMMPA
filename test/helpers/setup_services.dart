import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/ai/service/ai_service.dart';
import 'package:inspector_gadget/base_state.dart';
import 'package:inspector_gadget/camera/view/capture_state.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/database/service/personalization_state.dart';
import 'package:inspector_gadget/heart_rate/service/heart_rate.dart';
import 'package:inspector_gadget/interaction/service/interaction_state.dart';
import 'package:inspector_gadget/interaction/view/interaction_page.dart';
import 'package:inspector_gadget/location/service/location.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:statemachine/statemachine.dart' as sm;

import 'mock_preferences.dart';

class MockState extends Mock implements sm.State<String> {}

class MockInteractionState extends Mock implements InteractionState {}

class MockSttService extends Mock implements SttService {}

class MockSpeechToText extends Mock implements SpeechToText {}

class MockTtsService extends Mock implements TtsService {}

class MockAiService extends Mock implements AiService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockHeartRateService extends Mock implements HeartRateService {}

class MockLocationService extends Mock implements LocationService {}

class MockCaptureState extends Mock implements CaptureState {}

class MockPersonalizationState extends Mock implements PersonalizationState {}

MockPreferencesService setUpServices() {
  var mockPreferences = MockPreferencesService();
  if (!GetIt.I.isRegistered<PreferencesService>()) {
    when(() => mockPreferences.themeMode).thenReturn(ThemeMode.system);
    when(() => mockPreferences.llmDebugMode).thenReturn(true);
    when(() => mockPreferences.areSpeechServicesNative).thenReturn(true);
    when(() => mockPreferences.areNativeSpeechServicesLocal).thenReturn(false);
    when(() => mockPreferences.inputLocale)
        .thenReturn(PreferencesService.inputLocaleDefault);
    when(() => mockPreferences.outputLocale)
        .thenReturn(PreferencesService.outputLocaleDefault);
    when(() => mockPreferences.appLocale)
        .thenReturn(PreferencesService.appLocaleDefault);
    when(() => mockPreferences.detailedCameraControls)
        .thenReturn(PreferencesService.detailedCameraControlsDefault);
    final mockPrefService = MockPrefService();
    when(() => mockPreferences.prefService).thenReturn(mockPrefService);
    GetIt.I.registerSingleton<PreferencesService>(mockPreferences);
  } else {
    mockPreferences =
        GetIt.I.get<PreferencesService>() as MockPreferencesService;
  }

  if (!GetIt.I.isRegistered<InteractionState>()) {
    final sm.State<String> initialState = MockState();
    when(() => initialState.name).thenReturn(StateBase.waitingStateLabel);
    final InteractionState interactionState = MockInteractionState();
    when(() => interactionState.current).thenReturn(initialState);
    when(() => interactionState.setState(StateBase.waitingStateLabel))
        .thenReturn(StateBase.waitingStateLabel);
    when(() => interactionState.setState(StateBase.recordingStateLabel))
        .thenReturn(StateBase.recordingStateLabel);
    when(() => interactionState.setState(StateBase.llmStateLabel))
        .thenReturn(StateBase.llmStateLabel);
    when(() => interactionState.setState(StateBase.errorStateLabel))
        .thenReturn(StateBase.errorStateLabel);
    when(() => interactionState.stateIndex).thenReturn(0);
    GetIt.I.registerSingleton<InteractionState>(interactionState);
  }

  if (!GetIt.I.isRegistered<SttService>()) {
    final SpeechToText speechToText = MockSpeechToText();
    when(speechToText.listen).thenAnswer((_) async {
      return;
    });
    final SttService sttService = MockSttService();
    when(() => sttService.localeNames).thenReturn([]);
    when(() => sttService.hasSpeech).thenReturn(true);
    when(() => sttService.speech).thenReturn(speechToText);
    GetIt.I.registerSingleton<SttService>(sttService);
  }

  if (!GetIt.I.isRegistered<TtsService>()) {
    final TtsService ttsService = MockTtsService();
    when(() => ttsService.languages).thenReturn([]);
    when(() => ttsService.matchLanguage(PreferencesService.inputLocaleDefault))
        .thenReturn(PreferencesService.outputLocaleDefault);
    GetIt.I.registerSingleton<TtsService>(ttsService);
  }

  if (!GetIt.I.isRegistered<AiService>()) {
    final AiService aiService = MockAiService();
    final mockResponse = GenerateContentResponse(
      [
        Candidate(
          Content.text(''),
          [
            SafetyRating(
              HarmCategory.harassment,
              HarmProbability.negligible,
            ),
            SafetyRating(
              HarmCategory.hateSpeech,
              HarmProbability.negligible,
            ),
            SafetyRating(
              HarmCategory.sexuallyExplicit,
              HarmProbability.negligible,
            ),
            SafetyRating(
              HarmCategory.dangerousContent,
              HarmProbability.negligible,
            ),
          ],
          CitationMetadata([]),
          FinishReason.stop,
          '',
        ),
      ],
      null,
    );
    when(() => aiService.chatStep(InteractionPage.llmTestPrompt, ''))
        .thenAnswer((_) async {
      return mockResponse;
    });
    when(
      () => aiService.translate(
        InteractionPage.llmTestPrompt,
        PreferencesService.outputLocaleDefault,
      ),
    ).thenAnswer((_) async {
      return mockResponse;
    });
    GetIt.I.registerSingleton<AiService>(aiService);
  }

  if (!GetIt.I.isRegistered<DatabaseService>()) {
    GetIt.I.registerLazySingleton<DatabaseService>(MockDatabaseService.new);
  }

  if (!GetIt.I.isRegistered<HeartRateService>()) {
    GetIt.I.registerLazySingleton<HeartRateService>(MockHeartRateService.new);
  }

  if (!GetIt.I.isRegistered<LocationService>()) {
    final LocationService locationService = MockLocationService();
    final now = DateTime.now();
    final mockLocation = Location(
      latitude: 36.7420,
      longitude: -119.7702,
      accuracy: 0,
      altitude: 94,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      millisecondsSinceEpoch: now.millisecondsSinceEpoch.toDouble(),
      timestamp: now,
      isMock: true,
    );

    when(locationService.obtain).thenAnswer((_) async {
      return mockLocation;
    });

    GetIt.I.registerSingleton<LocationService>(locationService);
  }

  if (!GetIt.I.isRegistered<CaptureState>()) {
    final sm.State<String> initialState = MockState();
    when(() => initialState.name).thenReturn(CaptureState.previewStateLabel);
    final CaptureState captureState = MockCaptureState();
    when(() => captureState.current).thenReturn(initialState);
    when(() => captureState.setState(CaptureState.previewStateLabel))
        .thenReturn(CaptureState.previewStateLabel);
    when(() => captureState.stateIndex).thenReturn(0);
    GetIt.I.registerSingleton<CaptureState>(captureState);
  }

  if (!GetIt.I.isRegistered<PersonalizationState>()) {
    final sm.State<String> initialState = MockState();
    when(() => initialState.name).thenReturn(StateBase.browsingStateLabel);
    final PersonalizationState personalizationState =
        MockPersonalizationState();
    when(() => personalizationState.current).thenReturn(initialState);
    when(
      () => personalizationState.setState(StateBase.browsingStateLabel),
    ).thenReturn(StateBase.browsingStateLabel);
    when(() => personalizationState.stateIndex).thenReturn(0);
    GetIt.I.registerSingleton<PersonalizationState>(personalizationState);
  }

  return mockPreferences;
}
