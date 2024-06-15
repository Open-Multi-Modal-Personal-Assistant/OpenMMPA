import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:pref/pref.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: PrefPage(
        children: [
          PrefText(
            label: 'Api Key',
            pref: PreferencesState.apiKeyTag,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'\w')),
            ],
          ),
          const PrefCheckbox(
            title: Text('TSS / STT Remote?'),
            pref: PreferencesState.areSpeechServicesRemoteTag,
          ),
        ],
      ),
    );
  }
}
