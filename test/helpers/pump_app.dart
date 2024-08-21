import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:pref/pref.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    final mockPreferences = GetIt.I.get<PreferencesService>();
    return pumpWidget(
      PrefService(
        service: mockPreferences.prefService!,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget,
        ),
      ),
    );
  }

  Future<void> pumpAndSettleEx([int minTimes = 1]) async {
    var count = 0;
    var wasThereError = false;
    do {
      wasThereError = false;
      try {
        await pumpAndSettle();
        // ignore: avoid_catching_errors
      } on FlutterError {
        wasThereError = true;
      }
      count += 1;
    } while (wasThereError && count < minTimes);
  }
}
