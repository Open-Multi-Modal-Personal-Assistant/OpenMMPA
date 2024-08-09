import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:pref/pref.dart';

import '../../helpers/helpers.dart';

void main() {
  group('PreferencesPage', () {
    testWidgets('renders PreferencesView', (tester) async {
      await tester.pumpApp(const PreferencesView());
      expect(find.byType(PreferencesView), findsOneWidget);
    });
  });

  group('PreferencesView', () {
    testWidgets('renders preferences page', (tester) async {
      await tester.pumpApp(const PreferencesView());
      expect(find.widgetWithText(PrefText, 'Gemini API Key'), findsOneWidget);
      expect(
        find.widgetWithText(PrefCheckbox, 'TTS / STT Native?'),
        findsOneWidget,
      );
    });
  });
}
