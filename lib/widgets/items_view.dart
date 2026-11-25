import 'package:brazier/theme/app_theme.dart';
import 'package:brazier/widgets/shimmer_text.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/currency.dart';
import '../models/item.dart';
import 'item_card.dart';

import 'dart:ui' show ImageFilter;

typedef ReorderCallback = void Function(int oldIndex, int newIndex);

enum SortOption { defaultOrder, alphabetical, cost, usageStreak }

enum SortDirection { ascending, descending }

const _segmentStyle = ButtonStyle(
  visualDensity: VisualDensity.compact,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
);

class ItemsView extends StatefulWidget {
  final List<Item> items;
  final List<Category> categories;
  final String searchQuery;
  final Set<String> selectedCategoryIds;
  final Set<ItemType> selectedItemTypes;
  final Set<bool>
  goalSelection; // {} = both, {true} = reached, {false} = not reached
  final Set<MonthlyReviewStatus> usageSelection; // {} = all
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
  final ValueChanged<Set<bool>> onGoalSelectionChanged;
  final ValueChanged<Set<MonthlyReviewStatus>> onUsageSelectionChanged;
  final Function(double? minP, double? maxP) onPriceFilterChanged;
  final Function(SortOption option, SortDirection direction) onApplySorting;
  final VoidCallback onToggleFilter;
  final VoidCallback onResetFilters;
  final VoidCallback onOpenSettings;
  final ValueChanged<Item> onEditItem;
  final ValueChanged<String> onDeleteItem;
  final Function(Item item, MonthlyReviewStatus status) onUpdateMonthlyStatus;
  final ReorderCallback onReorderItems;
  final ValueChanged<double>? onSidePanelWidthChanged;

  const ItemsView({
    super.key,
    required this.items,
    required this.categories,
    required this.searchQuery,
    required this.selectedCategoryIds,
    required this.selectedItemTypes,
    required this.goalSelection,
    required this.usageSelection,
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
    required this.onGoalSelectionChanged,
    required this.onUsageSelectionChanged,
    required this.onPriceFilterChanged,
    required this.onApplySorting,
    required this.onToggleFilter,
    required this.onResetFilters,
    required this.onOpenSettings,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onUpdateMonthlyStatus,
    required this.onReorderItems,
    this.onSidePanelWidthChanged,
  });

  @override
  State<ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<ItemsView> {
  bool _isCompactView = false;
  int _activeSubmenuIndex =
      0; // 0: Categories, 1: Price, 2: Status, 3: Search, 4: Display/Reorder
  double _sidePanelWidth = 310.0;

  late FocusNode _searchFocusNode;

  // Sorting local state (applied when 'Reorder' is tapped)
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
      _minPriceController.text = (widget.minPriceFilter ?? 0.0).toStringAsFixed(
        2,
      );
    }
    if (oldWidget.maxPriceFilter != widget.maxPriceFilter) {
      _maxPriceController.text = (widget.maxPriceFilter ?? maxLimit)
          .toStringAsFixed(2);
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

  Widget _buildCategoryButton(ThemeData theme, Category cat) {
    final noneSelected = widget.selectedCategoryIds.isEmpty;
    final isSelected = widget.selectedCategoryIds.contains(cat.id);

    final grey = theme.colorScheme.onSurfaceVariant;
    final onCatColor =
        ThemeData.estimateBrightnessForColor(cat.color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    final Color background = isSelected
        ? cat.color
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    // none selected -> colored icon, selected -> everything colored, otherwise gray
    final Color iconColor = isSelected
        ? onCatColor
        : (noneSelected ? cat.color : grey);
    final Color textColor = isSelected
        ? onCatColor
        : (noneSelected ? theme.colorScheme.onSurface : grey);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final newSet = Set<String>.from(widget.selectedCategoryIds);
          if (isSelected) {
            newSet.remove(cat.id);
          } else {
            newSet.add(cat.id);
          }
          widget.onCategoryFilterChanged(newSet);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cat.icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                cat.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(ThemeData theme) {
    return SizedBox(
      height: 52,
      child: Center(
        child: Opacity(
          opacity: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'fastlane/metadata/android/en-US/images/icon/logo.png',
                height: 22,
              ),
              const SizedBox(width: 6),

              ShimmerText(
                text: 'Brazier',
                baseColor: theme.colorScheme.outline,
                glareColor: AppColors.flameYellow,
                secondGlareColor: AppColors.yellowOrange, // your orange
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableGridItem(
    int index,
    int crossAxisCount,
    double tileWidth,
  ) {
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
              child: Opacity(opacity: 0.92, child: _buildItemCard(item)),
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

  Widget _buildSubmenuPanel(
    BuildContext context,
    ThemeData theme, {
    int? indexOverride,
  }) {
    final maxLimit = widget.maxItemPrice > 0 ? widget.maxItemPrice : 100.0;
    final currentMin = (widget.minPriceFilter ?? 0.0).clamp(0.0, maxLimit);
    final currentMax = (widget.maxPriceFilter ?? maxLimit).clamp(
      currentMin,
      maxLimit,
    );

    final noCategorySelected = widget.selectedCategoryIds.isEmpty;
    final targetIndex = indexOverride ?? _activeSubmenuIndex;

    switch (targetIndex) {
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
                Flexible(
                  child: Text(
                    noCategorySelected
                        ? 'All Categories (Default)'
                        : '${widget.selectedCategoryIds.length} selected',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: noCategorySelected
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                      fontWeight: noCategorySelected
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.categories
                      .map((cat) => _buildCategoryButton(theme, cat))
                      .toList(),
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
              inactiveColor: theme.colorScheme.surfaceContainerHighest,
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Min (${widget.currency.symbol})',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Max (${widget.currency.symbol})',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
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
            const SizedBox(height: 16),

            // Type
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ItemType>(
                multiSelectionEnabled: true,
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                style: _segmentStyle,
                segments: const [
                  ButtonSegment(
                    value: ItemType.subscription,
                    icon: Icon(Icons.autorenew, size: 16),
                    label: Text('Subscription'),
                  ),
                  ButtonSegment(
                    value: ItemType.singlePurchase,
                    icon: Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text('Single Purchase'),
                  ),
                ],
                selected: widget.selectedItemTypes,
                onSelectionChanged: widget.onItemTypeFilterChanged,
              ),
            ),
            const SizedBox(height: 10),

            // Usage
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MonthlyReviewStatus>(
                multiSelectionEnabled: true,
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                style: _segmentStyle,
                segments: const [
                  ButtonSegment(
                    value: MonthlyReviewStatus.used,
                    icon: Icon(Icons.local_fire_department, size: 16),
                    label: Text('Used'),
                  ),
                  ButtonSegment(
                    value: MonthlyReviewStatus.notUsed,
                    icon: Icon(Icons.block, size: 16),
                    label: Text('Not used'),
                  ),
                  ButtonSegment(
                    value: MonthlyReviewStatus.pending,
                    icon: Icon(Icons.pending_outlined, size: 16),
                    label: Text('Review'),
                  ),
                ],
                selected: widget.usageSelection,
                onSelectionChanged: widget.onUsageSelectionChanged,
              ),
            ),
            const SizedBox(height: 10),

            // Goal
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                multiSelectionEnabled: true,
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                style: _segmentStyle,
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.check_circle_outline, size: 16),
                    label: Text('Reached'),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.cancel_outlined, size: 16),
                    label: Text('Not reached'),
                  ),
                ],
                selected: widget.goalSelection,
                onSelectionChanged: widget.onGoalSelectionChanged,
              ),
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
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
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
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'Card Layout:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.dns, size: 16),
                        label: Text('Detailed'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.reorder, size: 16),
                        label: Text('Compact'),
                      ),
                    ],
                    selected: {_isCompactView},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _isCompactView = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sort by
            Card.outlined(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sort by
                    Row(
                      children: [
                        const Text(
                          'Sort By:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<SortOption>(
                            value: _tempSortOption,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: SortOption.defaultOrder,
                                child: Text('Default Order'),
                              ),
                              DropdownMenuItem(
                                value: SortOption.alphabetical,
                                child: Text('Alphabetically'),
                              ),
                              DropdownMenuItem(
                                value: SortOption.cost,
                                child: Text('Cost / Price'),
                              ),
                              DropdownMenuItem(
                                value: SortOption.usageStreak,
                                child: Text('Usage Streak'),
                              ),
                            ],
                            onChanged: (opt) {
                              if (opt != null) {
                                setState(() => _tempSortOption = opt);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Direction (wraps on small screens)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'Direction:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SegmentedButton<SortDirection>(
                          segments: const [
                            ButtonSegment(
                              value: SortDirection.ascending,
                              icon: Icon(Icons.arrow_upward, size: 16),
                              label: Text('Asc'),
                            ),
                            ButtonSegment(
                              value: SortDirection.descending,
                              icon: Icon(Icons.arrow_downward, size: 16),
                              label: Text('Desc'),
                            ),
                          ],
                          selected: {_tempSortDirection},
                          onSelectionChanged: (selection) {
                            setState(
                              () => _tempSortDirection = selection.first,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Apply button, always on the right
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => widget.onApplySorting(
                          _tempSortOption,
                          _tempSortDirection,
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Reorder'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWideSidePanel(
    BuildContext context,
    ThemeData theme,
    int activeFilterCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubmenuPanel(context, theme, indexOverride: 3), // Search
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildSubmenuPanel(
                context,
                theme,
                indexOverride: 0,
              ), // Categories
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildSubmenuPanel(
                context,
                theme,
                indexOverride: 1,
              ), // Price Range
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildSubmenuPanel(
                context,
                theme,
                indexOverride: 2,
              ), // Status & Type
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildSubmenuPanel(
                context,
                theme,
                indexOverride: 4,
              ), // Display & Sorting

              if (activeFilterCount > 0) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: widget.onResetFilters,
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Reset All Filters'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
            header: _buildBranding(Theme.of(context)),
            itemCount: widget.items.length,
            padding: EdgeInsets.only(bottom: 180, left: 6, right: 6),
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
          final tileWidth =
              (width - 24 - ((crossAxisCount - 1) * 8)) / crossAxisCount;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildBranding(Theme.of(context)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 150),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: _isCompactView ? 95 : 240,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildReorderableGridItem(index, crossAxisCount, tileWidth),
                    childCount: widget.items.length,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final maxLimit = widget.maxItemPrice > 0 ? widget.maxItemPrice : 100.0;
    final isPriceFiltered =
        (widget.minPriceFilter != null && widget.minPriceFilter! > 0.01) ||
        (widget.maxPriceFilter != null &&
            widget.maxPriceFilter! < (maxLimit - 0.01));

    final isGoalActive = widget.goalSelection.length == 1;
    final isUsageActive =
        widget.usageSelection.isNotEmpty &&
        widget.usageSelection.length < MonthlyReviewStatus.values.length;
    final isTypeActive = widget.selectedItemTypes.length == 1;

    final categoriesCount = widget.selectedCategoryIds.length;
    final priceCount = isPriceFiltered ? 1 : 0;
    final statusCount =
        (isGoalActive ? 1 : 0) +
        (isUsageActive ? 1 : 0) +
        (isTypeActive ? 1 : 0);
    final searchCount = widget.searchQuery.isNotEmpty ? 1 : 0;

    final activeFilterCount =
        categoriesCount + priceCount + statusCount + searchCount;

    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    Widget buildTab(int index, IconData icon, String tooltip, int count) {
      return IconButton(
        tooltip: tooltip,
        icon: Badge(
          smallSize: 8,
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: Icon(
            icon,
            color: _activeSubmenuIndex == index
                ? theme.colorScheme.primary
                : null,
          ),
        ),
        onPressed: () => setState(() => _activeSubmenuIndex = index),
      );
    }

    Widget blurredCircle({required Color color, required Widget child}) {
      return ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: color,
            shape: CircleBorder(
              side: BorderSide(
                color: theme.colorScheme.inverseSurface.withValues(alpha: 0.08),
              ),
            ),
            child: child,
          ),
        ),
      );
    }

    // Floating action buttons row (Filter left, Settings right) with NO bar background behind them
    Widget buildFloatingButtonsRow() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            blurredCircle(
              color:
                  (activeFilterCount > 0
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest)
                      .withValues(alpha: 0.30),
              child: IconButton(
                tooltip: activeFilterCount > 0
                    ? 'Filters ($activeFilterCount active)'
                    : 'Filter & View Controls',
                icon: Badge(
                  isLabelVisible:
                      activeFilterCount > 0 &&
                      (!widget.isFilterExpanded || isWideScreen),
                  label: Text('$activeFilterCount'),
                  child: Icon(
                    widget.isFilterExpanded
                        ? Icons.filter_list_off
                        : Icons.filter_list,
                    color: activeFilterCount > 0
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: widget.onToggleFilter,
              ),
            ),
            blurredCircle(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.30,
              ),
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

    // WIDE SCREEN LAYOUT: Side Panel on Left + Resizer Hinge + Items Grid on Right
    if (isWideScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isFilterExpanded) ...[
            SizedBox(
              width: _sidePanelWidth.clamp(
                220.0,
                (MediaQuery.of(context).size.width * 0.5).clamp(280.0, 600.0),
              ),
              child: _buildWideSidePanel(context, theme, activeFilterCount),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  final maxW = (MediaQuery.of(context).size.width * 0.5).clamp(
                    280.0,
                    600.0,
                  );
                  final newWidth = (_sidePanelWidth + details.delta.dx).clamp(
                    220.0,
                    maxW,
                  );
                  setState(() {
                    _sidePanelWidth = newWidth;
                  });
                  widget.onSidePanelWidthChanged?.call(newWidth);
                },
                child: Container(
                  width: 14,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.drag_indicator,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            child: Stack(
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
            ),
          ),
        ],
      );
    }

    // SMALL SCREEN LAYOUT (Phones): Inline Filter Section Pushes Items List DOWN; Floating Buttons Float at Top of Items
    return Column(
      children: [
        // Real Layout Filter Section (pushes everything below down)
        if (widget.isFilterExpanded)
          SizedBox(
            width: double.infinity,
            child: Material(
              elevation: 4,
              color: theme.colorScheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 5 Submenu Icon Tabs Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildTab(
                            0,
                            Icons.category_outlined,
                            'Categories',
                            categoriesCount,
                          ),
                          buildTab(
                            1,
                            Icons.monetization_on_outlined,
                            'Price Range',
                            priceCount,
                          ),
                          buildTab(
                            2,
                            Icons.check_circle_outline,
                            'Status & Type',
                            statusCount,
                          ),
                          buildTab(3, Icons.search, 'Search', searchCount),
                          buildTab(4, Icons.tune, 'Display & Sort', 0),
                          const SizedBox(width: 12),
                          if (activeFilterCount > 0)
                            TextButton(
                              onPressed: widget.onResetFilters,
                              child: const Text(
                                'Clear All',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 12),
                    _buildSubmenuPanel(context, theme),
                  ],
                ),
              ),
            ),
          ),

        // Items Area with Floating Buttons Floating Directly Above Item Cards
        Expanded(
          child: Stack(
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
          ),
        ),
      ],
    );
  }
}
