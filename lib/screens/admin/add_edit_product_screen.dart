import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../services/watch_service.dart';
import '../../models/watch.dart';
import '../../models/brand.dart';
import '../../models/category.dart' as model;
import '../../utils/validators.dart';

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
  List<XFile> _selectedImages = []; // Use XFile for both web and mobile
  List<String> _existingImageUrls = [];
  bool _isLoading = false;
  bool _isLoadingBrands = false;
  bool _isLoadingCategories = false;
  bool _hasBeltOption = false;
  bool _hasChainOption = false;

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
      // Image Optimization: compress to 70% and limit max width
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1000,
      );
      if (images != null && images.isNotEmpty) {
        final remainingSlots =
            5 - _selectedImages.length - _existingImageUrls.length;
        if (remainingSlots > 0) {
          final newFiles = <XFile>[];
          for (var xFile in images.take(remainingSlots)) {
            try {
              final bytes = await xFile.readAsBytes();
              if (bytes.isNotEmpty) {
                newFiles.add(xFile);
              }
            } catch (e) {
              print('Failed to read file ${xFile.path}: $e');
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
        _selectedImages.removeAt(index);
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
      final name = InputSanitizer.sanitize(_nameController.text);
      final sku = InputSanitizer.sanitize(_skuController.text);
      final description = InputSanitizer.sanitize(_descriptionController.text);

      // Duplicate check optimized via specialized method
      final nameExists = await _adminService.watchNameExists(
        name,
        excludeWatchId: widget.watch?.id,
      );

      if (nameExists) {
        setState(() => _isLoading = false);
        _showDuplicateError(
            'A product with this name already exists. Please use a different name.');
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

      if (widget.watch != null) {
        await _adminService.updateWatch(
          id: widget.watch!.id,
          brandId: _selectedBrandId,
          name: name,
          sku: sku,
          description: description,
          price: double.parse(
              InputSanitizer.sanitizeNumeric(_priceController.text)),
          stock:
              int.parse(InputSanitizer.sanitizeNumeric(_stockController.text)),
          category: _selectedCategory!,
          specifications: specifications.isNotEmpty ? specifications : null,
          discountPercentage: _discountController.text.isNotEmpty
              ? int.tryParse(_discountController.text)
              : null,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
          hasBeltOption: _hasBeltOption,
          hasChainOption: _hasChainOption,
        );
      } else {
        await _adminService.createWatch(
          brandId: _selectedBrandId!,
          name: name,
          sku: sku,
          description: description,
          price: double.parse(
              InputSanitizer.sanitizeNumeric(_priceController.text)),
          stock:
              int.parse(InputSanitizer.sanitizeNumeric(_stockController.text)),
          category: _selectedCategory!,
          specifications: specifications.isNotEmpty ? specifications : null,
          discountPercentage: _discountController.text.isNotEmpty
              ? int.tryParse(_discountController.text)
              : null,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
          hasBeltOption: _hasBeltOption,
          hasChainOption: _hasChainOption,
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
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
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
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  DropdownButtonFormField<String>(
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

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => Validators.required(value, 'Name'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU / Model Number *',
                      border: OutlineInputBorder(),
                      helperText: 'Unique identifier for inventory management',
                    ),
                    validator: (value) => Validators.required(value, 'SKU'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        Validators.required(value, 'Description'),
                  ),
                  const SizedBox(height: 16),

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
                          validator: Validators.price,
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
                          validator: Validators.stock,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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

                  DropdownButtonFormField<String>(
                    value: _categories.any((c) => c.name == _selectedCategory)
                        ? _selectedCategory
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category.name,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Strap Options Available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text(
                      'Belt Option Available',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
