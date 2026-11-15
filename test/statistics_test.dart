import 'package:brazier/models/currency.dart';
import 'package:brazier/models/item.dart';
import 'package:brazier/widgets/items_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('ItemsDetailScreen displays Monthly Cost Overview table', (WidgetTester tester) async {
    final cat = Category.defaultCategories.first;

    final activeItem = Item(
      id: '1',
      name: 'Active Headphones',
      price: 100.0,
      category: cat,
      goalDurationMonths: 10,
      usedDurationMonths: 5,
      lastReviewedMonthKey: Item.currentMonthKey,
      currentMonthUsed: true,
    );

    final inactiveItem = Item(
      id: '2',
      name: 'Unused Jacket',
      price: 200.0,
      category: cat,
      goalDurationMonths: 10,
      usedDurationMonths: 2,
      lastReviewedMonthKey: Item.currentMonthKey,
      currentMonthUsed: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ItemsDetailScreen(
          title: 'Overview Summary',
          items: [activeItem, inactiveItem],
          currency: Currency.euro,
        ),
      ),
    );

    // Verify Monthly Cost Breakdown table is rendered
    expect(find.text('Monthly Cost Breakdown'), findsOneWidget);
    expect(find.text('Target Cost'), findsOneWidget);
    expect(find.text('Current Cost'), findsOneWidget);
    expect(find.text('Active Cost'), findsOneWidget);

    // Tap Info button
    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();

    // Verify explanation dialog opens
    expect(find.text('Monthly Cost Metrics'), findsOneWidget);
    expect(find.text('Active Monthly Cost:'), findsOneWidget);
  });
}
