import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/watch_provider.dart';
import '../../widgets/watch_card.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';
import '../search/search_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../providers/notification_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../wishlist/wishlist_screen.dart';
import '../browse/browse_screen.dart';
import '../../widgets/neumorphic_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final watchProvider = Provider.of<WatchProvider>(context, listen: false);
      watchProvider.fetchFeaturedWatches();
      watchProvider.fetchBanners();
      watchProvider.fetchBrands();
      watchProvider.fetchCategories();
      watchProvider.fetchPromotionHighlight();
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.softUiBackground,
          onRefresh: () async {
            final watchProvider =
                Provider.of<WatchProvider>(context, listen: false);
            await Future.wait([
              watchProvider.fetchFeaturedWatches(),
              watchProvider.fetchBanners(),
              watchProvider.fetchBrands(),
              watchProvider.fetchPromotionHighlight(),
            ]);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Neumorphic Top Bar & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      _buildSearchBar(context),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Consumer<WatchProvider>(
                  builder: (context, watchProvider, child) {
                    if (watchProvider.isLoading &&
                        watchProvider.featuredWatches.isEmpty &&
                        watchProvider.banners.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banners
                        if (watchProvider.banners.isNotEmpty)
                          _buildHeroSection(watchProvider.banners),

                        // Brands
                        if (watchProvider.brands.isNotEmpty)
                          _buildTopBrandsSection(watchProvider.brands),

                        // Promotion
                        if (watchProvider.promotionHighlight != null)
                          _buildPromotionSection(
                              watchProvider.promotionHighlight!),

                        // Featured Title
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Text(
                            'Featured Collection',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.softUiTextColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Grid
              Consumer<WatchProvider>(
                builder: (context, watchProvider, child) {
                  if (watchProvider.featuredWatches.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final watch = watchProvider.featuredWatches[index];
                          return WatchCard(
                            watch: watch,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(watchId: watch.id),
                              ),
                            ),
                          );
                        },
                        childCount: watchProvider.featuredWatches.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'WatchHub',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.softUiTextColor,
            letterSpacing: 0.5,
          ),
        ),
        Row(
          children: [
            _buildActionIcon(
              context,
              icon: Icons.favorite_border_rounded,
              hasBadge: Provider.of<WishlistProvider>(context).itemCount > 0,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
              ),
            ),
            const SizedBox(width: 16),
            _buildActionIcon(
              context,
              icon: Icons.notifications_none_rounded,
              hasBadge:
                  Provider.of<NotificationProvider>(context).unreadCount > 0,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(BuildContext context,
      {required IconData icon,
      required bool hasBadge,
      required VoidCallback onTap}) {
    return NeumorphicButton(
      onTap: onTap,
      shape: BoxShape.circle,
      padding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Icon(icon, color: AppTheme.softUiTextColor, size: 22),
          if (hasBadge)
            Container(
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

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      ),
      child: NeumorphicContainer(
        isConcave: true,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: AppTheme.softUiTextColor.withOpacity(0.5)),
            const SizedBox(width: 12),
            Text(
              'Find your perfect timepiece...',
              style: TextStyle(
                color: AppTheme.softUiTextColor.withOpacity(0.4),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(List<dynamic> banners) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 220,
          viewportFraction: 0.9,
          enlargeCenterPage: true,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          enableInfiniteScroll: true,
        ),
        items: banners.map((banner) {
          return NeumorphicButton(
            onTap: () {
              if (banner.link != null && banner.link!.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailScreen(watchId: banner.link!),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(25),
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: banner.image,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.softUiTextColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (banner.title != null)
                          Text(
                            banner.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (banner.subtitle != null)
                          Text(
                            banner.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopBrandsSection(List<dynamic> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Top Brands',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.softUiTextColor,
            ),
          ),
        ),
        SizedBox(
          height: 120, // Adjusted height to accommodate labels
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeumorphicButton(
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(8),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                BrowseScreen(initialBrandId: brand.id),
                          ),
                        );
                      },
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child:
                              brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: brand.logoUrl!,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.watch,
                                              color: Colors.grey, size: 25),
                                    )
                                  : const Icon(Icons.watch,
                                      color: Colors.grey, size: 25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 75,
                      child: Text(
                        brand.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.softUiTextColor,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionSection(dynamic promotion) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: NeumorphicButton(
        borderRadius: BorderRadius.circular(25),
        padding: EdgeInsets.zero,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BrowseScreen(initialOnlySale: true),
            ),
          );
        },
        child: Container(
          height: 180,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                if (promotion.imageUrl != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: promotion.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.softUiBackground.withOpacity(0.9),
                        AppTheme.softUiBackground.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (promotion.title != null)
                        Text(
                          promotion.title!,
                          style: const TextStyle(
                            color: AppTheme.softUiTextColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (promotion.subtitle != null)
                        Text(
                          promotion.subtitle!,
                          style: TextStyle(
                            color: AppTheme.softUiTextColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
