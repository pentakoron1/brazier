import 'package:material_ui/material_ui.dart';

class InfoDialog extends StatefulWidget {

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.category_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'How Brazier Works:',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
                  "\n\nThe price per month is based on how much you are using the item"
                  "\nFor example:\nIf you bought a computer at 1000€ and you've been using it for 10 months, then it's the equivalent of paying 100€ per month.\nSo the more you use the item, the less you pay per month."
                  "\nFor subscriptions, you then pay more per month if you not use it all the time, because the total price gets divided only by the months where you used it."
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}