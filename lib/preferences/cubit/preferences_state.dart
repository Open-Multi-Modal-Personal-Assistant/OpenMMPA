import 'package:pref/pref.dart';

class PreferencesState {
  static BasePrefService? prefService;

  static const String geminiApiKeyTag = 'gemini_api_key';
  static const String geminiApiKeyDefault = '';
  static const String alphaVantageAccessKeyTag = 'alpha_vantage_access_key';
  static const String alphaVantageAccessKeyDefault = '';
  static const String tavilyApiKeyTag = 'tavily_api_key';
  static const String tavilyApiKeyDefault = '';
  static const String areSpeechServicesNativeTag = 'are_speech_services_native';
  static const bool areSpeechServicesNativeDefault = false;
  static const String areSpeechServicesRemoteTag = 'are_speech_services_remote';
  static const bool areSpeechServicesRemoteDefault = true;
  static const String inputLocaleTag = 'input_locale';
  static const String inputLocaleDefault = 'en';
  static const String outputLocaleTag = 'output_locale';
  static const String outputLocaleDefault = 'en';
  static const int pauseForDefault = 3;
  static const int listenForDefault = 60;
  static const String prefix = 'ig';

  static Future<void> init() async {
    prefService = await PrefServiceShared.init(
      prefix: prefix,
      defaults: {
        geminiApiKeyTag: geminiApiKeyDefault,
        alphaVantageAccessKeyTag: alphaVantageAccessKeyDefault,
        tavilyApiKeyTag: tavilyApiKeyDefault,
        areSpeechServicesNativeTag: areSpeechServicesNativeDefault,
        areSpeechServicesRemoteTag: areSpeechServicesRemoteDefault,
        inputLocaleTag: inputLocaleDefault,
        outputLocaleTag: outputLocaleDefault,
      },
    );
  }

  String get geminiApiKey =>
      prefService?.get<String>(geminiApiKeyTag) ?? geminiApiKeyDefault;
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
  String get inputLocale =>
      prefService?.get<String>(inputLocaleTag) ?? inputLocaleDefault;
  String get outputLocale =>
      prefService?.get<String>(outputLocaleTag) ?? outputLocaleDefault;
}
