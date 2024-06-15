import 'package:bloc/bloc.dart';

import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

class CounterCubit extends Cubit<PreferencesState> {
  CounterCubit() : super(PreferencesState());

  void setApiKey(String apiKey) {
    state.setApiKey(apiKey);
    emit(state);
  }

  void setRemoteSpeechServices({
    bool areSpeechServicesRemote =
        PreferencesState.areSpeechServicesRemoteDefault,
  }) {
    state.setAreSpeechServicesRemote(
      areSpeechServicesRemote: areSpeechServicesRemote,
    );
    emit(state);
  }

  String getApiKey() {
    return state.apiKey;
  }

  bool getAreSpeechServicesRemote() {
    return state.areSpeechServicesRemote;
  }
}
