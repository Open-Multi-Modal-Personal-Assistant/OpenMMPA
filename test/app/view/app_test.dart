import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/app/app.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

import '../../helpers/helpers.dart';

void main() {
  group('App', () {
    testWidgets('renders MainPage', (tester) async {
      PreferencesState.prefService = MockPrefService();
      await tester.pumpWidget(const App());
      expect(find.byType(MainPage), findsOneWidget);
    });
  });
}
