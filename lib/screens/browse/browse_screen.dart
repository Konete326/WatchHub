import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/watch_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/watch.dart';
import '../product/product_detail_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../../utils/theme.dart';

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
  bool _isSortMenuOpen = false;

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
    const kBackgroundColor = Color(0xFFE0E5EC);
    const kTextColor = Color(0xFF4A5568);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: kBackgroundColor,
            child: Row(
              children: [
                if (widget.showBackButton)
                  _NeumorphicButton(
                    onTap: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(10),
                    shape: BoxShape.circle,
                    child: const Icon(Icons.arrow_back, color: kTextColor),
                  ),
                if (widget.showBackButton) const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Browse',
                    style: TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                _NeumorphicButton(
                  onTap: () =>
                      setState(() => _isSortMenuOpen = !_isSortMenuOpen),
                  padding: const EdgeInsets.all(10),
                  shape: BoxShape.circle,
                  child: Icon(Icons.sort,
                      color:
                          _isSortMenuOpen ? AppTheme.primaryColor : kTextColor),
                ),
                const SizedBox(width: 12),
                _NeumorphicButton(
                  onTap: () => _showFilters(),
                  padding: const EdgeInsets.all(10),
                  shape: BoxShape.circle,
                  child: const Icon(Icons.filter_list, color: kTextColor),
                ),
                const SizedBox(width: 12),
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _NeumorphicButton(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const WishlistScreen()),
                            );
                          },
                          padding: const EdgeInsets.all(10),
                          shape: BoxShape.circle,
                          child: const Icon(Icons.favorite_border,
                              color: kTextColor),
                        ),
                        if (wishlistProvider.itemCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: _NeumorphicContainer(
                              isConcave: true,
                              shape: BoxShape.circle,
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${wishlistProvider.itemCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _fetchWatches(),
            color: AppTheme.primaryColor,
            backgroundColor: kBackgroundColor,
            child: Consumer<WatchProvider>(
              builder: (context, watchProvider, child) {
                if (watchProvider.isLoading && watchProvider.watches.isEmpty) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) =>
                        const _NeumorphicProductShimmer(),
                  );
                }

                if (watchProvider.errorMessage != null &&
                    watchProvider.watches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NeumorphicContainer(
                          shape: BoxShape.circle,
                          padding: const EdgeInsets.all(30),
                          isConcave: true,
                          child: const Icon(Icons.error_outline,
                              size: 64, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          watchProvider.errorMessage!,
                          style:
                              const TextStyle(fontSize: 16, color: kTextColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _NeumorphicButton(
                          onTap: () => _fetchWatches(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          borderRadius: BorderRadius.circular(15),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (watchProvider.watches.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No watches found',
                    message:
                        'Try adjusting your filters or search terms to find what you\'re looking for.',
                    onAction: () {
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
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: watchProvider.watches.length +
                      (watchProvider.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= watchProvider.watches.length) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                      );
                    }

                    final watch = watchProvider.watches[index];
                    return _NeumorphicWatchCard(
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
          if (_isSortMenuOpen)
            Positioned(
              top: 0,
              right: 24,
              child: _NeumorphicSortMenu(
                currentSortBy: _sortBy,
                currentSortOrder: _sortOrder,
                onSelected: (value) {
                  setState(() {
                    _isSortMenuOpen = false;
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
              ),
            ),
        ],
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
              child: const Text('Reset Filters',
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
              decoration: const BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _NeumorphicFilterChip(
                            label: 'All',
                            isSelected: _selectedCategory == null,
                            onTap: () {
                              setModalState(() => _selectedCategory = null);
                              setState(() => _selectedCategory = null);
                            },
                          ),
                          ...watchProvider.categories.map((category) {
                            return _NeumorphicFilterChip(
                              label: category.name,
                              isSelected: _selectedCategory == category.name,
                              onTap: () {
                                setModalState(() => _selectedCategory =
                                    _selectedCategory == category.name
                                        ? null
                                        : category.name);
                                setState(() => _selectedCategory =
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
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _NeumorphicFilterChip(
                            label: 'All',
                            isSelected: _selectedBrandId == null,
                            onTap: () {
                              setModalState(() => _selectedBrandId = null);
                              setState(() => _selectedBrandId = null);
                            },
                          ),
                          ...watchProvider.brands.map((brand) {
                            return _NeumorphicFilterChip(
                              label: brand.name,
                              isSelected: _selectedBrandId == brand.id,
                              onTap: () {
                                setModalState(() => _selectedBrandId =
                                    _selectedBrandId == brand.id
                                        ? null
                                        : brand.id);
                                setState(() => _selectedBrandId =
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
                  const SizedBox(height: 48),
                  _NeumorphicButton(
                    onTap: () {
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
                ],
              ),
            );
          },
        );
      },
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

class _NeumorphicSortMenu extends StatelessWidget {
  final String currentSortBy;
  final String currentSortOrder;
  final Function(String) onSelected;

  const _NeumorphicSortMenu({
    required this.currentSortBy,
    required this.currentSortOrder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    String activeKey = '';
    if (currentSortBy == 'createdAt')
      activeKey = 'newest';
    else if (currentSortBy == 'popularity')
      activeKey = 'popularity';
    else
      activeKey = '$currentSortBy\_$currentSortOrder';

    return _NeumorphicContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItem('newest', 'Newest', activeKey == 'newest'),
          _buildItem(
              'price_asc', 'Price: Low to High', activeKey == 'price_asc'),
          _buildItem(
              'price_desc', 'Price: High to Low', activeKey == 'price_desc'),
          _buildItem('popularity', 'Most Popular', activeKey == 'popularity'),
        ],
      ),
    );
  }

  Widget _buildItem(String value, String label, bool isActive) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.black.withOpacity(0.02) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : const Color(0xFF4A5568),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NeumorphicWatchCard extends StatelessWidget {
  final Watch watch;
  final VoidCallback onTap;

  const _NeumorphicWatchCard({required this.watch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const kTextColor = Color(0xFF4A5568);
    return GestureDetector(
      onTap: onTap,
      child: _NeumorphicContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NeumorphicContainer(
                isConcave: true,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Center(
                      child: Hero(
                        tag: 'watch_${watch.id}',
                        child: CachedNetworkImage(
                          imageUrl:
                              watch.images.isNotEmpty ? watch.images.first : '',
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: const Color(0xFFE0E5EC),
                            highlightColor: const Color(0xFFF0F5FC),
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.watch),
                        ),
                      ),
                    ),
                    if (watch.isOnSale)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${watch.discountPercentage}% OFF',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    watch.brand?.name.toUpperCase() ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: kTextColor.withOpacity(0.5),
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    watch.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) {
                      return Text(
                        settings.formatPrice(watch.currentPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                baseColor: const Color(0xFFE0E5EC),
                highlightColor: const Color(0xFFF0F5FC),
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
