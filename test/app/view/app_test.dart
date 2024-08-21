import 'package:flutter_test/flutter_test.dart';
import 'package:inspector_gadget/app/view/app_view.dart';
import 'package:inspector_gadget/main/view/main_page.dart';

import '../../helpers/setup_services.dart';

void main() {
  setUpAll(() async {
    setUpServices();
  });

  group('App', () {
    testWidgets('renders MainPage', (tester) async {
      await tester.pumpWidget(const AppView());
      await tester.pumpAndSettle();

      expect(find.byType(MainPage), findsOneWidget);
    });
  });
}
