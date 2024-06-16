import 'package:pref/pref.dart';

class PreferencesState {
  PreferencesState() {
    PrefServiceShared.init(
      prefix: prefix,
      defaults: {
        apiKeyTag: apiKeyDefault,
        areSpeechServicesRemoteTag: areSpeechServicesRemoteDefault,
      },
    ).then((ps) {
      prefService = ps;
    });
  }

  late PrefServiceShared prefService;

  static const String apiKeyTag = 'api_key';
  static const String apiKeyDefault = '';
  static const String areSpeechServicesRemoteTag = 'are_speech_services_remote';
  static const bool areSpeechServicesRemoteDefault = true;
  static const String prefix = 'ig';

  String get apiKey => prefService.get<String>(apiKeyTag) ?? apiKeyDefault;
  bool get areSpeechServicesRemote =>
      prefService.get<bool>(areSpeechServicesRemoteTag) ??
      areSpeechServicesRemoteDefault;

  // void setApiKey(String apiKey) {
  //   prefService.set<String>(apiKeyTag, apiKey);
  // }
  //
  // void setAreSpeechServicesRemote({
  //   bool areSpeechServicesRemote = areSpeechServicesRemoteDefault,
  // }) {
  //   prefService.set<bool>(areSpeechServicesRemoteTag,
  //        areSpeechServicesRemote);
  // }
}
