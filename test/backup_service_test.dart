import 'package:brazier/models/currency.dart';
import 'package:brazier/models/item.dart';
import 'package:brazier/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final defaultCat = Category(
    id: 'devices',
    displayName: 'Devices',
    icon: Icons.devices,
    color: Colors.blue,
  );

  final sampleItems = [
    Item(
      id: '1',
      name: 'Smartphone "Pro", Max',
      itemType: ItemType.singlePurchase,
      price: 999.99,
      category: defaultCat,
      goalDurationMonths: 24,
      usedDurationMonths: 12,
      lastReviewedMonthKey: '2025-05',
      currentMonthUsed: true,
      isDefaultUsed: false,
      usageStreak: 12,
    ),
    Item(
      id: '2',
      name: 'Gym Subscription',
      itemType: ItemType.subscription,
      price: 30.0,
      category: defaultCat,
      goalDurationMonths: 6,
      usedDurationMonths: 6,
      lastReviewedMonthKey: '2025-05',
      currentMonthUsed: true,
      isDefaultUsed: true,
      usageStreak: 6,
    ),
  ];

  test('Export and import items data only', () {
    final csvContent = BackupService.createCsvBackup(
      saveItemsData: true,
      saveSettings: false,
      items: sampleItems,
      categories: [defaultCat],
      themeMode: ThemeMode.dark,
      localeCode: 'en',
      showSegmentedProgressBar: true,
      currency: Currency.euro,
    );

    expect(csvContent.contains('# ITEMS'), true);
    expect(csvContent.contains('# SETTINGS'), false);

    final parsedBackup = BackupService.parseCsvBackup(csvContent, [defaultCat]);

    expect(parsedBackup.hasData, true);
    expect(parsedBackup.settings, null);
    expect(parsedBackup.items?.length, 2);
    expect(parsedBackup.items?.first.name, 'Smartphone "Pro", Max');
    expect(parsedBackup.items?.first.price, 999.99);
    expect(parsedBackup.items?.last.itemType, ItemType.subscription);
  });

  test('Export and import settings data only', () {
    final csvContent = BackupService.createCsvBackup(
      saveItemsData: false,
      saveSettings: true,
      items: sampleItems,
      categories: [defaultCat],
      themeMode: ThemeMode.dark,
      localeCode: 'en',
      showSegmentedProgressBar: false,
      currency: Currency.usDollar,
    );

    expect(csvContent.contains('# ITEMS'), false);
    expect(csvContent.contains('# SETTINGS'), true);
    expect(csvContent.contains('USD'), true);

    final parsedBackup = BackupService.parseCsvBackup(csvContent, [defaultCat]);

    expect(parsedBackup.hasData, true);
    expect(parsedBackup.items, null);
    expect(parsedBackup.settings?.themeMode, ThemeMode.dark);
    expect(parsedBackup.settings?.showSegmentedProgressBar, false);
    expect(parsedBackup.settings?.currency?.code, 'USD');
  });

  test('Export and import both items and settings', () {
    final csvContent = BackupService.createCsvBackup(
      saveItemsData: true,
      saveSettings: true,
      items: sampleItems,
      categories: [defaultCat],
      themeMode: ThemeMode.light,
      localeCode: 'es',
      showSegmentedProgressBar: true,
      currency: Currency.euro,
    );

    expect(csvContent.contains('# ITEMS'), true);
    expect(csvContent.contains('# SETTINGS'), true);

    final parsedBackup = BackupService.parseCsvBackup(csvContent, [defaultCat]);

    expect(parsedBackup.hasData, true);
    expect(parsedBackup.items?.length, 2);
    expect(parsedBackup.settings?.themeMode, ThemeMode.light);
    expect(parsedBackup.settings?.currency?.code, 'EUR');
  });
}
