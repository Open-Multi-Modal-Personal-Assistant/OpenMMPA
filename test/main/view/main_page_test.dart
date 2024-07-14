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
  group('MainView', () {
    late MainCubit mainCubit;

    setUp(() {
      mainCubit = MockMainCubit();
    });

    testWidgets('renders MainPage', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: mainCubit,
          child: const MainPage(),
        ),
      );
      expect(find.byType(MainPage), findsOneWidget);
    });

    testWidgets('renders four buttons', (tester) async {
      const stateName = MainCubit.waitingStateLabel;
      when(() => mainCubit.state.name).thenReturn(stateName);
      await tester.pumpApp(
        BlocProvider.value(
          value: mainCubit,
          child: const MainPage(),
        ),
      );
      expect(find.widgetWithIcon(IconButton, Icons.chat), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.translate), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.voice_chat), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.dataset), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.settings), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.help), findsOneWidget);
    });

    testWidgets('navigates to interaction when the uni modal button is tapped',
        (tester) async {
      const stateName = MainCubit.waitingStateLabel;
      when(() => mainCubit.state.name).thenReturn(stateName);
      await tester.pumpApp(
        BlocProvider.value(
          value: mainCubit,
          child: const MainPage(),
        ),
      );
      await tester.tap(find.byKey(const Key(MainPage.uniModalKey)));
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesView), findsOneWidget);
    });

    testWidgets('navigates to interaction when the translate button is tapped',
        (tester) async {
      const stateName = MainCubit.waitingStateLabel;
      when(() => mainCubit.state.name).thenReturn(stateName);
      await tester.pumpApp(
        BlocProvider.value(
          value: mainCubit,
          child: const MainPage(),
        ),
      );
      await tester.tap(find.byKey(const Key(MainPage.translateKey)));
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesView), findsOneWidget);
    });

    testWidgets(
        'navigates to interaction when the multi modal button is tapped',
        (tester) async {
      const stateName = MainCubit.waitingStateLabel;
      when(() => mainCubit.state.name).thenReturn(stateName);
      await tester.pumpApp(
        BlocProvider.value(
          value: mainCubit,
          child: const MainPage(),
        ),
      );
      await tester.tap(find.byKey(const Key(MainPage.multiModalKey)));
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesView), findsOneWidget);
    });

    testWidgets('navigates to preferences when the pref button is tapped',
        (tester) async {
      const stateName = MainCubit.waitingStateLabel;
      when(() => mainCubit.state.name).thenReturn(stateName);
      await tester.pumpApp(
        BlocProvider.value(
          value: mainCubit,
          child: const MainPage(),
        ),
      );
      await tester.tap(find.byKey(const Key(MainPage.settingsKey)));
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesView), findsOneWidget);
    });
  });
}
