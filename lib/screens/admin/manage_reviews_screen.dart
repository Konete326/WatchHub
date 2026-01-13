import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../models/review.dart';
import '../../utils/theme.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../widgets/admin/admin_drawer.dart';

class ManageReviewsScreen extends StatefulWidget {
  const ManageReviewsScreen({super.key});

  @override
  State<ManageReviewsScreen> createState() => _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends State<ManageReviewsScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;

  // Filters
  String _selectedStatus = 'pending'; // Default moderation tab
  String? _filterSentiment;
  bool? _filterHasMedia;
  int? _filterRating;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = [
          'pending',
          'flagged',
          'approved',
          'rejected'
        ][_tabController.index];
        _updateStatus(status);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _updateStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadReviews(refresh: true);
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

    setState(() => _isLoading = true);

    try {
      final result = await _adminService.getAllReviews(
        page: _currentPage,
        limit: 20,
        status: _selectedStatus,
        rating: _filterRating,
        sentiment: _filterSentiment,
        hasMedia: _filterHasMedia,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final reviewsData = result['reviews'];
      List<Review> reviews = (reviewsData as List).cast<Review>();

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

  Future<void> _updateReviewStatus(String id, String status) async {
    try {
      await _adminService.updateReviewStatus(id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Review marked as $status'),
            backgroundColor: AppTheme.successColor),
      );
      _loadReviews(refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _submitReply(String id) async {
    if (_replyController.text.isEmpty) return;
    try {
      await _adminService.replyToReview(id, _replyController.text);
      _replyController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reply posted'),
            backgroundColor: AppTheme.successColor),
      );
      _loadReviews(refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _toggleFeature(String id, bool isFeatured) async {
    await _adminService.toggleFeatureReview(id, isFeatured);
    _loadReviews(refresh: true);
  }

  void _showReplyDialog(Review review) {
    _replyController.text = review.adminReply ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${review.user?.name ?? "Review"}'),
        content: TextField(
          controller: _replyController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your response...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _submitReply(review.id),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            child: const Text('Submit Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Review Moderation'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'PENDING'),
            Tab(text: 'FLAGGED'),
            Tab(text: 'APPROVED'),
            Tab(text: 'REJECTED'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadReviews(refresh: true),
              child: _isLoading && _reviews.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _reviews.isEmpty
                      ? _buildErrorState()
                      : _reviews.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount:
                                  _reviews.length + (_hasMorePages ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _reviews.length) {
                                  return _buildLoadMore();
                                }
                                return _buildReviewCard(_reviews[index]);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Sent: ${_filterSentiment ?? "All"}',
              onTap: () => _showSentimentFilter(),
              isActive: _filterSentiment != null,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label:
                  'Media: ${_filterHasMedia == null ? "All" : (_filterHasMedia! ? "Only" : "None")}',
              onTap: () {
                setState(() {
                  if (_filterHasMedia == null)
                    _filterHasMedia = true;
                  else if (_filterHasMedia!)
                    _filterHasMedia = false;
                  else
                    _filterHasMedia = null;
                });
                _loadReviews(refresh: true);
              },
              isActive: _filterHasMedia != null,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Rating: ${_filterRating ?? "All"}',
              onTap: () => _showRatingFilter(),
              isActive: _filterRating != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label,
      required VoidCallback onTap,
      bool isActive = false}) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildReviewCard(Review review) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(review.user?.name[0] ?? '?',
                  style: const TextStyle(color: AppTheme.primaryColor)),
            ),
            title: Row(
              children: [
                Text(review.user?.name ?? 'Anonymous',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (review.tags?.contains('verified') ?? false)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.verified, size: 14, color: Colors.blue),
                  ),
                const Spacer(),
                _buildSentimentBadge(review),
              ],
            ),
            subtitle: Text(dateFormat.format(review.createdAt),
                style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: Icon(review.isFeatured ? Icons.star : Icons.star_border,
                  color: review.isFeatured ? Colors.orange : null),
              onPressed: () => _toggleFeature(review.id, !review.isFeatured),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingBarIndicator(
                  rating: review.rating.toDouble(),
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 18,
                ),
                const SizedBox(height: 8),
                Text(review.comment,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
                if (review.flagReason != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Auto-Flag: ${review.flagReason}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12))),
                      ],
                    ),
                  ),
                if (review.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: review.images.length,
                        itemBuilder: (context, i) =>
                            _buildMediaPreview(review.images[i]),
                      ),
                    ),
                  ),
                if (review.adminReply != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOUR RESPONSE',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(review.adminReply!,
                            style: const TextStyle(
                                fontSize: 13, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                if (_selectedStatus == 'pending' ||
                    _selectedStatus == 'flagged') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      onPressed: () =>
                          _updateReviewStatus(review.id, 'rejected'),
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      onPressed: () =>
                          _updateReviewStatus(review.id, 'approved'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor),
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    icon: const Icon(Icons.reply, size: 16),
                    label: Text(review.adminReply == null
                        ? 'Respond'
                        : 'Edit Response'),
                    onPressed: () => _showReplyDialog(review),
                  ),
                  const Spacer(),
                  if (_selectedStatus == 'approved')
                    TextButton(
                      onPressed: () =>
                          _updateReviewStatus(review.id, 'rejected'),
                      child: const Text('Unapprove',
                          style: TextStyle(color: Colors.red)),
                    )
                  else
                    TextButton(
                      onPressed: () =>
                          _updateReviewStatus(review.id, 'approved'),
                      child: const Text('Restore',
                          style: TextStyle(color: AppTheme.successColor)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSentimentBadge(Review review) {
    final score = review.sentimentScore ?? 0.0;
    Color color = Colors.grey;
    IconData icon = Icons.sentiment_neutral;

    if (score > 0.2) {
      color = Colors.green;
      icon = Icons.sentiment_satisfied;
    } else if (score < -0.2) {
      color = Colors.red;
      icon = Icons.sentiment_dissatisfied;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(review.sentimentLabel,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No ${_selectedStatus.toUpperCase()} reviews',
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'An error occurred',
              style: const TextStyle(fontSize: 16, color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadReviews(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: TextButton(
          onPressed: () => _loadReviews(refresh: false),
          child: const Text('Load More Reviews'),
        ),
      ),
    );
  }

  void _showSentimentFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              title: const Text('All Sentiments'),
              onTap: () {
                setState(() => _filterSentiment = null);
                _loadReviews(refresh: true);
                Navigator.pop(context);
              }),
          ListTile(
              title: const Text('Positive'),
              leading:
                  const Icon(Icons.sentiment_satisfied, color: Colors.green),
              onTap: () {
                setState(() => _filterSentiment = 'positive');
                _loadReviews(refresh: true);
                Navigator.pop(context);
              }),
          ListTile(
              title: const Text('Neutral'),
              leading: const Icon(Icons.sentiment_neutral, color: Colors.grey),
              onTap: () {
                setState(() => _filterSentiment = 'neutral');
                _loadReviews(refresh: true);
                Navigator.pop(context);
              }),
          ListTile(
              title: const Text('Negative'),
              leading:
                  const Icon(Icons.sentiment_dissatisfied, color: Colors.red),
              onTap: () {
                setState(() => _filterSentiment = 'negative');
                _loadReviews(refresh: true);
                Navigator.pop(context);
              }),
        ],
      ),
    );
  }

  void _showRatingFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              title: const Text('All Ratings'),
              onTap: () {
                setState(() => _filterRating = null);
                _loadReviews(refresh: true);
                Navigator.pop(context);
              }),
          ...List.generate(
              5,
              (i) => ListTile(
                    title: Text('${5 - i} Stars'),
                    leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                            5 - i,
                            (_) => const Icon(Icons.star,
                                size: 16, color: Colors.amber))),
                    onTap: () {
                      setState(() => _filterRating = 5 - i);
                      _loadReviews(refresh: true);
                      Navigator.pop(context);
                    },
                  )),
        ],
      ),
    );
  }
}
