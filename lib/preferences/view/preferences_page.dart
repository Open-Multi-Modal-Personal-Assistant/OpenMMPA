import 'package:flutter/material.dart';
import 'package:inspector_gadget/database/view/history_page.dart';
import 'package:inspector_gadget/database/view/personalization_page.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/view/ai_rag.dart';
import 'package:inspector_gadget/preferences/view/api_keys.dart';
import 'package:inspector_gadget/preferences/view/speech_services.dart';
import 'package:inspector_gadget/preferences/view/system.dart';
import 'package:pref/pref.dart';
import 'package:tuple/tuple.dart';

typedef PageNavigation = Widget Function(BuildContext context);

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
              builder: (context) => const HistoryPage(),
            ),
          );
        },
        leading: const Icon(Icons.manage_history),
        child: Text(l10n.historyButtonLabel),
      ),
      const PrefLabel(title: Divider(height: 1)),
    ];

    final screenConfigs = <Tuple3<IconData, String, PageNavigation>>[
      Tuple3(
        Icons.key,
        l10n.preferencesApiKeysLabel,
        (context) => const ApiKeysPreferencesPage(),
      ),
      Tuple3(
        Icons.dataset,
        l10n.preferencesAiRagLabel,
        (context) => const AiRagPreferencesPage(),
      ),
      Tuple3(
        Icons.transcribe,
        l10n.preferencesSpeechServicesLabel,
        (context) => const SpeechServicesPreferencesPage(),
      ),
      Tuple3(
        Icons.build,
        l10n.preferencesSystemLabel,
        (context) => const SystemPreferencesPage(),
      ),
    ];

    for (final screenConfig in screenConfigs) {
      preferences.add(
        PrefButton(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: screenConfig.item3,
              ),
            );
          },
          leading: Icon(screenConfig.item1),
          child: Text(screenConfig.item2),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesAppBarTitle)),
      body: PrefPage(children: preferences),
    );
  }
}
