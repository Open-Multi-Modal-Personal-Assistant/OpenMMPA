import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:pref/pref.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SttCubit(),
      child: const PreferencesView(),
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
    final localeItems = sttState.localeNames
        .map(
          (localeName) => DropdownMenuItem(
            value: localeName.localeId,
            child: Text(localeName.name),
          ),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesAppBarTitle)),
      body: PrefPage(
        children: [
          PrefText(
            label: l10n.preferencesGeminiApiKeyLabel,
            pref: PreferencesState.geminiApiKeyTag,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'\w')),
            ],
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
          PrefCheckbox(
            title: Text(l10n.preferencesSpeechServicesNativeLabel),
            pref: PreferencesState.areSpeechServicesNativeTag,
          ),
          PrefCheckbox(
            title: Text(l10n.preferencesSpeechServicesRemoteLabel),
            pref: PreferencesState.areSpeechServicesRemoteTag,
          ),
          PrefDropdown<String>(
            title: Text(l10n.preferencesInputLocaleLabel),
            subtitle: Text(l10n.preferencesInputLocaleSubLabel),
            pref: PreferencesState.inputLocaleTag,
            items: localeItems,
          ),
          PrefDropdown<String>(
            title: Text(l10n.preferencesOutputLocaleLabel),
            subtitle: Text(l10n.preferencesOutputLocaleSubLabel),
            pref: PreferencesState.outputLocaleTag,
            items: localeItems,
          ),
        ],
      ),
    );
  }
}
