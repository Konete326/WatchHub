import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/admin_provider.dart';
import '../../utils/theme.dart';

class ManagePromotionScreen extends StatefulWidget {
  const ManagePromotionScreen({super.key});

  @override
  State<ManagePromotionScreen> createState() => _ManagePromotionScreenState();
}

class _ManagePromotionScreenState extends State<ManagePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _linkController = TextEditingController();
  final _bgController =
      TextEditingController(text: '0xFFB71C1C'); // Default Red
  final _textColController =
      TextEditingController(text: '0xFFFFFFFF'); // Default White

  String _type = 'text'; // 'image' or 'text'
  File? _imageFile;
  bool _isActive = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      await provider.fetchPromotionHighlight();
      if (provider.promotionHighlight != null) {
        final promo = provider.promotionHighlight!;
        setState(() {
          _type = promo.type;
          _titleController.text = promo.title ?? '';
          _subtitleController.text = promo.subtitle ?? '';
          _linkController.text = promo.link ?? '';
          _bgController.text = promo.backgroundColor ?? '0xFFB71C1C';
          _textColController.text = promo.textColor ?? '0xFFFFFFFF';
          _isActive = promo.isActive;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _linkController.dispose();
    _bgController.dispose();
    _textColController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == 'image' &&
        _imageFile == null &&
        Provider.of<AdminProvider>(context, listen: false)
                .promotionHighlight
                ?.imageUrl ==
            null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    final success = await Provider.of<AdminProvider>(context, listen: false)
        .updatePromotionHighlight(
      type: _type,
      imageFile: _imageFile,
      title: _type == 'text' ? _titleController.text : null,
      subtitle: _type == 'text' ? _subtitleController.text : null,
      backgroundColor: _type == 'text' ? _bgController.text : null,
      textColor: _type == 'text' ? _textColController.text : null,
      link: _linkController.text,
      isActive: _isActive,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Promotion updated successfully'),
            backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Sale Highlight')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.promotionHighlight == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview Section
                  const Text('Preview on Home Screen',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildLivePreview(provider),
                  const Divider(height: 40),

                  const Text('Highlight Configuration',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  const Text('Type',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 20,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: 'text',
                            groupValue: _type,
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                          const Text('Text Based'),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: 'image',
                            groupValue: _type,
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                          const Text('Image Based'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_type == 'image') ...[
                    const Text('Banner Image',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                          image: _imageFile != null && !kIsWeb
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover)
                              : (provider.promotionHighlight?.imageUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(provider
                                          .promotionHighlight!.imageUrl!),
                                      fit: BoxFit.cover)
                                  : null),
                        ),
                        child: _imageFile != null && kIsWeb
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageFile!.path,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (_imageFile == null &&
                                    provider.promotionHighlight?.imageUrl ==
                                        null)
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text('Select Banner Image',
                                          style: TextStyle(
                                              color: Colors.grey.shade600)),
                                    ],
                                  )
                                : Stack(
                                    children: [
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          radius: 16,
                                          child: IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 16, color: Colors.white),
                                            onPressed: _pickImage,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Sale Title',
                        hintText: 'e.g. FLASH SALE!',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle',
                        hintText: 'e.g. Up to 50% Off on Luxury Watches',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subtitles),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bgController,
                            decoration: InputDecoration(
                              labelText: 'BG Color (HEX)',
                              hintText: '0xFFB71C1C',
                              border: const OutlineInputBorder(),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildColorIndicator(_bgController.text),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _textColController,
                            decoration: InputDecoration(
                              labelText: 'Text Color (HEX)',
                              hintText: '0xFFFFFFFF',
                              border: const OutlineInputBorder(),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildColorIndicator(
                                    _textColController.text),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: 'Link / Product ID (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      title: const Text('Is Active'),
                      subtitle: const Text(
                          'Determine if this highlight shows on home'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Highlight',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLivePreview(AdminProvider provider) {
    if (!_isActive) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Text('Promotion is currently inactive',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final bool isImage = _type == 'image';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: !isImage
            ? _safeColor(_bgController.text, Colors.red.shade900)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isImage
          ? (_imageFile != null
              ? (kIsWeb
                  ? Image.network(_imageFile!.path,
                      height: 120, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(_imageFile!,
                      height: 120, width: double.infinity, fit: BoxFit.cover))
              : (provider.promotionHighlight?.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: provider.promotionHighlight!.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    )
                  : Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image))))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Text(
                    _titleController.text.isEmpty
                        ? 'SALE TITLE'
                        : _titleController.text,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _safeColor(_textColController.text, Colors.white),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_subtitleController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _subtitleController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: _safeColor(_textColController.text, Colors.white)
                            .withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildColorIndicator(String hex) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: _safeColor(hex, Colors.transparent),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400),
      ),
    );
  }

  Color _safeColor(String hex, Color fallback) {
    try {
      if (!hex.startsWith('0xFF')) {
        if (hex.startsWith('#')) {
          return Color(int.parse('0xFF${hex.substring(1)}'));
        }
        return Color(int.parse('0xFF$hex'));
      }
      return Color(int.parse(hex));
    } catch (_) {
      return fallback;
    }
  }
}
