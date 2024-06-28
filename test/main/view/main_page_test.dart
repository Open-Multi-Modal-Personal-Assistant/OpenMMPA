import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:statemachine/statemachine.dart' as sm;

import '../../helpers/helpers.dart';

class MockMainCubit extends MockCubit<sm.State<String>> implements MainCubit {}

void main() {
  group('MainPage', () {
    testWidgets('renders MainView', (tester) async {
      await tester.pumpApp(const MainPage());
      expect(find.byType(MainView), findsOneWidget);
    });
  });

  group('MainView', () {
    late MainCubit mainCubit;

    setUp(() {
      mainCubit = MockMainCubit();
    });

    testWidgets('renders four buttons', (tester) async {
      const stateName = MainCubit.waitingStateLabel;
      when(() => mainCubit.state.name).thenReturn(stateName);
      await tester.pumpApp(
        BlocProvider.value(
          value: mainCubit,
          child: const MainView(),
        ),
      );
      expect(find.byKey(const Key(MainView.martyMcFlyKey)), findsOneWidget);
      expect(find.byKey(const Key(MainView.theDocKey)), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.translate), findsOneWidget);
      expect(find.byKey(const Key(MainView.translateKey)), findsOneWidget);
      expect(find.byKey(const Key(MainView.fluxCapacitorKey)), findsOneWidget);
    });

    testWidgets('navigates to preferences when the pref button is tapped',
        (tester) async {
      const stateName = MainCubit.waitingStateLabel;
      when(() => mainCubit.state.name).thenReturn(stateName);
      await tester.pumpApp(
        BlocProvider.value(
          value: mainCubit,
          child: const MainView(),
        ),
      );
      await tester.tap(find.byKey(const Key(MainView.fluxCapacitorKey)));
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesView), findsOneWidget);
    });
  });
}
