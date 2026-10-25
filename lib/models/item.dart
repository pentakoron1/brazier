// ignore_for_file: non_const_argument_for_const_parameter

import 'package:flutter/material.dart';

import 'currency.dart';

class Category {
  final String id;
  String displayName;
  IconData icon;
  Color color;

  Category({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.color,
  });

  static List<Category> get defaultCategories => [
    Category(id: 'clothes', displayName: 'Clothes', icon: Icons.checkroom, color: Colors.purple),
    Category(id: 'devices', displayName: 'Devices', icon: Icons.devices, color: Colors.blue),
    Category(id: 'home', displayName: 'Home', icon: Icons.home, color: Colors.orange),
    Category(id: 'fitness', displayName: 'Fitness & Sports', icon: Icons.fitness_center, color: Colors.teal),
    Category(id: 'vehicles', displayName: 'Vehicles', icon: Icons.directions_car, color: Colors.red),
    Category(id: 'other', displayName: 'Other', icon: Icons.category, color: Colors.grey),
  ];

  Category copyWith({
    String? id,
    String? displayName,
    IconData? icon,
    Color? color,
  }) {
    return Category(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.toARGB32(),
    };
  }

  static const List<IconData> availableIcons = [
    Icons.checkroom,
    Icons.devices,
    Icons.home,
    Icons.menu_book,
    Icons.directions_car,
    Icons.sports_esports,
    Icons.fitness_center,
    Icons.category,
    Icons.shopping_bag,
    Icons.phone_iphone,
    Icons.laptop,
    Icons.headset,
    Icons.chair,
    Icons.watch,
    Icons.camera_alt,
    Icons.kitchen,
    Icons.palette,
    Icons.build,
    Icons.flight,
    Icons.local_grocery_store,
    Icons.fastfood,
    Icons.pets,
    Icons.music_note,
    Icons.content_cut,
  ];

  static IconData getIconFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.category;
    return availableIcons.firstWhere(
      (icon) => icon.codePoint == codePoint,
      orElse: () => Icons.category,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      icon: getIconFromCodePoint(json['iconCodePoint'] as int?),
      color: Color(json['colorValue'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Global feature toggle to enable or disable the "Default as Used" feature across the application.
/// Set to `false` to disable the option in UI dialogs and auto-sync behavior, or `true` to enable it.
const bool enableDefaultAsUsedFeature = false;

/// Global feature toggle to enable or disable loading default sample items on first launch.
/// Set to `false` for a clean empty state on launch, or `true` to populate initial sample items.
const bool enableDefaultItemsOnFirstLaunch = false;

enum MonthlyReviewStatus {
  pending,
  used,
  notUsed,
}

class Item {
  final String id;
  String name;
  double price;
  Category category;
  int goalDurationMonths;
  int usedDurationMonths;
  String? lastReviewedMonthKey;
  bool? currentMonthUsed;
  bool isDefaultUsed;
  int usageStreak;
  Currency? currency;

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.goalDurationMonths,
    required this.usedDurationMonths,
    this.lastReviewedMonthKey,
    this.currentMonthUsed,
    this.isDefaultUsed = false,
    this.usageStreak = 0,
    this.currency,
  });

  /// Returns the currency for this item, falling back to [defaultCurrency] if not specified.
  Currency getEffectiveCurrency(Currency defaultCurrency) {
    return currency ?? defaultCurrency;
  }

  /// Calculates current year-month key string, e.g. "2025-05".
  static String get currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Automatically syncs monthly usage if [isDefaultUsed] is enabled.
  void checkAutoSyncDefaultUsed() {
    if (!enableDefaultAsUsedFeature) return;
    if (isDefaultUsed && lastReviewedMonthKey != currentMonthKey) {
      if (lastReviewedMonthKey != null) {
        // A new month has arrived for a default-used item -> increment usage & streak
        usedDurationMonths += 1;
        usageStreak += 1;
      } else if (usageStreak == 0) {
        usageStreak = usedDurationMonths > 0 ? usedDurationMonths : 1;
      }
      lastReviewedMonthKey = currentMonthKey;
      currentMonthUsed = true;
    }
  }

  /// Returns the current month's review status.
  MonthlyReviewStatus get currentMonthlyStatus {
    if (enableDefaultAsUsedFeature) {
      checkAutoSyncDefaultUsed();
      if (isDefaultUsed) {
        return MonthlyReviewStatus.used;
      }
    }
    if (lastReviewedMonthKey != currentMonthKey) {
      return MonthlyReviewStatus.pending;
    }
    if (currentMonthUsed == true) {
      return MonthlyReviewStatus.used;
    } else if (currentMonthUsed == false) {
      return MonthlyReviewStatus.notUsed;
    }
    return MonthlyReviewStatus.pending;
  }

  /// Calculates the price per month based on goal duration.
  double get goalPricePerMonth {
    if (goalDurationMonths <= 0) return price;
    return price / goalDurationMonths;
  }

  /// Calculates the price per month based on actual used duration.
  double get usedPricePerMonth {
    if (usedDurationMonths <= 0) return price;
    return price / usedDurationMonths;
  }

  /// Returns true if the actual used duration has reached or exceeded the goal duration.
  bool get isGoalReached => usedDurationMonths >= goalDurationMonths;

  /// Progress ratio towards goal (0.0 to 1.0+).
  double get progressRatio {
    if (goalDurationMonths <= 0) return 1.0;
    return usedDurationMonths / goalDurationMonths;
  }

  Item copyWith({
    String? id,
    String? name,
    double? price,
    Category? category,
    int? goalDurationMonths,
    int? usedDurationMonths,
    String? lastReviewedMonthKey,
    bool? currentMonthUsed,
    bool? isDefaultUsed,
    int? usageStreak,
    Currency? currency,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      goalDurationMonths: goalDurationMonths ?? this.goalDurationMonths,
      usedDurationMonths: usedDurationMonths ?? this.usedDurationMonths,
      lastReviewedMonthKey: lastReviewedMonthKey ?? this.lastReviewedMonthKey,
      currentMonthUsed: currentMonthUsed ?? this.currentMonthUsed,
      isDefaultUsed: isDefaultUsed ?? this.isDefaultUsed,
      usageStreak: usageStreak ?? this.usageStreak,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'categoryId': category.id,
      'goalDurationMonths': goalDurationMonths,
      'usedDurationMonths': usedDurationMonths,
      'lastReviewedMonthKey': lastReviewedMonthKey,
      'currentMonthUsed': currentMonthUsed,
      'isDefaultUsed': isDefaultUsed,
      'usageStreak': usageStreak,
      if (currency != null) 'currency': currency!.toJson(),
    };
  }

  factory Item.fromJson(Map<String, dynamic> json, List<Category> categories) {
    final catId = json['categoryId'] as String?;
    final foundCategory = categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => categories.isNotEmpty ? categories.first : Category.defaultCategories.first,
    );

    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: foundCategory,
      goalDurationMonths: json['goalDurationMonths'] as int? ?? 12,
      usedDurationMonths: json['usedDurationMonths'] as int? ?? 0,
      lastReviewedMonthKey: json['lastReviewedMonthKey'] as String?,
      currentMonthUsed: json['currentMonthUsed'] as bool?,
      isDefaultUsed: json['isDefaultUsed'] as bool? ?? false,
      usageStreak: json['usageStreak'] as int? ?? 0,
      currency: json['currency'] != null
          ? Currency.fromJson(json['currency'] as Map<String, dynamic>)
          : null,
    );
  }
}
