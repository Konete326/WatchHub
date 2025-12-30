import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../models/review.dart';
import '../../utils/theme.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../product/product_detail_screen.dart';

class ManageReviewsScreen extends StatefulWidget {
  const ManageReviewsScreen({super.key});

  @override
  State<ManageReviewsScreen> createState() => _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends State<ManageReviewsScreen> {
  final AdminService _adminService = AdminService();

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;

  // Filters
  String? _filterWatchId;
  String? _filterUserId;
  int? _filterRating;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _reviews = [];
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (!_hasMorePages || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _adminService.getAllReviews(
        page: _currentPage,
        limit: 20,
        watchId: _filterWatchId,
        userId: _filterUserId,
        rating: _filterRating,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final reviews = (result['reviews'] as List?)
              ?.map((json) => Review.fromJson(json))
              .toList() ??
          [];

      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      if (mounted) {
        setState(() {
          if (refresh) {
            _reviews = reviews;
          } else {
            _reviews.addAll(reviews);
          }
          _currentPage = pagination['page'] as int? ?? _currentPage;
          _totalPages = pagination['totalPages'] as int? ?? 1;
          _hasMorePages = _currentPage < _totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteReview(String id, String? comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: Text(
            'Are you sure you want to delete this review${comment != null ? ': "${comment.length > 50 ? comment.substring(0, 50) + "..." : comment}"' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteReview(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _loadReviews(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete review: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _applyFilters() {
    _loadReviews(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _filterWatchId = null;
      _filterUserId = null;
      _filterRating = null;
      _searchController.clear();
    });
    _loadReviews(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reviews'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by user name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _clearFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    // Rating Filter
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _filterRating,
                        decoration: const InputDecoration(
                          labelText: 'Rating',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                          border: OutlineInputBorder(),
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
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: '${_sortBy}_$_sortOrder',
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'createdAt_desc',
                              child: Text('Newest First')),
                          DropdownMenuItem(
                              value: 'createdAt_asc',
                              child: Text('Oldest First')),
                          DropdownMenuItem(
                              value: 'rating_desc',
                              child: Text('Highest Rating')),
                          DropdownMenuItem(
                              value: 'rating_asc',
                              child: Text('Lowest Rating')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            final parts = value.split('_');
                            setState(() {
                              _sortBy = parts[0];
                              _sortOrder = parts[1];
                            });
                            _applyFilters();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clear Filters
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed: _clearFilters,
                      tooltip: 'Clear Filters',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reviews List
          Expanded(
            child: _isLoading && _reviews.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _reviews.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.reviews,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'No reviews found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadReviews(refresh: true),
                            child: ListView.builder(
                              itemCount:
                                  _reviews.length + (_hasMorePages ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _reviews.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _loadReviews(refresh: false),
                                        child: const Text('Load More'),
                                      ),
                                    ),
                                  );
                                }

                                final review = _reviews[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: InkWell(
                                    onTap: review.watch != null
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProductDetailScreen(
                                                  watchId: review.watchId,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header Row
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // User Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      review.user?.name ??
                                                          'Anonymous',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    if (review.user?.email !=
                                                        null)
                                                      Text(
                                                        review.user!.email!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              // Rating
                                              RatingBarIndicator(
                                                rating:
                                                    review.rating.toDouble(),
                                                itemBuilder: (context, index) =>
                                                    const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                                itemCount: 5,
                                                itemSize: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              // Delete Button
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () => _deleteReview(
                                                  review.id,
                                                  review.comment,
                                                ),
                                                tooltip: 'Delete Review',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Watch Info
                                          if (review.watch != null)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.watch,
                                                      size: 16,
                                                      color: Colors.blue),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      '${review.watch!.brand?.name ?? ""} ${review.watch!.name}'
                                                          .trim(),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(height: 12),

                                          // Comment
                                          Text(
                                            review.comment,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(height: 12),

                                          // Images
                                          if (review.images.isNotEmpty) ...[
                                            SizedBox(
                                              height: 60,
                                              child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount: review.images.length,
                                                itemBuilder: (context, index) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: CachedNetworkImage(
                                                        imageUrl: review
                                                            .images[index],
                                                        width: 60,
                                                        height: 60,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
                                                          width: 60,
                                                          height: 60,
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2),
                                                          ),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            const Icon(
                                                                Icons.error),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ],

                                          // Footer
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                dateFormat
                                                    .format(review.createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.thumb_up,
                                                      size: 16,
                                                      color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${review.helpfulCount}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
