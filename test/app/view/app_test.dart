import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/app/view/app_view.dart';
import 'package:inspector_gadget/main/view/main_page.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  group('App', () {
    testWidgets('renders MainPage', (tester) async {
      final mockPreferences = MockPreferencesService();
      when(() => mockPreferences.themeMode).thenReturn(ThemeMode.system);
      when(() => mockPreferences.appLocale)
          .thenReturn(PreferencesService.appLocaleDefault);
      final mockPrefService = MockPrefService();
      when(() => mockPreferences.prefService).thenReturn(mockPrefService);
      GetIt.I.registerSingleton<PreferencesService>(mockPreferences);

      await tester.pumpWidget(const AppView());

      expect(find.byType(MainPage), findsOneWidget);
    });
  });
}
