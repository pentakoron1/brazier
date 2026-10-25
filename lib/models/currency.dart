enum CurrencySymbolPosition {
  before, // e.g., $10.00
  after, // e.g., 10.00 €
}

class Currency {
  final String code;
  final String symbol;
  final String name;
  final CurrencySymbolPosition symbolPosition;
  final int decimalDigits;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.symbolPosition = CurrencySymbolPosition.after,
    this.decimalDigits = 2,
  });

  /// Formats a monetary amount based on this currency's settings.
  /// For example: 12.5 -> "12.50 €" or "$12.50"
  String format(double amount, {bool showMonthly = false}) {
    final formattedAmount = amount.toStringAsFixed(decimalDigits);
    final monthlySuffix = showMonthly ? ' / mo' : '';
    if (symbolPosition == CurrencySymbolPosition.before) {
      return '$symbol$formattedAmount$monthlySuffix';
    } else {
      return '$formattedAmount $symbol$monthlySuffix';
    }
  }

  /// Compact monthly format, e.g. "12.50 €/mo" or "$12.50/mo"
  String formatMonthly(double amount) {
    final formattedAmount = amount.toStringAsFixed(decimalDigits);
    if (symbolPosition == CurrencySymbolPosition.before) {
      return '$symbol$formattedAmount/mo';
    } else {
      return '$formattedAmount $symbol/mo';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'symbol': symbol,
      'name': name,
      'symbolPosition': symbolPosition.name,
      'decimalDigits': decimalDigits,
    };
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? 'EUR';
    final symbol = json['symbol'] as String? ?? '€';
    final name = json['name'] as String? ?? 'Euro';
    final symbolPositionStr = json['symbolPosition'] as String?;
    final symbolPosition = symbolPositionStr == 'before'
        ? CurrencySymbolPosition.before
        : CurrencySymbolPosition.after;
    final decimalDigits = json['decimalDigits'] as int? ?? 2;

    // Check if it matches a preset
    for (final preset in presetCurrencies) {
      if (preset.code == code && preset.symbol == symbol) {
        return preset;
      }
    }

    return Currency(
      code: code,
      symbol: symbol,
      name: name,
      symbolPosition: symbolPosition,
      decimalDigits: decimalDigits,
    );
  }

  static const List<Currency> presetCurrencies = [
    Currency(
      code: 'EUR',
      symbol: '€',
      name: 'Euro (EUR)',
      symbolPosition: CurrencySymbolPosition.after,
    ),
    Currency(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar (USD)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound (GBP)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen (JPY)',
      symbolPosition: CurrencySymbolPosition.before,
      decimalDigits: 0,
    ),
    Currency(
      code: 'CAD',
      symbol: 'CA\$',
      name: 'Canadian Dollar (CAD)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'AUD',
      symbol: 'A\$',
      name: 'Australian Dollar (AUD)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'CHF',
      symbol: 'CHF',
      name: 'Swiss Franc (CHF)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee (INR)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'BRL',
      symbol: 'R\$',
      name: 'Brazilian Real (BRL)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'CNY',
      symbol: '¥',
      name: 'Chinese Yuan (CNY)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'KRW',
      symbol: '₩',
      name: 'South Korean Won (KRW)',
      symbolPosition: CurrencySymbolPosition.before,
      decimalDigits: 0,
    ),
    Currency(
      code: 'MXN',
      symbol: 'MEX\$',
      name: 'Mexican Peso (MXN)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'SGD',
      symbol: 'S\$',
      name: 'Singapore Dollar (SGD)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'HKD',
      symbol: 'HK\$',
      name: 'Hong Kong Dollar (HKD)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'SEK',
      symbol: 'kr',
      name: 'Swedish Krona (SEK)',
      symbolPosition: CurrencySymbolPosition.after,
    ),
    Currency(
      code: 'NOK',
      symbol: 'kr',
      name: 'Norwegian Krone (NOK)',
      symbolPosition: CurrencySymbolPosition.after,
    ),
    Currency(
      code: 'DKK',
      symbol: 'kr.',
      name: 'Danish Krone (DKK)',
      symbolPosition: CurrencySymbolPosition.after,
    ),
    Currency(
      code: 'PLN',
      symbol: 'zł',
      name: 'Polish Zloty (PLN)',
      symbolPosition: CurrencySymbolPosition.after,
    ),
    Currency(
      code: 'TRY',
      symbol: '₺',
      name: 'Turkish Lira (TRY)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'RUB',
      symbol: '₽',
      name: 'Russian Ruble (RUB)',
      symbolPosition: CurrencySymbolPosition.after,
    ),
    Currency(
      code: 'AED',
      symbol: 'AED',
      name: 'UAE Dirham (AED)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand (ZAR)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
    Currency(
      code: 'NZD',
      symbol: 'NZ\$',
      name: 'New Zealand Dollar (NZD)',
      symbolPosition: CurrencySymbolPosition.before,
    ),
  ];

  static const Currency defaultCurrency = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro (EUR)',
    symbolPosition: CurrencySymbolPosition.after,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          symbol == other.symbol &&
          symbolPosition == other.symbolPosition &&
          decimalDigits == other.decimalDigits;

  @override
  int get hashCode =>
      code.hashCode ^
      symbol.hashCode ^
      symbolPosition.hashCode ^
      decimalDigits.hashCode;
}
