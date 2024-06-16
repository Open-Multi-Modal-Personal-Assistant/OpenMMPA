import 'package:flutter/material.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:pref/pref.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return PrefService(
      service: PreferencesState.prefService!,
      child: MaterialApp(
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainPage(),
      ),
    );
  }
}
