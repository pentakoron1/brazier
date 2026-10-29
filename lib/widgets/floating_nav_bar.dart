import 'package:material_ui/material_ui.dart';
import 'dart:ui';
class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int pendingReviewCount;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.pendingReviewCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(

      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: NavigationBar(
                height: 64,
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha:0.3),
                surfaceTintColor: Colors.transparent,
                indicatorColor: Theme.of(context).colorScheme.primaryContainer,
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2),
                    label: 'Items',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: pendingReviewCount > 0,
                      label: Text('$pendingReviewCount'),
                      child: const Icon(Icons.rate_review_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: pendingReviewCount > 0,
                      label: Text('$pendingReviewCount'),
                      child: const Icon(Icons.rate_review),
                    ),
                    label: 'Review',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics),
                    label: 'Statistics',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
