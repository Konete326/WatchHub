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
import '../../widgets/neumorphic_widgets.dart' show showQuickView;

class BrowseScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialBrandId;
  final bool initialOnlySale;
  final bool showBackButton;
  final VoidCallback? onBack;

  const BrowseScreen({
    super.key,
    this.initialCategory,
    this.initialBrandId,
    this.initialOnlySale = false,
    this.showBackButton = true,
    this.onBack,
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

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedBrandId = widget.initialBrandId;
    _onlySale = widget.initialOnlySale;
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
      onlySale: _onlySale,
      minPrice: _minPrice,
      maxPrice: _maxPrice == 50000 ? null : _maxPrice,
      strapType: _selectedStrapType,
      inStockOnly: _inStockOnly,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = AppTheme.softUiBackground;
    const kTextColor = AppTheme.softUiTextColor;

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
                    onTap: widget.onBack ?? () => Navigator.pop(context),
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
                  onTap: () => _showFilters(),
                  padding: const EdgeInsets.all(10),
                  shape: BoxShape.circle,
                  child: const Icon(Icons.tune, color: kTextColor),
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
                        _onlySale = false;
                        _minPrice = 0;
                        _maxPrice = 50000;
                        _selectedStrapType = null;
                        _inStockOnly = false;
                        _sortBy = 'createdAt';
                        _sortOrder = 'desc';
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
                    if (!watch.isInStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A5568).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _NeumorphicButton(
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(6),
                        onTap: () {
                          if (watch.images.isNotEmpty) {
                            showQuickView(
                              context,
                              watch.images.first,
                              'watch_${watch.id}',
                            );
                          }
                        },
                        child: Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: kTextColor.withOpacity(0.7),
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
