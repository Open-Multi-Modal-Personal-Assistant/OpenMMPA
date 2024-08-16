import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:pref/pref.dart';

import '../../helpers/helpers.dart';

void main() {
  group('PreferencesPage', () {
    testWidgets('renders PreferencesView', (tester) async {
      await tester.pumpApp(const PreferencesPage());
      expect(find.byType(PreferencesPage), findsOneWidget);
    });
  });

  group('PreferencesView', () {
    testWidgets('renders preferences page', (tester) async {
      await tester.pumpApp(const PreferencesPage());
      expect(
        find.widgetWithText(PrefButton, 'Personalization'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(PrefButton, 'Chat History'),
        findsOneWidget,
      );
    });
  });
}
