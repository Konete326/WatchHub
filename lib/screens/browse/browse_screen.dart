import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/watch_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/watch_card.dart';
import '../../utils/animation_utils.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';
import '../../widgets/shimmer_loading.dart';
import '../search/search_screen.dart';

class BrowseScreen extends StatefulWidget {
  final String? brandId;
  final String? category;

  const BrowseScreen({
    super.key,
    this.brandId,
    this.category,
  });

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String? _selectedCategory;
  String? _selectedBrandId;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  double _minPrice = 0;
  double _maxPrice = 100000;
  RangeValues _priceRange = const RangeValues(0, 100000);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _selectedBrandId = widget.brandId;
    Future.microtask(() {
      final watchProvider = Provider.of<WatchProvider>(context, listen: false);
      watchProvider.fetchBrands();
      watchProvider.fetchCategories();
      // Fetch watches after a small delay to ensure context is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _fetchWatches();
        }
      });
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final watchProvider = Provider.of<WatchProvider>(context, listen: false);
      if (!watchProvider.isLoadingMore && watchProvider.hasMorePages) {
        _fetchWatches(loadMore: true);
      }
    }
  }

  Future<void> _fetchWatches({bool loadMore = false}) async {
    final watchProvider = Provider.of<WatchProvider>(context, listen: false);
    await watchProvider.fetchWatches(
      refresh: !loadMore,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      category: _selectedCategory,
      brandId: _selectedBrandId,
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 100000 ? _priceRange.end : null,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedBrandId = null;
      _priceRange = const RangeValues(0, 100000);
      _minPrice = 0;
      _maxPrice = 100000;
    });
    _fetchWatches();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedBrandId != null) count++;
    if (_priceRange.start > 0 || _priceRange.end < 100000) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Browse Watches',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.accentColor,
                    ],
                  ),
                ),
              ),
            ),
        actions: [
              // View Toggle
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ).animate().fadeIn(duration: 300.ms).scale(),
              // Sort Menu
          PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Colors.white),
                color: Colors.white,
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'price_asc':
                    _sortBy = 'price';
                    _sortOrder = 'asc';
                    break;
                  case 'price_desc':
                    _sortBy = 'price';
                    _sortOrder = 'desc';
                    break;
                  case 'popularity':
                    _sortBy = 'popularity';
                    _sortOrder = 'desc';
                    break;
                  case 'newest':
                    _sortBy = 'createdAt';
                    _sortOrder = 'desc';
                    break;
                }
              });
              _fetchWatches();
            },
            itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'newest',
                    child: Row(
                      children: [
                        Icon(Icons.new_releases, size: 20),
                        SizedBox(width: 8),
                        Text('Newest'),
                      ],
                    ),
                  ),
              const PopupMenuItem(
                    value: 'price_asc',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 20),
                        SizedBox(width: 8),
                        Text('Price: Low to High'),
                      ],
                    ),
                  ),
              const PopupMenuItem(
                    value: 'price_desc',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 20),
                        SizedBox(width: 8),
                        Text('Price: High to Low'),
                      ],
                    ),
                  ),
              const PopupMenuItem(
                    value: 'popularity',
                    child: Row(
                      children: [
                        Icon(Icons.trending_up, size: 20),
                        SizedBox(width: 8),
                        Text('Most Popular'),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).scale(),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search watches...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.isEmpty) {
                    _fetchWatches();
                  } else {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value && mounted) {
                        _fetchWatches();
                      }
                    });
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _fetchWatches();
                  }
                },
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1, end: 0),
            ),
          ),

          // Active Filters & Filter Button
          SliverToBoxAdapter(
            child: Consumer<WatchProvider>(
              builder: (context, watchProvider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (_selectedCategory != null)
                                    _buildFilterChip(
                                      label: watchProvider.categories
                                              .firstWhere(
                                                (c) => c.name == _selectedCategory,
                                                orElse: () => watchProvider
                                                    .categories.first,
                                              )
                                              .name ??
                                          _selectedCategory!,
                                      onRemove: () {
                                        setState(() {
                                          _selectedCategory = null;
                                        });
                                        _fetchWatches();
                                      },
                                    ),
                                  if (_selectedBrandId != null)
                                    _buildFilterChip(
                                      label: watchProvider.brands
                                              .firstWhere(
                                                (b) => b.id == _selectedBrandId,
                                                orElse: () =>
                                                    watchProvider.brands.first,
                                              )
                                              .name ??
                                          'Brand',
                                      onRemove: () {
                                        setState(() {
                                          _selectedBrandId = null;
                                        });
                                        _fetchWatches();
                                      },
                                    ),
                                  if (_priceRange.start > 0 ||
                                      _priceRange.end < 100000)
                                    _buildFilterChip(
                                      label:
                                          '\$${_priceRange.start.toStringAsFixed(0)} - \$${_priceRange.end.toStringAsFixed(0)}',
                                      onRemove: () {
                                        setState(() {
                                          _priceRange = const RangeValues(0, 100000);
                                        });
                                        _fetchWatches();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showFilters(),
                                icon: const Icon(Icons.filter_list, size: 18),
                                label: const Text('Filters'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              if (_activeFilterCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.errorColor,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '$_activeFilterCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_activeFilterCount > 0) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear all filters'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0);
              },
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),

          // Watches Grid/List
          Consumer<WatchProvider>(
          builder: (context, watchProvider, child) {
            if (watchProvider.isLoading && watchProvider.watches.isEmpty) {
                return SliverPadding(
                padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                      childAspectRatio: 0.68,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ProductCardShimmer(),
                      childCount: 6,
                    ),
                  ),
              );
            }

            if (watchProvider.watches.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        )
                            .animate()
                            .fadeIn()
                            .scale(delay: 200.ms),
                        const SizedBox(height: 16),
                        Text(
                          'No watches found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Filters'),
                          )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .scale(),
                        ],
                      ],
                    ),
                  ),
                );
              }

              if (_isGridView) {
                return SliverPadding(
              padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                if (index >= watchProvider.watches.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                }

                final watch = watchProvider.watches[index];
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2,
                          child: ScaleAnimation(
                            scale: 0.5,
                            child: FadeInAnimation(
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: WatchCard(
                  watch: watch,
                  onTap: () {
                    AnimationUtils.pushContainerTransform(
                      context,
                      ProductDetailScreen(watchId: watch.id),
                    );
                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: watchProvider.watches.length +
                          (watchProvider.isLoadingMore ? 1 : 0),
                    ),
                  ),
                );
              } else {
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= watchProvider.watches.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final watch = watchProvider.watches[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildListCard(watch),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: watchProvider.watches.length +
                          (watchProvider.isLoadingMore ? 1 : 0),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        labelStyle: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    )
        .animate()
        .fadeIn()
        .scale();
  }

  Widget _buildListCard(dynamic watch) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          AnimationUtils.pushContainerTransform(
            context,
            ProductDetailScreen(watchId: watch.id),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
              ),
              child: watch.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: watch.images.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.watch, color: Colors.grey),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (watch.brand != null)
                      Text(
                        watch.brand!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      watch.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, child) {
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (watch.isOnSale)
                                    Text(
                                      settings.formatPrice(watch.price),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    settings.formatPrice(watch.currentPrice),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (watch.averageRating != null &&
                                watch.averageRating! > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    watch.averageRating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                .animate()
                                .fadeIn()
                                .slideX(begin: -0.1, end: 0),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedCategory = null;
                                  _selectedBrandId = null;
                                  _priceRange = const RangeValues(0, 100000);
                                });
                                setState(() {
                                  _selectedCategory = null;
                                  _selectedBrandId = null;
                                  _priceRange = const RangeValues(0, 100000);
                                });
                              },
                              child: const Text('Reset'),
                            )
                                .animate()
                                .fadeIn()
                                .slideX(begin: 0.1, end: 0),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Price Range
                            _buildPriceRangeFilter(setModalState)
                                .animate()
                                .fadeIn(delay: 100.ms)
                                .slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 24),
                            // Category
                            _buildCategoryFilter(setModalState)
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 24),
                            // Brand
                            _buildBrandFilter(setModalState)
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      // Apply Button
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _fetchWatches();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Apply Filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .scale(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriceRangeFilter(StateSetter setModalState) {
    return Consumer<WatchProvider>(
      builder: (context, watchProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 100000,
              divisions: 100,
              labels: RangeLabels(
                '\$${_priceRange.start.toStringAsFixed(0)}',
                '\$${_priceRange.end.toStringAsFixed(0)}',
              ),
              onChanged: (RangeValues values) {
                setModalState(() {
                  _priceRange = values;
                });
                setState(() {
                  _priceRange = values;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${_priceRange.start.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${_priceRange.end.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryFilter(StateSetter setModalState) {
    return Consumer<WatchProvider>(
                    builder: (context, watchProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
                        spacing: 8,
              runSpacing: 8,
                        children: [
                _buildFilterOption(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () {
                              setModalState(() => _selectedCategory = null);
                              setState(() => _selectedCategory = null);
                            },
                          ),
                          ...watchProvider.categories.map((category) {
                  return _buildFilterOption(
                    label: category.name,
                    isSelected: _selectedCategory == category.name,
                    onTap: () {
                      setModalState(() {
                        _selectedCategory =
                            _selectedCategory == category.name
                                ? null
                                : category.name;
                      });
                      setState(() {
                        _selectedCategory =
                            _selectedCategory == category.name
                                ? null
                                : category.name;
                      });
                              },
                            );
                          }).toList(),
              ],
            ),
                        ],
                      );
                    },
    );
  }

  Widget _buildBrandFilter(StateSetter setModalState) {
    return Consumer<WatchProvider>(
      builder: (context, watchProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brand',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
                        spacing: 8,
              runSpacing: 8,
                        children: [
                _buildFilterOption(
                  label: 'All',
                  isSelected: _selectedBrandId == null,
                  onTap: () {
                              setModalState(() => _selectedBrandId = null);
                              setState(() => _selectedBrandId = null);
                            },
                          ),
                          ...watchProvider.brands.map((brand) {
                  return _buildFilterOption(
                    label: brand.name,
                    isSelected: _selectedBrandId == brand.id,
                    onTap: () {
                      setModalState(() {
                        _selectedBrandId =
                            _selectedBrandId == brand.id ? null : brand.id;
                      });
                      setState(() {
                        _selectedBrandId =
                            _selectedBrandId == brand.id ? null : brand.id;
                      });
                              },
                            );
                          }).toList(),
                        ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
