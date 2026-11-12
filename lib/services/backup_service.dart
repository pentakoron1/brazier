import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/currency.dart';
import '../models/item.dart';

class BackupSettingsData {
  final ThemeMode? themeMode;
  final String? localeCode;
  final bool? showSegmentedProgressBar;
  final Currency? currency;

  BackupSettingsData({
    this.themeMode,
    this.localeCode,
    this.showSegmentedProgressBar,
    this.currency,
  });

  bool get hasData =>
      themeMode != null ||
      localeCode != null ||
      showSegmentedProgressBar != null ||
      currency != null;
}

class BackupData {
  final BackupSettingsData? settings;
  final List<Category>? categories;
  final List<Item>? items;

  BackupData({
    this.settings,
    this.categories,
    this.items,
  });

  bool get hasData =>
      (settings != null && settings!.hasData) ||
      (categories != null && categories!.isNotEmpty) ||
      (items != null && items!.isNotEmpty);
}

class BackupService {
  /// Generates a default backup file name with timestamp.
  static String generateFileName() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'brazier_backup_$timestamp.csv';
  }

  /// Encodes backup data into an open CSV string.
  static String createCsvBackup({
    required bool saveItemsData,
    required bool saveSettings,
    required List<Item> items,
    required List<Category> categories,
    required ThemeMode themeMode,
    required String localeCode,
    required bool showSegmentedProgressBar,
    required Currency currency,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# BRAZIER BACKUP V1');
    buffer.writeln('# Created: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    if (saveSettings) {
      buffer.writeln('# SETTINGS');
      buffer.writeln('setting_key,setting_value');
      buffer.writeln('theme_mode,${_escapeCsv(themeMode.name)}');
      buffer.writeln('locale_code,${_escapeCsv(localeCode)}');
      buffer.writeln('show_segmented_progress_bar,${showSegmentedProgressBar.toString()}');
      buffer.writeln('currency_code,${_escapeCsv(currency.code)}');
      buffer.writeln('currency_symbol,${_escapeCsv(currency.symbol)}');
      buffer.writeln('currency_name,${_escapeCsv(currency.name)}');
      buffer.writeln('currency_position,${_escapeCsv(currency.position.name)}');
      buffer.writeln();
    }

    if (saveItemsData) {
      buffer.writeln('# CATEGORIES');
      buffer.writeln('category_id,display_name,icon_code_point,color_argb');
      for (final cat in categories) {
        buffer.writeln([
          _escapeCsv(cat.id),
          _escapeCsv(cat.displayName),
          cat.icon.codePoint.toString(),
          cat.color.toARGB32().toString(),
        ].join(','));
      }
      buffer.writeln();

      buffer.writeln('# ITEMS');
      buffer.writeln(
        'id,name,item_type,price,category_id,goal_duration_months,used_duration_months,last_reviewed_month_key,current_month_used,is_default_used,usage_streak',
      );
      for (final item in items) {
        buffer.writeln([
          _escapeCsv(item.id),
          _escapeCsv(item.name),
          _escapeCsv(item.itemType.name),
          item.price.toString(),
          _escapeCsv(item.category.id),
          item.goalDurationMonths.toString(),
          item.usedDurationMonths.toString(),
          _escapeCsv(item.lastReviewedMonthKey ?? ''),
          item.currentMonthUsed == null ? '' : item.currentMonthUsed.toString(),
          item.isDefaultUsed.toString(),
          item.usageStreak.toString(),
        ].join(','));
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Prompts user to save backup CSV file directly on their device.
  static Future<bool> saveBackupToDevice({
    required String csvContent,
    required String fileName,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(csvContent));
    final result = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'text/csv',
    );
    return result != null;
  }

  /// Shares backup CSV file via platform share sheet.
  static Future<void> shareBackupFile({
    required String csvContent,
    required String fileName,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(csvContent));
    if (kIsWeb) {
      final xFile = XFile.fromData(bytes, name: fileName, mimeType: 'text/csv');
      await Share.shareXFiles([xFile]);
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvContent, flush: true);

      final localXFile = XFile(file.path, mimeType: 'text/csv');
      await Share.shareXFiles([localXFile]);
    }
  }

  /// Opens system file picker and parses chosen CSV backup file.
  static Future<BackupData?> pickAndParseBackup(List<Category> existingCategories) async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (pickedFile == null) {
      return null;
    }

    final bytes = await pickedFile.readAsBytes();
    final csvContent = utf8.decode(bytes);

    if (csvContent.trim().isEmpty) {
      return null;
    }

    return parseCsvBackup(csvContent, existingCategories);
  }

  /// Parses CSV content into [BackupData].
  static BackupData parseCsvBackup(String csvContent, List<Category> existingCategories) {
    final rows = _parseCsvRows(csvContent);
    if (rows.isEmpty) {
      return BackupData();
    }

    _CsvSection currentSection = _CsvSection.none;
    final Map<String, String> settingsMap = {};
    final List<Category> parsedCategories = [];
    final List<Item> parsedItems = [];

    Map<String, int>? currentHeaders;

    for (final row in rows) {
      if (row.isEmpty) continue;
      final firstCell = row[0].trim();

      if (firstCell.startsWith('#')) {
        final upper = firstCell.toUpperCase();
        if (upper.contains('SETTINGS')) {
          currentSection = _CsvSection.settings;
          currentHeaders = null;
        } else if (upper.contains('CATEGORIES')) {
          currentSection = _CsvSection.categories;
          currentHeaders = null;
        } else if (upper.contains('ITEMS')) {
          currentSection = _CsvSection.items;
          currentHeaders = null;
        }
        continue;
      }

      final rowJoinedLower = row.join(',').toLowerCase();

      // Detect header row for table sections
      if (rowJoinedLower.contains('setting_key')) {
        currentSection = _CsvSection.settings;
        currentHeaders = null;
        continue;
      } else if (rowJoinedLower.contains('icon_code_point') || rowJoinedLower.contains('color_argb')) {
        currentSection = _CsvSection.categories;
        currentHeaders = _buildHeaderMap(row);
        continue;
      } else if (rowJoinedLower.contains('goal_duration_months') ||
          rowJoinedLower.contains('item_type') ||
          rowJoinedLower.contains('used_duration_months') ||
          rowJoinedLower.contains('usage_streak')) {
        currentSection = _CsvSection.items;
        currentHeaders = _buildHeaderMap(row);
        continue;
      }

      switch (currentSection) {
        case _CsvSection.settings:
          if (row.length >= 2) {
            settingsMap[row[0].trim()] = row[1].trim();
          }
          break;

        case _CsvSection.categories:
          final cat = _parseCategoryRow(row, currentHeaders);
          if (cat != null) {
            parsedCategories.add(cat);
          }
          break;

        case _CsvSection.items:
          final List<Category> combinedCategories = [
            ...parsedCategories,
            ...existingCategories.where(
              (ec) => !parsedCategories.any((pc) => pc.id == ec.id),
            ),
          ];
          final item = _parseItemRow(row, currentHeaders, combinedCategories);
          if (item != null) {
            parsedItems.add(item);
          }
          break;

        case _CsvSection.none:
          break;
      }
    }

    // Parse Settings if any
    BackupSettingsData? settingsData;
    if (settingsMap.isNotEmpty) {
      ThemeMode? themeMode;
      final rawTheme = settingsMap['theme_mode'];
      if (rawTheme == 'dark') themeMode = ThemeMode.dark;
      if (rawTheme == 'light') themeMode = ThemeMode.light;
      if (rawTheme == 'system') themeMode = ThemeMode.system;

      final localeCode = settingsMap['locale_code'];

      bool? showSegmentedProgressBar;
      if (settingsMap.containsKey('show_segmented_progress_bar')) {
        showSegmentedProgressBar = settingsMap['show_segmented_progress_bar'] == 'true';
      }

      Currency? currency;
      if (settingsMap.containsKey('currency_code')) {
        final code = settingsMap['currency_code'] ?? 'EUR';
        final symbol = settingsMap['currency_symbol'] ?? '€';
        final name = settingsMap['currency_name'] ?? 'Euro';
        final posStr = settingsMap['currency_position'] ?? 'after';
        final pos = posStr == 'before'
            ? CurrencySymbolPosition.before
            : CurrencySymbolPosition.after;

        currency = Currency(
          code: code,
          symbol: symbol,
          name: name,
          position: pos,
        );
      }

      settingsData = BackupSettingsData(
        themeMode: themeMode,
        localeCode: localeCode,
        showSegmentedProgressBar: showSegmentedProgressBar,
        currency: currency,
      );
    }

    return BackupData(
      settings: settingsData,
      categories: parsedCategories.isNotEmpty ? parsedCategories : null,
      items: parsedItems.isNotEmpty ? parsedItems : null,
    );
  }

  static Map<String, int> _buildHeaderMap(List<String> row) {
    final Map<String, int> map = {};
    for (int i = 0; i < row.length; i++) {
      map[row[i].trim().toLowerCase()] = i;
    }
    return map;
  }

  static Category? _parseCategoryRow(List<String> row, Map<String, int>? headers) {
    if (row.isEmpty) return null;

    String getValue(String key, int fallbackIndex) {
      if (headers != null && headers.containsKey(key)) {
        final idx = headers[key]!;
        if (idx < row.length) return row[idx].trim();
      }
      if (fallbackIndex < row.length) return row[fallbackIndex].trim();
      return '';
    }

    final id = getValue('category_id', 0).isEmpty
        ? getValue('id', 0)
        : getValue('category_id', 0);
    if (id.isEmpty) return null;

    final displayName = getValue('display_name', 1).isEmpty
        ? id
        : getValue('display_name', 1);

    final iconCode = int.tryParse(getValue('icon_code_point', 2));
    final colorValue = int.tryParse(getValue('color_argb', 3));

    return Category(
      id: id,
      displayName: displayName,
      icon: Category.getIconFromCodePoint(iconCode),
      color: colorValue != null ? Color(colorValue) : Colors.orange,
    );
  }

  static Item? _parseItemRow(
    List<String> row,
    Map<String, int>? headers,
    List<Category> categories,
  ) {
    if (row.isEmpty) return null;

    String getValue(String key, int fallbackIndex) {
      if (headers != null && headers.containsKey(key)) {
        final idx = headers[key]!;
        if (idx < row.length) return row[idx].trim();
      }
      if (fallbackIndex < row.length) return row[fallbackIndex].trim();
      return '';
    }

    final id = getValue('id', 0);
    final name = getValue('name', 1);
    if (name.isEmpty && id.isEmpty) return null;

    final rawType = getValue('item_type', 2);
    final itemType = rawType == 'subscription'
        ? ItemType.subscription
        : ItemType.singlePurchase;

    final price = double.tryParse(getValue('price', 3)) ?? 0.0;
    final categoryId = getValue('category_id', 4);

    final foundCategory = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : Category.defaultCategories.first,
    );

    final goalDuration = int.tryParse(getValue('goal_duration_months', 5)) ?? 12;
    final usedDuration = int.tryParse(getValue('used_duration_months', 6)) ?? 0;
    final lastReviewed = getValue('last_reviewed_month_key', 7);
    final rawCurrentUsed = getValue('current_month_used', 8);
    final isDefaultUsed = getValue('is_default_used', 9) == 'true';
    final usageStreak = int.tryParse(getValue('usage_streak', 10)) ?? 0;

    bool? currentMonthUsed;
    if (rawCurrentUsed == 'true') {
      currentMonthUsed = true;
    } else if (rawCurrentUsed == 'false') {
      currentMonthUsed = false;
    }

    return Item(
      id: id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isNotEmpty ? name : 'Unnamed Item',
      itemType: itemType,
      price: price,
      category: foundCategory,
      goalDurationMonths: goalDuration,
      usedDurationMonths: usedDuration,
      lastReviewedMonthKey: lastReviewed.isNotEmpty ? lastReviewed : null,
      currentMonthUsed: currentMonthUsed,
      isDefaultUsed: isDefaultUsed,
      usageStreak: usageStreak,
    );
  }

  static String _escapeCsv(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  static List<List<String>> _parseCsvRows(String input) {
    final List<List<String>> rows = [];
    final StringBuffer fieldBuffer = StringBuffer();
    List<String> currentRow = [];
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            fieldBuffer.write('"');
            i++; // Skip second quote
          } else {
            inQuotes = false;
          }
        } else {
          fieldBuffer.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(fieldBuffer.toString());
          fieldBuffer.clear();
        } else if (char == '\n' || char == '\r') {
          if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
            i++; // Skip \n after \r
          }
          currentRow.add(fieldBuffer.toString());
          fieldBuffer.clear();
          if (currentRow.isNotEmpty && !(currentRow.length == 1 && currentRow[0].isEmpty)) {
            rows.add(currentRow);
          }
          currentRow = [];
        } else {
          fieldBuffer.write(char);
        }
      }
    }

    if (fieldBuffer.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(fieldBuffer.toString());
      if (currentRow.isNotEmpty && !(currentRow.length == 1 && currentRow[0].isEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }
}

enum _CsvSection {
  none,
  settings,
  categories,
  items,
}
