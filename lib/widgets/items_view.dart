import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/currency.dart';
import '../models/item.dart';
import 'item_card.dart';

typedef ReorderCallback = void Function(int oldIndex, int newIndex);

class ItemsView extends StatefulWidget {
  final List<Item> items;
  final List<Category> categories;
  final String searchQuery;
  final Set<String> selectedCategoryIds;
  final bool showOnlyGoalReached;
  final bool showSegmentedProgressBar;
  final Currency currency;
  final ValueChanged<String> onSearchQueryChanged;
  final ValueChanged<Set<String>> onCategoryFilterChanged;
  final ValueChanged<bool> onGoalFilterChanged;
  final VoidCallback onResetFilters;
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
    required this.showOnlyGoalReached,
    this.showSegmentedProgressBar = true,
    this.currency = Currency.euro,
    required this.onSearchQueryChanged,
    required this.onCategoryFilterChanged,
    required this.onGoalFilterChanged,
    required this.onResetFilters,
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
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        categories: widget.categories,
        selectedCategoryIds: widget.selectedCategoryIds,
        showOnlyGoalReached: widget.showOnlyGoalReached,
        onCategoryFilterChanged: widget.onCategoryFilterChanged,
        onGoalFilterChanged: widget.onGoalFilterChanged,
        onResetFilters: widget.onResetFilters,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = _searchFocusNode.hasFocus || widget.searchQuery.isNotEmpty;
    final activeFilterCount = (widget.showOnlyGoalReached ? 1 : 0) + widget.selectedCategoryIds.length;

    return Column(
      children: [
        const SizedBox(height: 12),
        // Search & View Mode Toggle Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Search Bar with Expansion when focused/typing
              Expanded(
                flex: isSearching ? 3 : 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: TextField(
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
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
                ),
              ),
              const SizedBox(width: 8),

              // Multi-Select Filter Dropdown Button
              IconButton.filledTonal(
                style: activeFilterCount > 0
                    ? IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                      )
                    : null,
                tooltip: activeFilterCount > 0
                    ? 'Filters ($activeFilterCount active)'
                    : 'Filter Categories & Status',
                icon: Badge(
                  isLabelVisible: activeFilterCount > 0,
                  label: Text('$activeFilterCount'),
                  child: const Icon(Icons.filter_list),
                ),
                onPressed: () => _openFilterBottomSheet(context),
              ),
              const SizedBox(width: 6),

              // Compact / Detailed View Toggle Button
              IconButton.filledTonal(
                tooltip: _isCompactView ? 'Switch to Detailed View' : 'Switch to Compact View',
                icon: Icon(_isCompactView ? Icons.view_agenda_outlined : Icons.view_headline),
                onPressed: () {
                  setState(() {
                    _isCompactView = !_isCompactView;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Items List or Responsive Multi-Column Grid with Drag-and-Drop Reordering
        Expanded(
          child: widget.items.isEmpty
              ? Center(
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
                            'Try adjusting your search query or category filters.',
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
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    // Calculate grid columns dynamically for wide screens (tablets, foldables, web, desktop)
                    int crossAxisCount = 1;
                    if (width >= 1350) {
                      crossAxisCount = 3;
                    } else if (width >= 900) {
                      crossAxisCount = 2;
                    }

                    if (crossAxisCount == 1) {
                      return ReorderableListView.builder(
                        itemCount: widget.items.length,
                        padding: const EdgeInsets.only(bottom: 180),
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
                        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 150, top: 4),
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
                ),
        ),
      ],
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final List<Category> categories;
  final Set<String> selectedCategoryIds;
  final bool showOnlyGoalReached;
  final ValueChanged<Set<String>> onCategoryFilterChanged;
  final ValueChanged<bool> onGoalFilterChanged;
  final VoidCallback onResetFilters;

  const _FilterBottomSheet({
    required this.categories,
    required this.selectedCategoryIds,
    required this.showOnlyGoalReached,
    required this.onCategoryFilterChanged,
    required this.onGoalFilterChanged,
    required this.onResetFilters,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<String> _tempCategoryIds;
  late bool _tempGoalReached;

  @override
  void initState() {
    super.initState();
    _tempCategoryIds = Set.from(widget.selectedCategoryIds);
    _tempGoalReached = widget.showOnlyGoalReached;
  }

  void _clearAll() {
    setState(() {
      _tempCategoryIds.clear();
      _tempGoalReached = false;
    });
  }

  void _apply() {
    widget.onCategoryFilterChanged(_tempCategoryIds);
    widget.onGoalFilterChanged(_tempGoalReached);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.filter_list,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Filter Items',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_tempCategoryIds.isNotEmpty || _tempGoalReached)
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear All'),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter Section
                  Text(
                    'STATUS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isDarkMode
                        ? const Color(0xFF222B38)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    title: const Text('Goal Reached Only'),
                    subtitle: const Text('Show only items that met or exceeded goal duration'),
                    secondary: Icon(
                      Icons.check_circle_outline,
                      color: _tempGoalReached ? theme.colorScheme.primary : null,
                    ),
                    value: _tempGoalReached,
                    onChanged: (val) {
                      setState(() {
                        _tempGoalReached = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Categories Filter Section (Multiple Choice)
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
                        _tempCategoryIds.isEmpty
                            ? 'All Categories'
                            : '${_tempCategoryIds.length} selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...widget.categories.map((cat) {
                    final isSelected = _tempCategoryIds.contains(cat.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: CheckboxListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected
                            ? (isDarkMode
                                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                : theme.colorScheme.primaryContainer.withValues(alpha: 0.4))
                            : (isDarkMode
                                ? const Color(0xFF1E2634)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                        title: Text(
                          cat.displayName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        secondary: CircleAvatar(
                          radius: 16,
                          backgroundColor: cat.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                          child: Icon(cat.icon, size: 16, color: cat.color),
                        ),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _tempCategoryIds.add(cat.id);
                            } else {
                              _tempCategoryIds.remove(cat.id);
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.check),
                label: const Text('Apply Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
