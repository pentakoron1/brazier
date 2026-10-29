import 'package:material_ui/material_ui.dart';

import '../models/item.dart';
import '../theme/app_theme.dart';

const Color fireOrange = AppColors.fireOrange; // Single unified Fire Orange Accent from AppTheme

class WinstreaksDetailScreen extends StatelessWidget {
  final List<Item> items;

  const WinstreaksDetailScreen({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final sortedItems = List<Item>.from(items)
      ..sort((a, b) => b.usageStreak.compareTo(a.usageStreak));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_fire_department, color: fireOrange),
            const SizedBox(width: 8),
            Text(
              'Usage Winstreaks',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: sortedItems.isEmpty
          ? Center(
              child: Text(
                'No items found.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          : Column(
              children: [
                // Column Headers Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Item',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Used / Goal',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Current Streak',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Items List
                Expanded(
                  child: ListView.separated(
                    itemCount: sortedItems.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = sortedItems[index];
                      final cat = item.category;
                      final hasStreak = item.usageStreak > 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Column 0: Category Icon + Item Name
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: cat.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                                    child: Icon(cat.icon, size: 14, color: cat.color),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Column 1: Used Months / Goal Months
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.usedDurationMonths} / ${item.goalDurationMonths} mo',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: item.isGoalReached
                                      ? fireOrange
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Column 2: Winstreak Badge
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: hasStreak
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                            const SizedBox(width: 3),
                                            Text(
                                              '${item.usageStreak} mo',
                                              style: TextStyle(
                                                color: isDarkMode ? const Color(0xFFFF9E80) : fireOrange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        'No streak',
                                        style: TextStyle(
                                          color: theme.colorScheme.outline,
                                          fontSize: 11,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
