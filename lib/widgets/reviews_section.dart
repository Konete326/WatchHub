import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/review_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/watch_provider.dart';
import '../models/review.dart';
import '../utils/theme.dart';
import 'review_dialog.dart';
import 'shimmer_loading.dart';

class ReviewsSection extends StatefulWidget {
  final String watchId;

  const ReviewsSection({super.key, required this.watchId});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  String _selectedSort = 'newest';
  int? _filterRating;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false)
          .fetchWatchReviews(widget.watchId, refresh: true);
    });
  }

  void _refreshReviews() {
    Provider.of<ReviewProvider>(context, listen: false)
        .fetchWatchReviews(widget.watchId, refresh: true);
  }

  void _loadMoreReviews() {
    Provider.of<ReviewProvider>(context, listen: false)
        .fetchWatchReviews(widget.watchId, refresh: false);
  }

  void _applySort() {
    final provider = Provider.of<ReviewProvider>(context, listen: false);
    switch (_selectedSort) {
      case 'newest':
        provider.setSortOrder('createdAt', 'desc');
        break;
      case 'oldest':
        provider.setSortOrder('createdAt', 'asc');
        break;
      case 'highest':
        provider.setSortOrder('rating', 'desc');
        break;
      case 'lowest':
        provider.setSortOrder('rating', 'asc');
        break;
    }
    _refreshReviews();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id;

    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final reviews = _filterRating != null
            ? reviewProvider.reviews
                .where((r) => r.rating == _filterRating)
                .toList()
            : reviewProvider.reviews;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentUserId != null)
                    TextButton.icon(
                      onPressed: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (context) => ReviewDialog(
                            watchId: widget.watchId,
                          ),
                        );
                        if (result == true) {
                          _refreshReviews();
                          if (mounted) {
                            Provider.of<WatchProvider>(context, listen: false)
                                .fetchWatchById(widget.watchId);
                          }
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Write Review'),
                    ),
                ],
              ),
            ),

            // Rating Distribution
            if (reviewProvider.ratingDistribution != null)
              _buildRatingDistribution(reviewProvider.ratingDistribution!),

            // Filters and Sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Rating Filter
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _filterRating,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Rating',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Ratings')),
                        ...List.generate(
                            5,
                            (index) => DropdownMenuItem(
                                  value: index + 1,
                                  child: Row(
                                    children: [
                                      ...List.generate(
                                          index + 1,
                                          (_) => const Icon(Icons.star,
                                              size: 16, color: Colors.amber)),
                                    ],
                                  ),
                                )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterRating = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSort,
                      decoration: const InputDecoration(
                        labelText: 'Sort',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(
                            value: 'oldest', child: Text('Oldest')),
                        DropdownMenuItem(
                            value: 'highest', child: Text('Highest Rating')),
                        DropdownMenuItem(
                            value: 'lowest', child: Text('Lowest Rating')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSort = value!;
                          _applySort();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Error Message
            if (reviewProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 8),
                      Text(
                        reviewProvider.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _refreshReviews,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            // Reviews List
            else if (reviewProvider.isLoading && reviews.isEmpty)
              const ListShimmer(itemCount: 3)
            else if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.reviews, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...reviews.map((review) => _buildReviewItem(
                    review,
                    currentUserId,
                    reviewProvider,
                  )),

            // Load More Button
            if (reviewProvider.hasMorePages && !reviewProvider.isLoading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: OutlinedButton(
                    onPressed: _loadMoreReviews,
                    child: const Text('Load More Reviews'),
                  ),
                ),
              ),

            if (reviewProvider.isLoading && reviews.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRatingDistribution(dynamic distribution) {
    // Calculate total reviews
    int total = 0;
    final ratingCounts = <int, int>{};

    if (distribution is List) {
      for (var item in distribution) {
        if (item is Map && item['rating'] != null && item['_count'] != null) {
          final rating = item['rating'] as int;
          final count = item['_count']['rating'] as int? ?? 0;
          ratingCounts[rating] = count;
          total += count;
        }
      }
    } else if (distribution is Map) {
      // Handle Map<String, dynamic> format where keys are rating strings
      for (var entry in distribution.entries) {
        final rating = int.tryParse(entry.key.toString());
        if (rating != null && rating >= 1 && rating <= 5) {
          final count = (entry.value as num?)?.toInt() ?? 0;
          ratingCounts[rating] = count;
          total += count;
        }
      }
    }

    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (int index = 0; index < 5; index++)
            Builder(
              builder: (context) {
                final rating = 5 - index;
                final count = ratingCounts[rating] ?? 0;
                final percentage = total > 0 ? (count / total) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('$rating', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    Review review,
    String? currentUserId,
    ReviewProvider reviewProvider,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isOwnReview = currentUserId != null && review.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info and Rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    review.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.user?.name ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RatingBarIndicator(
                        rating: review.rating.toDouble(),
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 16,
                      ),
                    ],
                  ),
                ),
                if (isOwnReview)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await showDialog(
                          context: context,
                          builder: (context) => ReviewDialog(
                            watchId: widget.watchId,
                            review: review,
                          ),
                        );
                        if (result == true) {
                          _refreshReviews();
                          if (mounted) {
                            Provider.of<WatchProvider>(context, listen: false)
                                .fetchWatchById(widget.watchId);
                          }
                        }
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Review'),
                            content: const Text(
                                'Are you sure you want to delete this review?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          final success =
                              await reviewProvider.deleteReview(review.id);
                          if (mounted) {
                            if (success) {
                              Provider.of<WatchProvider>(context, listen: false)
                                  .fetchWatchById(widget.watchId);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Review deleted'
                                    : reviewProvider.errorMessage ??
                                        'Failed to delete review'),
                                backgroundColor: success
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                              ),
                            );
                            if (success) {
                              _refreshReviews();
                            }
                          }
                        }
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Images
            if (review.images.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullImageGallery(
                                images: review.images,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: review.images[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const ShimmerWidget.rounded(
                              width: 80,
                              height: 80,
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Date and Helpful
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await reviewProvider.markReviewHelpful(review.id);
                    _refreshReviews();
                  },
                  icon: const Icon(Icons.thumb_up, size: 16),
                  label: Text('${review.helpfulCount}'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FullImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullImageGallery> createState() => _FullImageGalleryState();
}

class _FullImageGalleryState extends State<FullImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text('Failed to load image',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
