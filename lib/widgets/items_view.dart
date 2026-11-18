import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/currency.dart';
import '../models/item.dart';
import 'item_card.dart';

typedef ReorderCallback = void Function(int oldIndex, int newIndex);

enum SortOption {
  defaultOrder,
  alphabetical,
  cost,
  usageStreak,
}

enum SortDirection {
  ascending,
  descending,
}

class ItemsView extends StatefulWidget {
  final List<Item> items;
  final List<Category> categories;
  final String searchQuery;
  final Set<String> selectedCategoryIds;
  final Set<ItemType> selectedItemTypes;
  final bool showOnlyGoalReached;
  final bool showOnlyCurrentlyUsed;
  final double maxItemPrice;
  final double? minPriceFilter;
  final double? maxPriceFilter;
  final SortOption sortOption;
  final SortDirection sortDirection;
  final bool isFilterExpanded;
  final bool showSegmentedProgressBar;
  final Currency currency;
  final ValueChanged<String> onSearchQueryChanged;
  final ValueChanged<Set<String>> onCategoryFilterChanged;
  final ValueChanged<Set<ItemType>> onItemTypeFilterChanged;
  final ValueChanged<bool> onGoalFilterChanged;
  final ValueChanged<bool> onCurrentlyUsedFilterChanged;
  final Function(double? minP, double? maxP) onPriceFilterChanged;
  final Function(SortOption option, SortDirection direction) onApplySorting;
  final VoidCallback onToggleFilter;
  final VoidCallback onResetFilters;
  final VoidCallback onOpenSettings;
  final ValueChanged<Item> onEditItem;
  final ValueChanged<String> onDeleteItem;
  final Function(Item item, MonthlyReviewStatus status) onUpdateMonthlyStatus;
  final ReorderCallback onReorderItems;

  const ItemsView({
    super.key,
    required this.items,
    required this.categories,
    required this.searchQuery,
    required this.selectedCategoryIds,
    required this.selectedItemTypes,
    required this.showOnlyGoalReached,
    required this.showOnlyCurrentlyUsed,
    required this.maxItemPrice,
    required this.minPriceFilter,
    required this.maxPriceFilter,
    required this.sortOption,
    required this.sortDirection,
    this.isFilterExpanded = false,
    this.showSegmentedProgressBar = true,
    this.currency = Currency.euro,
    required this.onSearchQueryChanged,
    required this.onCategoryFilterChanged,
    required this.onItemTypeFilterChanged,
    required this.onGoalFilterChanged,
    required this.onCurrentlyUsedFilterChanged,
    required this.onPriceFilterChanged,
    required this.onApplySorting,
    required this.onToggleFilter,
    required this.onResetFilters,
    required this.onOpenSettings,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onUpdateMonthlyStatus,
    required this.onReorderItems,
  });

  @override
  State<ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<ItemsView> {
  bool _isCompactView = false;
  int _activeSubmenuIndex = 0; // 0: Categories, 1: Price, 2: Status, 3: Search, 4: Display/Reorder

  late FocusNode _searchFocusNode;

  // Sorting local state (applied when 'Apply' is tapped)
  late SortOption _tempSortOption;
  late SortDirection _tempSortDirection;

  // Price text controllers for direct editing
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    _tempSortOption = widget.sortOption;
    _tempSortDirection = widget.sortDirection;

    final maxLimit = widget.maxItemPrice > 0 ? widget.maxItemPrice : 100.0;
    _minPriceController = TextEditingController(
      text: (widget.minPriceFilter ?? 0.0).toStringAsFixed(2),
    );
    _maxPriceController = TextEditingController(
      text: (widget.maxPriceFilter ?? maxLimit).toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(ItemsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortOption != widget.sortOption ||
        oldWidget.sortDirection != widget.sortDirection) {
      _tempSortOption = widget.sortOption;
      _tempSortDirection = widget.sortDirection;
    }
    final maxLimit = widget.maxItemPrice > 0 ? widget.maxItemPrice : 100.0;
    if (oldWidget.minPriceFilter != widget.minPriceFilter) {
      _minPriceController.text = (widget.minPriceFilter ?? 0.0).toStringAsFixed(2);
    }
    if (oldWidget.maxPriceFilter != widget.maxPriceFilter) {
      _maxPriceController.text = (widget.maxPriceFilter ?? maxLimit).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Widget _buildItemCard(Item item) {
    return _isCompactView
        ? CompactItemCard(
            item: item,
            showSegmentedProgressBar: widget.showSegmentedProgressBar,
            currency: widget.currency,
            onEdit: () => widget.onEditItem(item),
            onDelete: () => widget.onDeleteItem(item.id),
            onUpdateMonthlyStatus: (newStatus) =>
                widget.onUpdateMonthlyStatus(item, newStatus),
          )
        : ItemCard(
            item: item,
            showSegmentedProgressBar: widget.showSegmentedProgressBar,
            currency: widget.currency,
            onEdit: () => widget.onEditItem(item),
            onDelete: () => widget.onDeleteItem(item.id),
            onUpdateMonthlyStatus: (newStatus) =>
                widget.onUpdateMonthlyStatus(item, newStatus),
          );
  }

  Widget _buildReorderableGridItem(int index, int crossAxisCount, double tileWidth) {
    final item = widget.items[index];
    final theme = Theme.of(context);

    return DragTarget<int>(
      key: ValueKey('drag_${item.id}'),
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        HapticFeedback.selectionClick();
        widget.onReorderItems(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return LongPressDraggable<int>(
          data: index,
          onDragStarted: () {
            HapticFeedback.mediumImpact();
          },
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            child: SizedBox(
              width: tileWidth,
              child: Opacity(
                opacity: 0.92,
                child: _buildItemCard(item),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.25,
            child: _buildItemCard(item),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isHovered
                  ? Border.all(color: theme.colorScheme.primary, width: 2.5)
                  : null,
            ),
            child: _buildItemCard(item),
          ),
        );
      },
    );
  }

  Widget _buildSubmenuPanel(BuildContext context, ThemeData theme, bool isDarkMode) {
    final maxLimit = widget.maxItemPrice > 0 ? widget.maxItemPrice : 100.0;
    final currentMin = (widget.minPriceFilter ?? 0.0).clamp(0.0, maxLimit);
    final currentMax = (widget.maxPriceFilter ?? maxLimit).clamp(currentMin, maxLimit);

    final noCategorySelected = widget.selectedCategoryIds.isEmpty;

    switch (_activeSubmenuIndex) {
      // SUBMENU 0: CATEGORIES
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CATEGORIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  noCategorySelected
                      ? 'All Categories (Default)'
                      : '${widget.selectedCategoryIds.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: noCategorySelected
                        ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)
                        : theme.colorScheme.primary,
                    fontWeight: noCategorySelected ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.categories.map((cat) {
                    final isExplicitlySelected = widget.selectedCategoryIds.contains(cat.id);
                    final isChecked = noCategorySelected || isExplicitlySelected;
                    final isGrayCheck = noCategorySelected;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tileColor: isExplicitlySelected
                            ? (isDarkMode
                                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                : theme.colorScheme.primaryContainer.withValues(alpha: 0.4))
                            : (isDarkMode
                                ? const Color(0xFF1E2634)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                        title: Text(
                          cat.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isExplicitlySelected ? FontWeight.bold : FontWeight.normal,
                            color: isGrayCheck ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700) : null,
                          ),
                        ),
                        secondary: CircleAvatar(
                          radius: 14,
                          backgroundColor: cat.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                          child: Icon(cat.icon, size: 14, color: cat.color),
                        ),
                        activeColor: isGrayCheck
                            ? (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400)
                            : theme.colorScheme.primary,
                        checkColor: isGrayCheck
                            ? (isDarkMode ? Colors.grey.shade900 : Colors.white)
                            : theme.colorScheme.onPrimary,
                        value: isChecked,
                        onChanged: (val) {
                          final newSet = Set<String>.from(widget.selectedCategoryIds);
                          if (noCategorySelected) {
                            newSet.add(cat.id);
                          } else {
                            if (val == true) {
                              newSet.add(cat.id);
                            } else {
                              newSet.remove(cat.id);
                            }
                          }
                          widget.onCategoryFilterChanged(newSet);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );

      // SUBMENU 1: PRICE
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PRICE RANGE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            RangeSlider(
              values: RangeValues(currentMin, currentMax),
              min: 0.0,
              max: maxLimit,
              activeColor: theme.colorScheme.primary,
              inactiveColor: isDarkMode
                  ? const Color(0xFF28303F)
                  : theme.colorScheme.surfaceContainerHighest,
              labels: RangeLabels(
                widget.currency.format(currentMin),
                widget.currency.format(currentMax),
              ),
              onChanged: (RangeValues values) {
                _minPriceController.text = values.start.toStringAsFixed(2);
                _maxPriceController.text = values.end.toStringAsFixed(2);
                final isDefaultMin = values.start <= 0.01;
                final isDefaultMax = values.end >= (maxLimit - 0.01);
                widget.onPriceFilterChanged(
                  isDefaultMin ? null : values.start,
                  isDefaultMax ? null : values.end,
                );
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Min (${widget.currency.symbol})',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsedMin = double.tryParse(val.trim());
                      if (parsedMin != null) {
                        widget.onPriceFilterChanged(
                          parsedMin <= 0.01 ? null : parsedMin,
                          widget.maxPriceFilter,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Max (${widget.currency.symbol})',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsedMax = double.tryParse(val.trim());
                      if (parsedMax != null) {
                        widget.onPriceFilterChanged(
                          widget.minPriceFilter,
                          parsedMax >= (maxLimit - 0.01) ? null : parsedMax,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      // SUBMENU 2: STATUS
      case 2:
        final isSingleExplicit = widget.selectedItemTypes.contains(ItemType.singlePurchase);
        final isSubscriptionExplicit = widget.selectedItemTypes.contains(ItemType.subscription);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ITEM STATUS & TYPE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Subscription Only', style: TextStyle(fontSize: 13)),
              secondary: const Icon(Icons.autorenew, size: 18),
              value: isSubscriptionExplicit,
              onChanged: (val) {
                final newSet = Set<ItemType>.from(widget.selectedItemTypes);
                if (val == true) {
                  newSet.add(ItemType.subscription);
                } else {
                  newSet.remove(ItemType.subscription);
                }
                widget.onItemTypeFilterChanged(newSet);
              },
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Single Purchase Only', style: TextStyle(fontSize: 13)),
              secondary: const Icon(Icons.shopping_bag_outlined, size: 18),
              value: isSingleExplicit,
              onChanged: (val) {
                final newSet = Set<ItemType>.from(widget.selectedItemTypes);
                if (val == true) {
                  newSet.add(ItemType.singlePurchase);
                } else {
                  newSet.remove(ItemType.singlePurchase);
                }
                widget.onItemTypeFilterChanged(newSet);
              },
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Currently Used Only', style: TextStyle(fontSize: 13)),
              secondary: const Icon(Icons.local_fire_department, size: 18),
              value: widget.showOnlyCurrentlyUsed,
              onChanged: (val) {
                widget.onCurrentlyUsedFilterChanged(val ?? false);
              },
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text('Goal Reached Only', style: TextStyle(fontSize: 13)),
              secondary: const Icon(Icons.check_circle_outline, size: 18),
              value: widget.showOnlyGoalReached,
              onChanged: (val) {
                widget.onGoalFilterChanged(val ?? false);
              },
            ),
          ],
        );

      // SUBMENU 3: SEARCH
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SEARCH ITEM NAME',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type item name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => widget.onSearchQueryChanged(''),
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: widget.onSearchQueryChanged,
            ),
          ],
        );

      // SUBMENU 4: DISPLAY & REORDER
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DISPLAY & SORTING',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // View mode toggle
            Row(
              children: [
                const Text('Card Layout:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Detailed')),
                    ButtonSegment(value: true, label: Text('Compact')),
                  ],
                  selected: {_isCompactView},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isCompactView = selection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sort by
            Row(
              children: [
                const Text('Sort By:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<SortOption>(
                    value: _tempSortOption,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: SortOption.defaultOrder, child: Text('Default Order')),
                      DropdownMenuItem(value: SortOption.alphabetical, child: Text('Alphabetically')),
                      DropdownMenuItem(value: SortOption.cost, child: Text('Cost / Price')),
                      DropdownMenuItem(value: SortOption.usageStreak, child: Text('Usage Streak')),
                    ],
                    onChanged: (opt) {
                      if (opt != null) {
                        setState(() {
                          _tempSortOption = opt;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Sort direction
            Row(
              children: [
                const Text('Direction:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                SegmentedButton<SortDirection>(
                  segments: const [
                    ButtonSegment(value: SortDirection.ascending, icon: Icon(Icons.arrow_upward, size: 16), label: Text('Asc')),
                    ButtonSegment(value: SortDirection.descending, icon: Icon(Icons.arrow_downward, size: 16), label: Text('Desc')),
                  ],
                  selected: {_tempSortDirection},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _tempSortDirection = selection.first;
                    });
                  },
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    widget.onApplySorting(_tempSortOption, _tempSortDirection);
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState(ThemeData theme, int activeFilterCount) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              (widget.searchQuery.isNotEmpty || activeFilterCount > 0)
                  ? Icons.filter_alt_off_outlined
                  : Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              (widget.searchQuery.isNotEmpty || activeFilterCount > 0)
                  ? 'No items match your active filters.'
                  : 'No items added yet.\nTap "+" to add a new item!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (widget.searchQuery.isNotEmpty || activeFilterCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search query, price range, or category filters.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onResetFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsListOrGrid(double topPadding) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 1;
        if (width >= 1350) {
          crossAxisCount = 3;
        } else if (width >= 900) {
          crossAxisCount = 2;
        }

        if (crossAxisCount == 1) {
          return ReorderableListView.builder(
            itemCount: widget.items.length,
            padding: EdgeInsets.only(top: topPadding, bottom: 180, left: 12, right: 12),
            onReorderStart: (_) {
              HapticFeedback.mediumImpact();
            },
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.selectionClick();
              widget.onReorderItems(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return KeyedSubtree(
                key: ValueKey('reorder_${item.id}'),
                child: _buildItemCard(item),
              );
            },
          );
        } else {
          final tileWidth = (width - 24 - ((crossAxisCount - 1) * 8)) / crossAxisCount;

          return GridView.builder(
            itemCount: widget.items.length,
            padding: EdgeInsets.only(left: 12, right: 12, bottom: 150, top: topPadding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: _isCompactView ? 95 : 240,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return _buildReorderableGridItem(index, crossAxisCount, tileWidth);
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final maxLimit = widget.maxItemPrice > 0 ? widget.maxItemPrice : 100.0;
    final isPriceFiltered = (widget.minPriceFilter != null && widget.minPriceFilter! > 0.01) ||
        (widget.maxPriceFilter != null && widget.maxPriceFilter! < (maxLimit - 0.01));

    final activeFilterCount = (widget.showOnlyGoalReached ? 1 : 0) +
        (widget.showOnlyCurrentlyUsed ? 1 : 0) +
        widget.selectedCategoryIds.length +
        widget.selectedItemTypes.length +
        (widget.searchQuery.isNotEmpty ? 1 : 0) +
        (isPriceFiltered ? 1 : 0);

    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    // Floating action buttons row (Filter left, Settings right) with NO bar background behind them
    Widget buildFloatingButtonsRow() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: activeFilterCount > 0
                  ? theme.colorScheme.primaryContainer
                  : (isDarkMode ? const Color(0xFF242C3B) : theme.colorScheme.surface),
              child: IconButton(
                tooltip: activeFilterCount > 0
                    ? 'Filters ($activeFilterCount active)'
                    : 'Filter & View Controls',
                icon: Badge(
                  isLabelVisible: activeFilterCount > 0,
                  label: Text('$activeFilterCount'),
                  child: Icon(
                    widget.isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                    color: activeFilterCount > 0
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: widget.onToggleFilter,
              ),
            ),
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: isDarkMode ? const Color(0xFF242C3B) : theme.colorScheme.surface,
              child: IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: widget.onOpenSettings,
              ),
            ),
          ],
        ),
      );
    }

    // WIDE SCREEN LAYOUT: Floating Buttons Directly Above Items Grid; Side Panel on Left via HomeScreen
    if (isWideScreen) {
      return Stack(
        children: [
          Positioned.fill(
            child: widget.items.isEmpty
                ? _buildEmptyState(theme, activeFilterCount)
                : _buildItemsListOrGrid(56.0),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: buildFloatingButtonsRow(),
          ),
        ],
      );
    }

    // SMALL SCREEN LAYOUT (Phones): Items List Fills Background; Floating Filter & Settings Buttons Floating Directly Above Items
    final topPaddingForList = widget.isFilterExpanded ? 260.0 : 56.0;

    return Stack(
      children: [
        // Layer 1: Items List/Grid filling background directly behind floating controls
        Positioned.fill(
          child: widget.items.isEmpty
              ? _buildEmptyState(theme, activeFilterCount)
              : _buildItemsListOrGrid(topPaddingForList),
        ),

        // Layer 2: Floating Controls (Top Filter Section when expanded + Floating Filter & Settings Buttons Pushed Down Below It)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isFilterExpanded)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Material(
                    elevation: 6,
                    color: isDarkMode
                        ? const Color(0xFF1E2634)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF2E3B4E) : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 5 Submenu Icon Tabs Row (No title text, no close X icon)
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.category_outlined,
                                  color: _activeSubmenuIndex == 0 ? theme.colorScheme.primary : null,
                                ),
                                tooltip: 'Categories',
                                onPressed: () => setState(() => _activeSubmenuIndex = 0),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.monetization_on_outlined,
                                  color: _activeSubmenuIndex == 1 ? theme.colorScheme.primary : null,
                                ),
                                tooltip: 'Price Range',
                                onPressed: () => setState(() => _activeSubmenuIndex = 1),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.check_circle_outline,
                                  color: _activeSubmenuIndex == 2 ? theme.colorScheme.primary : null,
                                ),
                                tooltip: 'Status & Type',
                                onPressed: () => setState(() => _activeSubmenuIndex = 2),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: _activeSubmenuIndex == 3 ? theme.colorScheme.primary : null,
                                ),
                                tooltip: 'Search',
                                onPressed: () => setState(() => _activeSubmenuIndex = 3),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.tune,
                                  color: _activeSubmenuIndex == 4 ? theme.colorScheme.primary : null,
                                ),
                                tooltip: 'Display & Sort',
                                onPressed: () => setState(() => _activeSubmenuIndex = 4),
                              ),
                              const Spacer(),
                              if (activeFilterCount > 0)
                                TextButton(
                                  onPressed: widget.onResetFilters,
                                  child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                          const Divider(height: 12),
                          _buildSubmenuPanel(context, theme, isDarkMode),
                        ],
                      ),
                    ),
                  ),
                ),

              // Floating Buttons Row (Floating directly on top of items cards!)
              buildFloatingButtonsRow(),
            ],
          ),
        ),
      ],
    );
  }
}
