import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:strings/strings.dart';

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
  static const String volumeTag = 'volume';
  static const int volumeMinimum = 0;
  static const int volumeDefault = 60;
  static const int volumeMaximum = 100;
  static const int volumedDivisions =
      volumeMaximum - volumeMinimum;
  static const String unitSystemTag = 'unit_system';
  static const bool unitSystemDefault = false;
  static const imperialCountries = ['US', 'UK', 'LR', 'MM'];
  static const String inputLocaleTag = 'input_locale';
  static const String inputLocaleDefault = 'en_US';
  static const String outputLocaleTag = 'output_locale';
  static const String outputLocaleDefault = 'en-US';
  static const String llmDebugModeTag = 'llm_debug_mode';
  static const bool llmDebugModeDefault = false;
  static const int pauseForDefault = 3;
  static const int listenForDefault = 60;
  static const String themeSelectionTag = 'theme_selection';
  static const String themeSelectionSystem = 'system';
  static const String themeSelectionLight = 'light';
  static const String themeSelectionDark = 'dark';
  static const String themeSelectionDefault = themeSelectionSystem;
  static const String prefix = 'ig'; // Inspector Gadget

  static Future<void> init() async {
    prefService = await PrefServiceShared.init(
      prefix: prefix,
      defaults: {
        geminiApiKeyTag: geminiApiKeyDefault,
        fastLlmModeTag: fastLlmModeDefault,
        alphaVantageAccessKeyTag: alphaVantageAccessKeyDefault,
        tavilyApiKeyTag: tavilyApiKeyDefault,
        areSpeechServicesNativeTag: areSpeechServicesNativeDefault,
        volumeTag: volumeDefault,
        unitSystemTag: getUnitSystemDefault(),
        inputLocaleTag: inputLocaleDefault,
        outputLocaleTag: outputLocaleDefault,
        llmDebugModeTag: llmDebugModeDefault,
        themeSelectionTag: themeSelectionDefault,
      },
    );

    final savedVolume = prefService?.get<int>(volumeTag) ?? volumeDefault;
    if (savedVolume < 0 || savedVolume > 100) {
      debugPrint('Out of bounds volume $savedVolume reset to $volumeDefault');
      prefService?.set(volumeTag, volumeDefault);
    }
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
  int get volume => prefService?.get<int>(volumeTag) ?? volumeDefault;
  bool get unitSystem =>
      prefService?.get<bool>(unitSystemTag) ?? getUnitSystemDefault();
  String get inputLocale =>
      prefService?.get<String>(inputLocaleTag) ?? inputLocaleDefault;
  String get outputLocale =>
      prefService?.get<String>(outputLocaleTag) ?? outputLocaleDefault;
  bool get llmDebugMode =>
      prefService?.get<bool>(llmDebugModeTag) ?? llmDebugModeDefault;
  ThemeMode themeSelection() {
    final theme =
        prefService?.get<String>(themeSelectionTag) ?? themeSelectionDefault;
    if (theme == themeSelectionLight) {
      return ThemeMode.light;
    } else if (theme == themeSelectionDark) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system;
    }
  }

  static bool getUnitSystemDefault() {
    final localeName = Platform.localeName;
    final deviceCountry = localeName.right(2).toUpperCase();
    return !imperialCountries.contains(deviceCountry);
  }
}
