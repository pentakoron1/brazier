import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';
import 'items_detail_screen.dart';
import 'summary_card.dart';
import 'winstreaks_detail_screen.dart';

const Color fireOrange = AppColors.fireOrange; // Single unified Fire Orange Accent from AppTheme

class StatisticsView extends StatelessWidget {
  final List<Item> items;
  final Currency currency;

  const StatisticsView({
    super.key,
    required this.items,
    this.currency = Currency.euro,
  });

  void _navigateToDetailSubpage(
    BuildContext context,
    String title,
    List<Item> subpageItems, {
    Category? category,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemsDetailScreen(
          title: title,
          items: subpageItems,
          category: category,
          currency: currency,
        ),
      ),
    );
  }

  void _navigateToWinstreaksSubpage(BuildContext context, List<Item> allItems) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WinstreaksDetailScreen(items: allItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No statistics available yet.\nAdd items to see your cost analysis!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalSpent = items.fold(0.0, (sum, item) => sum + item.effectiveTotalPrice);
    final reachedGoals = items.where((i) => i.isGoalReached).toList();
    final inProgress = items.where((i) => !i.isGoalReached).toList();
    final activeStreaksCount = items.where((i) => i.usageStreak > 0).length;

    // Group items by category
    final Map<Category, List<Item>> categoryMap = {};
    for (final item in items) {
      categoryMap.putIfAbsent(item.category, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Summary Card (Clickable to open subpage with all items)
          SummaryCard(
            items: items,
            currency: currency,
            onTap: () => _navigateToDetailSubpage(
              context,
              'Overview Summary',
              items,
            ),
          ),

          const SizedBox(height: 8),

          // Goal Achievement Progress Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: fireOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Goal Achievement Status',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatusStatBox(
                            title: 'Goals Reached',
                            count: reachedGoals.length,
                            color: fireOrange,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatusStatBox(
                            title: 'In Progress',
                            count: inProgress.length,
                            color: isDarkMode ? const Color(0xFF3B485E) : const Color(0xFF64748B),
                            icon: Icons.timelapse,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Overall Completion: ${(reachedGoals.length / items.length * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: items.isNotEmpty ? reachedGoals.length / items.length : 0.0,
                        minHeight: 6,
                        backgroundColor: isDarkMode ? const Color(0xFF28303F) : theme.colorScheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(fireOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Usage Winstreaks Grid Section (Clickable to view winstreaks subpage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _navigateToWinstreaksSubpage(context, items),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: fireOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Winstreaks Grid',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: fireOrange.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$activeStreaksCount/${items.length} Active 🔥',
                              style: TextStyle(
                                color: isDarkMode ? const Color(0xFFFF9E80) : fireOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.outline,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Grid filled with points (Minimalist Disks & Fires)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: items.map((item) {
                          final hasStreak = item.usageStreak > 0;

                          if (hasStreak) {
                            // Fire Icon with Streak Number
                            return Tooltip(
                              message: '${item.name}: ${item.usageStreak} mo streak 🔥',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: fireOrange.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: fireOrange.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: fireOrange.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      size: 18,
                                      color: fireOrange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.usageStreak}',
                                      style: TextStyle(
                                        color: isDarkMode ? const Color(0xFFFF9E80) : fireOrange,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Simple Minimalist Disk / Dot
                            return Tooltip(
                              message: '${item.name}: No active streak',
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.outline,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Category Breakdown Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Cost Breakdown by Category (Tap to view items)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Category Cards (Clickable to open subpage with category items)
          ...categoryMap.entries.map((entry) {
            final category = entry.key;
            final catItems = entry.value;
            final categoryTotal = catItems.fold(0.0, (sum, i) => sum + i.effectiveTotalPrice);
            final categoryGoalRate = catItems.fold(0.0, (sum, i) => sum + i.goalPricePerMonth);
            final categoryUsedRate = catItems.fold(0.0, (sum, i) => sum + i.usedPricePerMonth);
            final categoryPercentage = totalSpent > 0 ? (categoryTotal / totalSpent) : 0.0;
            final catColor = category.color;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateToDetailSubpage(
                    context,
                    category.displayName,
                    catItems,
                    category: category,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: category.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                              child: Icon(category.icon, size: 18, color: catColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currency.format(categoryTotal),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.outline,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${catItems.length} ${catItems.length == 1 ? 'item' : 'items'} (${(categoryPercentage * 100).toStringAsFixed(0)}% of total)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Goal: ${currency.formatMonthly(categoryGoalRate, compact: true)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: categoryPercentage.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: isDarkMode ? const Color(0xFF253146) : theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(catColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Used Rate Equivalent:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currency.formatMonthly(categoryUsedRate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusStatBox extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusStatBox({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
