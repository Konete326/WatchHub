import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:animations/animations.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'home/home_screen.dart';
import 'browse/browse_screen.dart';
import 'cart/cart_screen.dart';
import 'wishlist/wishlist_screen.dart';
import 'profile/profile_screen.dart';
import '../utils/theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BrowseScreen(),
    const CartScreen(),
    const WishlistScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load cart and wishlist on app start
    Future.microtask(() {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
      Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _screens[_currentIndex],
        key: ValueKey<int>(_currentIndex),
      ),
      bottomNavigationBar: Consumer2<CartProvider, WishlistProvider>(
        builder: (context, cartProvider, wishlistProvider, child) {
          // Create badge map for items with counts
          Map<int, dynamic> badges = {};
          if (cartProvider.itemCount > 0) {
            badges[2] = '${cartProvider.itemCount}';
          }
          if (wishlistProvider.itemCount > 0) {
            badges[3] = '${wishlistProvider.itemCount}';
          }

          return ConvexAppBar.badge(
            badges,
            style: TabStyle.reactCircle,
            items: const [
              TabItem(icon: Icons.home, title: 'Home'),
              TabItem(icon: Icons.search, title: 'Browse'),
              TabItem(icon: Icons.shopping_cart, title: 'Cart'),
              TabItem(icon: Icons.favorite, title: 'Wishlist'),
              TabItem(icon: Icons.person, title: 'Profile'),
            ],
            initialActiveIndex: _currentIndex,
            activeColor: AppTheme.primaryColor,
            color: AppTheme.textSecondaryColor,
            backgroundColor: Colors.white,
            onTap: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
          );
        },
      ),
    );
  }
}
