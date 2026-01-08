import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/watch_provider.dart';

import '../../widgets/watch_card.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';
import '../search/search_screen.dart';
import '../notifications/notifications_screen.dart';
import '../browse/browse_screen.dart';
import '../../providers/notification_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../wishlist/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    Future.microtask(() {
      final watchProvider = Provider.of<WatchProvider>(context, listen: false);
      watchProvider.fetchFeaturedWatches();
      watchProvider.fetchBanners();
      watchProvider.fetchBrands();
      // fetchCategories is less critical for the main view now but good to have
      watchProvider.fetchCategories();
      watchProvider.fetchPromotionHighlight();
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Spacing for the fixed header
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),

              SliverToBoxAdapter(
                child: Consumer<WatchProvider>(
                  builder: (context, watchProvider, child) {
                    // Loading State with no data
                    if (watchProvider.isLoading &&
                        watchProvider.featuredWatches.isEmpty &&
                        watchProvider.banners.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // Error State
                    if (watchProvider.errorMessage != null &&
                        watchProvider.featuredWatches.isEmpty) {
                      return Center(
                        child: Text(watchProvider.errorMessage!),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Hero Section (Banners)
                        if (watchProvider.banners.isNotEmpty)
                          _buildHeroSection(watchProvider.banners),

                        // Top Brands Section
                        if (watchProvider.brands.isNotEmpty)
                          _buildTopBrandsSection(watchProvider.brands),

                        // Limited Edition / Promotion Section
                        if (watchProvider.promotionHighlight != null)
                          _buildLimitedEditionSection(
                              watchProvider.promotionHighlight!),

                        // Featured Watches Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Featured Collection',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: const Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Featured Product Grid
              Consumer<WatchProvider>(
                builder: (context, watchProvider, child) {
                  if (watchProvider.featuredWatches.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.60, // Taller cards for classy feel
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final watch = watchProvider.featuredWatches[index];
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
                        childCount: watchProvider.featuredWatches.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // Glassmorphism Header & Search Bar
          _buildGlassHeader(context),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo / Title
                    const Text(
                      'WatchHub',
                      style: TextStyle(
                        fontFamily:
                            'Didot', // Serif font for luxury if available, or fallbacks
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 1.0,
                      ),
                    ),
                    // Actions
                    Row(
                      children: [
                        _buildHeaderIcon(
                          icon: Icons.favorite_border,
                          hasBadge:
                              Provider.of<WishlistProvider>(context).itemCount >
                                  0,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WishlistScreen())),
                        ),
                        const SizedBox(width: 12),
                        _buildHeaderIcon(
                          icon: Icons.notifications_none,
                          hasBadge: Provider.of<NotificationProvider>(context)
                                  .unreadCount >
                              0,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Glassmorphism Search Bar
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA6ABBD).withOpacity(0.1),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Find your perfect timepiece...',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required bool hasBadge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.5),
            ),
            child: Icon(icon, color: const Color(0xFF1A1A1A), size: 24),
          ),
          if (hasBadge)
            Container(
              margin: const EdgeInsets.only(top: 8, right: 8),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(List<dynamic> banners) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32), // Increased spacing
      child: CarouselSlider(
        options: CarouselOptions(
          height: 340, // Increased height for better visual impact
          viewportFraction: 0.95, // Wider cards
          enlargeCenterPage: true,
          enlargeStrategy: CenterPageEnlargeStrategy.zoom, // Smooth zoom effect
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 6),
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
        ),
        items: banners.map((banner) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(28), // Modern rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.2), // Softer, deeper shadow
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                      spreadRadius: 1,
                    ),
                  ],
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(banner.image),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.95), // Thicker dark base
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banner.title != null)
                        Text(
                          banner.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28, // Larger font
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (banner.subtitle != null)
                        Text(
                          banner.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      const SizedBox(height: 12), // Space from bottom
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopBrandsSection(List<dynamic> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            'Top Brands',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF1A1A1A),
                ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () {
                    // Navigate to brand specific page or generic browse
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BrowseScreen(
                          initialBrandId: brand.id,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: brand.logoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: brand.logoUrl!,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[100],
                                ),
                              )
                            : Icon(Icons.watch,
                                color: Colors.grey[400], size: 30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        brand.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
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

  Widget _buildLimitedEditionSection(dynamic promotion) {
    // If it's an image type promotion, we treat it as a banner ad
    final bool isImage = promotion.type == 'image';
    if (!isImage && promotion.title == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GestureDetector(
        onTap: () {
          if (promotion.link != null && promotion.link!.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailScreen(watchId: promotion.link!),
              ),
            );
          }
        },
        child: Container(
          height: 220, // Standard banner height
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isImage
                ? Colors.transparent
                : Color(int.parse(promotion.backgroundColor ?? '0xFF1A1A1A')),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            image: isImage && promotion.imageUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(promotion.imageUrl!),
                    fit: BoxFit.cover, // Ensures the ad fills the space
                  )
                : null,
          ),
          child: Stack(
            children: [
              // Only show gradient and text if it's NOT just a pure image ad
              // OR if we have explicit text content to overlay
              if (!isImage ||
                  (promotion.title != null && promotion.title!.isNotEmpty)) ...[
                // Subtle Gradient for text readability
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Text Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (promotion.title != null)
                        Text(
                          promotion.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      if (promotion.subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          promotion.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Shop Now',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
