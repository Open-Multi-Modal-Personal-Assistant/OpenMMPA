import 'package:bloc/bloc.dart';

import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit() : super(PreferencesState());

  void emitState() {
    emit(state);
  }

  String getApiKey() {
    return state.apiKey;
  }

  bool getAreSpeechServicesRemote() {
    return state.areSpeechServicesRemote;
  }

  String getInputLocale() {
    return state.inputLocale;
  }

  String getOutputLocale() {
    return state.outputLocale;
  }
}
