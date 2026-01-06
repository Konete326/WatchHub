import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/foundation.dart';
import 'dart:io';
=======
import 'package:flutter/foundation.dart' show kIsWeb;
>>>>>>> 901f25d8b804aa5f2b3d8401be6831ddb03f5199
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../services/watch_service.dart';
import '../../models/watch.dart';
import '../../models/brand.dart';
import '../../models/category.dart' as model;
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class AddEditProductScreen extends StatefulWidget {
  final Watch? watch;

  const AddEditProductScreen({super.key, this.watch});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _movementController = TextEditingController();
  final _caseMaterialController = TextEditingController();
  final _waterResistanceController = TextEditingController();
  final _diameterController = TextEditingController();
  final _discountController = TextEditingController();

  final AdminService _adminService = AdminService();
  final WatchService _watchService = WatchService();
  final ImagePicker _imagePicker = ImagePicker();

  List<Brand> _brands = [];
  List<model.Category> _categories = [];
  String? _selectedBrandId;
  String? _selectedCategory;
<<<<<<< HEAD
  List<File> _selectedImages = [];
  List<Uint8List> _selectedImageBytes = []; // For web platform
  List<String> _selectedImageDataUrls = []; // For web preview
=======
  List<XFile> _selectedImages = []; // Use XFile for both web and mobile
>>>>>>> 901f25d8b804aa5f2b3d8401be6831ddb03f5199
  List<String> _existingImageUrls = [];
  bool _isLoading = false;
  bool _isLoadingBrands = false;
  bool _isLoadingCategories = false;
  bool _hasBeltOption = false; // Whether belt option is available
  bool _hasChainOption = false; // Whether chain option is available

  @override
  void initState() {
    super.initState();
    _loadBrands();
    _loadCategories();
    if (widget.watch != null) {
      _nameController.text = widget.watch!.name;
      _skuController.text = widget.watch!.sku;
      _descriptionController.text = widget.watch!.description;
      _priceController.text = widget.watch!.price.toString();
      _stockController.text = widget.watch!.stock.toString();
      _selectedBrandId = widget.watch!.brandId;
      _selectedCategory = widget.watch!.category;
      _existingImageUrls = List<String>.from(widget.watch!.images);

      if (widget.watch!.specifications != null) {
        _movementController.text =
            widget.watch!.specifications!['movement'] ?? '';
        _caseMaterialController.text =
            widget.watch!.specifications!['caseMaterial'] ?? '';
        _waterResistanceController.text =
            widget.watch!.specifications!['waterResistance'] ?? '';
        _diameterController.text =
            widget.watch!.specifications!['diameter'] ?? '';
      }
      if (widget.watch!.discountPercentage != null) {
        _discountController.text = widget.watch!.discountPercentage.toString();
      }
      _hasBeltOption = widget.watch!.hasBeltOption;
      _hasChainOption = widget.watch!.hasChainOption;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _movementController.dispose();
    _caseMaterialController.dispose();
    _waterResistanceController.dispose();
    _diameterController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);
    try {
      final brands = await _watchService.getBrands();
      if (mounted) {
        setState(() {
          _brands = brands;
          // Validate that selected brand still exists in the list
          if (_selectedBrandId != null &&
              !_brands.any((b) => b.id == _selectedBrandId)) {
            _selectedBrandId = null;
          }
          _isLoadingBrands = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBrands = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load brands: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await _watchService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          // Validate that selected category still exists in the list
          if (_selectedCategory != null &&
              !_categories.any((c) => c.name == _selectedCategory)) {
            _selectedCategory = null;
          }
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
<<<<<<< HEAD
      final images = await _imagePicker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) {
        final totalExisting = _existingImageUrls.length;
        final totalSelected =
            kIsWeb ? _selectedImageBytes.length : _selectedImages.length;
        final remainingSlots =
            Constants.maxProductImages - totalSelected - totalExisting;

        if (remainingSlots <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Maximum ${Constants.maxProductImages} images allowed')),
          );
          return;
        }

        final imagesToAdd = images.take(remainingSlots);

        if (kIsWeb) {
          // Web platform: read as bytes
          for (final xfile in imagesToAdd) {
            final bytes = await xfile.readAsBytes();
            _selectedImageBytes.add(bytes);
            // Create a data URL for preview
            _selectedImageDataUrls.add(xfile.path);
          }
        } else {
          // Mobile platform: use File
          for (final xfile in imagesToAdd) {
            _selectedImages.add(File(xfile.path));
          }
        }

        setState(() {});
=======
      final images = await _imagePicker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        final remainingSlots =
            5 - _selectedImages.length - _existingImageUrls.length;
        if (remainingSlots > 0) {
          final newFiles = <XFile>[];
          for (var xFile in images.take(remainingSlots)) {
            try {
              // Verify file is readable by trying to read bytes
              try {
                final bytes = await xFile.readAsBytes();
                if (bytes.isNotEmpty) {
                  newFiles.add(xFile);
                }
              } catch (e) {
                // If reading fails, skip this file
                print('Failed to read file ${xFile.path}: $e');
              }
            } catch (e) {
              print('Error processing file ${xFile.path}: $e');
            }
          }
          
          if (mounted) {
            setState(() {
              _selectedImages.addAll(newFiles);
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum 5 images allowed')),
            );
          }
        }
>>>>>>> 901f25d8b804aa5f2b3d8401be6831ddb03f5199
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: ${e.toString()}')),
        );
      }
    }
  }

  void _removeImage(int index, bool isExisting) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        if (kIsWeb) {
          _selectedImageBytes.removeAt(index);
          _selectedImageDataUrls.removeAt(index);
        } else {
          _selectedImages.removeAt(index);
        }
      }
    });
  }

  void _showDuplicateError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Duplicate Found'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a brand')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final sku = _skuController.text.trim();

<<<<<<< HEAD
      // Check for duplicate name/sku using search functionality
      final result =
          await _adminService.getAllWatches(search: name, limit: 100);
      final existingWatches = (result['watches'] as List<Watch>?) ?? <Watch>[];

      final isNameDuplicate = existingWatches.any((w) =>
          w.name.toLowerCase() == name.toLowerCase() &&
          w.id != widget.watch?.id);

      if (isNameDuplicate) {
=======
      // Check for duplicate name (case-insensitive, exact match)
      final nameExists = await _adminService.watchNameExists(
        name,
        excludeWatchId: widget.watch?.id,
      );

      if (nameExists) {
>>>>>>> 901f25d8b804aa5f2b3d8401be6831ddb03f5199
        setState(() => _isLoading = false);
        _showDuplicateError(
            'A product with this name already exists. Please use a different name.');
        return;
      }

      // Check for SKU duplicate - we need to fetch more carefully if name check didn't catch it
      // For now, we search by SKU as well if possible, or filter retrieved list
      // Since AdminService search checks name, we might need a separate check or a broader search
      // But for small-mid catalog, checking the fetched list + a specific SKU search is better

      final isSkuDuplicate = existingWatches.any((w) =>
          w.sku.toLowerCase() == sku.toLowerCase() && w.id != widget.watch?.id);

      if (isSkuDuplicate) {
        setState(() => _isLoading = false);
        _showDuplicateError(
            'A product with this SKU already exists. Please use a unique SKU.');
        return;
      }

      final specifications = <String, dynamic>{};
      if (_movementController.text.isNotEmpty) {
        specifications['movement'] = _movementController.text;
      }
      if (_caseMaterialController.text.isNotEmpty) {
        specifications['caseMaterial'] = _caseMaterialController.text;
      }
      if (_waterResistanceController.text.isNotEmpty) {
        specifications['waterResistance'] = _waterResistanceController.text;
      }
      if (_diameterController.text.isNotEmpty) {
        specifications['diameter'] = _diameterController.text;
      }

      // Prepare image data based on platform
      final hasNewImages =
          kIsWeb ? _selectedImageBytes.isNotEmpty : _selectedImages.isNotEmpty;

      if (widget.watch != null) {
        // Update existing watch
        await _adminService.updateWatch(
          id: widget.watch!.id,
          brandId: _selectedBrandId,
          name: name,
          sku: sku,
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          category: _selectedCategory!,
          specifications: specifications.isNotEmpty ? specifications : null,
          discountPercentage: _discountController.text.isNotEmpty
              ? int.tryParse(_discountController.text)
              : null,
<<<<<<< HEAD
          imageFiles: kIsWeb ? null : (hasNewImages ? _selectedImages : null),
          imageBytes:
              kIsWeb ? (hasNewImages ? _selectedImageBytes : null) : null,
=======
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
          hasBeltOption: _hasBeltOption,
          hasChainOption: _hasChainOption,
>>>>>>> 901f25d8b804aa5f2b3d8401be6831ddb03f5199
        );
      } else {
        // Create new watch
        await _adminService.createWatch(
          brandId: _selectedBrandId!,
          name: name,
          sku: sku,
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          category: _selectedCategory!,
          specifications: specifications.isNotEmpty ? specifications : null,
          discountPercentage: _discountController.text.isNotEmpty
              ? int.tryParse(_discountController.text)
              : null,
<<<<<<< HEAD
          imageFiles: kIsWeb ? null : (hasNewImages ? _selectedImages : null),
          imageBytes:
              kIsWeb ? (hasNewImages ? _selectedImageBytes : null) : null,
=======
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
          hasBeltOption: _hasBeltOption,
          hasChainOption: _hasChainOption,
>>>>>>> 901f25d8b804aa5f2b3d8401be6831ddb03f5199
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.watch != null
                ? 'Watch updated successfully'
                : 'Watch created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save watch: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error creating/updating watch: $e');
      }
    }
  }

  // Helper method to build belt color picker with full color palette

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.watch != null ? 'Edit Product' : 'Add Product'),
      ),
      body: (_isLoadingBrands || _isLoadingCategories)
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Images Section
<<<<<<< HEAD
                  Builder(
                    builder: (context) {
                      final selectedCount = kIsWeb
                          ? _selectedImageBytes.length
                          : _selectedImages.length;
                      final totalCount =
                          selectedCount + _existingImageUrls.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Images ($totalCount/${Constants.maxProductImages})',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
=======
                  Text(
                    'Images (${_selectedImages.length + _existingImageUrls.length}/5)',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Existing images
                      ..._existingImageUrls.asMap().entries.map((entry) {
                        final index = entry.key;
                        final url = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index, true),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // New selected images
                      ..._selectedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<Uint8List>(
                                  future: file.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  },
                                ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index, false),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // Add image button
                      if (_selectedImages.length + _existingImageUrls.length <
                          5)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, size: 32),
>>>>>>> 901f25d8b804aa5f2b3d8401be6831ddb03f5199
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Existing images
                              ..._existingImageUrls
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final url = entry.value;
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: url,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index, true),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              // New selected images - Platform aware
                              if (kIsWeb)
                                ..._selectedImageBytes
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final bytes = entry.value;
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          bytes,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _removeImage(index, false),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                })
                              else
                                ..._selectedImages.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final file = entry.value;
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          file,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _removeImage(index, false),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              // Add image button
                              if (totalCount < Constants.maxProductImages)
                                GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add, size: 32),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Brand Selection
                  DropdownButtonFormField<String>(
                    // Only set value if it exists in the items list to avoid assertion error
                    value: _brands.any((b) => b.id == _selectedBrandId)
                        ? _selectedBrandId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Brand *',
                      border: OutlineInputBorder(),
                    ),
                    items: _brands.map((brand) {
                      return DropdownMenuItem(
                        value: brand.id,
                        child: Text(brand.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedBrandId = value),
                    validator: (value) =>
                        value == null ? 'Please select a brand' : null,
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),

                  // SKU / Model Number
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU / Model Number *',
                      border: OutlineInputBorder(),
                      helperText: 'Unique identifier for inventory management',
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter an SKU or Model Number'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter a description'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Price and Stock
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Please enter a price';
<<<<<<< HEAD
                            if (!RegExp(r'^[0-9]+\.?[0-9]*$').hasMatch(value!))
                              return 'Price must be a valid positive number';
                            final price = double.tryParse(value);
                            if (price == null) return 'Invalid price format';
                            if (price <= 0)
                              return 'Price must be greater than 0';
=======
                            final price = double.tryParse(value!);
                            if (price == null)
                              return 'Invalid price';
                            if (price < 0)
                              return 'Price cannot be negative';
>>>>>>> 901f25d8b804aa5f2b3d8401be6831ddb03f5199
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Please enter stock';
                            if (!RegExp(r'^[0-9]+$').hasMatch(value!))
                              return 'Stock must be a valid positive number';
                            final stock = int.tryParse(value);
                            if (stock == null) return 'Invalid stock format';
                            if (stock < 0) return 'Stock cannot be negative';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sale / Discount
                  TextFormField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount Percentage (%)',
                      hintText: 'e.g. 20 for 20% off',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final discount = int.tryParse(value);
                        if (discount == null) return 'Invalid number';
                        if (discount < 0 || discount > 100)
                          return 'Must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<String>(
                    // Only set value if it exists in the items list to avoid assertion error
                    value: _categories.any((c) => c.name == _selectedCategory)
                        ? _selectedCategory
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category.name, // The model stores name as string
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 24),

                  // Strap Options Availability
                  const Text(
                    'Strap Options Available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text(
                      'Belt Option Available',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Enable if customers can choose belt with color options',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _hasBeltOption,
                    onChanged: (value) {
                      setState(() {
                        _hasBeltOption = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Chain Option Available',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Enable if customers can choose chain with color options (Black, Silver, Gold)',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _hasChainOption,
                    onChanged: (value) {
                      setState(() {
                        _hasChainOption = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Specifications
                  const Text(
                    'Specifications (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _movementController,
                    decoration: const InputDecoration(
                      labelText: 'Movement',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _caseMaterialController,
                    decoration: const InputDecoration(
                      labelText: 'Case Material',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _waterResistanceController,
                          decoration: const InputDecoration(
                            labelText: 'Water Resistance',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _diameterController,
                          decoration: const InputDecoration(
                            labelText: 'Diameter',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.watch != null
                            ? 'Update Product'
                            : 'Create Product'),
                  ),
                ],
              ),
            ),
    );
  }
}
