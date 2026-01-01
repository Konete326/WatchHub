import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/category.dart';
import '../../utils/theme.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<AdminProvider>(context, listen: false)
        .fetchAllCategories());
  }

  void _showDuplicateError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Duplicate Category'),
          ],
        ),
        content: const Text(
            'A category with this name already exists. Please use a different name.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();

    // Dialog khulne se pehle purana error clear kar dein
    Provider.of<AdminProvider>(context, listen: false).clearError();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final adminProvider = Provider.of<AdminProvider>(context);

          return AlertDialog(
            title: Text(category == null ? 'Add Category' : 'Edit Category'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onChanged: (_) => adminProvider.clearError(),
                  ),

                  // Naya Error Message Section
                  if (adminProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        adminProvider.errorMessage!,
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: adminProvider.isLoading
                      ? null
                      : () {
                          adminProvider.clearError();
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: adminProvider.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final newName = nameController.text.trim();

                        // Check for duplicate name
                        final isDuplicate = adminProvider.categories.any((c) =>
                            c.name.toLowerCase() == newName.toLowerCase() &&
                            c.id != category?.id);

                        if (isDuplicate) {
                          _showDuplicateError();
                          return;
                        }

                        bool success;
                        if (category == null) {
                          success = await adminProvider.createCategory(
                            name: newName,
                          );
                        } else {
                          success = await adminProvider.updateCategory(
                            id: category.id,
                            name: newName,
                          );
                        }

                        if (success && mounted) {
                          if (Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(category == null
                                      ? 'Category added'
                                      : 'Category updated'),
                                  backgroundColor: AppTheme.successColor),
                            );
                          }
                        }
                      },
                child: adminProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete ${category.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success =
                  await Provider.of<AdminProvider>(context, listen: false)
                      .deleteCategory(category.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showAddEditDialog(category: category)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(category)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
