import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';

void main() {
  group('PreferencesService', () {
    test('initial state is initialState', () {
      expect(
        PreferencesService().fastLlmMode,
        equals(PreferencesService.fastLlmModeDefault),
      );

      expect(
        PreferencesService().areSpeechServicesNative,
        equals(PreferencesService.areSpeechServicesNativeDefault),
      );
    });
  });
}
