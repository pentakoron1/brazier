import 'package:material_ui/material_ui.dart';

import '../models/currency.dart';
import '../models/item.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String currentLocaleCode;
  final ValueChanged<String> onLocaleChanged;
  final bool showSegmentedProgressBar;
  final ValueChanged<bool> onSegmentedProgressBarChanged;
  final Currency currency;
  final ValueChanged<Currency> onCurrencyChanged;
  final VoidCallback onManageCategories;
  final List<Item> items;
  final List<Category> categories;
  final Future<void> Function({
    List<Item>? items,
    List<Category>? categories,
    BackupSettingsData? settings,
  }) onImportBackup;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.currentLocaleCode,
    required this.onLocaleChanged,
    required this.showSegmentedProgressBar,
    required this.onSegmentedProgressBarChanged,
    required this.currency,
    required this.onCurrencyChanged,
    required this.onManageCategories,
    required this.items,
    required this.categories,
    required this.onImportBackup,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showSegmentedProgressBar;
  late ThemeMode _themeMode;
  late String _currentLocaleCode;
  late Currency _currency;

  final Map<String, String> _supportedLanguages = {
    'system': 'System Default',
    'en': 'English',
    'es': 'Español (not supported yet)',
    'de': 'Deutsch (not supported yet)',
    'fr': 'Français (not supported yet)',
    'hi': 'हिन्दी (not supported yet)',
  };

  @override
  void initState() {
    super.initState();
    _showSegmentedProgressBar = widget.showSegmentedProgressBar;
    _themeMode = widget.themeMode;
    _currentLocaleCode = widget.currentLocaleCode;
    _currency = widget.currency;
  }

  void _openCustomCurrencyDialog(BuildContext context, {Currency? initial}) {
    showDialog(
      context: context,
      builder: (context) => CustomCurrencyDialog(
        initialCurrency: initial ?? (_currency.code == 'CUSTOM' ? _currency : null),
        onSave: (customCurrency) {
          setState(() {
            _currency = customCurrency;
          });
          widget.onCurrencyChanged(customCurrency);
        },
      ),
    );
  }

  void _openCurrencySelectionDialog(BuildContext context) {
    final presets = Currency.presetCurrencies;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select App Currency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...presets.map((preset) {
                  final isSelected = _currency.code == preset.code;
                  return ListTile(
                    title: Text(
                      preset.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('Format: ${preset.format(100.00)}'),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _currency = preset;
                      });
                      widget.onCurrencyChanged(preset);
                      Navigator.of(context).pop();
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Custom Currency...'),
                  subtitle: Text(
                    _currency.code == 'CUSTOM'
                        ? 'Current: ${_currency.displayName}'
                        : 'Set custom symbol & placement',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openCustomCurrencyDialog(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _openExportBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => _ExportBackupDialog(
        items: widget.items,
        categories: widget.categories,
        themeMode: _themeMode,
        localeCode: _currentLocaleCode,
        showSegmentedProgressBar: _showSegmentedProgressBar,
        currency: _currency,
      ),
    );
  }

  Future<void> _handleImportBackup() async {
    try {
      final backupData = await BackupService.pickAndParseBackup(widget.categories);

      if (!mounted) return;

      if (backupData == null) {
        return; // User canceled file picking
      }

      if (!backupData.hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The selected CSV file does not contain valid Brazier backup data.'),
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ImportPreviewDialog(backupData: backupData),
      );

      if (confirmed == true && mounted) {
        await widget.onImportBackup(
          items: backupData.items,
          categories: backupData.categories,
          settings: backupData.settings,
        );

        if (backupData.settings != null) {
          setState(() {
            if (backupData.settings!.themeMode != null) {
              _themeMode = backupData.settings!.themeMode!;
            }
            if (backupData.settings!.localeCode != null) {
              _currentLocaleCode = backupData.settings!.localeCode!;
            }
            if (backupData.settings!.showSegmentedProgressBar != null) {
              _showSegmentedProgressBar = backupData.settings!.showSegmentedProgressBar!;
            }
            if (backupData.settings!.currency != null) {
              _currency = backupData.settings!.currency!;
            }
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

          // APPEARANCE SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'APPEARANCE & LANGUAGE',
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

          // Language Selector ListTile
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: Text(_supportedLanguages[_currentLocaleCode] ?? 'System Default'),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: (code) {
                setState(() {
                  _currentLocaleCode = code;
                });
                widget.onLocaleChanged(code);
              },
              itemBuilder: (context) => _supportedLanguages.entries.map((entry) {
                final isSelected = _currentLocaleCode == entry.key;
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        entry.key == 'system' ? Icons.settings_system_daydream : Icons.translate,
                        color: isSelected ? theme.colorScheme.primary : null,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // CURRENCY SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'CURRENCY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('App Currency'),
            subtitle: Text(_currency.displayName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currency.code == 'CUSTOM')
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Custom Currency',
                    onPressed: () => _openCustomCurrencyDialog(context, initial: _currency),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _openCurrencySelectionDialog(context),
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

          // BACKUP & RESTORE SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'BACKUP & RESTORE',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export Backup'),
            subtitle: const Text('Export items and/or settings to an open CSV file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openExportBackupDialog,
          ),

          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore items or settings from a CSV backup file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleImportBackup,
          ),

          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _ExportBackupDialog extends StatefulWidget {
  final List<Item> items;
  final List<Category> categories;
  final ThemeMode themeMode;
  final String localeCode;
  final bool showSegmentedProgressBar;
  final Currency currency;

  const _ExportBackupDialog({
    required this.items,
    required this.categories,
    required this.themeMode,
    required this.localeCode,
    required this.showSegmentedProgressBar,
    required this.currency,
  });

  @override
  State<_ExportBackupDialog> createState() => _ExportBackupDialogState();
}

class _ExportBackupDialogState extends State<_ExportBackupDialog> {
  bool _saveItemsData = true;
  bool _saveSettings = true;

  void _export() {
    if (!_saveItemsData && !_saveSettings) return;

    final csvContent = BackupService.createCsvBackup(
      saveItemsData: _saveItemsData,
      saveSettings: _saveSettings,
      items: widget.items,
      categories: widget.categories,
      themeMode: widget.themeMode,
      localeCode: widget.localeCode,
      showSegmentedProgressBar: widget.showSegmentedProgressBar,
      currency: widget.currency,
    );

    final fileName = BackupService.generateFileName();

    Navigator.of(context).pop(); // Close setup dialog

    showDialog(
      context: context,
      builder: (context) => _BackupCreatedDialog(
        csvContent: csvContent,
        fileName: fileName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = _saveItemsData || _saveSettings;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.backup_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Export Backup'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose what information to include in the exported open CSV backup file:',
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Save items data'),
              subtitle: Text(
                'Includes all ${widget.items.length} item(s) and custom categories.',
              ),
              value: _saveItemsData,
              onChanged: (val) {
                setState(() {
                  _saveItemsData = val ?? false;
                });
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Save settings'),
              subtitle: const Text(
                'Includes theme mode, currency, language, and display options.',
              ),
              value: _saveSettings,
              onChanged: (val) {
                setState(() {
                  _saveSettings = val ?? false;
                });
              },
            ),
            if (!isValid) ...[
              const SizedBox(height: 8),
              Text(
                'Please select at least one option to export.',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: isValid ? _export : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Create Backup'),
        ),
      ],
    );
  }
}

class _BackupCreatedDialog extends StatefulWidget {
  final String csvContent;
  final String fileName;

  const _BackupCreatedDialog({
    required this.csvContent,
    required this.fileName,
  });

  @override
  State<_BackupCreatedDialog> createState() => _BackupCreatedDialogState();
}

class _BackupCreatedDialogState extends State<_BackupCreatedDialog> {
  bool _isSaving = false;
  bool _isSharing = false;

  Future<void> _handleSaveOnDevice() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final success = await BackupService.saveBackupToDevice(
        csvContent: widget.csvContent,
        fileName: widget.fileName,
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup saved on device successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShareFile() async {
    setState(() {
      _isSharing = true;
    });
    try {
      await BackupService.shareBackupFile(
        csvContent: widget.csvContent,
        fileName: widget.fileName,
      );
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
          const SizedBox(width: 10),
          const Text('Backup created!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your CSV backup file is ready. Choose how you would like to keep your backup:',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: (_isSaving || _isSharing) ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          onPressed: (_isSaving || _isSharing) ? null : _handleShareFile,
          icon: _isSharing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share_outlined),
          label: const Text('Share file'),
        ),
        FilledButton.icon(
          onPressed: (_isSaving || _isSharing) ? null : _handleSaveOnDevice,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_alt),
          label: const Text('Save on device'),
        ),
      ],
    );
  }
}

class _ImportPreviewDialog extends StatelessWidget {
  final BackupData backupData;

  const _ImportPreviewDialog({
    required this.backupData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItems = backupData.items != null && backupData.items!.isNotEmpty;
    final hasSettings = backupData.settings != null && backupData.settings!.hasData;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download_for_offline_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Import Backup'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The selected CSV file contains valid backup data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (hasItems) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
                title: Text('${backupData.items!.length} Items'),
                subtitle: Text(
                  'Categories: ${backupData.categories?.length ?? 0} custom categories',
                ),
              ),
            ],
            if (hasSettings) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.settings_suggest_outlined, color: theme.colorScheme.primary),
                title: const Text('Application Settings'),
                subtitle: Text(
                  [
                    if (backupData.settings!.themeMode != null)
                      'Theme: ${backupData.settings!.themeMode!.name}',
                    if (backupData.settings!.currency != null)
                      'Currency: ${backupData.settings!.currency!.displayName}',
                    if (backupData.settings!.localeCode != null)
                      'Language: ${backupData.settings!.localeCode}',
                  ].join(' • '),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Importing will update your current application data with the content from the backup file.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check),
          label: const Text('Import Now'),
        ),
      ],
    );
  }
}

class CustomCurrencyDialog extends StatefulWidget {
  final Currency? initialCurrency;
  final ValueChanged<Currency> onSave;

  const CustomCurrencyDialog({
    super.key,
    this.initialCurrency,
    required this.onSave,
  });

  @override
  State<CustomCurrencyDialog> createState() => _CustomCurrencyDialogState();
}

class _CustomCurrencyDialogState extends State<CustomCurrencyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  late CurrencySymbolPosition _position;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCurrency;
    _nameController = TextEditingController(text: initial?.name ?? 'Custom');
    _symbolController = TextEditingController(text: initial?.symbol ?? '');
    _position = initial?.position ?? CurrencySymbolPosition.after;

    _symbolController.addListener(_updateState);
    _nameController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final nameText = _nameController.text.trim();
      final symbolText = _symbolController.text.trim();
      final customCurrency = Currency(
        code: 'CUSTOM',
        symbol: symbolText,
        name: nameText.isEmpty ? 'Custom' : nameText,
        position: _position,
      );
      widget.onSave(customCurrency);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final tempCurrency = Currency(
      code: 'CUSTOM',
      symbol: _symbolController.text.trim().isEmpty ? '?' : _symbolController.text.trim(),
      name: _nameController.text.trim().isEmpty ? 'Custom' : _nameController.text.trim(),
      position: _position,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.edit_note_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Custom Currency',
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
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Currency Name',
                          hintText: 'e.g., Polish Złoty, Gold Coins',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _symbolController,
                        decoration: const InputDecoration(
                          labelText: 'Currency Symbol / Abbreviation',
                          hintText: 'e.g., zł, kr, pts, BTC',
                          prefixIcon: Icon(Icons.monetization_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a symbol or abbreviation';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Symbol Position',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<CurrencySymbolPosition>(
                        segments: const [
                          ButtonSegment(
                            value: CurrencySymbolPosition.after,
                            label: Text('After (100.00 zł)'),
                          ),
                          ButtonSegment(
                            value: CurrencySymbolPosition.before,
                            label: Text('Before (zł 100.00)'),
                          ),
                        ],
                        selected: {_position},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _position = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF242C3B)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIVE PREVIEW',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total price:'),
                                Text(
                                  tempCurrency.format(120.0),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Monthly cost:'),
                                Text(
                                  tempCurrency.formatMonthly(10.0),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),
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
                  label: const Text('Apply Currency'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
