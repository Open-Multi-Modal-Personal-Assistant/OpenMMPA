import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:pref/pref.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesAppBarTitle)),
      body: PrefPage(
        children: [
          PrefText(
            label: l10n.preferencesApiKeyLabel,
            pref: PreferencesState.apiKeyTag,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'\w')),
            ],
          ),
          PrefCheckbox(
            title: Text(l10n.preferencesSpeechServicesRemoteLabel),
            pref: PreferencesState.areSpeechServicesRemoteTag,
          ),
        ],
      ),
    );
  }
}
