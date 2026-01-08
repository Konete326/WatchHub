import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/watch_provider.dart';
import '../../widgets/watch_card.dart';
import '../product/product_detail_screen.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../providers/wishlist_provider.dart';
import '../wishlist/wishlist_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/glass_app_bar.dart';

class BrowseScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialBrandId;
  final bool showBackButton;

  const BrowseScreen({
    super.key,
    this.initialCategory,
    this.initialBrandId,
    this.showBackButton = true,
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

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedBrandId = widget.initialBrandId;
    _fetchWatches();
    Future.microtask(() {
      final watchProvider = Provider.of<WatchProvider>(context, listen: false);
      watchProvider.fetchBrands();
      watchProvider.fetchCategories();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      category: _selectedCategory,
      brandId: _selectedBrandId,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Browse Watches',
        showBackButton: widget.showBackButton,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
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
              const PopupMenuItem(value: 'newest', child: Text('Newest')),
              const PopupMenuItem(
                  value: 'price_asc', child: Text('Price: Low to High')),
              const PopupMenuItem(
                  value: 'price_desc', child: Text('Price: High to Low')),
              const PopupMenuItem(
                  value: 'popularity', child: Text('Most Popular')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(),
          ),
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const WishlistScreen()),
                      );
                    },
                  ),
                  if (wishlistProvider.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${wishlistProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchWatches(),
        child: Consumer<WatchProvider>(
          builder: (context, watchProvider, child) {
            if (watchProvider.isLoading && watchProvider.watches.isEmpty) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => const ProductCardShimmer(),
              );
            }

            if (watchProvider.errorMessage != null &&
                watchProvider.watches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      watchProvider.errorMessage!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _fetchWatches(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (watchProvider.watches.isEmpty) {
              return EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No watches found',
                message:
                    'Try adjusting your filters or search terms to find what you\'re looking for.',
                actionLabel: 'Start Shopping',
                onActionPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedBrandId = null;
                  });
                  _fetchWatches();
                },
              );
            }

            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: watchProvider.watches.length +
                  (watchProvider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= watchProvider.watches.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final watch = watchProvider.watches[index];
                return WatchCard(
                  watch: watch,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(watchId: watch.id),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Category'),
                  Consumer<WatchProvider>(
                    builder: (context, watchProvider, child) {
                      return Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              setModalState(() => _selectedCategory = null);
                              setState(() => _selectedCategory = null);
                            },
                          ),
                          ...watchProvider.categories.map((category) {
                            return FilterChip(
                              label: Text(category.name),
                              selected: _selectedCategory == category.name,
                              onSelected: (selected) {
                                setModalState(() => _selectedCategory =
                                    selected ? category.name : null);
                                setState(() => _selectedCategory =
                                    selected ? category.name : null);
                              },
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Brand'),
                  Consumer<WatchProvider>(
                    builder: (context, watchProvider, child) {
                      return Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedBrandId == null,
                            onSelected: (selected) {
                              setModalState(() => _selectedBrandId = null);
                              setState(() => _selectedBrandId = null);
                            },
                          ),
                          ...watchProvider.brands.map((brand) {
                            return FilterChip(
                              label: Text(brand.name),
                              selected: _selectedBrandId == brand.id,
                              onSelected: (selected) {
                                setModalState(() => _selectedBrandId =
                                    selected ? brand.id : null);
                                setState(() => _selectedBrandId =
                                    selected ? brand.id : null);
                              },
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchWatches();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
