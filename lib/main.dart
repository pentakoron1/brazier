import 'dart:math';
import 'package:material_ui/material_ui.dart';

import 'models/currency.dart';
import 'models/item.dart';
import 'services/backup_service.dart';
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
  String _localeCode = 'system';
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final mode = await StorageService.loadThemeMode();
    final locCode = await StorageService.loadLocaleCode();
    if (mounted) {
      setState(() {
        _themeMode = mode;
        _localeCode = locCode;
        _locale = locCode == 'system' ? null : Locale(locCode);
      });
    }
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    StorageService.saveThemeMode(mode);
  }

  void _setLocaleCode(String code) {
    setState(() {
      _localeCode = code;
      _locale = code == 'system' ? null : Locale(code);
    });
    StorageService.saveLocaleCode(code);
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
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('de', ''),
        Locale('fr', ''),
        Locale('hi', ''),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
        currentLocaleCode: _localeCode,
        onLocaleChanged: _setLocaleCode,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String currentLocaleCode;
  final ValueChanged<String> onLocaleChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.currentLocaleCode,
    required this.onLocaleChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  // Display preferences
  bool _showSegmentedProgressBar = true;
  Currency _currency = Currency.euro;

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
        bool updatedSubscriptions = false;
        for (final item in _items) {
          final oldGoal = item.goalDurationMonths;
          item.checkAutoIncrementSubscriptionRunningDuration();
          if (item.goalDurationMonths != oldGoal) {
            updatedSubscriptions = true;
          }
        }
        if (updatedSubscriptions) {
          StorageService.saveItems(_items);
        }
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

  String _searchQuery = '';
  Set<String> _selectedCategoryIds = {};
  Set<ItemType> _selectedItemTypes = {};
  bool _showOnlyGoalReached = false;
  bool _showOnlyCurrentlyUsed = false;
  double? _minPriceFilter;
  double? _maxPriceFilter;
  SortOption _sortOption = SortOption.defaultOrder;
  SortDirection _sortDirection = SortDirection.ascending;
  bool _isFilterExpanded = false;
  double _sidePanelWidth = 310.0;

  double get _maxItemPrice {
    if (_items.isEmpty) return 100.0;
    final maxP = _items.fold(0.0, (maxVal, item) => item.price > maxVal ? item.price : maxVal);
    return maxP > 0 ? maxP : 100.0;
  }

  List<Item> get _filteredItems {
    final maxP = _maxItemPrice;
    final filtered = _items.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryIds.isEmpty ||
          _selectedCategoryIds.contains(item.category.id);
      final matchesItemType = _selectedItemTypes.isEmpty ||
          _selectedItemTypes.contains(item.itemType);
      final matchesGoalFilter = !_showOnlyGoalReached || item.isGoalReached;
      final matchesCurrentlyUsed = !_showOnlyCurrentlyUsed || item.isCurrentlyUsed;

      final minP = _minPriceFilter ?? 0.0;
      final maxPFilter = _maxPriceFilter ?? maxP;
      final matchesPrice = item.price >= minP && item.price <= (maxPFilter + 0.01);

      return matchesQuery &&
          matchesCategory &&
          matchesItemType &&
          matchesGoalFilter &&
          matchesCurrentlyUsed &&
          matchesPrice;
    }).toList();

    if (_sortOption != SortOption.defaultOrder) {
      final isAsc = _sortDirection == SortDirection.ascending;
      switch (_sortOption) {
        case SortOption.alphabetical:
          filtered.sort((a, b) => isAsc
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case SortOption.cost:
          filtered.sort((a, b) => isAsc
              ? a.effectiveTotalPrice.compareTo(b.effectiveTotalPrice)
              : b.effectiveTotalPrice.compareTo(a.effectiveTotalPrice));
          break;
        case SortOption.usageStreak:
          filtered.sort((a, b) => isAsc
              ? a.usageStreak.compareTo(b.usageStreak)
              : b.usageStreak.compareTo(a.usageStreak));
          break;
        case SortOption.defaultOrder:
          break;
      }
    } else if (_sortDirection == SortDirection.descending) {
      return filtered.reversed.toList();
    }

    return filtered;
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategoryIds = {};
      _selectedItemTypes = {};
      _showOnlyGoalReached = false;
      _showOnlyCurrentlyUsed = false;
      _minPriceFilter = null;
      _maxPriceFilter = null;
      _sortOption = SortOption.defaultOrder;
      _sortDirection = SortDirection.ascending;
    });
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
      _selectedCategoryIds.remove(categoryId);
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

  Future<void> _handleImportBackup({
    List<Item>? items,
    List<Category>? categories,
    BackupSettingsData? settings,
  }) async {
    setState(() {
      if (categories != null && categories.isNotEmpty) {
        final Map<String, Category> catMap = {
          for (final c in _categories) c.id: c,
        };
        for (final c in categories) {
          catMap[c.id] = c;
        }
        _categories = catMap.values.toList();
        StorageService.saveCategories(_categories);
      }

      if (items != null) {
        _items = items;
        StorageService.saveItems(_items);
      }

      if (settings != null) {
        if (settings.themeMode != null) {
          widget.onThemeModeChanged(settings.themeMode!);
        }
        if (settings.localeCode != null) {
          widget.onLocaleChanged(settings.localeCode!);
        }
        if (settings.showSegmentedProgressBar != null) {
          _showSegmentedProgressBar = settings.showSegmentedProgressBar!;
          StorageService.saveSegmentedProgressBar(_showSegmentedProgressBar);
        }
        if (settings.currency != null) {
          _currency = settings.currency!;
          StorageService.saveCurrency(_currency);
        }
      }
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          currentLocaleCode: widget.currentLocaleCode,
          onLocaleChanged: widget.onLocaleChanged,
          showSegmentedProgressBar: _showSegmentedProgressBar,
          onSegmentedProgressBarChanged: (value) {
            setState(() {
              _showSegmentedProgressBar = value;
            });
            StorageService.saveSegmentedProgressBar(value);
          },
          currency: _currency,
          onCurrencyChanged: (currency) {
            setState(() {
              _currency = currency;
            });
            StorageService.saveCurrency(currency);
          },
          onManageCategories: _openCategoryManager,
          items: _items,
          categories: _categories,
          onImportBackup: _handleImportBackup,
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

    if (oldStatus == MonthlyReviewStatus.used && newStatus != MonthlyReviewStatus.used) {
      current.usedDurationMonths = max(0, current.usedDurationMonths - 1);
      current.usageStreak = max(0, current.usageStreak - 1);
    } else if (oldStatus != MonthlyReviewStatus.used && newStatus == MonthlyReviewStatus.used) {
      current.usedDurationMonths += 1;
      current.usageStreak += 1;
    }

    switch (newStatus) {
      case MonthlyReviewStatus.used:
        current.lastReviewedMonthKey = Item.currentMonthKey;
        current.currentMonthUsed = true;
        break;
      case MonthlyReviewStatus.notUsed:
        current.lastReviewedMonthKey = Item.currentMonthKey;
        current.currentMonthUsed = false;
        current.usageStreak = 0;
        current.isDefaultUsed = false;
        break;
      case MonthlyReviewStatus.pending:
        current.lastReviewedMonthKey = null;
        current.currentMonthUsed = null;
        current.isDefaultUsed = false;
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
        currency: _currency,
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
        currency: _currency,
        onSave: _editItem,
        onAddCategory: _addCategory,
        onUpdateCategory: _updateCategory,
        onDeleteCategory: _deleteCategory,
      ),
    );
  }

  Widget _buildWideSidePanel(BuildContext context, ThemeData theme, bool isDarkMode) {
    final maxLimit = _maxItemPrice;
    final currentMin = (_minPriceFilter ?? 0.0).clamp(0.0, maxLimit);
    final currentMax = (_maxPriceFilter ?? maxLimit).clamp(currentMin, maxLimit);
    final noCategorySelected = _selectedCategoryIds.isEmpty;

    final isSingleExplicit = _selectedItemTypes.contains(ItemType.singlePurchase);
    final isSubscriptionExplicit = _selectedItemTypes.contains(ItemType.subscription);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2634) : theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: isDarkMode ? const Color(0xFF2E3B4E) : theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Section
                    Text('SEARCH ITEM', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Type item name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 2. Categories Section
                    Text('CATEGORIES', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ..._categories.map((cat) {
                      final isExplicitlySelected = _selectedCategoryIds.contains(cat.id);
                      final isChecked = noCategorySelected || isExplicitlySelected;
                      final isGrayCheck = noCategorySelected;

                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(cat.displayName, style: TextStyle(fontSize: 13, fontWeight: isExplicitlySelected ? FontWeight.bold : FontWeight.normal)),
                        secondary: Icon(cat.icon, size: 18, color: cat.color),
                        activeColor: isGrayCheck ? (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400) : theme.colorScheme.primary,
                        value: isChecked,
                        onChanged: (val) {
                          setState(() {
                            if (noCategorySelected) {
                              _selectedCategoryIds = {cat.id};
                            } else {
                              if (val == true) {
                                _selectedCategoryIds.add(cat.id);
                              } else {
                                _selectedCategoryIds.remove(cat.id);
                              }
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 3. Price Range Section
                    Text('PRICE RANGE', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('${_currency.format(currentMin)} – ${_currency.format(currentMax)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: RangeValues(currentMin, currentMax),
                      min: 0.0,
                      max: maxLimit,
                      onChanged: (v) {
                        setState(() {
                          _minPriceFilter = v.start <= 0.01 ? null : v.start;
                          _maxPriceFilter = v.end >= (maxLimit - 0.01) ? null : v.end;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 4. Status & Type Section
                    Text('STATUS & TYPE', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Subscription', style: TextStyle(fontSize: 13)),
                      value: isSubscriptionExplicit,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedItemTypes.add(ItemType.subscription);
                          } else {
                            _selectedItemTypes.remove(ItemType.subscription);
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Single Purchase', style: TextStyle(fontSize: 13)),
                      value: isSingleExplicit,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedItemTypes.add(ItemType.singlePurchase);
                          } else {
                            _selectedItemTypes.remove(ItemType.singlePurchase);
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Currently Used', style: TextStyle(fontSize: 13)),
                      value: _showOnlyCurrentlyUsed,
                      onChanged: (val) => setState(() => _showOnlyCurrentlyUsed = val ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Goal Reached', style: TextStyle(fontSize: 13)),
                      value: _showOnlyGoalReached,
                      onChanged: (val) => setState(() => _showOnlyGoalReached = val ?? false),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 5. Display & Sorting
                    Text('SORTING', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButton<SortOption>(
                      value: _sortOption,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: SortOption.defaultOrder, child: Text('Default Order')),
                        DropdownMenuItem(value: SortOption.alphabetical, child: Text('Alphabetically')),
                        DropdownMenuItem(value: SortOption.cost, child: Text('Cost / Price')),
                        DropdownMenuItem(value: SortOption.usageStreak, child: Text('Usage Streak')),
                      ],
                      onChanged: (opt) {
                        if (opt != null) setState(() => _sortOption = opt);
                      },
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<SortDirection>(
                      segments: const [
                        ButtonSegment(value: SortDirection.ascending, icon: Icon(Icons.arrow_upward, size: 16), label: Text('Asc')),
                        ButtonSegment(value: SortDirection.descending, icon: Icon(Icons.arrow_downward, size: 16), label: Text('Desc')),
                      ],
                      selected: {_sortDirection},
                      onSelectionChanged: (s) => setState(() => _sortDirection = s.first),
                    ),

                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Reset All Filters'),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final filtered = _filteredItems;
    final pendingCount = _pendingReviewCount;
    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Widget mainAppScaffold = Scaffold(
      extendBody: true,
      appBar: null,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            // TAB 0: Items List View
            ItemsView(
              items: filtered,
              categories: _categories,
              searchQuery: _searchQuery,
              selectedCategoryIds: _selectedCategoryIds,
              selectedItemTypes: _selectedItemTypes,
              showOnlyGoalReached: _showOnlyGoalReached,
              showOnlyCurrentlyUsed: _showOnlyCurrentlyUsed,
              maxItemPrice: _maxItemPrice,
              minPriceFilter: _minPriceFilter,
              maxPriceFilter: _maxPriceFilter,
              sortOption: _sortOption,
              sortDirection: _sortDirection,
              isFilterExpanded: _isFilterExpanded,
              showSegmentedProgressBar: _showSegmentedProgressBar,
              currency: _currency,
              onSearchQueryChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              onCategoryFilterChanged: (categoryIds) {
                setState(() {
                  _selectedCategoryIds = categoryIds;
                });
              },
              onItemTypeFilterChanged: (types) {
                setState(() {
                  _selectedItemTypes = types;
                });
              },
              onGoalFilterChanged: (goalOnly) {
                setState(() {
                  _showOnlyGoalReached = goalOnly;
                });
              },
              onCurrentlyUsedFilterChanged: (currentlyUsedOnly) {
                setState(() {
                  _showOnlyCurrentlyUsed = currentlyUsedOnly;
                });
              },
              onPriceFilterChanged: (minP, maxP) {
                setState(() {
                  _minPriceFilter = minP;
                  _maxPriceFilter = maxP;
                });
              },
              onApplySorting: (opt, dir) {
                setState(() {
                  _sortOption = opt;
                  _sortDirection = dir;
                });
              },
              onToggleFilter: () {
                setState(() {
                  _isFilterExpanded = !_isFilterExpanded;
                });
              },
              onResetFilters: _resetFilters,
              onOpenSettings: _openSettings,
              onEditItem: _openEditDialog,
              onDeleteItem: _deleteItem,
              onUpdateMonthlyStatus: _updateMonthlyStatus,
              onReorderItems: _reorderItems,
            ),

            // TAB 1: Monthly Review View
            ReviewView(
              items: _items,
              currency: _currency,
              onReviewItem: _handleReviewItem,
              onResetAllReviews: _resetAllReviews,
              onOpenSettings: _openSettings,
            ),

            // TAB 2: Statistics View
            StatisticsView(
              items: _items,
              currency: _currency,
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

    if (isWideScreen && _isFilterExpanded) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: _sidePanelWidth.clamp(
                  220.0,
                  (MediaQuery.of(context).size.width * 0.5).clamp(280.0, 600.0),
                ),
                child: _buildWideSidePanel(context, theme, isDarkMode),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    final maxW = (MediaQuery.of(context).size.width * 0.5).clamp(280.0, 600.0);
                    setState(() {
                      _sidePanelWidth = (_sidePanelWidth + details.delta.dx).clamp(220.0, maxW);
                    });
                  },
                  child: Container(
                    width: 14,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF3B485E)
                              : theme.colorScheme.outlineVariant,
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
              Expanded(
                child: mainAppScaffold,
              ),
            ],
          ),
        ),
      );
    }

    return mainAppScaffold;
  }
}