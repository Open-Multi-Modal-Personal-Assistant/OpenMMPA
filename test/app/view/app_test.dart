import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/app/app.dart';
import 'package:inspector_gadget/main/main.dart';

void main() {
  group('App', () {
    testWidgets('renders MainPage', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(MainPage), findsOneWidget);
    });
  });
}
