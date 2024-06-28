import 'package:pref/pref.dart';

class PreferencesState {
  static BasePrefService? prefService;

  static const String apiKeyTag = 'api_key';
  static const String apiKeyDefault = '';
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
        apiKeyTag: apiKeyDefault,
        areSpeechServicesNativeTag: areSpeechServicesNativeDefault,
        areSpeechServicesRemoteTag: areSpeechServicesRemoteDefault,
        inputLocaleTag: inputLocaleDefault,
        outputLocaleTag: outputLocaleDefault,
      },
    );
  }

  String get apiKey => prefService?.get<String>(apiKeyTag) ?? apiKeyDefault;
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
