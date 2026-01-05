import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/watch_provider.dart';
import '../../widgets/watch_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../utils/theme.dart';
import '../../utils/animation_utils.dart';
import '../product/product_detail_screen.dart';
import '../search/search_screen.dart';
import '../browse/browse_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentBannerIndex = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    Future.microtask(() {
      final watchProvider = Provider.of<WatchProvider>(context, listen: false);
      watchProvider.fetchFeaturedWatches();
      watchProvider.fetchBanners();
      watchProvider.fetchBrands();
      watchProvider.fetchCategories();
      watchProvider.fetchPromotionHighlight();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Animated App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: const Text(
                'WatchHub',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double appBarHeight = 140;
                  final double toolbarHeight = kToolbarHeight;
                  final double expandedHeight = appBarHeight - toolbarHeight;
                  final double currentHeight = constraints.maxHeight - toolbarHeight;
                  final double expandRatio = (currentHeight / expandedHeight).clamp(0.0, 1.0);
                  
                  // Smooth curve for animations
                  final double curvedRatio = Curves.easeOut.transform(expandRatio);
                  final double opacity = curvedRatio;
                  final double scale = 0.3 + (curvedRatio * 0.7);
                  
                  return Container(
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
                    child: Stack(
                      children: [
                        // Watch icon that appears when fully expanded
                        if (opacity > 0.1)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.scale(
                                  scale: scale,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.25),
                                          Colors.white.withOpacity(0.15),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.watch,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Decorative sparkle elements
                        if (opacity > 0.7)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 20,
                            left: MediaQuery.of(context).size.width * 0.25,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: ((opacity - 0.7) / 0.3).clamp(0.0, 1.0),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.8),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (opacity > 0.7)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 20,
                            right: MediaQuery.of(context).size.width * 0.25,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: ((opacity - 0.7) / 0.3).clamp(0.0, 1.0),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.8),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  AnimationUtils.pushFadeThrough(context, const SearchScreen());
                },
              ).animate().fadeIn(duration: 300.ms).scale(),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Consumer<WatchProvider>(
              builder: (context, watchProvider, child) {
                if (watchProvider.isLoading &&
                    watchProvider.featuredWatches.isEmpty) {
                  return _buildLoadingState();
                }

                if (watchProvider.errorMessage != null &&
                    watchProvider.featuredWatches.isEmpty &&
                    watchProvider.banners.isEmpty &&
                    !watchProvider.isLoading) {
                  return _buildErrorState(watchProvider);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await watchProvider.fetchFeaturedWatches();
                    await watchProvider.fetchBanners();
                    await watchProvider.fetchBrands();
                    await watchProvider.fetchCategories();
                    await watchProvider.fetchPromotionHighlight();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated Banner Carousel
                      _buildAnimatedBannerCarousel(watchProvider)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.1, end: 0),

                      // Promotion Highlight
                      if (watchProvider.promotionHighlight != null)
                        _buildAnimatedPromotionHighlight(
                                watchProvider.promotionHighlight!)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideX(begin: -0.1, end: 0),

                      // Brand Showcase
                      if (watchProvider.brands.isNotEmpty)
                        _buildBrandShowcase(watchProvider.brands)
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideX(begin: -0.1, end: 0),

                      // Categories Section
                      if (watchProvider.categories.isNotEmpty)
                        _buildCategoriesSection(watchProvider.categories)
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms)
                            .slideX(begin: -0.1, end: 0),

                      // Featured Watches Section
                      _buildFeaturedWatchesSection(watchProvider)
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 400.ms),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const BannerShimmer(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ProductCardShimmer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WatchProvider watchProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                    size: 64, color: AppTheme.errorColor)
                .animate()
                .shake(duration: 600.ms),
            const SizedBox(height: 16),
            Text(
              watchProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                watchProvider.clearError();
                watchProvider.fetchFeaturedWatches();
                watchProvider.fetchBanners();
                watchProvider.fetchBrands();
                watchProvider.fetchCategories();
                watchProvider.fetchPromotionHighlight();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBannerCarousel(WatchProvider watchProvider) {
    if (watchProvider.banners.isEmpty) {
      return _buildDefaultBanner();
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: watchProvider.banners.length,
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final banner = watchProvider.banners[index];
            return _buildBannerItem(banner, index);
          },
        ),
        const SizedBox(height: 12),
        // Animated Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            watchProvider.banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentBannerIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBannerItem(dynamic banner, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: banner.image,
              fit: BoxFit.cover,
              placeholder: (context, url) => const BannerShimmer(),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.primaryColor,
                child: const Icon(Icons.error, color: Colors.white),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Content
            if (banner.title != null || banner.subtitle != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (banner.title != null)
                      Text(
                        banner.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.2, end: 0),
                    if (banner.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        banner.subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.accentColor,
            AppTheme.secondaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePainter(),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.watch, size: 80, color: Colors.white)
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms, color: Colors.white70)
                    .then()
                    .scale(delay: 500.ms, duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                    .then()
                    .scale(delay: 500.ms, duration: 1000.ms, begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
                const SizedBox(height: 20),
                const Text(
                  'Discover Premium Watches',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Luxury timepieces for every occasion',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPromotionHighlight(dynamic promotion) {
    final bool isImage = promotion.type == 'image';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: promotion.link != null && promotion.link!.isNotEmpty
              ? () {
                  AnimationUtils.pushContainerTransform(
                    context,
                    ProductDetailScreen(watchId: promotion.link!),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: !isImage
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(int.parse(promotion.backgroundColor ?? '0xFFB71C1C')),
                        Color(int.parse(promotion.backgroundColor ?? '0xFFB71C1C'))
                            .withOpacity(0.8),
                      ],
                    )
                  : null,
              color: isImage ? Colors.transparent : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (isImage)
                  CachedNetworkImage(
                    imageUrl: promotion.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 140,
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                if (!isImage || promotion.title != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (promotion.title != null)
                          Text(
                            promotion.title!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                  int.parse(promotion.textColor ?? '0xFFFFFFFF')),
                              shadows: isImage
                                  ? [
                                      const Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                        if (promotion.subtitle != null &&
                            promotion.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            promotion.subtitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(int.parse(
                                          promotion.textColor ?? '0xFFFFFFFF'))
                                      .withOpacity(0.9),
                              shadows: isImage
                                  ? [
                                      const Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.1, end: 0),
                        ],
                      ],
                    ),
                  ),
                // Pulse effect
                if (promotion.link != null && promotion.link!.isNotEmpty)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                  0.3 * _pulseController.value),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandShowcase(List brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Brands',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .fadeIn()
                  .slideX(begin: -0.1, end: 0),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrowseScreen(),
                    ),
                  );
                },
                child: const Text('See All'),
              )
                  .animate()
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildBrandCard(brands[index], index),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBrandCard(dynamic brand, int index) {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BrowseScreen(brandId: brand.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: brand.logoUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.branding_watermark,
                                  color: AppTheme.primaryColor, size: 28),
                            ),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.branding_watermark,
                              color: AppTheme.primaryColor, size: 28),
                        ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    brand.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(delay: (index * 50).ms, duration: 300.ms)
        .then()
        .shimmer(duration: 1000.ms, delay: 500.ms);
  }

  Widget _buildCategoriesSection(List categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .fadeIn()
                  .slideX(begin: -0.1, end: 0),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrowseScreen(),
                    ),
                  );
                },
                child: const Text('See All'),
              )
                  .animate()
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildCategoryCard(categories[index], index),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoryCard(dynamic category, int index) {
    final colors = [
      [AppTheme.primaryColor, AppTheme.accentColor],
      [AppTheme.secondaryColor, AppTheme.primaryColor],
      [AppTheme.accentColor, AppTheme.secondaryColor],
      [Colors.purple, Colors.blue],
      [Colors.orange, Colors.red],
    ];
    final colorPair = colors[index % colors.length];

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
        boxShadow: [
          BoxShadow(
            color: colorPair[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BrowseScreen(category: category.name),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: category.imageUrl!,
                      fit: BoxFit.cover,
                      color: Colors.white.withOpacity(0.2),
                      colorBlendMode: BlendMode.overlay,
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .scale(delay: (index * 50).ms, duration: 300.ms)
        .then()
        .shimmer(duration: 1000.ms, delay: 500.ms);
  }

  Widget _buildFeaturedWatchesSection(WatchProvider watchProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Watches',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .fadeIn()
                  .slideX(begin: -0.1, end: 0),
              if (watchProvider.featuredWatches.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BrowseScreen(),
                      ),
                    );
                  },
                  child: const Text('See All'),
                )
                    .animate()
                    .fadeIn()
                    .slideX(begin: 0.1, end: 0),
            ],
          ),
        ),
        if (watchProvider.featuredWatches.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.watch_off,
                          size: 64, color: Colors.grey.shade400)
                      .animate()
                      .fadeIn()
                      .scale(),
                  const SizedBox(height: 16),
                  Text(
                    'No watches available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth =
                  MediaQuery.of(context).size.width;
              final double childAspectRatio =
                  screenWidth < 360 ? 0.6 : 0.7;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: watchProvider.featuredWatches.length,
                itemBuilder: (context, index) {
                  final watch = watchProvider.featuredWatches[index];
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
              );
            },
          ),
      ],
    );
  }
}

// Custom painter for wave pattern
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (double i = 0; i < size.width; i += 20) {
      path.moveTo(i, size.height * 0.3);
      path.quadraticBezierTo(
        i + 10,
        size.height * 0.3 + 10,
        i + 20,
        size.height * 0.3,
      );
    }
    canvas.drawPath(path, paint);

    final path2 = Path();
    for (double i = 0; i < size.width; i += 20) {
      path2.moveTo(i, size.height * 0.7);
      path2.quadraticBezierTo(
        i + 10,
        size.height * 0.7 - 10,
        i + 20,
        size.height * 0.7,
      );
    }
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
