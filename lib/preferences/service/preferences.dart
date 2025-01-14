import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:strings/strings.dart';

class PreferencesService with ChangeNotifier {
  static const String fastLlmModeTag = 'fast_llm_mode';
  static const bool fastLlmModeDefault = true;
  static const String alphaVantageAccessKeyTag = 'alpha_vantage_access_key';
  static const String alphaVantageAccessKeyDefault = '';
  static const String tavilyApiKeyTag = 'tavily_api_key';
  static const String tavilyApiKeyDefault = '';
  static const String areSpeechServicesNativeTag = 'are_speech_services_native';
  static const bool areSpeechServicesNativeDefault = false;
  static const String areNativeSpeechServicesLocalTag =
      'are_native_speech_services_local';
  static const bool areNativeSpeechServicesLocalDefault = false;
  static const String volumeTag = 'volume';
  static const int volumeMinimum = 0;
  static const int volumeDefault = 60;
  static const int volumeMaximum = 100;
  static const int volumedDivisions = (volumeMaximum - volumeMinimum + 1) ~/ 5;
  static const String unitSystemTag = 'unit_system';
  static const bool unitSystemDefault = false;
  static const imperialCountries = ['US', 'UK', 'LR', 'MM'];
  static const String localeLanguageDefault = 'en';
  static const String localeCountryDefault = 'US';
  static const String inputLocaleTag = 'input_locale';
  static const String inputLocaleDefault =
      '$localeLanguageDefault-$localeCountryDefault';
  static const String outputLocaleTag = 'output_locale';
  static const String outputLocaleDefault = inputLocaleDefault;
  static const String appLocaleTag = 'app_locale';
  static const String appLocaleDefault = inputLocaleDefault;
  static const String llmDebugModeTag = 'llm_debug_mode';
  static const bool llmDebugModeDefault = false;
  static const int pauseForDefault = 10;
  static const int listenForDefault = 60;
  static const String themeSelectionTag = 'theme_selection';
  static const String themeSelectionSystem = 'system';
  static const String themeSelectionLight = 'light';
  static const String themeSelectionDark = 'dark';
  static const String themeSelectionDefault = themeSelectionSystem;
  static const int ragThresholdMinimum = 0;
  static const int ragThresholdDefault = 170;
  static const int ragThresholdMaximum = 300;
  static const int ragThresholdDivisions =
      (ragThresholdMaximum - ragThresholdMinimum + 1) ~/ 10;
  static const String personalizationRagThresholdTag =
      'personalization_rag_threshold';
  static const String historyRagThresholdTag = 'history_rag_threshold';
  static const String harmBlockThresholdUnspecified =
      'HARM_BLOCK_THRESHOLD_UNSPECIFIED';
  static const String harmBlockThresholdLow = 'HARM_BLOCK_THRESHOLD_LOW';
  static const String harmBlockThresholdMedium = 'HARM_BLOCK_THRESHOLD_MEDIUM';
  static const String harmBlockThresholdHigh = 'HARM_BLOCK_THRESHOLD_HIGH';
  static const String harmBlockThresholdNone = 'HARM_BLOCK_THRESHOLD_NONE';
  static const String harmCategoryUnspecifiedTag = 'HARM_CATEGORY_UNSPECIFIED';
  static const String harmCategoryHarassmentTag = 'HARM_CATEGORY_HARASSMENT';
  static const String harmCategoryHateSpeechTag = 'HARM_CATEGORY_HATE_SPEECH';
  static const String harmCategorySexuallyExplicitTag =
      'HARM_CATEGORY_SEXUALLY_EXPLICIT';
  static const String harmCategoryDangerousContentTag =
      'HARM_CATEGORY_DANGEROUS_CONTENT';
  static const String harmCategoryHarassmentDefault = harmBlockThresholdNone;
  static const String harmCategoryHateSpeechDefault = harmBlockThresholdNone;
  static const String harmCategorySexuallyExplicitDefault =
      harmBlockThresholdHigh;
  static const String harmCategoryDangerousContentDefault =
      harmBlockThresholdNone;
  static const String classicGoogleTranslateTag = 'classic_google_translate';
  static const bool classicGoogleTranslateDefault = false;
  static const String cameraResolutionTag = 'camera_resolution';
  static const String cameraResolutionDefault = cameraResolutionMedium;
  static const String cameraResolutionLow = 'low';
  static const String cameraResolutionMedium = 'medium';
  static const String cameraResolutionHigh = 'high';
  static const String cameraResolutionVeryHigh = 'veryHigh';
  static const String measureHeartRateTag = 'measure_heart_rate';
  static const bool measureHeartRateDefault = false;

  final String prefix = 'ommpa'; // Inspector Gadget

  BasePrefService? prefService;

  Future<PreferencesService> init() async {
    prefService = await PrefServiceShared.init(
      prefix: prefix,
      defaults: {
        fastLlmModeTag: fastLlmModeDefault,
        alphaVantageAccessKeyTag: alphaVantageAccessKeyDefault,
        tavilyApiKeyTag: tavilyApiKeyDefault,
        areSpeechServicesNativeTag: areSpeechServicesNativeDefault,
        areNativeSpeechServicesLocalTag: areNativeSpeechServicesLocalDefault,
        volumeTag: volumeDefault,
        unitSystemTag: getUnitSystemDefault(),
        inputLocaleTag: inputLocaleDefault,
        outputLocaleTag: outputLocaleDefault,
        appLocaleTag: appLocaleDefault,
        llmDebugModeTag: llmDebugModeDefault,
        themeSelectionTag: themeSelectionDefault,
        personalizationRagThresholdTag: ragThresholdDefault,
        historyRagThresholdTag: ragThresholdDefault,
        harmCategoryHarassmentTag: harmCategoryHarassmentDefault,
        harmCategoryHateSpeechTag: harmCategoryHateSpeechDefault,
        harmCategorySexuallyExplicitTag: harmCategoryHarassmentDefault,
        harmCategoryDangerousContentTag: harmCategorySexuallyExplicitDefault,
        classicGoogleTranslateTag: classicGoogleTranslateDefault,
        cameraResolutionTag: cameraResolutionDefault,
        measureHeartRateTag: measureHeartRateDefault,
      },
    );

    final savedVolume = prefService?.get<int>(volumeTag) ?? volumeDefault;
    if (savedVolume < 0 || savedVolume > 100) {
      debugPrint('Out of bounds volume $savedVolume reset to $volumeDefault');
      prefService?.set(volumeTag, volumeDefault);
    }

    return this;
  }

  bool get fastLlmMode =>
      prefService?.get<bool>(fastLlmModeTag) ?? fastLlmModeDefault;
  String get alphaVantageAccessKey =>
      prefService?.get<String>(alphaVantageAccessKeyTag) ??
      alphaVantageAccessKeyDefault;
  String get tavilyApiKey =>
      prefService?.get<String>(tavilyApiKeyTag) ?? tavilyApiKeyDefault;
  bool get areSpeechServicesNative =>
      prefService?.get<bool>(areSpeechServicesNativeTag) ??
      areSpeechServicesNativeDefault;
  bool get areNativeSpeechServicesLocal =>
      prefService?.get<bool>(areNativeSpeechServicesLocalTag) ??
      areNativeSpeechServicesLocalDefault;
  int get volume => prefService?.get<int>(volumeTag) ?? volumeDefault;
  bool get unitSystem =>
      prefService?.get<bool>(unitSystemTag) ?? getUnitSystemDefault();
  String get inputLocale =>
      prefService?.get<String>(inputLocaleTag) ?? inputLocaleDefault;
  String get outputLocale =>
      prefService?.get<String>(outputLocaleTag) ?? outputLocaleDefault;
  String get appLocale =>
      prefService?.get<String>(appLocaleTag) ?? appLocaleDefault;
  bool get llmDebugMode =>
      prefService?.get<bool>(llmDebugModeTag) ?? llmDebugModeDefault;
  HarmBlockThreshold get harmCategoryHarassment => getHarmBlockThreshold(
        prefService?.get<String>(harmCategoryHarassmentTag) ??
            harmCategoryHarassmentDefault,
      );
  HarmBlockThreshold get harmCategoryHateSpeech => getHarmBlockThreshold(
        prefService?.get<String>(harmCategoryHateSpeechTag) ??
            harmCategoryHateSpeechDefault,
      );
  HarmBlockThreshold get harmCategorySexuallyExplicit => getHarmBlockThreshold(
        prefService?.get<String>(harmCategorySexuallyExplicitTag) ??
            harmCategorySexuallyExplicitDefault,
      );
  HarmBlockThreshold get harmCategoryDangerousContent => getHarmBlockThreshold(
        prefService?.get<String>(harmCategoryDangerousContentTag) ??
            harmCategoryDangerousContentDefault,
      );
  bool get classicGoogleTranslate =>
      prefService?.get<bool>(classicGoogleTranslateTag) ??
      classicGoogleTranslateDefault;
  String get theme =>
      prefService?.get<String>(themeSelectionTag) ?? themeSelectionDefault;
  ThemeMode get themeMode => switch (theme) {
        themeSelectionLight => ThemeMode.light,
        themeSelectionDark => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  HarmBlockThreshold getHarmBlockThreshold(String harmBlockThreshold) =>
      switch (harmBlockThreshold) {
        harmBlockThresholdLow => HarmBlockThreshold.low,
        harmBlockThresholdMedium => HarmBlockThreshold.medium,
        harmBlockThresholdHigh => HarmBlockThreshold.high,
        harmBlockThresholdNone => HarmBlockThreshold.none,
        _ => HarmBlockThreshold.none,
      };

  double get personalizationRagThreshold =>
      (prefService?.get<int>(personalizationRagThresholdTag) ??
          ragThresholdDefault) /
      100.0;
  double get historyRagThreshold =>
      (prefService?.get<int>(historyRagThresholdTag) ?? ragThresholdDefault) /
      100.0;

  bool get measureHeartRate =>
      prefService?.get<bool>(measureHeartRateTag) ?? measureHeartRateDefault;

  static bool getUnitSystemDefault() {
    final localeName = Platform.localeName;
    final deviceCountry = localeName.right(2).toUpperCase();
    return !imperialCountries.contains(deviceCountry);
  }

  void setOutputLocale(String locale) {
    if (locale.isNotEmpty) {
      prefService?.set<String>(outputLocaleTag, locale);
    }
  }

  String get cameraResolution =>
      prefService?.get<String>(cameraResolutionTag) ?? cameraResolutionDefault;
  ResolutionPreset get cameraResolutionPreset => switch (cameraResolution) {
        cameraResolutionVeryHigh => ResolutionPreset.veryHigh,
        cameraResolutionHigh => ResolutionPreset.high,
        cameraResolutionMedium => ResolutionPreset.medium,
        _ => ResolutionPreset.low // also low
      };

  void emit() {
    notifyListeners();
  }
}
