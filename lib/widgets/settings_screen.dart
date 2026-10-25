import 'package:flutter/material.dart';

import '../models/currency.dart';
import 'currency_picker_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool showSegmentedProgressBar;
  final ValueChanged<bool> onSegmentedProgressBarChanged;
  final Currency currentCurrency;
  final ValueChanged<Currency> onCurrencyChanged;
  final VoidCallback onManageCategories;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.showSegmentedProgressBar,
    required this.onSegmentedProgressBarChanged,
    required this.currentCurrency,
    required this.onCurrencyChanged,
    required this.onManageCategories,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showSegmentedProgressBar;
  late ThemeMode _themeMode;
  late Currency _currentCurrency;

  @override
  void initState() {
    super.initState();
    _showSegmentedProgressBar = widget.showSegmentedProgressBar;
    _themeMode = widget.themeMode;
    _currentCurrency = widget.currentCurrency;
  }

  void _openCurrencyPicker() {
    showDialog(
      context: context,
      builder: (context) => CurrencyPickerDialog(
        currentCurrency: _currentCurrency,
        onSelected: (currency) {
          setState(() {
            _currentCurrency = currency;
          });
          widget.onCurrencyChanged(currency);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // CURRENCY SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'CURRENCY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Default Currency'),
            subtitle: Text('${_currentCurrency.name} • Preview: ${_currentCurrency.format(100)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openCurrencyPicker,
          ),

          const Divider(height: 1),

          // APPEARANCE SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'APPEARANCE & THEME',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Dark Mode Control ListTile
          ListTile(
            leading: Icon(
              _themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : _themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
            ),
            title: const Text('App Theme'),
            subtitle: Text(
              _themeMode == ThemeMode.system
                  ? 'System Default'
                  : _themeMode == ThemeMode.light
                      ? 'Light Theme'
                      : 'Dark Theme',
            ),
            trailing: PopupMenuButton<ThemeMode>(
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: (mode) {
                setState(() {
                  _themeMode = mode;
                });
                widget.onThemeModeChanged(mode);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      Icon(
                        Icons.brightness_auto,
                        color: _themeMode == ThemeMode.system ? theme.colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'System Default',
                        style: TextStyle(
                          fontWeight: _themeMode == ThemeMode.system ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      Icon(
                        Icons.light_mode,
                        color: _themeMode == ThemeMode.light ? theme.colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Light Theme',
                        style: TextStyle(
                          fontWeight: _themeMode == ThemeMode.light ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      Icon(
                        Icons.dark_mode,
                        color: _themeMode == ThemeMode.dark ? theme.colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Dark Theme',
                        style: TextStyle(
                          fontWeight: _themeMode == ThemeMode.dark ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // DISPLAY SETTINGS SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'PROGRESS BAR DISPLAY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Toggle Visual Separation of Months
          SwitchListTile(
            secondary: const Icon(Icons.view_week_outlined),
            title: const Text('Segmented Month Progress Bars'),
            subtitle: const Text('Visually divide progress bars into individual month step pills'),
            value: _showSegmentedProgressBar,
            onChanged: (value) {
              setState(() {
                _showSegmentedProgressBar = value;
              });
              widget.onSegmentedProgressBarChanged(value);
            },
          ),

          const Divider(height: 1),

          // CATEGORIES MANAGEMENT SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'CATEGORY MANAGEMENT',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Manage Categories Button
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, edit icons, set custom colors, or delete categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onManageCategories,
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
