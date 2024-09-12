import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/camera/view/camera_page.dart';
import 'package:inspector_gadget/database/view/personalization_page.dart';
import 'package:inspector_gadget/interaction/view/interaction_page.dart';
import 'package:inspector_gadget/main/view/main_page.dart';
import 'package:inspector_gadget/preferences/view/preferences_page.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/setup_services.dart';

void main() {
  setUpAll(() async {
    setUpServices();
  });

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

    testWidgets('navigates to interaction when the uni modal button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.uniModalKey)));
      await tester.pumpAndSettleEx();

      expect(find.byType(InteractionPage), findsOneWidget);
    });

    testWidgets(
        'navigates to camera page when the multi modal button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.multiModalKey)));
      await tester.pumpAndSettleEx();

      expect(find.byType(CameraPage), findsOneWidget);
    });

    testWidgets('navigates to interaction when the translate button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.translateKey)));
      await tester.pumpAndSettleEx();

      expect(find.byType(InteractionPage), findsOneWidget);
    });

    testWidgets('navigates to p13n page when the p13n button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.personalizationKey)));
      await tester.pumpAndSettleEx();

      expect(find.byType(PersonalizationPage), findsOneWidget);
    });

    testWidgets('navigates to preferences when the pref button is tapped',
        (tester) async {
      await tester.pumpApp(const MainPage());
      await tester.tap(find.byKey(const Key(MainPage.settingsKey)));
      await tester.pumpAndSettleEx();

      expect(find.byType(PreferencesPage), findsOneWidget);
    });
  });
}
