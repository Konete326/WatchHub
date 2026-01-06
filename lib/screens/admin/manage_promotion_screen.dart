import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

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
  XFile? _imageFile;
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
        _imageFile = image;
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
                          image: _imageFile != null
                              ? null
                              : (provider.promotionHighlight?.imageUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(provider
                                          .promotionHighlight!.imageUrl!),
                                      fit: BoxFit.cover)
                                  : null),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FutureBuilder<Uint8List>(
                                  future: _imageFile!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        height: 160,
                                        width: double.infinity,
                                      );
                                    }
                                    return const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2));
                                  },
                                ),
                              )
                            : (provider.promotionHighlight?.imageUrl == null)
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
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: _buildColorIndicator(
                                        _bgController.text),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.palette),
                                    onPressed: () => _showColorPicker(
                                      context,
                                      _bgController,
                                      'Background Color',
                                    ),
                                    tooltip: 'Pick Color',
                                  ),
                                ],
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
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: _buildColorIndicator(
                                        _textColController.text),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.palette),
                                    onPressed: () => _showColorPicker(
                                      context,
                                      _textColController,
                                      'Text Color',
                                    ),
                                    tooltip: 'Pick Color',
                                  ),
                                ],
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
              ? FutureBuilder<Uint8List>(
                  future: _imageFile!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                )
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

  String _colorToHex(Color color) {
    return '0xFF${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _showColorPicker(
    BuildContext context,
    TextEditingController controller,
    String title,
  ) async {
    final currentColor = _safeColor(controller.text, Colors.black);

    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: currentColor,
        title: title,
      ),
    );

    if (selectedColor != null) {
      controller.text = _colorToHex(selectedColor);
      setState(() {});
    }
  }
}

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.title,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  // Comprehensive color palette
  final List<List<Color>> _colorPalette = [
    // Reds
    [
      const Color(0xFFFF0000),
      const Color(0xFFFF1744),
      const Color(0xFFD32F2F),
      const Color(0xFFC62828),
      const Color(0xFFB71C1C),
    ],
    // Pinks
    [
      const Color(0xFFFFC0CB),
      const Color(0xFFFF69B4),
      const Color(0xFFFF1493),
      const Color(0xFFE91E63),
      const Color(0xFFC2185B),
    ],
    // Purples
    [
      const Color(0xFFE1BEE7),
      const Color(0xFFBA68C8),
      const Color(0xFF9C27B0),
      const Color(0xFF7B1FA2),
      const Color(0xFF4A148C),
    ],
    // Deep Purples
    [
      const Color(0xFFD1C4E9),
      const Color(0xFF9575CD),
      const Color(0xFF673AB7),
      const Color(0xFF512DA8),
      const Color(0xFF311B92),
    ],
    // Indigos
    [
      const Color(0xFFC5CAE9),
      const Color(0xFF7986CB),
      const Color(0xFF3F51B5),
      const Color(0xFF303F9F),
      const Color(0xFF1A237E),
    ],
    // Blues
    [
      const Color(0xFFBBDEFB),
      const Color(0xFF64B5F6),
      const Color(0xFF2196F3),
      const Color(0xFF1976D2),
      const Color(0xFF0D47A1),
    ],
    // Light Blues
    [
      const Color(0xFFB3E5FC),
      const Color(0xFF4FC3F7),
      const Color(0xFF03A9F4),
      const Color(0xFF0277BD),
      const Color(0xFF01579B),
    ],
    // Cyans
    [
      const Color(0xFFB2EBF2),
      const Color(0xFF4DD0E1),
      const Color(0xFF00BCD4),
      const Color(0xFF0097A7),
      const Color(0xFF006064),
    ],
    // Teals
    [
      const Color(0xFFB2DFDB),
      const Color(0xFF4DB6AC),
      const Color(0xFF009688),
      const Color(0xFF00796B),
      const Color(0xFF004D40),
    ],
    // Greens
    [
      const Color(0xFFC8E6C9),
      const Color(0xFF81C784),
      const Color(0xFF4CAF50),
      const Color(0xFF388E3C),
      const Color(0xFF1B5E20),
    ],
    // Light Greens
    [
      const Color(0xFFDCEDC8),
      const Color(0xFFAED581),
      const Color(0xFF8BC34A),
      const Color(0xFF689F38),
      const Color(0xFF33691E),
    ],
    // Limes
    [
      const Color(0xFFF0F4C3),
      const Color(0xFFDCE775),
      const Color(0xFFCDDC39),
      const Color(0xFFAFB42B),
      const Color(0xFF827717),
    ],
    // Yellows
    [
      const Color(0xFFFFF9C4),
      const Color(0xFFFFF176),
      const Color(0xFFFFEB3B),
      const Color(0xFFF9A825),
      const Color(0xFFF57F17),
    ],
    // Ambers
    [
      const Color(0xFFFFE082),
      const Color(0xFFFFD54F),
      const Color(0xFFFFC107),
      const Color(0xFFFF8F00),
      const Color(0xFFFF6F00),
    ],
    // Oranges
    [
      const Color(0xFFFFE0B2),
      const Color(0xFFFFB74D),
      const Color(0xFFFF9800),
      const Color(0xFFF57C00),
      const Color(0xFFE65100),
    ],
    // Deep Oranges
    [
      const Color(0xFFFFCCBC),
      const Color(0xFFFF8A65),
      const Color(0xFFFF5722),
      const Color(0xFFD84315),
      const Color(0xFFBF360C),
    ],
    // Browns
    [
      const Color(0xFFD7CCC8),
      const Color(0xFFA1887F),
      const Color(0xFF795548),
      const Color(0xFF5D4037),
      const Color(0xFF3E2723),
    ],
    // Greys
    [
      const Color(0xFFF5F5F5),
      const Color(0xFFE0E0E0),
      const Color(0xFF9E9E9E),
      const Color(0xFF616161),
      const Color(0xFF212121),
    ],
    // Blue Greys
    [
      const Color(0xFFCFD8DC),
      const Color(0xFF90A4AE),
      const Color(0xFF607D8B),
      const Color(0xFF455A64),
      const Color(0xFF263238),
    ],
    // Black and White
    [
      const Color(0xFFFFFFFF),
      const Color(0xFFFAFAFA),
      const Color(0xFF000000),
      const Color(0xFF424242),
      const Color(0xFF757575),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Color Palette
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Selection Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Selected Color',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '0xFF${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Color Grid
                    ..._colorPalette.map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: row.map((color) {
                              final isSelected =
                                  color.value == _selectedColor.value;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedColor = color;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.grey.shade300,
                                        width: isSelected ? 3 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            // Footer with buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedColor),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
