import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';

const Color fireOrange = AppColors.fireOrange; // Single unified Fire Orange Accent from AppTheme

/// Color of [gradient] at position [t] (0..1). Assumes evenly spaced stops.
/// Shared by SteppedProgressBar and the continuous bar.
Color sampleGradient(Gradient gradient, double t) {
  final colors = gradient.colors;
  if (colors.length == 1) return colors.first;
  final scaled = t.clamp(0.0, 1.0) * (colors.length - 1);
  final i = scaled.floor().clamp(0, colors.length - 2);
  return Color.lerp(colors[i], colors[i + 1], scaled - i)!;
}

/// [ratio] is used / goal and is NOT clamped: 1.0 = goal reached,
/// 1.25 = a quarter into the second cycle, and so on.
Widget continuousProgressBar({
  required double ratio,
  required Color trackColor,
  double height = 5,
  Gradient baseGradient = AppGradients.flameGradient,
}) {
  final safeRatio = (ratio.isNaN || ratio < 0) ? 0.0 : ratio;

  // Head position within the bar (0..1). A full cycle puts the head at the end.
  double head = safeRatio % 1;
  if (head == 0 && safeRatio > 0) head = 1;

  final goalReached = safeRatio >= 1;

  return ClipRRect(
    borderRadius: BorderRadius.circular(height * 1.2),
    child: Container(
      height: height,
      color: trackColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final headWidth = width * head;

          return Row(
            children: [
              // Part from the start of the bar up to the head.
              // At the head t = 1 (orange), going back it fades toward yellow.
              if (safeRatio > 0)
                Container(
                  width: headWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        sampleGradient(baseGradient, 1 - head),
                        sampleGradient(baseGradient, 1),
                      ],
                    ),
                  ),
                ),

              // Part after the head, only once the goal has been passed.
              // It holds the older steps of the previous cycle,
              // from t = 1 - head down to t = 0, left to right.
              if (goalReached && head < 1)
                Container(
                  width: width - headWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        sampleGradient(baseGradient, 0),
                        sampleGradient(baseGradient, 1 - head),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
class SteppedProgressBar extends StatelessWidget {
  final int goalMonths;
  final int usedMonths;
  final double minHeight;
  final Gradient baseGradient;

  const SteppedProgressBar({
    super.key,
    required this.goalMonths,
    required this.usedMonths,
    this.minHeight = 7.0,
    this.baseGradient = AppGradients.flameGradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final steps = goalMonths > 0 ? goalMonths : 1;
    final used = usedMonths < 0 ? 0 : usedMonths;
    final goalReached = used >= steps;

    // Index of the newest filled step (the head).
    // Equivalent to the continuous bar's head = ratio % 1 (1 at a full cycle).
    final headIndex = used == 0 ? -1 : (used - 1) % steps;

    final unfilledColor = isDarkMode
        ? const Color(0xFF28303F)
        : theme.colorScheme.surfaceContainerHighest;

    final gap = steps > 16 ? 1.5 : 2.5;

    return Row(
      children: List.generate(steps, (index) {
        final isFilled = goalReached || index < used;

        Gradient? gradient;
        if (isFilled) {
          // Steps behind the head, wrapping around the bar.
          final behind = (headIndex - index) % steps;

          // Head ends at t = 1 (orange); each step back moves toward t = 0.
          final tRight = 1 - behind / steps;
          final tLeft = 1 - (behind + 1) / steps;

          gradient = LinearGradient(
            colors: [
              sampleGradient(baseGradient, tLeft),
              sampleGradient(baseGradient, tRight),
            ],
          );
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == steps - 1 ? 0 : gap),
            height: minHeight,
            decoration: BoxDecoration(
              color: isFilled ? null : unfilledColor,
              gradient: gradient,
              borderRadius: BorderRadius.circular(minHeight / 2),
            ),
          ),
        );
      }),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Item item;
  final Currency defaultCurrency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<MonthlyReviewStatus> onUpdateMonthlyStatus;
  final bool showSegmentedProgressBar;

  const ItemCard({
    super.key,
    required this.item,
    this.defaultCurrency = Currency.defaultCurrency,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateMonthlyStatus,
    this.showSegmentedProgressBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isGoalReached = item.isGoalReached;
    final monthlyStatus = item.currentMonthlyStatus;
    final effectiveCurrency = item.getEffectiveCurrency(defaultCurrency);

    // All cards look identical regardless of goal completed or not
    final cardBgColor = isDarkMode ? const Color(0xFF1C222D) : theme.colorScheme.surface;
    final cardBorderColor = isDarkMode ? const Color(0xFF2B3342) : theme.colorScheme.outlineVariant;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cardBorderColor,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upper Content Group
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header: Badges (Category, Status Dropdown, Fire Streak, Goal Reached) wrapped safely + Actions Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Category Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.category.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.category.icon,
                                  size: 15,
                                  color: item.category.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.category.displayName,
                                  style: TextStyle(
                                    color: item.category.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Interactive Monthly Status Dropdown Chip
                          PopupMenuButton<MonthlyReviewStatus>(
                            tooltip: 'Change current month usage state',
                            onSelected: onUpdateMonthlyStatus,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: MonthlyReviewStatus.used,
                                child: Row(
                                  children: [
                                    const Icon(Icons.check, color: fireOrange, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      (enableDefaultAsUsedFeature && item.isDefaultUsed)
                                          ? 'Currently Used (Auto)'
                                          : 'Currently Used (+1 mo)',
                                      style: TextStyle(
                                        fontWeight: monthlyStatus == MonthlyReviewStatus.used
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: MonthlyReviewStatus.notUsed,
                                child: Row(
                                  children: [
                                    const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Not Used',
                                      style: TextStyle(
                                        fontWeight: monthlyStatus == MonthlyReviewStatus.notUsed
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: MonthlyReviewStatus.pending,
                                child: Row(
                                  children: [
                                    const Icon(Icons.rate_review_outlined, color: Colors.grey, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Needs Review',
                                      style: TextStyle(
                                        fontWeight: monthlyStatus == MonthlyReviewStatus.pending
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: monthlyStatus == MonthlyReviewStatus.used
                                    ? (isDarkMode ? Colors.white.withValues(alpha: 0.18) : Colors.black87)
                                    : (isDarkMode ? const Color(0xFF252E3E) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: monthlyStatus == MonthlyReviewStatus.used
                                      ? (isDarkMode ? Colors.white38 : Colors.black26)
                                      : theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    monthlyStatus == MonthlyReviewStatus.used
                                        ? Icons.check
                                        : monthlyStatus == MonthlyReviewStatus.notUsed
                                            ? Icons.close
                                            : Icons.help_outline,
                                    size: 13,
                                    color: monthlyStatus == MonthlyReviewStatus.used
                                        ? Colors.white
                                        : theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    monthlyStatus == MonthlyReviewStatus.used
                                        ? ((enableDefaultAsUsedFeature && item.isDefaultUsed)
                                            ? 'Currently used (Auto)'
                                            : 'Currently used')
                                        : monthlyStatus == MonthlyReviewStatus.notUsed
                                            ? 'Not used'
                                            : 'Needs review',
                                    style: TextStyle(
                                      color: monthlyStatus == MonthlyReviewStatus.used
                                          ? Colors.white
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: monthlyStatus == MonthlyReviewStatus.used
                                        ? Colors.white
                                        : theme.colorScheme.outline,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Fire Streak Badge (Winstreak)
                          if (item.usageStreak > 0)
                            Tooltip(
                              message: '${item.usageStreak} consecutive months used!',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: fireOrange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: fireOrange.withValues(alpha: 0.6)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      size: 14,
                                      color: fireOrange,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${item.usageStreak}',
                                      style: TextStyle(
                                        color: isDarkMode ? const Color(0xFFFF9E80) : fireOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Goal Reached Badge
                          if (isGoalReached)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppGradients.orangeGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stars, size: 13, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Goal Reached',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Edit / Delete Popup Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Color(0xFF64748B)),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Item Name & Total Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        effectiveCurrency.format(item.price),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Cost per Month Comparison Grid
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF242C3B) : theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF2E384A) : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Goal Duration Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.flag_outlined, size: 15, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Goal (${item.goalDurationMonths} mo)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                effectiveCurrency.format(item.goalPricePerMonth, showMonthly: true),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(width: 10),
                      // Used Duration Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.history,
                                  size: 15,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Used (${item.usedDurationMonths} mo)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.usedDurationMonths > 0
                                    ? effectiveCurrency.format(item.usedPricePerMonth, showMonthly: true)
                                    : 'N/A',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom Anchored Group (Progress Labels + Progress Bar)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Usage Progress',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${item.usedDurationMonths} / ${item.goalDurationMonths} months',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isGoalReached ? fireOrange : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Progress Bar (Stepped Segmented vs Continuous Linear)
                showSegmentedProgressBar
                    ? SteppedProgressBar(
                        goalMonths: item.goalDurationMonths,
                        usedMonths: item.usedDurationMonths,
                        minHeight: 7,
                      )
                    : continuousProgressBar(
                        ratio: item.progressRatio, // don't clamp it anymore
                        trackColor: isDarkMode
                            ? const Color(0xFF28303F)
                            : theme.colorScheme.surfaceContainerHighest,
                        height: 7,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CompactItemCard extends StatelessWidget {
  final Item item;
  final Currency defaultCurrency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<MonthlyReviewStatus> onUpdateMonthlyStatus;
  final bool showSegmentedProgressBar;

  const CompactItemCard({
    super.key,
    required this.item,
    this.defaultCurrency = Currency.defaultCurrency,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateMonthlyStatus,
    this.showSegmentedProgressBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final monthlyStatus = item.currentMonthlyStatus;
    final effectiveCurrency = item.getEffectiveCurrency(defaultCurrency);

    final cardBgColor = isDarkMode ? const Color(0xFF1C222D) : theme.colorScheme.surface;
    final cardBorderColor = isDarkMode ? const Color(0xFF2B3342) : theme.colorScheme.outlineVariant;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardBorderColor,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Category Icon Badge (ICON ONLY!), Status Dropdown, Fire Streak, Name, Price, Actions Menu
            Row(
              children: [
                // Category Badge (ICON ONLY)
                Tooltip(
                  message: item.category.displayName,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.category.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.category.icon,
                      size: 16,
                      color: item.category.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Compact Monthly Status Dropdown (ICON focused!)
                PopupMenuButton<MonthlyReviewStatus>(
                  tooltip: 'Change current month status',
                  onSelected: onUpdateMonthlyStatus,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: MonthlyReviewStatus.used,
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: fireOrange, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            (enableDefaultAsUsedFeature && item.isDefaultUsed)
                                ? 'Currently Used (Auto)'
                                : 'Currently Used (+1 mo)',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: MonthlyReviewStatus.notUsed,
                      child: Row(
                        children: [
                          const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                          const SizedBox(width: 8),
                          const Text('Not Used'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: MonthlyReviewStatus.pending,
                      child: Row(
                        children: [
                          const Icon(Icons.rate_review_outlined, color: Colors.grey, size: 18),
                          const SizedBox(width: 8),
                          const Text('Needs Review'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: monthlyStatus == MonthlyReviewStatus.used
                          ? (isDarkMode ? Colors.white.withValues(alpha: 0.18) : Colors.black87)
                          : (isDarkMode ? const Color(0xFF252E3E) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: monthlyStatus == MonthlyReviewStatus.used
                            ? (isDarkMode ? Colors.white38 : Colors.black26)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          monthlyStatus == MonthlyReviewStatus.used
                              ? Icons.check
                              : monthlyStatus == MonthlyReviewStatus.notUsed
                                  ? Icons.close
                                  : Icons.help_outline,
                          size: 13,
                          color: monthlyStatus == MonthlyReviewStatus.used
                              ? Colors.white
                              : theme.colorScheme.outline,
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: monthlyStatus == MonthlyReviewStatus.used
                              ? Colors.white
                              : theme.colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Fire Streak Badge
                if (item.usageStreak > 0) ...[
                  Tooltip(
                    message: '${item.usageStreak} consecutive months used!',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: fireOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: fireOrange.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            size: 13,
                            color: fireOrange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.usageStreak}',
                            style: TextStyle(
                              color: isDarkMode ? const Color(0xFFFF9E80) : fireOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Item Name
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Price
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    effectiveCurrency.format(item.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Popup Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Bottom Anchored Group (Used Rate & Month Numbers + Stepped Progress Bar)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Used Price per Month
                    Text(
                      item.usedDurationMonths > 0
                          ? effectiveCurrency.formatMonthly(item.usedPricePerMonth)
                          : 'N/A',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                    // Month Numbers
                    Text(
                      '${item.usedDurationMonths}/${item.goalDurationMonths} mo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: item.isGoalReached ? fireOrange : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Progress Bar (Stepped Segmented vs Continuous Linear)
                showSegmentedProgressBar
                    ? SteppedProgressBar(
                  goalMonths: item.goalDurationMonths,
                  usedMonths: item.usedDurationMonths,
                  minHeight: 5,
                )
                    : continuousProgressBar(
                  ratio: item.progressRatio, // don't clamp it anymore
                  trackColor: isDarkMode
                      ? const Color(0xFF28303F)
                      : theme.colorScheme.surfaceContainerHighest,
                  height: 5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
