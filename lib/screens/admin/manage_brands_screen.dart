import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/admin_provider.dart';
import '../../models/brand.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/admin/admin_layout.dart';

class ManageBrandsScreen extends StatefulWidget {
  const ManageBrandsScreen({super.key});

  @override
  State<ManageBrandsScreen> createState() => _ManageBrandsScreenState();
}

class _ManageBrandsScreenState extends State<ManageBrandsScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchAllBrands());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDuplicateError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Duplicate Brand'),
          ],
        ),
        content: const Text(
            'A brand with this name already exists. Please use a different name.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showAddEditDialog({Brand? brand}) {
    final nameController = TextEditingController(text: brand?.name ?? '');
    final descController =
        TextEditingController(text: brand?.description ?? '');
    XFile? selectedImage;
    final formKey = GlobalKey<FormState>();

    Provider.of<AdminProvider>(context, listen: false).clearError();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final adminProvider = Provider.of<AdminProvider>(context);

          return AlertDialog(
            title: Text(brand == null ? 'Add Brand' : 'Edit Brand'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 70);
                        if (image != null)
                          setDialogState(() => selectedImage = image);
                      },
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          image: selectedImage != null
                              ? null
                              : (brand?.logoUrl != null &&
                                      brand!.logoUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          brand.logoUrl!),
                                      fit: BoxFit.contain)
                                  : null),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: FutureBuilder<Uint8List>(
                                    future: selectedImage!.readAsBytes(),
                                    builder: (context, snapshot) => snapshot
                                            .hasData
                                        ? Image.memory(snapshot.data!,
                                            fit: BoxFit.contain)
                                        : const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))))
                            : (brand?.logoUrl == null ||
                                    brand!.logoUrl!.isEmpty)
                                ? const Icon(Icons.business_outlined,
                                    size: 40, color: Colors.grey)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: 'Brand Name',
                          border: OutlineInputBorder()),
                      validator: (v) => Validators.required(v, 'Name'),
                      onChanged: (_) => adminProvider.clearError(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    if (adminProvider.errorMessage != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(adminProvider.errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: adminProvider.isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: adminProvider.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final newName =
                            InputSanitizer.sanitize(nameController.text);
                        final newDesc =
                            InputSanitizer.sanitize(descController.text);
                        final isDuplicate = adminProvider.brands.any((b) =>
                            b.name.toLowerCase() == newName.toLowerCase() &&
                            b.id != brand?.id);
                        if (isDuplicate) {
                          _showDuplicateError();
                          return;
                        }
                        bool success = brand == null
                            ? await adminProvider.createBrand(
                                name: newName,
                                description: newDesc.isEmpty ? null : newDesc,
                                logoFile: selectedImage)
                            : await adminProvider.updateBrand(
                                id: brand.id,
                                name: newName,
                                description: newDesc.isEmpty ? null : newDesc,
                                logoFile: selectedImage);
                        if (success && mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(brand == null
                                  ? 'Brand added'
                                  : 'Brand updated'),
                              backgroundColor: AppTheme.successColor));
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

  void _deleteBrand(Brand brand) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brand'),
        content: Text('Are you sure you want to delete ${brand.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success =
                  await Provider.of<AdminProvider>(context, listen: false)
                      .deleteBrand(brand.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Brand deleted')));
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
    return AdminLayout(
      title: 'Manage Brands',
      currentRoute: '/admin/brands',
      actions: [
        IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditDialog(),
            tooltip: 'Add Brand'),
      ],
      child: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          final filteredBrands = provider.brands
              .where((b) =>
                  b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search brands...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: provider.isLoading && provider.brands.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredBrands.isEmpty
                        ? const Center(child: Text('No brands found'))
                        : RefreshIndicator(
                            onRefresh: () => provider.fetchAllBrands(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredBrands.length,
                              itemBuilder: (context, index) {
                                final brand = filteredBrands[index];
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: Colors.grey.shade200)),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: brand.logoUrl != null &&
                                              brand.logoUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: brand.logoUrl!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.contain)
                                          : Container(
                                              width: 40,
                                              height: 40,
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                  Icons.business_outlined)),
                                    ),
                                    title: Text(brand.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: brand.description != null
                                        ? Text(brand.description!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 20,
                                                color: Colors.blue),
                                            onPressed: () => _showAddEditDialog(
                                                brand: brand)),
                                        IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deleteBrand(brand)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
