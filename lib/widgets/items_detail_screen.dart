import 'dart:math';
import 'package:material_ui/material_ui.dart';

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
  final Currency currency;

  const ItemsDetailScreen({
    super.key,
    required this.title,
    required this.items,
    this.category,
    this.currency = Currency.euro,
  });

  void _showCostExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: fireOrange),
            SizedBox(width: 8),
            Text('Monthly Cost Metrics'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target Monthly Cost:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'The total planned monthly cost if every item is used for its goal duration.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'Current Monthly Cost:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'The sum of current monthly cost rates across all items in this list.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'Active Monthly Cost:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'The sum of current monthly costs for ONLY the items you currently use this month. Items not used this month are excluded because you do not incur active usage cost for them. Subscriptions are always counted in the active cost, as you always have to pay for them.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTable(BuildContext context, ThemeData theme, bool isDarkMode) {
    final targetCost = items.fold(0.0, (sum, i) => sum + i.goalPricePerMonth);
    final currentCost = items.fold(
      0.0,
      (sum, i) => sum + (i.usedDurationMonths > 0 ? i.usedPricePerMonth : i.goalPricePerMonth),
    );
    final activeCost = items.where((i) => i.isCurrentlyUsed).fold(
      0.0,
      (sum, i) => sum + (i.usedDurationMonths > 0 ? i.usedPricePerMonth : i.goalPricePerMonth),
    );
    final activeCount = items.where((i) => i.isCurrentlyUsed).length;

    Widget buildMetricColumn({
      required String label,
      required String value,
      required String subtitle,
      required Color color,
      required IconData icon,
      required VoidCallback onTapInfo,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF232C3A)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF2E3B4E) : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C2330) : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2B3648) : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 20, color: fireOrange),
                  const SizedBox(width: 8),
                  Text(
                    'Monthly Cost Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                tooltip: 'How metrics are calculated',
                onPressed: () => _showCostExplanationDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 400;

              if (isCompact) {
                return Column(
                  children: [
                    Row(
                      children: [
                        buildMetricColumn(
                          label: 'Target Cost',
                          value: currency.formatMonthly(targetCost, compact: true),
                          subtitle: 'Goal rate',
                          color: theme.colorScheme.primary,
                          icon: Icons.flag_outlined,
                          onTapInfo: () => _showCostExplanationDialog(context),
                        ),
                        const SizedBox(width: 8),
                        buildMetricColumn(
                          label: 'Current Cost',
                          value: currency.formatMonthly(currentCost, compact: true),
                          subtitle: 'All ${items.length} items',
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                          icon: Icons.calculate_outlined,
                          onTapInfo: () => _showCostExplanationDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        buildMetricColumn(
                          label: 'Active Cost',
                          value: currency.formatMonthly(activeCost, compact: true),
                          subtitle: '$activeCount currently used',
                          color: fireOrange,
                          icon: Icons.local_fire_department_outlined,
                          onTapInfo: () => _showCostExplanationDialog(context),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  buildMetricColumn(
                    label: 'Target Cost',
                    value: currency.formatMonthly(targetCost, compact: true),
                    subtitle: 'Goal rate',
                    color: theme.colorScheme.primary,
                    icon: Icons.flag_outlined,
                    onTapInfo: () => _showCostExplanationDialog(context),
                  ),
                  const SizedBox(width: 8),
                  buildMetricColumn(
                    label: 'Current Cost',
                    value: currency.formatMonthly(currentCost, compact: true),
                    subtitle: 'All ${items.length} items',
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                    icon: Icons.calculate_outlined,
                    onTapInfo: () => _showCostExplanationDialog(context),
                  ),
                  const SizedBox(width: 8),
                  buildMetricColumn(
                    label: 'Active Cost',
                    value: currency.formatMonthly(activeCost, compact: true),
                    subtitle: '$activeCount active',
                    color: fireOrange,
                    icon: Icons.local_fire_department_outlined,
                    onTapInfo: () => _showCostExplanationDialog(context),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Baseline scaling: max total price and max monthly cost across items in this subpage
    final maxPrice = items.fold(0.0, (maxVal, item) => item.effectiveTotalPrice > maxVal ? item.effectiveTotalPrice : maxVal);
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
              itemCount: items.length + 1,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSummaryTable(context, theme, isDarkMode);
                }

                final item = items[index - 1];
                final cat = item.category;

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
                          borderRadius: BorderRadius.circular(4),
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
                                          decoration: BoxDecoration(
                                            gradient: AppGradients.flameGradient,
                                            borderRadius: BorderRadius.all(Radius.circular(4)),
                                          ),
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
                                    'Target Goal (${item.goalDurationMonths} mo): ${currency.formatMonthly(item.goalPricePerMonth, compact: true)}',
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
                            label: item.isSubscription ? 'Total Cost:' : 'Total Price:',
                            value: currency.format(item.effectiveTotalPrice),
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
                            value: item.usedDurationMonths > 0
                                ? currency.formatMonthly(item.usedPricePerMonth, compact: true)
                                : currency.formatMonthly(item.goalPricePerMonth, compact: true),
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
