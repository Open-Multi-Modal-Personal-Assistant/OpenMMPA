import 'dart:io';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:pref/pref.dart';

class ApiKeysPreferencesPage extends StatelessWidget {
  const ApiKeysPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final apiKeysPreferences = <Widget>[
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
        leading: const Icon(Icons.cloud_download),
        child: Text(l10n.preferencesImportApiKeysTitle),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesApiKeysLabel)),
      body: PrefPage(children: apiKeysPreferences),
    );
  }
}
