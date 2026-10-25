import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/currency.dart';
import '../models/item.dart';

class StorageService {
  static const String _categoriesKey = 'brazier_categories_v1';
  static const String _itemsKey = 'brazier_items_v1';
  static const String _themeModeKey = 'brazier_theme_mode_v1';
  static const String _segmentedProgressKey = 'brazier_segmented_progress_v1';
  static const String _currencyKey = 'brazier_currency_v1';

  /// Saves the list of categories to SharedPreferences.
  static Future<void> saveCategories(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = categories.map((c) => c.toJson()).toList();
    await prefs.setString(_categoriesKey, jsonEncode(jsonList));
  }

  /// Loads categories from SharedPreferences. Returns default categories if none saved.
  static Future<List<Category>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return Category.defaultCategories;
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final categories = jsonList
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
      return categories.isNotEmpty ? categories : Category.defaultCategories;
    } catch (_) {
      return Category.defaultCategories;
    }
  }

  /// Saves the list of items to SharedPreferences.
  static Future<void> saveItems(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setString(_itemsKey, jsonEncode(jsonList));
  }

  /// Loads items from SharedPreferences using the saved categories list.
  /// Returns null if this is the first launch with no saved items.
  static Future<List<Item>?> loadItems(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_itemsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => Item.fromJson(item as Map<String, dynamic>, categories))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Saves theme mode preference ('system', 'light', 'dark').
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// Loads theme mode preference.
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_themeModeKey);
    if (name == 'light') return ThemeMode.light;
    if (name == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  /// Saves segmented progress bar setting.
  static Future<void> saveSegmentedProgressBar(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_segmentedProgressKey, value);
  }

  /// Loads segmented progress bar setting.
  static Future<bool> loadSegmentedProgressBar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_segmentedProgressKey) ?? true;
  }

  static const String _customCurrenciesKey = 'brazier_custom_currencies_v1';

  /// Saves the list of user-created custom currencies.
  static Future<void> saveCustomCurrencies(List<Currency> customCurrencies) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = customCurrencies.map((c) => c.toJson()).toList();
    await prefs.setString(_customCurrenciesKey, jsonEncode(jsonList));
  }

  /// Loads user-created custom currencies.
  static Future<List<Currency>> loadCustomCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customCurrenciesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => Currency.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Adds a custom currency if not already present.
  static Future<List<Currency>> addCustomCurrency(Currency currency) async {
    final existing = await loadCustomCurrencies();
    final isPreset = Currency.presetCurrencies.any(
      (p) => p.code == currency.code && p.symbol == currency.symbol,
    );
    if (!isPreset && !existing.contains(currency)) {
      final updated = [...existing, currency];
      await saveCustomCurrencies(updated);
      return updated;
    }
    return existing;
  }

  /// Saves the default app currency setting.
  static Future<void> saveCurrency(Currency currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, jsonEncode(currency.toJson()));
    await addCustomCurrency(currency);
  }

  /// Loads the default app currency setting.
  static Future<Currency> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_currencyKey);
    if (jsonString == null || jsonString.isEmpty) {
      return Currency.defaultCurrency;
    }
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return Currency.fromJson(jsonMap);
    } catch (_) {
      return Currency.defaultCurrency;
    }
  }
}
