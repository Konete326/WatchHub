import 'dart:typed_data';
import 'package:flutter/material.dart';
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
          SnackBar(
            content: Text(widget.review != null
                ? 'Review updated successfully'
                : 'Review submitted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewProvider.errorMessage ?? 'Failed to submit review',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.review != null ? 'Edit Review' : 'Write a Review',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating
                      const Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: RatingBar.builder(
                          initialRating: _rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 40,
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _rating = rating;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Comment
                      const Text(
                        'Your Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Share your experience with this product...',
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 8),
                      Text(
                        '${_commentController.text.length}/1000 characters',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Images
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Photos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_selectedImages.length}/5',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length) {
                              if (_selectedImages.length >= 5) {
                                return const SizedBox.shrink();
                              }
                              return InkWell(
                                onTap: _pickImages,
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo,
                                          color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final image = _selectedImages[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FutureBuilder<Uint8List>(
                                      future: image.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          );
                                        }
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: InkWell(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.review != null ? 'Update' : 'Submit'),
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
