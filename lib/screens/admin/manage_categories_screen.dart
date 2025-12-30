import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/admin_provider.dart';
import '../../models/category.dart';
import '../../utils/theme.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchAllCategories());
  }

  void _showAddEditDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    File? selectedImage;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() => selectedImage = File(image.path));
                      }
                    },
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: selectedImage != null
                            ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                            : (category?.imageUrl != null
                                ? DecorationImage(image: CachedNetworkImageProvider(category!.imageUrl!), fit: BoxFit.cover)
                                : null),
                      ),
                      child: (selectedImage == null && category?.imageUrl == null)
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                bool success;
                if (category == null) {
                  success = await adminProvider.createCategory(
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    imageFile: selectedImage,
                  );
                } else {
                  success = await adminProvider.updateCategory(
                    id: category.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    imageFile: selectedImage,
                  );
                }

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(category == null ? 'Category added' : 'Category updated'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteCategory(category.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted')));
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
                  leading: category.imageUrl != null
                      ? CachedNetworkImage(imageUrl: category.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.category),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: category.description != null ? Text(category.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditDialog(category: category)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(category)),
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
