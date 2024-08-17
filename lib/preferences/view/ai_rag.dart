import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/preferences/view/pref_integer.dart';
import 'package:pref/pref.dart';

class AiRagPreferencesPage extends StatelessWidget {
  const AiRagPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final harmBlockThresholds = [
      DropdownMenuItem(
        value: PreferencesState.harmBlockThresholdLow,
        child: Text(l10n.harmBlockThresholdLowLabel),
      ),
      DropdownMenuItem(
        value: PreferencesState.harmBlockThresholdMedium,
        child: Text(l10n.harmBlockThresholdMediumLabel),
      ),
      DropdownMenuItem(
        value: PreferencesState.harmBlockThresholdHigh,
        child: Text(l10n.harmBlockThresholdHighLabel),
      ),
      DropdownMenuItem(
        value: PreferencesState.harmBlockThresholdNone,
        child: Text(l10n.harmBlockThresholdNoneLabel),
      ),
    ];

    final aiRagPreferences = <Widget>[
      PrefCheckbox(
        title: Text(l10n.preferencesFastLlmModeLabel),
        pref: PreferencesState.fastLlmModeTag,
      ),
      PrefCheckbox(
        title: Text(l10n.classicGoogleTranslateLabel),
        pref: PreferencesState.classicGoogleTranslateTag,
      ),
      PrefLabel(title: Text(l10n.modelSafetySettingsLabel)),
      PrefDropdown<String>(
        title: Text(l10n.harmCategoryHarassmentLabel),
        pref: PreferencesState.harmCategoryHarassmentTag,
        items: harmBlockThresholds,
      ),
      PrefDropdown<String>(
        title: Text(l10n.harmCategoryHateSpeechLabel),
        pref: PreferencesState.harmCategoryHateSpeechTag,
        items: harmBlockThresholds,
      ),
      PrefDropdown<String>(
        title: Text(l10n.harmCategorySexuallyExplicitLabel),
        pref: PreferencesState.harmCategorySexuallyExplicitTag,
        items: harmBlockThresholds,
      ),
      PrefDropdown<String>(
        title: Text(l10n.harmCategoryDangerousContentLabel),
        pref: PreferencesState.harmCategoryDangerousContentTag,
        items: harmBlockThresholds,
      ),
      const PrefLabel(title: Divider(height: 1)),
      PrefSlider<int>(
        title: Text(l10n.personalizationRagThresholdLabel),
        pref: PreferencesState.personalizationRagThresholdTag,
        min: PreferencesState.ragThresholdMinimum,
        max: PreferencesState.ragThresholdMaximum,
        divisions: PreferencesState.ragThresholdDivisions,
        direction: Axis.vertical,
      ),
      const PrefInteger(
        pref: PreferencesState.personalizationRagThresholdTag,
        min: PreferencesState.ragThresholdMinimum,
        max: PreferencesState.ragThresholdMaximum,
      ),
      const PrefLabel(title: Divider(height: 1)),
      PrefSlider<int>(
        pref: PreferencesState.historyRagThresholdTag,
        title: Text(l10n.historyRagThresholdLabel),
        min: PreferencesState.ragThresholdMinimum,
        max: PreferencesState.ragThresholdMaximum,
        divisions: PreferencesState.ragThresholdDivisions,
        direction: Axis.vertical,
      ),
      const PrefInteger(
        pref: PreferencesState.historyRagThresholdTag,
        min: PreferencesState.ragThresholdMinimum,
        max: PreferencesState.ragThresholdMaximum,
      ),
    ];

    if (kDebugMode) {
      aiRagPreferences.add(
        PrefCheckbox(
          title: Text(l10n.preferencesLlmDebugModeLabel),
          pref: PreferencesState.llmDebugModeTag,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesAiRagLabel)),
      body: PrefPage(children: aiRagPreferences),
    );
  }
}
