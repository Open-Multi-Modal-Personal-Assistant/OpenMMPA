import 'dart:io';

import 'package:pref/pref.dart';

class PreferencesState {
  static BasePrefService? prefService;

  static const String geminiApiKeyTag = 'gemini_api_key';
  static const String geminiApiKeyDefault = '';
  static const String fastLlmModeTag = 'fast_llm_mode';
  static const bool fastLlmModeDefault = true;
  static const String alphaVantageAccessKeyTag = 'alpha_vantage_access_key';
  static const String alphaVantageAccessKeyDefault = '';
  static const String tavilyApiKeyTag = 'tavily_api_key';
  static const String tavilyApiKeyDefault = '';
  static const String areSpeechServicesNativeTag = 'are_speech_services_native';
  static const bool areSpeechServicesNativeDefault = false;
  static const String areSpeechServicesRemoteTag = 'are_speech_services_remote';
  static const bool areSpeechServicesRemoteDefault = true;
  static const String volumeTag = 'volume';
  static const int volumeDefault = 50;
  static const String unitSystemTag = 'unit_system';
  static const bool unitSystemDefault = false;
  static const imperialCountries = ['US', 'UK', 'LR', 'MM'];
  static const String inputLocaleTag = 'input_locale';
  static const String inputLocaleDefault = 'en';
  static const String outputLocaleTag = 'output_locale';
  static const String outputLocaleDefault = 'en';
  static const String llmDebugModeTag = 'llm_debug_mode';
  static const bool llmDebugModeDefault = false;
  static const int pauseForDefault = 3;
  static const int listenForDefault = 60;
  static const String prefix = 'ig';

  static Future<void> init() async {
    prefService = await PrefServiceShared.init(
      prefix: prefix,
      defaults: {
        geminiApiKeyTag: geminiApiKeyDefault,
        fastLlmModeTag: fastLlmModeDefault,
        alphaVantageAccessKeyTag: alphaVantageAccessKeyDefault,
        tavilyApiKeyTag: tavilyApiKeyDefault,
        areSpeechServicesNativeTag: areSpeechServicesNativeDefault,
        areSpeechServicesRemoteTag: areSpeechServicesRemoteDefault,
        volumeTag: volumeDefault,
        unitSystemTag: getUnitSystemDefault(),
        inputLocaleTag: inputLocaleDefault,
        outputLocaleTag: outputLocaleDefault,
        llmDebugModeTag: llmDebugModeDefault,
      },
    );
  }

  String get geminiApiKey =>
      prefService?.get<String>(geminiApiKeyTag) ?? geminiApiKeyDefault;
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
  bool get areSpeechServicesRemote =>
      prefService?.get<bool>(areSpeechServicesRemoteTag) ??
      areSpeechServicesRemoteDefault;
  int get volume => prefService?.get<int>(volumeTag) ?? volumeDefault;
  bool get unitSystem =>
      prefService?.get<bool>(unitSystemTag) ?? getUnitSystemDefault();
  String get inputLocale =>
      prefService?.get<String>(inputLocaleTag) ?? inputLocaleDefault;
  String get outputLocale =>
      prefService?.get<String>(outputLocaleTag) ?? outputLocaleDefault;
  bool get llmDebugMode =>
      prefService?.get<bool>(llmDebugModeTag) ?? llmDebugModeDefault;

  static bool getUnitSystemDefault() {
    final localeName = Platform.localeName;
    if (localeName.length < 5 || localeName[2] != '_') {
      return unitSystemDefault;
    }

    final deviceCountry = localeName.substring(3, 5);
    return !imperialCountries.contains(deviceCountry);
  }
}
