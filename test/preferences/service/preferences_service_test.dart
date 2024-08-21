import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';

void main() {
  group('PreferencesService', () {
    test('initial state is initialState', () {
      expect(
        PreferencesService().geminiApiKey,
        equals(PreferencesService.geminiApiKeyDefault),
      );

      expect(
        PreferencesService().areSpeechServicesNative,
        equals(PreferencesService.areSpeechServicesNativeDefault),
      );
    });
  });
}
