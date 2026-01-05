import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/watch_provider.dart';

import '../../widgets/watch_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';
import '../search/search_screen.dart';

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
      watchProvider.fetchPromotionHighlight();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WatchHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<WatchProvider>(context, listen: false)
              .fetchFeaturedWatches();
        },
        child: Consumer<WatchProvider>(
          builder: (context, watchProvider, child) {
            if (watchProvider.isLoading &&
                watchProvider.featuredWatches.isEmpty) {
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) =>
                            const ProductCardShimmer(),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Only show error screen if there's a real error AND no data at all
            // Otherwise, show content with empty states
            if (watchProvider.errorMessage != null &&
                watchProvider.featuredWatches.isEmpty &&
                watchProvider.banners.isEmpty &&
                !watchProvider.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text(watchProvider.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        watchProvider.clearError();
                        watchProvider.fetchFeaturedWatches();
                        watchProvider.fetchBanners();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Banner Slider
                  Consumer<WatchProvider>(
                    builder: (context, watchProvider, child) {
                      if (watchProvider.banners.isEmpty) {
                        // Fallback static banner
                        return Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.accentColor
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.watch,
                                  size: 64, color: Colors.white),
                              const SizedBox(height: 16),
                              const Text(
                                'Discover Premium Watches',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Luxury timepieces for every occasion',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return CarouselSlider(
                        options: CarouselOptions(
                          height: 200,
                          viewportFraction: 1.0,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 5),
                          enlargeCenterPage: false,
                        ),
                        items: watchProvider.banners.map((banner) {
                          return Builder(
                            builder: (BuildContext context) {
                              final imageUrl = banner.image;

                              return Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: MediaQuery.of(context).size.width,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const BannerShimmer(),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: AppTheme.primaryColor,
                                      child: const Icon(Icons.error,
                                          color: Colors.white),
                                    ),
                                  ),
                                  if (banner.title != null ||
                                      banner.subtitle != null)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.7),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (banner.title != null)
                                              Text(
                                                banner.title!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (banner.subtitle != null)
                                              Text(
                                                banner.subtitle!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // Sale Highlight
                  if (watchProvider.promotionHighlight != null)
                    _buildPromotionHighlight(watchProvider.promotionHighlight!),

                  // Featured Watches Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Watches',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),

                  if (watchProvider.featuredWatches.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No watches available'),
                      ),
                    )
                  else
                    LayoutBuilder(builder: (context, constraints) {
                      // Calculate aspect ratio based on screen width
                      // For smaller screens (like iPhone SE - ~320px width), use a taller aspect ratio
                      // For larger screens, use the standard 0.7
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
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromotionHighlight(dynamic promotion) {
    final bool isImage = promotion.type == 'image';

    return InkWell(
      onTap: promotion.link != null && promotion.link!.isNotEmpty
          ? () {
              // Navigate to link (e.g. product detail)
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailScreen(watchId: promotion.link!),
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: !isImage
              ? Color(int.parse(promotion.backgroundColor ?? '0xFFB71C1C'))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isImage
            ? CachedNetworkImage(
                imageUrl: promotion.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(height: 120, color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Text(
                      promotion.title ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(
                            int.parse(promotion.textColor ?? '0xFFFFFFFF')),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (promotion.subtitle != null &&
                        promotion.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        promotion.subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(int.parse(
                                  promotion.textColor ?? '0xFFFFFFFF'))
                              .withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
