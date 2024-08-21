import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/preferences/view/preferences_page.dart';
import 'package:pref/pref.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/setup_services.dart';

void main() {
  setUpAll(() async {
    setUpServices();
  });

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
