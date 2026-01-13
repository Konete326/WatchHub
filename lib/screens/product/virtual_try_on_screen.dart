import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/theme.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final String watchImageUrl;

  const VirtualTryOnScreen({super.key, required this.watchImageUrl});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  Uint8List? _wristImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Transformation state for the watch overlay
  Offset _position = const Offset(100, 100);
  double _scale = 1.0;
  double _rotation = 0.0;

  // Previous values for gesture handling
  Offset _startPosition = Offset.zero;
  double _startScale = 1.0;
  double _startRotation = 0.0;

  bool _isHelpVisible = true;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _wristImageBytes = bytes;
          // Reset transformations when new photo is taken
          _position = const Offset(150, 300); // Approximate center-ish
          _scale = 1.0;
          _rotation = 0.0;
          _isHelpVisible = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing camera: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _wristImageBytes = bytes;
          _position = const Offset(150, 300);
          _scale = 1.0;
          _rotation = 0.0;
          _isHelpVisible = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing gallery: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _resetTransform() {
    setState(() {
      _position = const Offset(150, 300);
      _scale = 1.0;
      _rotation = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_wristImageBytes == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: Colors.white54,
              ),
              const SizedBox(height: 24),
              const Text(
                'Virtual AR Try-On',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Take a photo of your wrist to see how this watch looks on you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera),
                label: const Text('OPEN CAMERA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Add gallery option for web compatibility
              TextButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined,
                    color: Colors.white70),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Image (Wrist) - Using Image.memory for cross-platform support
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.0,
              child: Image.memory(
                _wristImageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 80,
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Watch Overlay with Gestures
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onScaleStart: (details) {
                _startPosition = _position;
                _startScale = _scale;
                _startRotation = _rotation;
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Update position
                  _position = _startPosition +
                      details.focalPoint -
                      details.localFocalPoint;

                  // Update scale
                  _scale = (_startScale * details.scale).clamp(0.2, 5.0);

                  // Update rotation
                  _rotation = _startRotation + details.rotation;
                });
              },
              child: Transform(
                transform: Matrix4.identity()
                  ..scale(_scale, _scale)
                  ..rotateZ(_rotation),
                alignment: Alignment.center,
                child: IgnorePointer(
                  ignoring: true,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: CachedNetworkImage(
                      imageUrl: widget.watchImageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.watch,
                        color: Colors.white54,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. UI Overlays
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.refresh,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
              onPressed: _resetTransform,
              tooltip: 'Reset Watch Position',
            ),
          ),

          if (_isHelpVisible)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app, color: Colors.white70),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Drag to move, pinch to resize, twist to rotate.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.white54),
                      onPressed: () => setState(() => _isHelpVisible = false),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('RETAKE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('GALLERY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
