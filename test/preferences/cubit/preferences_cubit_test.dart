import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/preferences/preferences.dart';

void main() {
  group('PreferencesCubit', () {
    test('initial state is initialState', () {
      expect(
        PreferencesCubit().state.geminiApiKey,
        equals(PreferencesState.geminiApiKeyDefault),
      );
      expect(
        PreferencesCubit().state.areSpeechServicesNative,
        equals(PreferencesState.areSpeechServicesNativeDefault),
      );
    });
  });
}
