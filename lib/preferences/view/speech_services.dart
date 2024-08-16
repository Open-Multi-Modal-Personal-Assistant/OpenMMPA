import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:pref/pref.dart';

class SpeechServicesPreferencesPage extends StatelessWidget {
  const SpeechServicesPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<SttCubit>(),
      child: BlocProvider.value(
        value: context.read<TtsCubit>(),
        child: const SpeechServicesPreferencesView(),
      ),
    );
  }
}

class SpeechServicesPreferencesView extends StatefulWidget {
  const SpeechServicesPreferencesView({super.key});

  @override
  State<SpeechServicesPreferencesView> createState() =>
      _SpeechServicesPreferencesViewState();
}

class _SpeechServicesPreferencesViewState
    extends State<SpeechServicesPreferencesView> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sttState = context.select((SttCubit cubit) => cubit.state);
    final inputLocales = sttState.localeNames
        .map(
          (localeName) => DropdownMenuItem(
            value: localeName.localeId,
            child: Text(localeName.name),
          ),
        )
        .toList(growable: false);

    final ttsState = context.select((TtsCubit cubit) => cubit.state);
    var outputLanguages = ttsState.languages
        .map(
          (language) => DropdownMenuItem(
            value: language,
            child: Text(language),
          ),
        )
        .toList(growable: false);

    if (inputLocales.isNotEmpty && outputLanguages.isEmpty) {
      ttsState.supplementLanguages(sttState.localeNames);
      outputLanguages = sttState.localeNames
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
        pref: PreferencesState.areSpeechServicesNativeTag,
      ),
      PrefCheckbox(
        title: Text(l10n.preferencesNativeSpeechServicesLocalLabel),
        pref: PreferencesState.areNativeSpeechServicesLocalTag,
      ),
      PrefSlider<int>(
        title: Text(l10n.preferencesVolumeLabel),
        pref: PreferencesState.volumeTag,
        min: PreferencesState.volumeMinimum,
        max: PreferencesState.volumeMaximum,
        divisions: PreferencesState.volumedDivisions,
        direction: Axis.vertical,
      ),
      PrefDropdown<String>(
        title: Text(l10n.preferencesInputLocaleLabel),
        subtitle: Text(l10n.preferencesInputLocaleSubLabel),
        pref: PreferencesState.inputLocaleTag,
        items: inputLocales,
      ),
      PrefDropdown<String>(
        title: Text(l10n.preferencesOutputLocaleLabel),
        subtitle: Text(l10n.preferencesOutputLocaleSubLabel),
        pref: PreferencesState.outputLocaleTag,
        items: outputLanguages,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesSpeechServicesLabel)),
      body: PrefPage(children: speechServicesPreferences),
    );
  }
}
