import 'package:brazier/models/currency.dart';
import 'package:brazier/models/item.dart';
import 'package:brazier/widgets/items_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('ItemsView displays filter button, expanding search, and reset filters button when empty', (WidgetTester tester) async {
    final categories = Category.defaultCategories;
    bool resetCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemsView(
            items: const [],
            categories: categories,
            searchQuery: 'Nonexistent',
            selectedCategoryIds: const {'clothes'},
            showOnlyGoalReached: false,
            maxItemPrice: 500.0,
            minPriceFilter: null,
            maxPriceFilter: null,
            currency: Currency.euro,
            onSearchQueryChanged: (_) {},
            onCategoryFilterChanged: (_) {},
            onGoalFilterChanged: (_) {},
            onPriceFilterChanged: (minP, maxP) {},
            onResetFilters: () {
              resetCalled = true;
            },
            onOpenSettings: () {},
            onEditItem: (_) {},
            onDeleteItem: (_) {},
            onUpdateMonthlyStatus: (item, status) {},
            onReorderItems: (oldIdx, newIdx) {},
          ),
        ),
      ),
    );

    // Verify empty state message
    expect(find.text('No items match your active filters.'), findsOneWidget);

    // Tap "Reset Filters" button
    await tester.tap(find.text('Reset Filters'));
    await tester.pumpAndSettle();

    expect(resetCalled, true);
  });
}
