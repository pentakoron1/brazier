import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../services/storage_service.dart';

class CurrencyPickerDialog extends StatefulWidget {
  final Currency currentCurrency;
  final ValueChanged<Currency> onSelected;

  const CurrencyPickerDialog({
    super.key,
    required this.currentCurrency,
    required this.onSelected,
  });

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  String _searchQuery = '';
  List<Currency> _customCurrencies = [];

  @override
  void initState() {
    super.initState();
    _loadCustomCurrencies();
  }

  Future<void> _loadCustomCurrencies() async {
    final loaded = await StorageService.loadCustomCurrencies();
    if (mounted) {
      setState(() {
        _customCurrencies = loaded;
      });
    }
  }

  List<Currency> get _allCustomCurrencies {
    final list = List<Currency>.from(_customCurrencies);
    // If widget.currentCurrency is neither in preset nor customCurrencies, include it as custom
    final isPreset = Currency.presetCurrencies.any(
      (p) => p.code == widget.currentCurrency.code && p.symbol == widget.currentCurrency.symbol,
    );
    final inCustom = list.any(
      (c) => c.code == widget.currentCurrency.code && c.symbol == widget.currentCurrency.symbol,
    );
    if (!isPreset && !inCustom) {
      list.add(widget.currentCurrency);
    }
    return list;
  }

  List<Currency> _filterList(List<Currency> currencies) {
    if (_searchQuery.trim().isEmpty) return currencies;
    final q = _searchQuery.toLowerCase();
    return currencies.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteCustomCurrency(Currency currency) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Custom Currency'),
        content: Text('Are you sure you want to delete "${currency.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updated = _customCurrencies
          .where((c) => !(c.code == currency.code && c.symbol == currency.symbol))
          .toList();
      await StorageService.saveCustomCurrencies(updated);
      setState(() {
        _customCurrencies = updated;
      });
    }
  }

  void _openCustomCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => _CustomCurrencyDialog(
        onSave: (customCurrency) async {
          await StorageService.addCustomCurrency(customCurrency);
          widget.onSelected(customCurrency);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredPresets = _filterList(Currency.presetCurrencies);
    final filteredCustoms = _filterList(_allCustomCurrencies);
    final isEmpty = filteredPresets.isEmpty && filteredCustoms.isEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.currency_exchange,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select Currency',
                    style: theme.textTheme.titleLarge?.copyWith(
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

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // Custom Currency Button
            OutlinedButton.icon(
              onPressed: _openCustomCurrencyDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Currency'),
            ),
            const SizedBox(height: 8),

            const Divider(),

            // Currencies List
            Expanded(
              child: isEmpty
                  ? Center(
                      child: Text(
                        'No currency matches "$_searchQuery"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        // Custom Currencies Section
                        if (filteredCustoms.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Text(
                              'CUSTOM CURRENCIES',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...filteredCustoms.map((currency) {
                            final isSelected = widget.currentCurrency.code == currency.code &&
                                widget.currentCurrency.symbol == currency.symbol;

                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              selected: isSelected,
                              selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                foregroundColor: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                                child: Text(
                                  currency.symbol,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currency.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Custom',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onTertiaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Format preview: ${currency.format(100)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    tooltip: 'Delete custom currency',
                                    onPressed: () => _deleteCustomCurrency(currency),
                                  ),
                                ],
                              ),
                              onTap: () {
                                widget.onSelected(currency);
                                Navigator.of(context).pop();
                              },
                            );
                          }),
                          const SizedBox(height: 8),
                          const Divider(),
                        ],

                        // Preset Currencies Section
                        if (filteredPresets.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Text(
                              'PRESET CURRENCIES',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...filteredPresets.map((currency) {
                            final isSelected = widget.currentCurrency.code == currency.code &&
                                widget.currentCurrency.symbol == currency.symbol;

                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              selected: isSelected,
                              selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                foregroundColor: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                                child: Text(
                                  currency.symbol,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                currency.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'Format preview: ${currency.format(100)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                                  : null,
                              onTap: () {
                                widget.onSelected(currency);
                                Navigator.of(context).pop();
                              },
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomCurrencyDialog extends StatefulWidget {
  final ValueChanged<Currency> onSave;

  const _CustomCurrencyDialog({required this.onSave});

  @override
  State<_CustomCurrencyDialog> createState() => _CustomCurrencyDialogState();
}

class _CustomCurrencyDialogState extends State<_CustomCurrencyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  CurrencySymbolPosition _symbolPosition = CurrencySymbolPosition.after;
  int _decimalDigits = 2;

  @override
  void dispose() {
    _codeController.dispose();
    _symbolController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final code = _codeController.text.trim().toUpperCase();
      final symbol = _symbolController.text.trim();
      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : '$code ($symbol)';

      final custom = Currency(
        code: code,
        symbol: symbol,
        name: name,
        symbolPosition: _symbolPosition,
        decimalDigits: _decimalDigits,
      );

      widget.onSave(custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPreview = Currency(
      code: _codeController.text.isEmpty ? 'CUST' : _codeController.text.toUpperCase(),
      symbol: _symbolController.text.isEmpty ? '?' : _symbolController.text,
      name: 'Custom',
      symbolPosition: _symbolPosition,
      decimalDigits: _decimalDigits,
    );

    return AlertDialog(
      title: const Text('Add Custom Currency'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Currency Code',
                  hintText: 'e.g. BTC, SEK, NOK',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter currency code';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(
                  labelText: 'Symbol',
                  hintText: r'e.g. ₿, kr, R$',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter currency symbol';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (Optional)',
                  hintText: 'e.g. Bitcoin, Swedish Krona',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Symbol Position Segmented Button
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Symbol Position',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<CurrencySymbolPosition>(
                segments: const [
                  ButtonSegment(
                    value: CurrencySymbolPosition.before,
                    label: Text(r'Before ($)'),
                  ),
                  ButtonSegment(
                    value: CurrencySymbolPosition.after,
                    label: Text('After (€)'),
                  ),
                ],
                selected: {_symbolPosition},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _symbolPosition = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Decimal Digits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Decimal Digits:'),
                  DropdownButton<int>(
                    value: _decimalDigits,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('0 (e.g. 100)')),
                      DropdownMenuItem(value: 2, child: Text('2 (e.g. 100.00)')),
                      DropdownMenuItem(value: 3, child: Text('3 (e.g. 100.000)')),
                      DropdownMenuItem(value: 4, child: Text('4 (e.g. 100.0000)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _decimalDigits = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Preview',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentPreview.format(125.50),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
