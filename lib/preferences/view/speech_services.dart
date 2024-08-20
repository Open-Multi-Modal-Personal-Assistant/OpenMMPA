import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:pref/pref.dart';

class SpeechServicesPreferencesPage extends StatelessWidget {
  const SpeechServicesPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stt = GetIt.I.get<SttService>();
    final inputLocales = stt.localeNames
        .map(
          (localeName) => DropdownMenuItem(
            value: localeName.localeId,
            child: Text(localeName.name),
          ),
        )
        .toList(growable: false);

    final tts = GetIt.I.get<TtsService>();
    var outputLanguages = tts.languages
        .map(
          (language) => DropdownMenuItem(
            value: language,
            child: Text(language),
          ),
        )
        .toList(growable: false);

    if (inputLocales.isNotEmpty && outputLanguages.isEmpty) {
      tts.supplementLanguages(stt.localeNames);
      outputLanguages = stt.localeNames
          .map(
            (localeName) => DropdownMenuItem(
              value: localeName.localeId,
              child: Text(localeName.name),
            ),
          )
          .toList(growable: false);
    }

    final speechServicesPreferences = <Widget>[
      PrefCheckbox(
        title: Text(l10n.preferencesSpeechServicesNativeLabel),
        pref: PreferencesService.areSpeechServicesNativeTag,
      ),
      PrefCheckbox(
        title: Text(l10n.preferencesNativeSpeechServicesLocalLabel),
        pref: PreferencesService.areNativeSpeechServicesLocalTag,
      ),
      PrefSlider<int>(
        title: Text(l10n.preferencesVolumeLabel),
        pref: PreferencesService.volumeTag,
        min: PreferencesService.volumeMinimum,
        max: PreferencesService.volumeMaximum,
        divisions: PreferencesService.volumedDivisions,
        direction: Axis.vertical,
      ),
      PrefDropdown<String>(
        title: Text(l10n.preferencesInputLocaleLabel),
        subtitle: Text(l10n.preferencesInputLocaleSubLabel),
        pref: PreferencesService.inputLocaleTag,
        items: inputLocales,
      ),
      PrefDropdown<String>(
        title: Text(l10n.preferencesOutputLocaleLabel),
        subtitle: Text(l10n.preferencesOutputLocaleSubLabel),
        pref: PreferencesService.outputLocaleTag,
        items: outputLanguages,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesSpeechServicesLabel)),
      body: PrefPage(children: speechServicesPreferences),
    );
  }
}
