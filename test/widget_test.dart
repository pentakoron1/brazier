import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brazier/main.dart';
import 'package:brazier/widgets/items_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const BrazierApp());
    await tester.pumpAndSettle();

    // Verify that HomeScreen and ItemsView are displayed.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ItemsView), findsOneWidget);
  });
}
