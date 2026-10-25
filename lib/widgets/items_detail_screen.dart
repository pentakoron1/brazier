import 'dart:math';
import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';

const Color fireOrange = AppColors.fireOrange; // Single unified Fire Orange Accent from AppTheme

/// Label + bar + value. Switches to a stacked layout when space is tight.
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Widget bar;
  final bool compact;
  final double valueWidth;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.bar,
    required this.compact,
    this.labelStyle,
    this.valueStyle,
  }) : valueWidth = 80;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Label (left) and value (right) above the bar
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(value, textAlign: TextAlign.right, style: valueStyle),
            ],
          ),
          const SizedBox(height: 4),
          bar,
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: labelStyle)),
        Expanded(child: bar),
        const SizedBox(width: 12),
        SizedBox(
          width: valueWidth,
          child: Text(value, textAlign: TextAlign.right, style: valueStyle),
        ),
      ],
    );
  }
}

class ItemsDetailScreen extends StatelessWidget {
  final String title;
  final List<Item> items;
  final Category? category;
  final Currency defaultCurrency;

  const ItemsDetailScreen({
    super.key,
    required this.title,
    required this.items,
    this.category,
    this.defaultCurrency = Currency.defaultCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Baseline scaling: max total price and max monthly cost across items in this subpage
    final maxPrice = items.fold(0.0, (maxVal, item) => item.price > maxVal ? item.price : maxVal);
    final maxMonthlyCost = items.fold(0.0, (maxVal, item) {
      final usedCost = item.usedDurationMonths > 0 ? item.usedPricePerMonth : item.goalPricePerMonth;
      final itemMax = max(item.goalPricePerMonth, usedCost);
      return itemMax > maxVal ? itemMax : maxVal;
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (category != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: category!.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                child: Icon(category!.icon, size: 16, color: category!.color),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No items found in this section.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final cat = item.category;
                final effectiveCurrency = item.getEffectiveCurrency(defaultCurrency);

                // Total Price ratio (scaled to maxPrice)
                final priceRatio = maxPrice > 0 ? (item.price / maxPrice).clamp(0.05, 1.0) : 0.0;

                // Monthly Progress ratios (scaled relative to maxMonthlyCost)
                final usedPrice = item.usedDurationMonths > 0 ? item.usedPricePerMonth : item.goalPricePerMonth;
                final goalRatio = maxMonthlyCost > 0 ? (item.goalPricePerMonth / maxMonthlyCost).clamp(0.02, 1.0) : 0.0;
                final usedRatio = maxMonthlyCost > 0 ? (usedPrice / maxMonthlyCost).clamp(0.02, 1.0) : 0.0;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1C222D) : theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF2B3342) : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // threshold that switches the layout when the display is too small
                      final compact = constraints.maxWidth < 420;

                      final labelStyle = theme.textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      );

                      final priceBar = ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: priceRatio,
                          minHeight: 6,
                          backgroundColor: isDarkMode
                              ? const Color(0xFF28303F)
                              : theme.colorScheme.surfaceContainerHighest,
                        ),
                      );

                      final monthlyBar = LayoutBuilder(
                        builder: (context, c) {
                          final totalWidth = c.maxWidth;
                          final goalLeft = totalWidth > 0 ? (totalWidth * goalRatio).clamp(0.0, totalWidth) : 0.0;
                          final maxMarkerLeft = max(0.0, totalWidth - 8);
                          final markerLeft = maxMarkerLeft > 0 ? (goalLeft - 4).clamp(0.0, maxMarkerLeft) : 0.0;

                          return SizedBox(
                            height: 8,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0, right: 0, top: 1, height: 6,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF28303F)
                                          : theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 0, right: 0, top: 1, height: 6,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: usedRatio.clamp(0.0, 1.0),
                                        heightFactor: 1,
                                        child: const DecoratedBox(
                                          decoration: BoxDecoration(gradient: AppGradients.flameGradient),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: markerLeft,
                                  top: 0,
                                  child: Tooltip(
                                    message:
                                        'Target Goal (${item.goalDurationMonths} mo): ${effectiveCurrency.formatMonthly(item.goalPricePerMonth)}',
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.flameOrange, width: 1.5),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: cat.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                                child: Icon(cat.icon, size: 16, color: cat.color),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (item.isGoalReached)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: fireOrange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Goal Reached',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _MetricRow(
                            compact: compact,
                            label: 'Total Price:',
                            value: effectiveCurrency.format(item.price),
                            labelStyle: labelStyle,
                            valueStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                            bar: priceBar,
                          ),
                          SizedBox(height: compact ? 12 : 10),

                          _MetricRow(
                            compact: compact,
                            label: 'Monthly Cost:',
                            value: effectiveCurrency.formatMonthly(
                              item.usedDurationMonths > 0
                                  ? item.usedPricePerMonth
                                  : item.goalPricePerMonth,
                            ),
                            labelStyle: labelStyle,
                            valueStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: item.isGoalReached ? fireOrange : null,
                            ),
                            bar: monthlyBar,
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
