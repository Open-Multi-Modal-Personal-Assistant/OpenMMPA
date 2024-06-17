import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/app/app.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pref/pref.dart';

abstract class MockWithExpandedToString extends Mock {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return super.toString();
  }
}

class MockPrefService extends MockWithExpandedToString
    implements BasePrefService {}

void main() {
  group('App', () {
    testWidgets('renders MainPage', (tester) async {
      PreferencesState.prefService = MockPrefService();
      await tester.pumpWidget(const App());
      expect(find.byType(MainPage), findsOneWidget);
    });
  });
}
