import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/review_provider.dart';
import '../models/review.dart';
import '../utils/theme.dart';

class ReviewDialog extends StatefulWidget {
  final String watchId;
  final Review? review; // If provided, this is an edit dialog

  const ReviewDialog({
    super.key,
    required this.watchId,
    this.review,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  double _rating = 5.0;
  bool _isSubmitting = false;
  bool _imagesChanged = false;

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _rating = widget.review!.rating.toDouble();
      _commentController.text = widget.review!.comment;
    }
    _commentController.addListener(() {
      setState(() {}); // Update character count
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload up to 5 images')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
        }
        _imagesChanged = true;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imagesChanged = true;
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final review = Review(
        id: widget.review?.id ?? '',
        userId: widget.review?.userId ?? '',
        watchId: widget.watchId,
        rating: _rating.toInt(),
        comment: _commentController.text.trim(),
        helpfulCount: widget.review?.helpfulCount ?? 0,
        createdAt: widget.review?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (widget.review != null) {
        success = await reviewProvider.updateReview(
          widget.review!.id,
          rating: _rating.toInt(),
          comment: _commentController.text.trim(),
          images: _imagesChanged ? _selectedImages : null,
        );
      } else {
        success =
            await reviewProvider.createReview(review, images: _selectedImages);
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Review submitted! It will be visible after a quick moderation check.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewProvider.errorMessage ?? 'Failed to submit review',
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = Color(0xFFE0E5EC);
    const kTextColor = Color(0xFF4A5568);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: _NeumorphicContainer(
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.review != null ? 'Edit Review' : 'Write a Review',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  _NeumorphicButton(
                    onTap: () => Navigator.of(context).pop(false),
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, size: 20, color: kTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate your experience',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _NeumorphicContainer(
                        isConcave: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        borderRadius: BorderRadius.circular(20),
                        child: RatingBar.builder(
                          initialRating: _rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 36,
                          unratedColor: kTextColor.withOpacity(0.1),
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _rating = rating;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Your Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NeumorphicIndicatorContainer(
                      isSelected: true,
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: TextFormField(
                        controller: _commentController,
                        maxLines: 4,
                        style: const TextStyle(color: kTextColor),
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts about the product...',
                          hintStyle:
                              TextStyle(color: kTextColor.withOpacity(0.4)),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your review';
                          }
                          if (value.trim().length < 10) {
                            return 'Review must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_commentController.text.length}/1000',
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        Text(
                          '${_selectedImages.length}/5',
                          style: TextStyle(
                            fontSize: 12,
                            color: kTextColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: _selectedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            if (_selectedImages.length >= 5) {
                              return const SizedBox.shrink();
                            }
                            return _NeumorphicButton(
                              onTap: _pickImages,
                              borderRadius: BorderRadius.circular(15),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final image = _selectedImages[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                _NeumorphicContainer(
                                  isConcave: true,
                                  borderRadius: BorderRadius.circular(15),
                                  padding: const EdgeInsets.all(4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FutureBuilder<Uint8List>(
                                      future: image.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            width: 72,
                                            height: 72,
                                          );
                                        }
                                        return Container(
                                          width: 72,
                                          height: 72,
                                          color: Colors.white.withOpacity(0.3),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(2, 2))
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: _NeumorphicButton(
                            onTap: () => Navigator.of(context).pop(false),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            borderRadius: BorderRadius.circular(15),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: kTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _NeumorphicButton(
                            onTap: _isSubmitting ? () {} : _submitReview,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            borderRadius: BorderRadius.circular(15),
                            child: Center(
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : Text(
                                      widget.review != null
                                          ? 'Update'
                                          : 'Submit',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Neumorphic Components (Redundant but self-contained for Dialog) ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final bool isConcave;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.isConcave = false,
  });

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE0E5EC);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: borderRadius,
        boxShadow: isConcave
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(4, 4),
                    blurRadius: 4,
                    spreadRadius: 1),
                BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-4, -4),
                    blurRadius: 4,
                    spreadRadius: 1),
              ]
            : [
                const BoxShadow(
                    color: Color(0xFFA3B1C6),
                    offset: Offset(6, 6),
                    blurRadius: 16),
                const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    offset: Offset(-6, -6),
                    blurRadius: 16),
              ],
      ),
      child: child,
    );
  }
}

class _NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const _NeumorphicButton({
    required this.child,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<_NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<_NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E5EC),
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(2, 2),
                      blurRadius: 2),
                  const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 2),
                ]
              : [
                  const BoxShadow(
                      color: Color(0xFFA3B1C6),
                      offset: Offset(4, 4),
                      blurRadius: 10),
                  const BoxShadow(
                      color: Color(0xFFFFFFFF),
                      offset: Offset(-4, -4),
                      blurRadius: 10),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _NeumorphicIndicatorContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;

  const _NeumorphicIndicatorContainer({
    required this.child,
    required this.isSelected,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: borderRadius,
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                    spreadRadius: 1),
                const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2, -2),
                    blurRadius: 2,
                    spreadRadius: 1),
              ]
            : [
                const BoxShadow(
                    color: Color(0xFFA3B1C6),
                    offset: Offset(4, 4),
                    blurRadius: 10),
                const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    offset: Offset(-4, -4),
                    blurRadius: 10),
              ],
      ),
      child: child,
    );
  }
}
