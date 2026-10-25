import 'dart:math';
import 'package:flutter/material.dart';

import 'models/currency.dart';
import 'models/item.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/category_manager_dialog.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/item_dialog.dart';
import 'widgets/items_view.dart';
import 'widgets/review_view.dart';
import 'widgets/settings_screen.dart';
import 'widgets/statistics_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrazierApp());
}

class BrazierApp extends StatefulWidget {
  const BrazierApp({super.key});

  @override
  State<BrazierApp> createState() => _BrazierAppState();
}

class _BrazierAppState extends State<BrazierApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await StorageService.loadThemeMode();
    if (mounted) {
      setState(() {
        _themeMode = mode;
      });
    }
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    StorageService.saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryOrange,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryOrange,
      onPrimary: Colors.white,
      secondary: AppColors.primaryOrange,
      tertiary: AppColors.primaryOrange,
      surface: AppColors.scaffoldBackground,
      surfaceContainerLow: AppColors.cardBackground,
      surfaceContainerLowest: AppColors.scaffoldBackground,
      surfaceContainerHighest: AppColors.containerBackground,
      onSurface: const Color(0xFFE2E8F0),
      outline: const Color(0xFF3B4454),
      outlineVariant: AppColors.cardBorder,
    );

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryOrange,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primaryOrange,
      secondary: AppColors.primaryOrange,
      tertiary: AppColors.primaryOrange,
      surface: const Color(0xFFF1F4F9),
      surfaceContainerLow: const Color(0xFFE2E8F0),
      surfaceContainerHighest: const Color(0xFFCBD5E1),
    );

    return MaterialApp(
      title: 'Brazier - Item Cost Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: lightColorScheme.surface,
        textTheme: AppTheme.createTextTheme(ThemeData.light().textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: lightColorScheme.surface,
          titleTextStyle: AppTheme.funnelDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.onSurface,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: darkColorScheme.surface,
        textTheme: AppTheme.createTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: darkColorScheme.surface,
          titleTextStyle: AppTheme.funnelDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkColorScheme.onSurface,
          ),
        ),
      ),
      home: HomeScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  // Display preferences
  bool _showSegmentedProgressBar = true;

  // App default currency
  Currency _currency = Currency.defaultCurrency;

  // Dynamic Categories list initialized with defaults
  List<Category> _categories = Category.defaultCategories;

  // Items list
  List<Item> _items = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final loadedProgressBar = await StorageService.loadSegmentedProgressBar();
    final loadedCurrency = await StorageService.loadCurrency();
    final loadedCategories = await StorageService.loadCategories();
    final loadedItems = await StorageService.loadItems(loadedCategories);

    if (!mounted) return;

    setState(() {
      _showSegmentedProgressBar = loadedProgressBar;
      _currency = loadedCurrency;
      _categories = loadedCategories;

      if (loadedItems != null) {
        _items = loadedItems;
      } else if (enableDefaultItemsOnFirstLaunch) {
        // First launch sample items
        final clothesCat = _categories.firstWhere((c) => c.id == 'clothes', orElse: () => _categories.first);
        final devicesCat = _categories.firstWhere((c) => c.id == 'devices', orElse: () => _categories.first);
        final fitnessCat = _categories.firstWhere((c) => c.id == 'fitness', orElse: () => _categories.first);

        _items = [
          Item(
            id: '1',
            name: 'Smartphone',
            price: 800.0,
            category: devicesCat,
            goalDurationMonths: 24,
            usedDurationMonths: 26,
            isDefaultUsed: enableDefaultAsUsedFeature,
            usageStreak: 26,
          ),
          Item(
            id: '2',
            name: 'Winter Jacket',
            price: 120.0,
            category: clothesCat,
            goalDurationMonths: 6,
            usedDurationMonths: 4,
            usageStreak: 4,
          ),
          Item(
            id: '3',
            name: 'Noise Cancelling Headphones',
            price: 240.0,
            category: devicesCat,
            goalDurationMonths: 12,
            usedDurationMonths: 12,
            usageStreak: 12,
          ),
          Item(
            id: '4',
            name: 'Running Shoes',
            price: 100.0,
            category: fitnessCat,
            goalDurationMonths: 5,
            usedDurationMonths: 2,
            usageStreak: 2,
          ),
        ];
        StorageService.saveItems(_items);
      } else {
        _items = [];
        StorageService.saveItems(_items);
      }
      _isLoading = false;
    });
  }

  void _setCurrency(Currency currency) {
    setState(() {
      _currency = currency;
    });
    StorageService.saveCurrency(currency);
  }

  String _searchQuery = '';
  Category? _selectedCategoryFilter;
  bool _showOnlyGoalReached = false;

  List<Item> get _filteredItems {
    return _items.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == null ||
          item.category.id == _selectedCategoryFilter!.id;
      final matchesGoalFilter = !_showOnlyGoalReached || item.isGoalReached;

      return matchesQuery && matchesCategory && matchesGoalFilter;
    }).toList();
  }

  int get _pendingReviewCount {
    return _items.where((i) => i.currentMonthlyStatus == MonthlyReviewStatus.pending).length;
  }

  void _reorderItems(int oldFilteredIndex, int newFilteredIndex) {
    setState(() {
      final filteredList = _filteredItems;
      if (oldFilteredIndex < 0 || oldFilteredIndex >= filteredList.length) return;

      final movedItem = filteredList[oldFilteredIndex];
      final oldRealIndex = _items.indexOf(movedItem);

      if (newFilteredIndex > oldFilteredIndex) {
        newFilteredIndex -= 1;
      }

      if (newFilteredIndex < 0 || newFilteredIndex >= filteredList.length) return;
      final targetItem = filteredList[newFilteredIndex];
      final newRealIndex = _items.indexOf(targetItem);

      if (oldRealIndex != -1 && newRealIndex != -1) {
        _items.removeAt(oldRealIndex);
        _items.insert(newRealIndex, movedItem);
      }
    });
    StorageService.saveItems(_items);
  }

  void _addCategory(Category cat) {
    setState(() {
      _categories.add(cat);
    });
    StorageService.saveCategories(_categories);
  }

  void _updateCategory(Category updatedCat) {
    setState(() {
      final index = _categories.indexWhere((c) => c.id == updatedCat.id);
      if (index != -1) {
        _categories[index] = updatedCat;
      }
      // Update item references so all existing items immediately reflect new name/icon/color
      for (final item in _items) {
        if (item.category.id == updatedCat.id) {
          item.category = updatedCat;
        }
      }
    });
    StorageService.saveCategories(_categories);
    StorageService.saveItems(_items);
  }

  void _deleteCategory(String categoryId) {
    if (_categories.length <= 1) return;

    setState(() {
      _categories.removeWhere((c) => c.id == categoryId);
      final fallbackCat = _categories.first;
      for (final item in _items) {
        if (item.category.id == categoryId) {
          item.category = fallbackCat;
        }
      }
      if (_selectedCategoryFilter?.id == categoryId) {
        _selectedCategoryFilter = null;
      }
    });
    StorageService.saveCategories(_categories);
    StorageService.saveItems(_items);
  }

  void _openCategoryManager() {
    showDialog(
      context: context,
      builder: (context) => CategoryManagerDialog(
        categories: _categories,
        onAddCategory: _addCategory,
        onUpdateCategory: _updateCategory,
        onDeleteCategory: _deleteCategory,
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          showSegmentedProgressBar: _showSegmentedProgressBar,
          onSegmentedProgressBarChanged: (value) {
            setState(() {
              _showSegmentedProgressBar = value;
            });
            StorageService.saveSegmentedProgressBar(value);
          },
          currentCurrency: _currency,
          onCurrencyChanged: _setCurrency,
          onManageCategories: _openCategoryManager,
        ),
      ),
    );
  }

  void _addItem(Item newItem) {
    setState(() {
      _items.add(newItem);
    });
    StorageService.saveItems(_items);
  }

  void _editItem(Item updatedItem) {
    setState(() {
      final index = _items.indexWhere((i) => i.id == updatedItem.id);
      if (index != -1) {
        _items[index] = updatedItem;
      }
    });
    StorageService.saveItems(_items);
  }

  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((i) => i.id == id);
    });
    StorageService.saveItems(_items);
  }

  void _handleReviewItem(Item item, bool used) {
    _updateMonthlyStatus(
      item,
      used ? MonthlyReviewStatus.used : MonthlyReviewStatus.notUsed,
    );
  }

  void _applyMonthlyStatusChange(Item current, MonthlyReviewStatus newStatus) {
    final oldStatus = current.currentMonthlyStatus;

    if (oldStatus == newStatus && !current.isDefaultUsed) return;

    // Adjust usedDurationMonths and usageStreak depending on transition
    if (oldStatus == MonthlyReviewStatus.used && newStatus != MonthlyReviewStatus.used) {
      // Was used, now no longer used -> decrement duration and decrement streak
      current.usedDurationMonths = max(0, current.usedDurationMonths - 1);
      current.usageStreak = max(0, current.usageStreak - 1);
    } else if (oldStatus != MonthlyReviewStatus.used && newStatus == MonthlyReviewStatus.used) {
      // Was not used/pending, now used -> increment duration and increment streak
      current.usedDurationMonths += 1;
      current.usageStreak += 1;
    }

    // Update review status flags
    switch (newStatus) {
      case MonthlyReviewStatus.used:
        current.lastReviewedMonthKey = Item.currentMonthKey;
        current.currentMonthUsed = true;
        break;
      case MonthlyReviewStatus.notUsed:
        current.lastReviewedMonthKey = Item.currentMonthKey;
        current.currentMonthUsed = false;
        current.usageStreak = 0; // Reset streak on explicitly marked not used
        current.isDefaultUsed = false; // Disable auto-default on explicit override
        break;
      case MonthlyReviewStatus.pending:
        current.lastReviewedMonthKey = null;
        current.currentMonthUsed = null;
        current.isDefaultUsed = false; // Disable auto-default on explicit override
        break;
    }
  }

  void _updateMonthlyStatus(Item item, MonthlyReviewStatus newStatus) {
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _applyMonthlyStatusChange(_items[index], newStatus);
      }
    });
    StorageService.saveItems(_items);
  }

  void _resetAllReviews() {
    setState(() {
      for (final item in _items) {
        _applyMonthlyStatusChange(item, MonthlyReviewStatus.pending);
      }
    });
    StorageService.saveItems(_items);
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (context) => ItemDialog(
        categories: _categories,
        defaultCurrency: _currency,
        onSave: _addItem,
        onAddCategory: _addCategory,
        onUpdateCategory: _updateCategory,
        onDeleteCategory: _deleteCategory,
      ),
    );
  }

  void _openEditDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => ItemDialog(
        item: item,
        categories: _categories,
        defaultCurrency: _currency,
        onSave: _editItem,
        onAddCategory: _addCategory,
        onUpdateCategory: _updateCategory,
        onDeleteCategory: _deleteCategory,
      ),
    );
  }

  String get _appBarTitle {
    switch (_currentTabIndex) {
      case 0:
        return 'Brazier Items';
      case 1:
        return 'Monthly Review';
      case 2:
        return 'Overview & Statistics';
      default:
        return 'Brazier';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;
    final pendingCount = _pendingReviewCount;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        notificationPredicate: (ScrollNotification notification) => false,
        title: Row(
          children: [
            Image.asset(
              'asset/icon/logo.png',
              height: 28,
              width: 28,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.local_fire_department, color: AppColors.primaryOrange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _appBarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Gear Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          if (_currentTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Item',
              onPressed: _openAddDialog,
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            // TAB 0: Items List View
            ItemsView(
              items: filtered,
              categories: _categories,
              defaultCurrency: _currency,
              searchQuery: _searchQuery,
              selectedCategoryFilter: _selectedCategoryFilter,
              showOnlyGoalReached: _showOnlyGoalReached,
              showSegmentedProgressBar: _showSegmentedProgressBar,
              onSearchQueryChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              onCategoryFilterChanged: (category) {
                setState(() {
                  _selectedCategoryFilter = category;
                });
              },
              onGoalFilterChanged: (goalOnly) {
                setState(() {
                  _showOnlyGoalReached = goalOnly;
                });
              },
              onEditItem: _openEditDialog,
              onDeleteItem: _deleteItem,
              onUpdateMonthlyStatus: _updateMonthlyStatus,
              onReorderItems: _reorderItems,
            ),

            // TAB 1: Monthly Review View
            ReviewView(
              items: _items,
              defaultCurrency: _currency,
              onReviewItem: _handleReviewItem,
              onResetAllReviews: _resetAllReviews,
            ),

            // TAB 2: Statistics View
            StatisticsView(
              items: _items,
              defaultCurrency: _currency,
            ),
          ],
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        pendingReviewCount: pendingCount,
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
    );
  }
}
