import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/admin_provider.dart';
import '../../utils/theme.dart';

import 'package:cached_network_image/cached_network_image.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminProvider>(context, listen: false).fetchAllBanners();
    });
  }

  void _showAddBannerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddBannerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Home Banners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBannerSheet,
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.banners.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.banners.isEmpty) {
            return const Center(
              child: Text('No banners found. Add one to show on home page.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminProvider.banners.length,
            itemBuilder: (context, index) {
              final banner = adminProvider.banners[index];
              final imageUrl = banner.image;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 150,
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Banner'),
                                    content: const Text(
                                        'Are you sure you want to delete this banner?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await adminProvider.deleteBanner(banner.id);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (banner.title != null)
                            Text(
                              banner.title!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (banner.subtitle != null)
                            Text(
                              banner.subtitle!,
                              style: const TextStyle(color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (banner.link != null)
                            Text(
                              'Link: ${banner.link}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddBannerSheet extends StatefulWidget {
  const AddBannerSheet({super.key});

  @override
  State<AddBannerSheet> createState() => _AddBannerSheetState();
}

class _AddBannerSheetState extends State<AddBannerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _linkController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

 
@override
void dispose() {
  _titleController.dispose();
  _subtitleController.dispose();
  _linkController.dispose();
  super.dispose();
}
Widget build(BuildContext context) {
  final adminProvider = context.watch<AdminProvider>();

  return Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      left: 16,
      right: 16,
      top: 24,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Banner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 📸 Image Picker
            GestureDetector(
              onTap: adminProvider.isLoading ? null : _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Select Banner Image'),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration:
                  const InputDecoration(labelText: 'Title (Optional)'),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _subtitleController,
              decoration:
                  const InputDecoration(labelText: 'Subtitle (Optional)'),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Link / Action URL (Optional)',
              ),
            ),

            const SizedBox(height: 24),

            // 🚀 Upload Button
            ElevatedButton(
              onPressed: adminProvider.isLoading
                  ? null
                  : () async {
                      if (_imageFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select an image'),
                          ),
                        );
                        return;
                      }

                      final success =
                          await adminProvider.createBanner(
                        imageFile: _imageFile!,
                        title: _titleController.text.trim().isNotEmpty
                            ? _titleController.text.trim()
                            : null,
                        subtitle:
                            _subtitleController.text.trim().isNotEmpty
                                ? _subtitleController.text.trim()
                                : null,
                        link: _linkController.text.trim().isNotEmpty
                            ? _linkController.text.trim()
                            : null,
                      );

                      if (!mounted) return;

                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Banner added successfully'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              adminProvider.errorMessage ??
                                  'Something went wrong',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: adminProvider.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Upload Banner'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
}