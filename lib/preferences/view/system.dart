import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/locale_ex.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:pref/pref.dart';

class SystemPreferencesPage extends StatelessWidget {
  const SystemPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeNames = LocaleNames.of(context);
    final preferences = GetIt.I.get<PreferencesService>();

    final systemPreferences = <Widget>[
      PrefCheckbox(
        title: Text(l10n.preferencesUnitSystemLabel),
        subtitle: Text(l10n.preferencesUnitSystemDescription),
        pref: PreferencesService.unitSystemTag,
      ),
      PrefLabel(title: Text(l10n.themeSelectionLabel)),
      PrefRadio<String>(
        title: Text(l10n.themeSelectionSystemLabel),
        value: PreferencesService.themeSelectionSystem,
        pref: PreferencesService.themeSelectionTag,
      ),
      PrefRadio<String>(
        title: Text(l10n.themeSelectionLightLabel),
        value: PreferencesService.themeSelectionLight,
        pref: PreferencesService.themeSelectionTag,
      ),
      PrefRadio<String>(
        title: Text(l10n.themeSelectionDarkLabel),
        value: PreferencesService.themeSelectionDark,
        pref: PreferencesService.themeSelectionTag,
      ),
      const PrefLabel(title: Divider(height: 1)),
      PrefLabel(title: Text(l10n.localeSelectionLabel)),
    ];

    for (final locale in AppLocalizations.supportedLocales) {
      systemPreferences.add(
        PrefRadio<String>(
          title: ListTile(
            leading: CountryFlag.fromLanguageCode(locale.languageCode),
            title: Text(localeNames?.nameOf(locale.languageCode) ?? '??'),
            contentPadding: const EdgeInsetsDirectional.only(start: 1, end: 1),
          ),
          value: locale.preferencesString(),
          pref: PreferencesService.appLocaleTag,
          onSelect: preferences.emit,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesSystemLabel)),
      body: PrefPage(children: systemPreferences),
    );
  }
}
