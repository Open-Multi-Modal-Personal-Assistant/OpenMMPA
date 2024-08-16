import 'package:flutter/material.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:pref/pref.dart';

class SystemPreferencesPage extends StatelessWidget {
  const SystemPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    final systemPreferences = <Widget>[
      PrefCheckbox(
        title: Text(l10n.preferencesUnitSystemLabel),
        subtitle: Text(l10n.preferencesUnitSystemDescription),
        pref: PreferencesState.unitSystemTag,
      ),
      PrefLabel(
        title: Text(
          l10n.themeSelectionLabel,
          style: textTheme.headlineSmall,
          maxLines: 3,
        ),
      ),
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
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesSystemLabel)),
      body: PrefPage(children: systemPreferences),
    );
  }
}
