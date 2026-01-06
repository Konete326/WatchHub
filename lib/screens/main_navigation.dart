import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'home/home_screen.dart';
import 'browse/browse_screen.dart';
import 'cart/cart_screen.dart';
import 'wishlist/wishlist_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/animated_cart_icon.dart';

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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: const AnimatedCartIcon(),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Consumer<WishlistProvider>(
              builder: (context, wishlistProvider, child) {
                return Badge(
                  label: Text(wishlistProvider.itemCount.toString()),
                  isLabelVisible: wishlistProvider.itemCount > 0,
                  child: const Icon(Icons.favorite),
                );
              },
            ),
            label: 'Wishlist',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
