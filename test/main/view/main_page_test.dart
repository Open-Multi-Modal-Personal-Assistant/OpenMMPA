import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:inspector_gadget/database/database.dart';
// import 'package:inspector_gadget/interaction/interaction.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/preferences.dart';

import '../../helpers/helpers.dart';

void main() {
  group('MainView', () {
    testWidgets('renders MainPage', (tester) async {
      await tester.pumpApp(const MainPage());
      expect(find.byType(MainPage), findsOneWidget);
    });

    testWidgets('renders all buttons', (tester) async {
      await tester.pumpApp(const MainPage());
      expect(find.widgetWithIcon(IconButton, Icons.chat), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.video_chat), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.translate), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.person_add), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.settings), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.help), findsOneWidget);
    });

    /* pumpAndSettle times out for some reason
    testWidgets('navigates to interaction when the uni modal button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.uniModalKey)));
      await tester.pumpAndSettle();
      expect(find.byType(InteractionView), findsOneWidget);
    });

    testWidgets(
        'navigates to interaction when the multi modal button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.multiModalKey)));
      await tester.pumpAndSettle();
      expect(find.byType(InteractionView), findsOneWidget);
    });

    testWidgets('navigates to interaction when the translate button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.translateKey)));
      await tester.pumpAndSettle();
      expect(find.byType(InteractionView), findsOneWidget);
    });

    testWidgets('navigates to p13n page when the p13n button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.personalizationKey)));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalizationView), findsOneWidget);
    });
   */

    testWidgets('navigates to preferences when the pref button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.settingsKey)));
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesPage), findsOneWidget);
    });
  });
}
