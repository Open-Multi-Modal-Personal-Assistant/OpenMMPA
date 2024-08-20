import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/preferences/view/pref_integer.dart';
import 'package:pref/pref.dart';

class AiRagPreferencesPage extends StatelessWidget {
  const AiRagPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final harmBlockThresholds = [
      DropdownMenuItem(
        value: PreferencesService.harmBlockThresholdLow,
        child: Text(l10n.harmBlockThresholdLowLabel),
      ),
      DropdownMenuItem(
        value: PreferencesService.harmBlockThresholdMedium,
        child: Text(l10n.harmBlockThresholdMediumLabel),
      ),
      DropdownMenuItem(
        value: PreferencesService.harmBlockThresholdHigh,
        child: Text(l10n.harmBlockThresholdHighLabel),
      ),
      DropdownMenuItem(
        value: PreferencesService.harmBlockThresholdNone,
        child: Text(l10n.harmBlockThresholdNoneLabel),
      ),
    ];

    final aiRagPreferences = <Widget>[
      PrefCheckbox(
        title: Text(l10n.preferencesFastLlmModeLabel),
        pref: PreferencesService.fastLlmModeTag,
      ),
      PrefCheckbox(
        title: Text(l10n.classicGoogleTranslateLabel),
        pref: PreferencesService.classicGoogleTranslateTag,
      ),
      PrefLabel(title: Text(l10n.modelSafetySettingsLabel)),
      PrefDropdown<String>(
        title: Text(l10n.harmCategoryHarassmentLabel),
        pref: PreferencesService.harmCategoryHarassmentTag,
        items: harmBlockThresholds,
      ),
      PrefDropdown<String>(
        title: Text(l10n.harmCategoryHateSpeechLabel),
        pref: PreferencesService.harmCategoryHateSpeechTag,
        items: harmBlockThresholds,
      ),
      PrefDropdown<String>(
        title: Text(l10n.harmCategorySexuallyExplicitLabel),
        pref: PreferencesService.harmCategorySexuallyExplicitTag,
        items: harmBlockThresholds,
      ),
      PrefDropdown<String>(
        title: Text(l10n.harmCategoryDangerousContentLabel),
        pref: PreferencesService.harmCategoryDangerousContentTag,
        items: harmBlockThresholds,
      ),
      const PrefLabel(title: Divider(height: 1)),
      PrefSlider<int>(
        title: Text(l10n.personalizationRagThresholdLabel),
        pref: PreferencesService.personalizationRagThresholdTag,
        min: PreferencesService.ragThresholdMinimum,
        max: PreferencesService.ragThresholdMaximum,
        divisions: PreferencesService.ragThresholdDivisions,
        direction: Axis.vertical,
      ),
      const PrefInteger(
        pref: PreferencesService.personalizationRagThresholdTag,
        min: PreferencesService.ragThresholdMinimum,
        max: PreferencesService.ragThresholdMaximum,
      ),
      const PrefLabel(title: Divider(height: 1)),
      PrefSlider<int>(
        pref: PreferencesService.historyRagThresholdTag,
        title: Text(l10n.historyRagThresholdLabel),
        min: PreferencesService.ragThresholdMinimum,
        max: PreferencesService.ragThresholdMaximum,
        divisions: PreferencesService.ragThresholdDivisions,
        direction: Axis.vertical,
      ),
      const PrefInteger(
        pref: PreferencesService.historyRagThresholdTag,
        min: PreferencesService.ragThresholdMinimum,
        max: PreferencesService.ragThresholdMaximum,
      ),
    ];

    if (kDebugMode) {
      aiRagPreferences.add(
        PrefCheckbox(
          title: Text(l10n.preferencesLlmDebugModeLabel),
          pref: PreferencesService.llmDebugModeTag,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesAiRagLabel)),
      body: PrefPage(children: aiRagPreferences),
    );
  }
}
