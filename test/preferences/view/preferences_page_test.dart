import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:pref/pref.dart';

import '../../helpers/helpers.dart';

class MockPreferencesCubit extends MockCubit<PreferencesState>
    implements PreferencesCubit {}

void main() {
  group('PreferencesPage', () {
    testWidgets('renders PreferencesView', (tester) async {
      await tester.pumpApp(const PreferencesPage());
      expect(find.byType(PreferencesView), findsOneWidget);
    });
  });

  group('PreferencesView', () {
    late PreferencesCubit preferencesCubit;

    setUp(() {
      preferencesCubit = MockPreferencesCubit();
    });

    testWidgets('renders preferences page', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: preferencesCubit,
          child: const PreferencesView(),
        ),
      );
      expect(find.widgetWithText(PrefText, 'API Key'), findsOneWidget);
      expect(find.widgetWithText(PrefCheckbox, 'TSS / STT Remote?'), findsOneWidget);
    });
  });
}
