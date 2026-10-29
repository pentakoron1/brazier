import 'package:material_ui/material_ui.dart';

import '../models/item.dart';

class CategoryManagerDialog extends StatefulWidget {
  final List<Category> categories;
  final ValueChanged<Category> onAddCategory;
  final ValueChanged<Category> onUpdateCategory;
  final ValueChanged<String> onDeleteCategory;

  const CategoryManagerDialog({
    super.key,
    required this.categories,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
  });

  @override
  State<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<CategoryManagerDialog> {
  void _openEditDialog([Category? category]) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        category: category,
        onSave: (cat) {
          if (category != null) {
            widget.onUpdateCategory(cat);
          } else {
            widget.onAddCategory(cat);
          }
          setState(() {});
        },
      ),
    );
  }

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
                    'Manage Categories',
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

            // Add Category Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add New Category'),
              ),
            ),
            const SizedBox(height: 16),

            // Category List
            Expanded(
              child: ListView.separated(
                itemCount: widget.categories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cat = widget.categories[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: cat.color.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                      child: Icon(cat.icon, size: 20, color: cat.color),
                    ),
                    title: Text(
                      cat.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Category',
                          onPressed: () => _openEditDialog(cat),
                        ),
                        if (widget.categories.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            tooltip: 'Delete Category',
                            onPressed: () {
                              widget.onDeleteCategory(cat.id);
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryEditDialog extends StatefulWidget {
  final Category? category;
  final ValueChanged<Category> onSave;

  const CategoryEditDialog({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  static List<IconData> get _availableIcons => Category.availableIcons;

  static const List<Color> _availableColors = [
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.pink,
    Colors.brown,
    Colors.blueGrey,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.displayName ?? '');
    _selectedIcon = cat?.icon ?? Icons.category;
    _selectedColor = cat?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedCat = Category(
        id: widget.category?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        displayName: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
      );

      widget.onSave(updatedCat);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isEditing = widget.category != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Category' : 'New Category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Icon Picker
                Text(
                  'Select Icon',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableIcons.map((icon) {
                    final selected = _selectedIcon == icon;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected
                              ? _selectedColor.withValues(alpha: 0.25)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? _selectedColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: selected ? _selectedColor : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Color Picker
                Text(
                  'Select Color',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableColors.map((color) {
                    final selected = _selectedColor == color;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: color,
                        child: selected
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Badge Preview
                Text(
                  'Preview Badge:',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_selectedIcon, size: 16, color: _selectedColor),
                      const SizedBox(width: 8),
                      Text(
                        _nameController.text.isEmpty ? 'Category Name' : _nameController.text,
                        style: TextStyle(
                          color: _selectedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(isEditing ? 'Save Category' : 'Create Category'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
