import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/admin/admin_drawer.dart';
import '../../providers/feature_provider.dart';

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
        title: Row(
          children: [
            const Text('Manage Home Banners'),
            if (context
                .watch<FeatureProvider>()
                .isEnabled('flash_sale_banner_v2'))
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('BETA',
                    style: TextStyle(fontSize: 10, color: Colors.black)),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBannerSheet,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
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

              // Debug: Print image URL to console
              if (imageUrl.isEmpty) {
                print('Banner ${banner.id} has empty image URL');
              } else {
                print('Banner ${banner.id} image URL: $imageUrl');
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200)),
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        imageUrl.isEmpty
                            ? Container(
                                height: 140,
                                width: double.infinity,
                                color: Colors.grey[200])
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                    height: 140, color: Colors.grey[100]),
                                errorWidget: (context, url, error) => Container(
                                    height: 140,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error)),
                              ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: banner.isActive
                                    ? Colors.green
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(banner.isActive ? 'ACTIVE' : 'INACTIVE',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (banner.abTestId != null)
                          Positioned(
                            top: 8,
                            right: 48,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('TEST: ${banner.version}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 16),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Banner'),
                                    content: const Text('Are you sure?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel')),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirm == true)
                                  await adminProvider.deleteBanner(banner.id);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(banner.title ?? 'No Title',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    if (banner.subtitle != null)
                                      Text(banner.subtitle!,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: banner.isActive,
                                onChanged: (v) => adminProvider
                                    .updateBanner(banner.id, {'isActive': v}),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          // Analytics Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Views', '${banner.impressions}',
                                  Icons.visibility_outlined),
                              _buildStatItem('Clicks', '${banner.clicks}',
                                  Icons.touch_app_outlined),
                              _buildStatItem(
                                  'CTR',
                                  '${banner.ctr.toStringAsFixed(1)}%',
                                  Icons.analytics_outlined),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Target & Type Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTag(Icons.devices,
                                  banner.targetDevices?.join(', ') ?? 'mobile'),
                              if (banner.allowedSegments != null)
                                _buildTag(Icons.groups,
                                    banner.allowedSegments!.join(', ')),
                              if (banner.startDate != null)
                                _buildTag(
                                    Icons.event,
                                    DateFormat('MM/dd')
                                        .format(banner.startDate!)),
                            ],
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
        ],
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
  final _abTestIdController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedSegments = [];
  List<String> _selectedDevices = ['mobile'];
  String? _abVersion;

  final segments = ['CHAMPION', 'LOYAL', 'AT RISK', 'HIBERNATING', 'VIP'];
  final devices = ['mobile', 'tablet', 'desktop'];

  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) setState(() => _imageFile = image);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _linkController.dispose();
    _abTestIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Promotion Banner',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: adminProvider.isLoading ? null : _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!)),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: _imageFile!.readAsBytes(),
                            builder: (context, snapshot) => snapshot.hasData
                                ? Image.memory(snapshot.data!,
                                    fit: BoxFit.cover)
                                : const Center(
                                    child: CircularProgressIndicator()),
                          ))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 40, color: Colors.grey),
                              Text('Select Image')
                            ]),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title')),
              TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(labelText: 'Subtitle')),
              TextFormField(
                  controller: _linkController,
                  decoration:
                      const InputDecoration(labelText: 'Action / Link')),
              const Divider(height: 32),
              const Text('Target Devices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Wrap(
                spacing: 8,
                children: devices
                    .map((d) => FilterChip(
                          label: Text(d, style: const TextStyle(fontSize: 10)),
                          selected: _selectedDevices.contains(d),
                          onSelected: (v) => setState(() {
                            if (v)
                              _selectedDevices.add(d);
                            else if (_selectedDevices.length > 1)
                              _selectedDevices.remove(d);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Text('Audience Segments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Wrap(
                spacing: 8,
                children: segments
                    .map((s) => FilterChip(
                          label: Text(s, style: const TextStyle(fontSize: 10)),
                          selected: _selectedSegments.contains(s),
                          onSelected: (v) => setState(() {
                            if (v)
                              _selectedSegments.add(s);
                            else
                              _selectedSegments.remove(s);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                          _startDate == null
                              ? 'Start Date'
                              : DateFormat('MM/dd').format(_startDate!),
                          style: const TextStyle(fontSize: 12)),
                      onTap: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)));
                        if (d != null) setState(() => _startDate = d);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                          _endDate == null
                              ? 'End Date'
                              : DateFormat('MM/dd').format(_endDate!),
                          style: const TextStyle(fontSize: 12)),
                      onTap: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)));
                        if (d != null) setState(() => _endDate = d);
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text('A/B Testing (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _abTestIdController,
                          decoration:
                              const InputDecoration(labelText: 'Test ID'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: DropdownButtonFormField<String>(
                    value: _abVersion,
                    decoration: const InputDecoration(labelText: 'Ver'),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('A')),
                      DropdownMenuItem(value: 'B', child: Text('B'))
                    ],
                    onChanged: (v) => setState(() => _abVersion = v),
                  )),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: adminProvider.isLoading
                    ? null
                    : () async {
                        if (_imageFile == null) return;
                        final success = await adminProvider.createBanner(
                          imageFile: _imageFile!,
                          title: _titleController.text.trim().isNotEmpty
                              ? _titleController.text.trim()
                              : null,
                          subtitle: _subtitleController.text.trim().isNotEmpty
                              ? _subtitleController.text.trim()
                              : null,
                          link: _linkController.text.trim().isNotEmpty
                              ? _linkController.text.trim()
                              : null,
                          startDate: _startDate,
                          endDate: _endDate,
                          allowedSegments: _selectedSegments.isNotEmpty
                              ? _selectedSegments
                              : null,
                          targetDevices: _selectedDevices,
                          abTestId: _abTestIdController.text.isNotEmpty
                              ? _abTestIdController.text
                              : null,
                          version: _abVersion,
                        );
                        if (success && mounted) Navigator.pop(context);
                      },
                child: adminProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Publish Banner'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
