import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:inspector_gadget/common/locale_ex.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/main/view/main_page.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:pref/pref.dart';
import 'package:watch_it/watch_it.dart';

class AppView extends StatelessWidget with WatchItMixin {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = GetIt.I.get<PreferencesService>();
    final themeMode = watchPropertyValue((PreferencesService s) => s.themeMode);
    final appLocale = watchPropertyValue((PreferencesService s) => s.appLocale);

    final localizationDelegates = [
      ...AppLocalizations.localizationsDelegates,
      const LocaleNamesLocalizationsDelegate(),
    ];

    return PrefService(
      service: preferences.prefService!,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FlexThemeData.light(
          scheme: FlexScheme.indigoM3,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        ),
        darkTheme: FlexThemeData.dark(
          scheme: FlexScheme.indigoM3,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        ),
        themeMode: themeMode,
        localizationsDelegates: localizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: LocaleEx.fromPreferences(appLocale),
        home: const MainPage(),
      ),
    );
  }
}
