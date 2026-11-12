import 'package:material_ui/material_ui.dart';

/// Structured information section for [InfoDialog].
class InfoSection {
  final String title;
  final String description;
  final String? example;
  final IconData? icon;

  const InfoSection({
    required this.title,
    required this.description,
    this.example,
    this.icon,
  });
}

/// A reusable, responsive information dialog component.
///
/// Can be customized with [title], [icon], [content], or [sections],
/// or used with zero arguments to display default usage information.
class InfoDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? content;
  final List<InfoSection>? sections;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;

  const InfoDialog({
    super.key,
    this.title = 'How Brazier Works',
    this.icon = Icons.lightbulb_outline,
    this.content,
    this.sections = _defaultUsageSections,
    this.primaryActionText,
    this.onPrimaryAction,
  });

  /// Predefined default sections explaining Brazier's monthly cost calculations.
  static const List<InfoSection> _defaultUsageSections = [
    InfoSection(
      title: 'Value Per Month',
      description:
          'The price per month is calculated based on how much you actively use the item.',
      icon: Icons.calculate_outlined,
    ),
    InfoSection(
      title: 'One-Time Purchases',
      description:
          'The more you use the item over time, the lower its effective monthly cost becomes.',
      example:
          'If you bought a computer for 1,000€ and have used it for 10 months, it is equivalent to paying 100€/month.',
      icon: Icons.shopping_bag_outlined,
    ),
    InfoSection(
      title: 'Subscriptions',
      description:
          'Subscriptions cost more per month if not used consistently, as the total cost is divided only by the months you actually used it.',
      icon: Icons.autorenew_outlined,
    ),
  ];

  /// Convenient helper method to display any InfoDialog anywhere in the app.
  static Future<T?> show<T>({
    required BuildContext context,
    String title = 'Information',
    IconData icon = Icons.info_outline,
    Widget? content,
    List<InfoSection>? sections,
    String? primaryActionText,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        icon: icon,
        content: content,
        sections: sections,
        primaryActionText: primaryActionText,
      ),
    );
  }

  /// Convenient helper method to display the usage information dialog.
  static Future<T?> showUsageInfo<T>(BuildContext context) {
    return showDialog<T>(
      context: context,
      builder: (context) => const InfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentContent = content;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Scrollable Content Body
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?currentContent,
                    if (sections != null && sections!.isNotEmpty)
                      ...sections!.map((section) => _buildSection(context, section)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Footer / Action Button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onPrimaryAction ?? () => Navigator.of(context).pop(),
                child: Text(primaryActionText ?? 'Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, InfoSection section) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (section.icon != null) ...[
                Icon(
                  section.icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            section.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          if (section.example != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.example!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
