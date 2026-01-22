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
    final List<Widget> screens = [
      const HomeScreen(),
      BrowseScreen(
        showBackButton: _currentIndex != 0,
        onBack: () => setState(() => _currentIndex = 0),
      ),
      CartScreen(
        showBackButton: _currentIndex != 0,
        onBack: () => setState(() => _currentIndex = 0),
      ),
      ProfileScreen(
        showBackButton: _currentIndex != 0,
        onBack: () => setState(() => _currentIndex = 0),
      ),
    ];

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
        extendBody: false,
        backgroundColor: AppTheme.backgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                offset: const Offset(0, -5),
                blurRadius: 20,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 75,
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
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: _PremiumNavButton(
        isSelected: isSelected,
        child: Icon(
          icon,
          color:
              isSelected ? AppTheme.goldColor : Colors.white.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: _PremiumNavButton(
        isSelected: isSelected,
        child: IconTheme(
          data: IconThemeData(
            color:
                isSelected ? AppTheme.goldColor : Colors.white.withOpacity(0.6),
            size: 24,
          ),
          child: const AnimatedCartIcon(),
        ),
      ),
    );
  }
}

class _PremiumNavButton extends StatelessWidget {
  final bool isSelected;
  final Widget child;

  const _PremiumNavButton({
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isSelected)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.goldColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          child,
          if (isSelected)
            Positioned(
              bottom: -4,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.goldColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
