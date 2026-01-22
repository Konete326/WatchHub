import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/watch_provider.dart';
import '../../models/watch.dart';
import '../../models/home_banner.dart';
import '../../widgets/watch_card.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';
import '../search/search_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../providers/notification_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../wishlist/wishlist_screen.dart';
import '../browse/browse_screen.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../providers/auth_provider.dart';
import '../../utils/haptics.dart';

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final userSegment = authProvider.user?.rfmSummary;
      final width = MediaQuery.of(context).size.width;
      final deviceType =
          width > 900 ? 'desktop' : (width > 600 ? 'tablet' : 'mobile');

      watchProvider.fetchFeaturedWatches();
      watchProvider.fetchBanners(
          userSegment: userSegment, deviceType: deviceType);
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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.backgroundColor,
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
                      return Column(
                        children: const [
                          BannerShimmer(),
                          SizedBox(height: 16),
                          ListShimmer(itemCount: 2),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Premium Parallax Hero
                        if (watchProvider.banners.isNotEmpty)
                          _buildParallaxHero(watchProvider.banners),

                        // Trust Badges
                        _buildTrustBadges(),

                        // Quick Filter Chips
                        _buildQuickFilters(),

                        // Featured Title
                        _buildSectionHeader(
                          context,
                          'Featured Collection',
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BrowseScreen(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Featured Grid
              Consumer<WatchProvider>(
                builder: (context, watchProvider, child) {
                  final width = MediaQuery.of(context).size.width;
                  final crossAxisCount =
                      width > 900 ? 4 : (width > 600 ? 3 : 2);

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.54,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final watch = watchProvider.featuredWatches[index];
                          return WatchCard(
                            watch: watch,
                            heroTag: 'featured_${watch.id}',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(watchId: watch.id),
                              ),
                            ),
                          );
                        },
                        childCount: watchProvider.featuredWatches.length
                            .clamp(0, crossAxisCount * 2),
                      ),
                    ),
                  );
                },
              ),

              // Curated Sections
              SliverToBoxAdapter(
                child: Consumer<WatchProvider>(
                  builder: (context, watchProvider, child) {
                    return Column(
                      children: [
                        // New Arrivals
                        if (watchProvider.newArrivals.isNotEmpty)
                          _buildCuratedSection(
                            context,
                            'New Arrivals',
                            watchProvider.newArrivals,
                          ),

                        // Editor's Picks
                        if (watchProvider.editorsPicks.isNotEmpty)
                          _buildCuratedSection(
                            context,
                            "Editor's Picks",
                            watchProvider.editorsPicks,
                          ),

                        // Promotion Highlight
                        if (watchProvider.promotionHighlight != null)
                          _buildPromotionSection(
                              watchProvider.promotionHighlight!),

                        // Brands
                        if (watchProvider.brands.isNotEmpty)
                          _buildTopBrandsSection(watchProvider.brands),

                        // Limited Editions
                        if (watchProvider.limitedEditions.isNotEmpty)
                          _buildCuratedSection(
                            context,
                            'Limited Editions',
                            watchProvider.limitedEditions,
                          ),

                        // Under PKR 50K
                        if (watchProvider.budgetWatches.isNotEmpty)
                          _buildCuratedSection(
                            context,
                            'Under PKR 50,000',
                            watchProvider.budgetWatches,
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BrowseScreen(initialMaxPrice: 50000),
                              ),
                            ),
                          ),

                        const SizedBox(height: 100),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'WatchHub',
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              _buildActionIcon(
                context,
                icon: Icons.favorite_border_rounded,
                tooltip: 'Wishlist',
                hasBadge: Provider.of<WishlistProvider>(context).itemCount > 0,
                onTap: () {
                  HapticHelper.selection();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildActionIcon(
                context,
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                hasBadge:
                    Provider.of<NotificationProvider>(context).unreadCount > 0,
                onTap: () {
                  HapticHelper.selection();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildActionIcon(BuildContext context,
      {required IconData icon,
      required bool hasBadge,
      required String tooltip,
      required VoidCallback onTap}) {
    return Semantics(
      label: tooltip,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
          ),
          child: Stack(
            alignment: Alignment.topRight,
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: AppTheme.textPrimaryColor, size: 20),
              if (hasBadge)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.roseGoldColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const BrowseScreen(
            autoFocusSearch: true,
            showBackButton: true,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: AppTheme.goldColor, size: 20),
            const SizedBox(width: 12),
            Text(
              'Search for your next luxury piece...',
              style: GoogleFonts.inter(
                color: AppTheme.textTertiaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParallaxHero(List<HomeBanner> banners) {
    final watchProvider = Provider.of<WatchProvider>(context, listen: false);

    // Track initial impression for the first banner
    if (banners.isNotEmpty) {
      watchProvider.trackBannerImpression(banners[0].id);
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: banners.length,
        controller: PageController(viewportFraction: 0.92),
        onPageChanged: (index) {
          watchProvider.trackBannerImpression(banners[index].id);
        },
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            child: PremiumCard(
              borderRadius: 24,
              onTap: () {
                // Track Click
                watchProvider.trackBannerClick(banner.id);

                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: banner.image,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: banner.image,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (banner.title != null)
                          Text(
                            banner.title!,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 4),
                        if (banner.subtitle != null)
                          Text(
                            banner.subtitle!,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrustBadges() {
    final badges = [
      {'icon': Icons.verified_user_outlined, 'label': 'Authentic'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Free Delivery'},
      {'icon': Icons.history_outlined, 'label': '2Y Warranty'},
      {'icon': Icons.lock_outline, 'label': 'Secure Pay'},
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          return Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(badge['icon'] as IconData,
                    color: AppTheme.goldColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  badge['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = [
      {'label': 'Rolex', 'type': 'brand'},
      {'label': 'Automatic', 'type': 'movement'},
      {'label': 'Leather', 'type': 'material'},
      {'label': 'Steel', 'type': 'material'},
      {'label': 'Luxury', 'type': 'category'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              onPressed: () {
                HapticHelper.light();
                String? category;
                String? strapType;
                String? search;

                if (filter['type'] == 'category') {
                  category = filter['label'];
                } else if (filter['type'] == 'material') {
                  strapType = filter['label']!.toLowerCase().contains('leather')
                      ? 'belt'
                      : 'chain';
                } else {
                  search = filter['label'];
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BrowseScreen(
                      initialCategory: category,
                      initialStrapType: strapType,
                      initialSearch: search,
                      showBackButton: true,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
              ),
              label: Text(
                filter['label']!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.goldColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCuratedSection(
      BuildContext context, String title, List<Watch> watches,
      {VoidCallback? onViewAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title, onViewAll: onViewAll),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: watches.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 180,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: WatchCard(
                    watch: watches[index],
                    heroTag:
                        '${title.replaceAll(' ', '_').toLowerCase()}_${watches[index].id}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(watchId: watches[index].id),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBrandsSection(List<dynamic> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Browse by Brand',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticHelper.light();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            BrowseScreen(initialBrandId: brand.id),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.borderColor.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: CachedNetworkImage(
                                        imageUrl: brand.logoUrl!,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: Colors.grey[200]!,
                                          highlightColor: Colors.grey[50]!,
                                          child: Container(color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.watch,
                                                color: Colors.grey, size: 20),
                                      ),
                                    )
                                  : const Icon(Icons.watch,
                                      color: Colors.grey, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        brand.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
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

  Widget _buildPromotionSection(dynamic promotion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: PremiumCard(
        borderRadius: 20,
        onTap: () {
          // Open promotion image on tap as well? Or keep navigation?
          // User said "same sale waley banner se bhi remove kro ye jo bhi colour shadow lagey hai"
          // User didn't explicitly ask for image view on sale, but implied consistency.
          // Keeping navigation for now as it's the primary purpose, but removing effects.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BrowseScreen(initialOnlySale: true),
            ),
          );
        },
        child: SizedBox(
          height: 180, // Increased height to prevent overflow
          width: double.infinity,
          child: Stack(
            children: [
              if (promotion.imageUrl != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: promotion.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              // Removed Gradient Overlay
              Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (promotion.title != null)
                        Text(
                          promotion.title!,
                          style: GoogleFonts.montserrat(
                            color: AppTheme.primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (promotion.subtitle != null)
                        Text(
                          promotion.subtitle!,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
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
    );
  }
}
