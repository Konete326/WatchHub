import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/review_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/watch_provider.dart';
import '../models/review.dart';
import '../utils/theme.dart';
import 'review_dialog.dart';
import 'neumorphic_widgets.dart';

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
    // Original review fetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ReviewProvider>(context, listen: false)
          .fetchWatchReviews(widget.watchId, refresh: true);
    });
  }

  void _refreshReviews() {
    if (!mounted) return;
    Provider.of<ReviewProvider>(context, listen: false)
        .fetchWatchReviews(widget.watchId, refresh: true);
  }

  void _loadMoreReviews() {
    if (!mounted) return;
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
    const kBackgroundColor = Color(0xFFE0E5EC);
    const kTextColor = Color(0xFF4A5568);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                if (currentUserId != null)
                  FutureBuilder<bool>(
                    future: Provider.of<ReviewProvider>(context, listen: false)
                        .canUserReview(widget.watchId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.data == true) {
                        return _NeumorphicButton(
                          onTap: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (context) => ReviewDialog(
                                watchId: widget.watchId,
                              ),
                            );
                            if (result == true && mounted) {
                              _refreshReviews();
                              Provider.of<WatchProvider>(context, listen: false)
                                  .fetchWatchById(widget.watchId);
                              setState(() {});
                            }
                          },
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          borderRadius: BorderRadius.circular(12),
                          child: const Row(
                            children: [
                              Icon(Icons.edit,
                                  size: 16, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text('Write Review',
                                  style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Rating Distribution
            if (reviewProvider.ratingDistribution != null)
              _buildRatingDistribution(reviewProvider.ratingDistribution!),

            const SizedBox(height: 24),

            // Filters and Sort (Neumorphic)
            Row(
              children: [
                Expanded(
                  child: _NeumorphicIndicatorContainer(
                    isSelected: true,
                    borderRadius: BorderRadius.circular(15),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _filterRating,
                        isExpanded: true,
                        dropdownColor: kBackgroundColor,
                        style: const TextStyle(color: kTextColor),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Ratings')),
                          ...List.generate(
                              5,
                              (index) => DropdownMenuItem(
                                    value: index + 1,
                                    child: Row(
                                      children: List.generate(
                                          index + 1,
                                          (_) => const Icon(Icons.star,
                                              size: 14, color: Colors.amber)),
                                    ),
                                  )),
                        ],
                        onChanged: (value) =>
                            setState(() => _filterRating = value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _NeumorphicIndicatorContainer(
                    isSelected: true,
                    borderRadius: BorderRadius.circular(15),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSort,
                        isExpanded: true,
                        dropdownColor: kBackgroundColor,
                        style: const TextStyle(color: kTextColor),
                        items: const [
                          DropdownMenuItem(
                              value: 'newest', child: Text('Newest')),
                          DropdownMenuItem(
                              value: 'oldest', child: Text('Oldest')),
                          DropdownMenuItem(
                              value: 'highest', child: Text('Highest')),
                          DropdownMenuItem(
                              value: 'lowest', child: Text('Lowest')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSort = value!;
                            _applySort();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Review List
            if (reviewProvider.isLoading && reviews.isEmpty)
              const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor))
            else if (reviews.isEmpty)
              _NeumorphicContainer(
                padding: const EdgeInsets.all(40),
                borderRadius: BorderRadius.circular(20),
                isConcave: true,
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.reviews, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No reviews yet',
                          style: TextStyle(color: Colors.grey)),
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

            // Load More
            if (reviewProvider.hasMorePages && !reviewProvider.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: _NeumorphicButton(
                    onTap: _loadMoreReviews,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    borderRadius: BorderRadius.circular(15),
                    child: const Text('Load More',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            const SizedBox(height: 60), // Extra space for bottom bar
          ],
        );
      },
    );
  }

  Widget _buildRatingDistribution(dynamic distribution) {
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

    return _NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rating Distribution',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF4A5568))),
          const SizedBox(height: 16),
          for (int i = 5; i >= 1; i--)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('$i',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF4A5568))),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 8,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            total > 0 ? (ratingCounts[i] ?? 0) / total : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${ratingCounts[i] ?? 0}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF4A5568))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
      Review review, String? currentUserId, ReviewProvider provider) {
    const kTextColor = Color(0xFF4A5568);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isOwnReview = currentUserId != null && review.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _NeumorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NeumorphicContainer(
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      review.user != null && review.user!.name.isNotEmpty
                          ? review.user!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(review.user?.name ?? 'Anonymous',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kTextColor)),
                          ),
                          if (review.tags?.contains('verified') ?? false) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified,
                                      size: 10, color: AppTheme.successColor),
                                  SizedBox(width: 2),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: review.rating.toDouble(),
                            itemBuilder: (context, index) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review.sentimentLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: review.sentimentScore != null &&
                                      review.sentimentScore! > 0.2
                                  ? Colors.green
                                  : (review.sentimentScore != null &&
                                          review.sentimentScore! < -0.2
                                      ? Colors.red
                                      : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (review.isFeatured)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.star_rounded,
                        color: Colors.orange, size: 24),
                  ),
                if (isOwnReview)
                  _NeumorphicButton(
                    onTap: () => _showReviewOptions(review, provider),
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.more_vert,
                        size: 18, color: kTextColor),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(review.comment,
                style: const TextStyle(color: kTextColor, height: 1.5)),
            const SizedBox(height: 16),
            if (review.images.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _NeumorphicIndicatorContainer(
                      isSelected: false,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: review.images[index],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (review.adminReply != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _NeumorphicContainer(
                  isConcave: true,
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Response from WatchHub',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review.adminReply!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: kTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (review.adminReplyAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dateFormat.format(review.adminReplyAt!),
                            style: TextStyle(
                                fontSize: 10,
                                color: kTextColor.withOpacity(0.4)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateFormat.format(review.createdAt),
                    style: TextStyle(
                        fontSize: 12, color: kTextColor.withOpacity(0.5))),
                _NeumorphicButton(
                  onTap: () => provider.markReviewHelpful(review.id).then((_) {
                    if (mounted) _refreshReviews();
                  }),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up_alt_outlined,
                          size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text('${review.helpfulCount}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewOptions(Review review, ReviewProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        decoration: const BoxDecoration(
          color: Color(0xFFE0E5EC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            _NeumorphicButton(
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showDeleteConfirmation();
                if (confirm == true) {
                  final success = await provider.deleteReview(review.id);
                  if (success && mounted) {
                    _refreshReviews();
                    // Update main watch rating
                    Provider.of<WatchProvider>(context, listen: false)
                        .fetchWatchById(widget.watchId);
                  }
                }
              },
              padding: const EdgeInsets.symmetric(vertical: 20),
              borderRadius: BorderRadius.circular(15),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      color: AppTheme.errorColor),
                  SizedBox(width: 12),
                  Text(
                    'Delete Review',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _NeumorphicButton(
              onTap: () => Navigator.pop(context),
              padding: const EdgeInsets.symmetric(vertical: 20),
              borderRadius: BorderRadius.circular(15),
              child: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF4A5568),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => NeumorphicDialog(
        title: 'Delete Review',
        content:
            'Are you sure you want to remove this review? This action cannot be undone.',
        confirmLabel: 'Delete',
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }
}

// --- Neumorphic Components ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final bool isConcave;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.isConcave = false,
  });

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE0E5EC);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
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
