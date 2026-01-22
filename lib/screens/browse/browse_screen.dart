import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/watch_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/search_provider.dart';
import '../product/product_detail_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/watch_card.dart';
import '../../utils/haptics.dart';
import '../../widgets/shimmer_loading.dart' show ShimmerWidget;

class BrowseScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialBrandId;
  final bool initialOnlySale;
  final double? initialMaxPrice;
  final String? initialStrapType;
  final String? initialSearch;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool autoFocusSearch;

  const BrowseScreen({
    super.key,
    this.initialCategory,
    this.initialBrandId,
    this.initialOnlySale = false,
    this.initialMaxPrice,
    this.initialStrapType,
    this.initialSearch,
    this.showBackButton = true,
    this.onBack,
    this.autoFocusSearch = false,
  });

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String? _selectedCategory;
  String? _selectedBrandId;
  bool _onlySale = false;
  double _minPrice = 0;
  double _maxPrice = 50000;
  String? _selectedStrapType; // 'belt' or 'chain'
  bool _inStockOnly = false;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedBrandId = widget.initialBrandId;
    _onlySale = widget.initialOnlySale;
    if (widget.initialMaxPrice != null) {
      _maxPrice = widget.initialMaxPrice!;
    }
    _selectedStrapType = widget.initialStrapType;
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    _fetchWatches();
    Future.microtask(() {
      final watchProvider = Provider.of<WatchProvider>(context, listen: false);
      watchProvider.fetchBrands();
      watchProvider.fetchCategories();
    });
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    
    // Auto-focus search field if requested
    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      category: _selectedCategory,
      brandId: _selectedBrandId,
      onlySale: _onlySale,
      minPrice: _minPrice,
      maxPrice: _maxPrice >= 50000 ? null : _maxPrice,
      strapType: _selectedStrapType,
      inStockOnly: _inStockOnly,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = AppTheme.softUiBackground;
    final watchProvider = Provider.of<WatchProvider>(context);
    final searchProvider = Provider.of<SearchProvider>(context);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _fetchWatches(),
              color: AppTheme.primaryColor,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: Row(
                        children: [
                          if (widget.showBackButton)
                            _NeumorphicButton(
                              onTap:
                                  widget.onBack ?? () => Navigator.pop(context),
                              padding: const EdgeInsets.all(10),
                              shape: BoxShape.circle,
                              child: const Icon(Icons.arrow_back,
                                  color: AppTheme.softUiTextColor),
                            ),
                          if (widget.showBackButton) const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Discover',
                              style: GoogleFonts.montserrat(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          _NeumorphicButton(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WishlistScreen()),
                              );
                            },
                            padding: const EdgeInsets.all(10),
                            shape: BoxShape.circle,
                            child: const Icon(Icons.favorite_border,
                                color: AppTheme.softUiTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sticky Search & Filter Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySearchDelegate(
                      child: Container(
                        color: kBackgroundColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSearchBar(),
                            ),
                            const SizedBox(width: 12),
                            _NeumorphicButton(
                              onTap: () => _showFilters(),
                              padding: const EdgeInsets.all(12),
                              borderRadius: BorderRadius.circular(15),
                              child: Icon(
                                Icons.tune_rounded,
                                color: (_selectedCategory != null ||
                                        _selectedBrandId != null ||
                                        _onlySale)
                                    ? AppTheme.goldColor
                                    : AppTheme.softUiTextColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _NeumorphicButton(
                              onTap: () {
                                HapticHelper.light();
                                searchProvider.toggleViewMode();
                              },
                              padding: const EdgeInsets.all(12),
                              borderRadius: BorderRadius.circular(15),
                              child: Icon(
                                searchProvider.isGridView
                                    ? Icons.view_list_rounded
                                    : Icons.grid_view_rounded,
                                color: AppTheme.softUiTextColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  if (watchProvider.isLoading && watchProvider.watches.isEmpty)
                    _buildSliverLoading(searchProvider.isGridView)
                  else if (watchProvider.watches.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No timepieces found',
                        message:
                            'We couldn\'t find any watches matching your criteria. Try adjusting your filters.',
                        onAction: () {
                          setState(() {
                            _selectedCategory = null;
                            _selectedBrandId = null;
                            _onlySale = false;
                            _minPrice = 0;
                            _maxPrice = 50000;
                            _searchController.clear();
                          });
                          _fetchWatches();
                        },
                      ),
                    )
                  else
                    _buildSliverProductList(
                        watchProvider, searchProvider.isGridView),

                  // Load More Indicator Shimmer
                  if (watchProvider.isLoadingMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                        child: searchProvider.isGridView
                            ? Row(
                                children: const [
                                  Expanded(child: _NeumorphicProductShimmer()),
                                  SizedBox(width: 16),
                                  Expanded(child: _NeumorphicProductShimmer()),
                                ],
                              )
                            : const _NeumorphicProductShimmer(),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // Search Suggestions Overlay
            if (_isSearchFocused) _buildSearchOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return _NeumorphicContainer(
      isConcave: true,
      borderRadius: BorderRadius.circular(15),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (val) {
          // Could implement real-time search here with debounce
        },
        onSubmitted: (val) {
          final searchProvider =
              Provider.of<SearchProvider>(context, listen: false);
          searchProvider.addRecentSearch(val);
          _fetchWatches();
        },
        decoration: InputDecoration(
          hintText: 'Search collection...',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.textTertiaryColor,
            fontSize: 14,
          ),
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded,
              color: AppTheme.textTertiaryColor, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _fetchWatches();
                  },
                  child: const Icon(Icons.close_rounded, size: 18),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchOverlay(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.only(top: 130), // Below header
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.softUiBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: AppTheme.softUiBackground,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (searchProvider.recentSearches.isNotEmpty) ...[
                            _buildSearchSectionTitle('Recent Searches',
                                onClear: () =>
                                    searchProvider.clearRecentSearches()),
                            ...searchProvider.recentSearches
                                .map((term) => _buildSearchItem(term)),
                            const Divider(height: 32),
                          ],
                          _buildSearchSectionTitle('Trending Terms'),
                          ...searchProvider.trendingTerms.map((term) =>
                              _buildSearchItem(term, isTrending: true)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSectionTitle(String title, {VoidCallback? onClear}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textTertiaryColor,
              letterSpacing: 1.0,
            ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Text(
                'Clear',
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppTheme.goldColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchItem(String term, {bool isTrending = false}) {
    return ListTile(
      leading: Icon(
        isTrending ? Icons.trending_up_rounded : Icons.history_rounded,
        size: 18,
        color: AppTheme.textTertiaryColor,
      ),
      title: Text(
        term,
        style:
            GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimaryColor),
      ),
      onTap: () {
        _searchController.text = term;
        _searchFocusNode.unfocus();
        Provider.of<SearchProvider>(context, listen: false)
            .addRecentSearch(term);
        _fetchWatches();
      },
    );
  }

  Widget _buildSliverLoading(bool isGridView) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);

    if (isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const _NeumorphicProductShimmer(),
            childCount: crossAxisCount * 3,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerWidget.rounded(
              height: 120,
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildSliverProductList(WatchProvider watchProvider, bool isGridView) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);

    if (isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.62,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final watch = watchProvider.watches[index];
              return WatchCard(
                watch: watch,
                isListMode: false,
                heroTag: 'browse_grid_${watch.id}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(watchId: watch.id)),
                ),
              );
            },
            childCount: watchProvider.watches.length,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final watch = watchProvider.watches[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: WatchCard(
                watch: watch,
                isListMode: true,
                heroTag: 'browse_list_${watch.id}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(watchId: watch.id)),
                ),
              ),
            );
          },
          childCount: watchProvider.watches.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback onAction,
  }) {
    const kTextColor = Color(0xFF4A5568);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NeumorphicContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(40),
              isConcave: true,
              child: Icon(icon, size: 64, color: kTextColor.withOpacity(0.3)),
            ),
            const SizedBox(height: 32),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextColor)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: kTextColor.withOpacity(0.6),
                    height: 1.5)),
            const SizedBox(height: 32),
            _NeumorphicButton(
              onTap: onAction,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              borderRadius: BorderRadius.circular(15),
              child: const Text('Clear All Filters',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const kBackgroundColor = Color(0xFFE0E5EC);
            const kTextColor = Color(0xFF4A5568);

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Search Options',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        _NeumorphicButton(
                          onTap: () {
                            setModalState(() {
                              _selectedCategory = null;
                              _selectedBrandId = null;
                              _onlySale = false;
                              _minPrice = 0;
                              _maxPrice = 50000;
                              _selectedStrapType = null;
                              _inStockOnly = false;
                              _sortBy = 'createdAt';
                              _sortOrder = 'desc';
                            });
                          },
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          borderRadius: BorderRadius.circular(12),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Presets Section
                  _buildPresetsSection(setModalState),

                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sort Section
                          const Text(
                            'Sort By',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextColor),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildFilterChip(
                                label: 'Newest',
                                isSelected: _sortBy == 'createdAt',
                                onTap: () {
                                  setModalState(() {
                                    _sortBy = 'createdAt';
                                    _sortOrder = 'desc';
                                  });
                                },
                              ),
                              _buildFilterChip(
                                label: 'Price: Low to High',
                                isSelected:
                                    _sortBy == 'price' && _sortOrder == 'asc',
                                onTap: () {
                                  setModalState(() {
                                    _sortBy = 'price';
                                    _sortOrder = 'asc';
                                  });
                                },
                              ),
                              _buildFilterChip(
                                label: 'Price: High to Low',
                                isSelected:
                                    _sortBy == 'price' && _sortOrder == 'desc',
                                onTap: () {
                                  setModalState(() {
                                    _sortBy = 'price';
                                    _sortOrder = 'desc';
                                  });
                                },
                              ),
                              _buildFilterChip(
                                label: 'Popularity',
                                isSelected: _sortBy == 'popularity',
                                onTap: () {
                                  setModalState(() {
                                    _sortBy = 'popularity';
                                    _sortOrder = 'desc';
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Price Range Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Price Range',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kTextColor),
                              ),
                              Consumer<SettingsProvider>(
                                builder: (context, settings, child) {
                                  return Text(
                                    '${settings.formatPrice(_minPrice)} - ${_maxPrice >= 50000 ? settings.formatPrice(_maxPrice) + '+' : settings.formatPrice(_maxPrice)}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RangeSlider(
                            values: RangeValues(_minPrice, _maxPrice),
                            min: 0,
                            max: 50000,
                            divisions: 50,
                            activeColor: AppTheme.primaryColor,
                            inactiveColor: Colors.black12,
                            onChanged: (values) {
                              setModalState(() {
                                _minPrice = values.start;
                                _maxPrice = values.end;
                              });
                            },
                          ),

                          const SizedBox(height: 32),

                          // Strap Type Section
                          const Text(
                            'Strap Type',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextColor),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildFilterChip(
                                label: 'Leather / Belt',
                                isSelected: _selectedStrapType == 'belt',
                                onTap: () {
                                  setModalState(() {
                                    _selectedStrapType =
                                        _selectedStrapType == 'belt'
                                            ? null
                                            : 'belt';
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildFilterChip(
                                label: 'Steel / Chain',
                                isSelected: _selectedStrapType == 'chain',
                                onTap: () {
                                  setModalState(() {
                                    _selectedStrapType =
                                        _selectedStrapType == 'chain'
                                            ? null
                                            : 'chain';
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Availability Section
                          const Text(
                            'Availability',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextColor),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildToggleItem(
                                label: 'On Sale',
                                value: _onlySale,
                                onChanged: (val) {
                                  setModalState(() => _onlySale = val);
                                },
                              ),
                              const SizedBox(width: 24),
                              _buildToggleItem(
                                label: 'In Stock Only',
                                value: _inStockOnly,
                                onChanged: (val) {
                                  setModalState(() => _inStockOnly = val);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Category Section
                          const Text(
                            'Category',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextColor),
                          ),
                          const SizedBox(height: 16),
                          Consumer<WatchProvider>(
                            builder: (context, watchProvider, child) {
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildFilterChip(
                                    label: 'All',
                                    isSelected: _selectedCategory == null,
                                    onTap: () => setModalState(
                                        () => _selectedCategory = null),
                                  ),
                                  ...watchProvider.categories.map((category) {
                                    return _buildFilterChip(
                                      label: category.name,
                                      isSelected:
                                          _selectedCategory == category.name,
                                      onTap: () {
                                        setModalState(() => _selectedCategory =
                                            _selectedCategory == category.name
                                                ? null
                                                : category.name);
                                      },
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Brand Section
                          const Text(
                            'Brand',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextColor),
                          ),
                          const SizedBox(height: 16),
                          Consumer<WatchProvider>(
                            builder: (context, watchProvider, child) {
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildFilterChip(
                                    label: 'All',
                                    isSelected: _selectedBrandId == null,
                                    onTap: () => setModalState(
                                        () => _selectedBrandId = null),
                                  ),
                                  ...watchProvider.brands.map((brand) {
                                    return _buildFilterChip(
                                      label: brand.name,
                                      isSelected: _selectedBrandId == brand.id,
                                      onTap: () {
                                        setModalState(() => _selectedBrandId =
                                            _selectedBrandId == brand.id
                                                ? null
                                                : brand.id);
                                      },
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Save Preset Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextButton.icon(
                      onPressed: () => _showSavePresetDialog(),
                      icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                      label: const Text('Save these filters as a preset'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.goldColor,
                        textStyle: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Footer / Apply Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _NeumorphicButton(
                      onTap: () {
                        setState(() {
                          // Already updated in setModalState but ensuring global state
                        });
                        Navigator.pop(context);
                        _fetchWatches();
                      },
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      borderRadius: BorderRadius.circular(20),
                      child: const Center(
                        child: Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return _NeumorphicFilterChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    const kTextColor = Color(0xFF4A5568);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NeumorphicContainer(
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(6),
            child: Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color:
                  value ? AppTheme.primaryColor : kTextColor.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(Function(void Function()) setModalState) {
    final searchProvider = Provider.of<SearchProvider>(context);
    if (searchProvider.presets.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Your Presets',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A5568),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: searchProvider.presets.length,
            itemBuilder: (context, index) {
              final preset = searchProvider.presets[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _NeumorphicButton(
                  onTap: () {
                    setModalState(() {
                      _selectedCategory = preset.category;
                      _selectedBrandId = preset.brandId;
                      _minPrice = preset.minPrice;
                      _maxPrice = preset.maxPrice;
                      _onlySale = preset.onlySale;
                    });
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Text(
                        preset.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => searchProvider.removePreset(preset.name),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSavePresetDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Filter Preset', style: GoogleFonts.montserrat()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              hintText: 'Preset name (e.g. Budget Rolex)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final searchProvider =
                    Provider.of<SearchProvider>(context, listen: false);
                searchProvider.savePreset(FilterPreset(
                  name: controller.text,
                  category: _selectedCategory,
                  brandId: _selectedBrandId,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                  onlySale: _onlySale,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter preset saved!')),
                );
              }
            },
            child: const Text('Save',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.softUiBackground,
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
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(3, 3),
                    blurRadius: 8),
                const BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-3, -3),
                    blurRadius: 8),
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
          color: AppTheme.softUiBackground,
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
                      color: AppTheme.softUiShadowDark,
                      offset: Offset(2, 2),
                      blurRadius: 5),
                  const BoxShadow(
                      color: AppTheme.softUiShadowLight,
                      offset: Offset(-2, -2),
                      blurRadius: 5),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _NeumorphicFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NeumorphicFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E5EC),
          borderRadius: BorderRadius.circular(20),
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
                      offset: Offset(3, 3),
                      blurRadius: 6),
                  const BoxShadow(
                      color: Color(0xFFFFFFFF),
                      offset: Offset(-3, -3),
                      blurRadius: 6),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFF4A5568),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 70;

  @override
  double get minExtent => 70;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class _NeumorphicProductShimmer extends StatelessWidget {
  const _NeumorphicProductShimmer();

  @override
  Widget build(BuildContext context) {
    return _NeumorphicContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _NeumorphicContainer(
              isConcave: true,
              borderRadius: BorderRadius.circular(20),
              child: Shimmer.fromColors(
                baseColor: AppTheme.softUiShadowDark.withOpacity(0.5),
                highlightColor: AppTheme.softUiBackground,
                child: Container(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: const Color(0xFFD1D9E6),
            highlightColor: const Color(0xFFE0E5EC),
            child: Container(
              height: 12,
              width: 60,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(5)),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: const Color(0xFFD1D9E6),
            highlightColor: const Color(0xFFE0E5EC),
            child: Container(
              height: 16,
              width: 100,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(5)),
            ),
          ),
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: const Color(0xFFD1D9E6),
            highlightColor: const Color(0xFFE0E5EC),
            child: Container(
              height: 18,
              width: 80,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(5)),
            ),
          ),
        ],
      ),
    );
  }
}
