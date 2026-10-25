import 'package:flutter_test/flutter_test.dart';
import 'package:brazier/models/currency.dart';
import 'package:brazier/models/item.dart';

void main() {
  group('Currency Model Tests', () {
    test('Formats currency with symbol after (EUR)', () {
      const eur = Currency(
        code: 'EUR',
        symbol: '€',
        name: 'Euro',
        symbolPosition: CurrencySymbolPosition.after,
      );

      expect(eur.format(12.5), '12.50 €');
      expect(eur.format(12.5, showMonthly: true), '12.50 € / mo');
      expect(eur.formatMonthly(12.5), '12.50 €/mo');
    });

    test('Formats currency with symbol before (USD)', () {
      const usd = Currency(
        code: 'USD',
        symbol: '\$',
        name: 'US Dollar',
        symbolPosition: CurrencySymbolPosition.before,
      );

      expect(usd.format(12.5), '\$12.50');
      expect(usd.format(12.5, showMonthly: true), '\$12.50 / mo');
      expect(usd.formatMonthly(12.5), '\$12.50/mo');
    });

    test('Formats currency with 0 decimal digits (JPY)', () {
      const jpy = Currency(
        code: 'JPY',
        symbol: '¥',
        name: 'Japanese Yen',
        symbolPosition: CurrencySymbolPosition.before,
        decimalDigits: 0,
      );

      expect(jpy.format(1200), '¥1200');
      expect(jpy.formatMonthly(100), '¥100/mo');
    });

    test('Formats custom currency with custom decimals (e.g. Bitcoin / SEK)', () {
      const btc = Currency(
        code: 'BTC',
        symbol: '₿',
        name: 'Bitcoin',
        symbolPosition: CurrencySymbolPosition.before,
        decimalDigits: 4,
      );

      expect(btc.format(0.0123), '₿0.0123');

      const sek = Currency(
        code: 'SEK',
        symbol: 'kr',
        name: 'Swedish Krona',
        symbolPosition: CurrencySymbolPosition.after,
        decimalDigits: 2,
      );

      expect(sek.format(150), '150.00 kr');
    });

    test('Serialization and Deserialization for preset and custom currencies', () {
      const gbp = Currency(
        code: 'GBP',
        symbol: '£',
        name: 'British Pound (GBP)',
        symbolPosition: CurrencySymbolPosition.before,
      );

      final jsonGbp = gbp.toJson();
      final restoredGbp = Currency.fromJson(jsonGbp);

      expect(restoredGbp.code, 'GBP');
      expect(restoredGbp.symbol, '£');
      expect(restoredGbp.symbolPosition, CurrencySymbolPosition.before);

      const customCurrency = Currency(
        code: 'MYCUR',
        symbol: 'MC\$',
        name: 'My Custom Currency',
        symbolPosition: CurrencySymbolPosition.before,
        decimalDigits: 3,
      );

      final jsonCustom = customCurrency.toJson();
      final restoredCustom = Currency.fromJson(jsonCustom);

      expect(restoredCustom.code, 'MYCUR');
      expect(restoredCustom.symbol, 'MC\$');
      expect(restoredCustom.name, 'My Custom Currency');
      expect(restoredCustom.symbolPosition, CurrencySymbolPosition.before);
      expect(restoredCustom.decimalDigits, 3);
    });

    test('Preset currencies list contains major famous currencies', () {
      final codes = Currency.presetCurrencies.map((c) => c.code).toList();
      expect(codes, containsAll(['EUR', 'USD', 'GBP', 'JPY', 'CAD', 'AUD', 'SEK', 'MXN', 'INR', 'BRL', 'CNY']));
    });

    test('Item inherits or overrides default currency', () {
      const defaultEur = Currency.defaultCurrency;
      const usd = Currency(
        code: 'USD',
        symbol: '\$',
        name: 'US Dollar',
        symbolPosition: CurrencySymbolPosition.before,
      );

      final itemWithDefault = Item(
        id: '1',
        name: 'Test 1',
        price: 50.0,
        category: Category.defaultCategories.first,
        goalDurationMonths: 10,
        usedDurationMonths: 5,
      );

      final itemWithOverride = Item(
        id: '2',
        name: 'Test 2',
        price: 50.0,
        category: Category.defaultCategories.first,
        goalDurationMonths: 10,
        usedDurationMonths: 5,
        currency: usd,
      );

      expect(itemWithDefault.getEffectiveCurrency(defaultEur), defaultEur);
      expect(itemWithOverride.getEffectiveCurrency(defaultEur), usd);
    });
  });
}
