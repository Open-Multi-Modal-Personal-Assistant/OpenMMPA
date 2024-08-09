import 'dart:io';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inspector_gadget/database/view/personalization_page.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:pref/pref.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<SttCubit>(),
      child: BlocProvider.value(
        value: context.read<TtsCubit>(),
        child: const PreferencesView(),
      ),
    );
  }
}

class PreferencesView extends StatefulWidget {
  const PreferencesView({super.key});

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
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
    final outputLanguages = ttsState.languages
        .map(
          (language) => DropdownMenuItem(
            value: language,
            child: Text(language),
          ),
        )
        .toList(growable: false);

    final preferences = [
      PrefButton(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const PersonalizationPage(),
            ),
          );
        },
        leading: const Icon(Icons.person_add),
        child: Text(l10n.personalizationButtonLabel),
      ),
      PrefButton(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const PersonalizationPage(),
            ),
          );
        },
        leading: const Icon(Icons.manage_history),
        child: Text(l10n.historyButtonLabel),
      ),
      PrefText(
        label: l10n.preferencesGeminiApiKeyLabel,
        pref: PreferencesState.geminiApiKeyTag,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'\w')),
        ],
      ),
      PrefCheckbox(
        title: Text(l10n.preferencesFastLlmModeLabel),
        pref: PreferencesState.fastLlmModeTag,
      ),
      PrefText(
        label: l10n.preferencesAlphaVantageAccessKeyLabel,
        pref: PreferencesState.alphaVantageAccessKeyTag,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'\w')),
        ],
      ),
      PrefText(
        label: l10n.preferencesTavilyApiKeyLabel,
        pref: PreferencesState.tavilyApiKeyTag,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\w-]+')),
        ],
      ),
      PrefButton(
        onTap: () async {
          final prefService = PrefService.of(context);
          final result = await FilePicker.platform.pickFiles();
          if (result != null && result.files.single.path != null) {
            final apiKeysCsvFile = File(result.files.single.path!);
            final csvLines = await apiKeysCsvFile.readAsLines();
            final preferencesMap = <String, String>{};
            for (final csvLine in csvLines) {
              if (!csvLine.isNullOrWhiteSpace) {
                final keyValues = csvLine.split(',');
                if (keyValues.length >= 2) {
                  preferencesMap.putIfAbsent(
                    keyValues[0],
                    () => keyValues[1],
                  );
                }
              }
            }

            await prefService.fromMap(preferencesMap);
          }
        },
        child: Text(l10n.preferencesImportApiKeysTitle),
      ),
      PrefCheckbox(
        title: Text(l10n.preferencesSpeechServicesNativeLabel),
        pref: PreferencesState.areSpeechServicesNativeTag,
      ),
      PrefCheckbox(
        title: Text(l10n.preferencesUnitSystemLabel),
        subtitle: Text(l10n.preferencesUnitSystemDescription),
        pref: PreferencesState.unitSystemTag,
      ),
      PrefSlider<int>(
        title: Text(l10n.preferencesVolumeLabel),
        pref: PreferencesState.volumeTag,
        min: 0,
        max: 100,
        divisions: 5,
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

    if (kDebugMode) {
      preferences.add(
        PrefCheckbox(
          title: Text(l10n.preferencesLlmDebugModeLabel),
          pref: PreferencesState.llmDebugModeTag,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesAppBarTitle)),
      body: PrefPage(children: preferences),
    );
  }
}
