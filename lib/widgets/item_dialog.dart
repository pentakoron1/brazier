import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../models/item.dart';
import 'category_manager_dialog.dart';
import 'currency_picker_dialog.dart';

class ItemDialog extends StatefulWidget {
  final Item? item;
  final List<Category> categories;
  final Currency defaultCurrency;
  final ValueChanged<Item> onSave;
  final ValueChanged<Category>? onAddCategory;
  final ValueChanged<Category>? onUpdateCategory;
  final ValueChanged<String>? onDeleteCategory;

  const ItemDialog({
    super.key,
    this.item,
    required this.categories,
    this.defaultCurrency = Currency.defaultCurrency,
    required this.onSave,
    this.onAddCategory,
    this.onUpdateCategory,
    this.onDeleteCategory,
  });

  @override
  State<ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<ItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _goalDurationController;
  late TextEditingController _usedDurationController;
  late Category _selectedCategory;
  late bool _isDefaultUsed;
  Currency? _itemCurrency;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(2) : '',
    );
    _goalDurationController = TextEditingController(
      text: item != null ? item.goalDurationMonths.toString() : '12',
    );
    _usedDurationController = TextEditingController(
      text: item != null ? item.usedDurationMonths.toString() : '0',
    );

    final Category initialCategory = (item != null && widget.categories.isNotEmpty)
        ? widget.categories.firstWhere(
            (c) => c.id == item.category.id || c.displayName == item.category.displayName,
            orElse: () => widget.categories.first,
          )
        : (widget.categories.isNotEmpty ? widget.categories.first : Category.defaultCategories.first);

    _selectedCategory = initialCategory;
    _isDefaultUsed = item?.isDefaultUsed ?? false;
    _itemCurrency = item?.currency;

    _priceController.addListener(_updateCalculations);
    _goalDurationController.addListener(_updateCalculations);
    _usedDurationController.addListener(_updateCalculations);
  }

  Currency get _effectiveCurrency => _itemCurrency ?? widget.defaultCurrency;

  void _updateCalculations() {
    setState(() {});
  }

  void _openCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        onSave: (newCat) {
          if (widget.onAddCategory != null) {
            widget.onAddCategory!(newCat);
          }
          setState(() {
            _selectedCategory = newCat;
          });
        },
      ),
    );
  }

  void _openCategoryManagerDialog() {
    if (widget.onAddCategory != null &&
        widget.onUpdateCategory != null &&
        widget.onDeleteCategory != null) {
      showDialog(
        context: context,
        builder: (context) => CategoryManagerDialog(
          categories: widget.categories,
          onAddCategory: (cat) {
            widget.onAddCategory!(cat);
            setState(() {});
          },
          onUpdateCategory: (cat) {
            widget.onUpdateCategory!(cat);
            if (_selectedCategory.id == cat.id) {
              _selectedCategory = cat;
            }
            setState(() {});
          },
          onDeleteCategory: (catId) {
            widget.onDeleteCategory!(catId);
            if (_selectedCategory.id == catId && widget.categories.isNotEmpty) {
              _selectedCategory = widget.categories.first;
            }
            setState(() {});
          },
        ),
      );
    }
  }

  void _openCurrencyPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => CurrencyPickerDialog(
        currentCurrency: _effectiveCurrency,
        onSelected: (selected) {
          setState(() {
            _itemCurrency = selected;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _goalDurationController.dispose();
    _usedDurationController.dispose();
    super.dispose();
  }

  double get _currentPrice => double.tryParse(_priceController.text) ?? 0.0;
  int get _currentGoalDuration => int.tryParse(_goalDurationController.text) ?? 1;
  int get _currentUsedDuration => int.tryParse(_usedDurationController.text) ?? 0;

  double get _goalPricePerMonth =>
      _currentGoalDuration > 0 ? _currentPrice / _currentGoalDuration : _currentPrice;

  double get _usedPricePerMonth =>
      _currentUsedDuration > 0 ? _currentPrice / _currentUsedDuration : _currentPrice;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newItem = Item(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        price: _currentPrice,
        category: _selectedCategory,
        goalDurationMonths: _currentGoalDuration,
        usedDurationMonths: _currentUsedDuration,
        lastReviewedMonthKey: widget.item?.lastReviewedMonthKey,
        currentMonthUsed: widget.item?.currentMonthUsed,
        isDefaultUsed: _isDefaultUsed,
        currency: _itemCurrency,
      );

      widget.onSave(newItem);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isGoalReached = _currentUsedDuration >= _currentGoalDuration && _currentGoalDuration > 0;
    final effCurrency = _effectiveCurrency;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed Top Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Item' : 'Add New Item',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          hintText: 'e.g., Winter Coat, iPhone, Bicycle',
                          prefixIcon: Icon(Icons.label_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Price field & Currency selection
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Price (${effCurrency.symbol})',
                                hintText: 'e.g., 100.00',
                                prefixText: '${effCurrency.symbol} ',
                                prefixStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a price';
                                }
                                final num = double.tryParse(value);
                                if (num == null || num < 0) {
                                  return 'Please enter a valid positive price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              onPressed: _openCurrencyPickerDialog,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    effCurrency.code,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('(${effCurrency.symbol})'),
                                  const Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category selector Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openCategoryManagerDialog,
                            icon: const Icon(Icons.settings, size: 16),
                            label: const Text('Manage Categories', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...widget.categories.map((cat) {
                            final selected = _selectedCategory.id == cat.id;
                            return FilterChip(
                              selected: selected,
                              showCheckmark: false,
                              avatar: Icon(
                                cat.icon,
                                size: 18,
                                color: selected
                                    ? theme.colorScheme.onPrimary
                                    : cat.color,
                              ),
                              label: Text(cat.displayName),
                              selectedColor: theme.colorScheme.primary,
                              labelStyle: TextStyle(
                                color: selected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (bool isSelected) {
                                if (isSelected) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                }
                              },
                            );
                          }),
                          // Add Category Chip directly among the choices!
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('Add Category'),
                            onPressed: _openCreateCategoryDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Duration section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Goal duration
                          Expanded(
                            child: TextFormField(
                              controller: _goalDurationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Goal Duration',
                                helperText: 'how long you want to keep the item.',
                                helperStyle: TextStyle(fontStyle: FontStyle.italic),
                                helperMaxLines: 3,
                                suffixText: 'months',
                                prefixIcon: Icon(Icons.flag_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter duration';
                                }
                                final months = int.tryParse(value);
                                if (months == null || months <= 0) {
                                  return 'Min 1 month';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Used duration
                          Expanded(
                            child: TextFormField(
                              controller: _usedDurationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Used Duration',
                                helperText: 'how long you already used the item.',
                                helperStyle: TextStyle(fontStyle: FontStyle.italic),
                                helperMaxLines: 3,
                                suffixText: 'months',
                                prefixIcon: Icon(Icons.history),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter duration';
                                }
                                final months = int.tryParse(value);
                                if (months == null || months < 0) {
                                  return 'Cannot be negative';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (enableDefaultAsUsedFeature) ...[
                        const SizedBox(height: 16),
                        // Default as Used Option
                        CheckboxListTile(
                          value: _isDefaultUsed,
                          onChanged: (val) {
                            setState(() {
                              _isDefaultUsed = val ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          activeColor: theme.colorScheme.primary,
                          title: const Text(
                            'Default as used every month',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Automatically marks this item as used every month without needing manual review',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Live Preview Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isGoalReached
                              ? (isDarkMode
                                  ? Colors.green.shade900.withValues(alpha: 0.3)
                                  : Colors.green.shade50)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isGoalReached
                                ? (isDarkMode ? Colors.green.shade400 : Colors.green.shade300)
                                : theme.colorScheme.outlineVariant,
                            width: isGoalReached ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isGoalReached ? Icons.check_circle : Icons.calculate,
                                  color: isGoalReached
                                      ? (isDarkMode ? Colors.green.shade300 : Colors.green.shade700)
                                      : theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isGoalReached ? 'Goal Reached!' : 'Calculated Cost / Month',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isGoalReached
                                        ? (isDarkMode ? Colors.green.shade200 : Colors.green.shade800)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Goal rate:',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  effCurrency.formatMonthly(_goalPricePerMonth),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Used rate:',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  _currentUsedDuration > 0
                                      ? effCurrency.formatMonthly(_usedPricePerMonth)
                                      : 'N/A (0 months)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isGoalReached
                                        ? (isDarkMode ? Colors.green.shade300 : Colors.green.shade700)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Fixed Sticky Action Buttons at the Bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(isEditing ? 'Save Changes' : 'Add Item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
