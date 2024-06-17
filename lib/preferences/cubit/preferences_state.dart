import 'package:pref/pref.dart';

class PreferencesState {
  static PrefServiceShared? prefService;

  static const String apiKeyTag = 'api_key';
  static const String apiKeyDefault = '';
  static const String areSpeechServicesRemoteTag = 'are_speech_services_remote';
  static const bool areSpeechServicesRemoteDefault = true;
  static const String prefix = 'ig';

  static Future<void> init() async {
    prefService = await PrefServiceShared.init(
      prefix: prefix,
      defaults: {
        apiKeyTag: apiKeyDefault,
        areSpeechServicesRemoteTag: areSpeechServicesRemoteDefault,
      },
    );
  }

  String get apiKey => prefService?.get<String>(apiKeyTag) ?? apiKeyDefault;
  bool get areSpeechServicesRemote =>
      prefService?.get<bool>(areSpeechServicesRemoteTag) ??
      areSpeechServicesRemoteDefault;
}
