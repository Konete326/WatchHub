import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../utils/theme.dart';
import 'home/home_screen.dart';
import 'browse/browse_screen.dart';
import 'cart/cart_screen.dart';
import 'profile/profile_screen.dart';
import '../providers/notification_provider.dart';
import '../widgets/animated_cart_icon.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Neumorphic Blue Theme Constants
  static const Color navBlueMain = Color(0xFF2E5BFF);
  static const Color navBlueLight = Color(0xFF4D76FF);
  static const Color navBlueDark = Color(0xFF1A3EBF);

  final List<Widget> _screens = [
    const HomeScreen(),
    const BrowseScreen(showBackButton: false),
    const CartScreen(showBackButton: false),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
      Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.softUiBackground,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Container(
            height: 85,
            decoration: BoxDecoration(
              color: navBlueMain,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: navBlueDark.withOpacity(0.5),
                  offset: const Offset(4, 4),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: navBlueLight.withOpacity(0.35),
                  offset: const Offset(-4, -4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.grid_view_rounded, 'Browse'),
                _buildCartItem(2),
                _buildNavItem(3, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: _NeumorphicNavButton(
        isSelected: isSelected,
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white60,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: _NeumorphicNavButton(
        isSelected: isSelected,
        child: IconTheme(
          data: IconThemeData(
            color: isSelected ? Colors.white : Colors.white60,
            size: 26,
          ),
          child: const AnimatedCartIcon(),
        ),
      ),
    );
  }
}

class _NeumorphicNavButton extends StatelessWidget {
  final bool isSelected;
  final Widget child;

  const _NeumorphicNavButton({
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const Color navBlueMain = Color(0xFF2E5BFF);
    const Color navBlueLight = Color(0xFF4D76FF);
    const Color navBlueDark = Color(0xFF1A3EBF);

    final bool isSelected = this.isSelected;

    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: isSelected ? navBlueLight : navBlueMain,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.35),
                    offset: const Offset(-3, -3),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(3, 3),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: navBlueDark.withOpacity(0.4),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: navBlueLight.withOpacity(0.2),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
