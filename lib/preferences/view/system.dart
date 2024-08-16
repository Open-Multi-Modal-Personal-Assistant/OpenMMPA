import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:inspector_gadget/l10n/cubit/locale_cubit.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/locale_ex.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:pref/pref.dart';

class SystemPreferencesPage extends StatelessWidget {
  const SystemPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<LocaleCubit>(),
      child: const SystemPreferencesView(),
    );
  }
}

class SystemPreferencesView extends StatelessWidget {
  const SystemPreferencesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeNames = LocaleNames.of(context);
    final localeCubit = context.select((LocaleCubit cubit) => cubit);

    final systemPreferences = <Widget>[
      PrefCheckbox(
        title: Text(l10n.preferencesUnitSystemLabel),
        subtitle: Text(l10n.preferencesUnitSystemDescription),
        pref: PreferencesState.unitSystemTag,
      ),
      PrefLabel(title: Text(l10n.themeSelectionLabel)),
      PrefRadio<String>(
        title: Text(l10n.themeSelectionSystemLabel),
        value: PreferencesState.themeSelectionSystem,
        pref: PreferencesState.themeSelectionTag,
      ),
      PrefRadio<String>(
        title: Text(l10n.themeSelectionLightLabel),
        value: PreferencesState.themeSelectionLight,
        pref: PreferencesState.themeSelectionTag,
      ),
      PrefRadio<String>(
        title: Text(l10n.themeSelectionDarkLabel),
        value: PreferencesState.themeSelectionDark,
        pref: PreferencesState.themeSelectionTag,
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
          pref: PreferencesState.appLocaleTag,
          onSelect: () => localeCubit.setLanguage(locale),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesSystemLabel)),
      body: PrefPage(children: systemPreferences),
    );
  }
}
