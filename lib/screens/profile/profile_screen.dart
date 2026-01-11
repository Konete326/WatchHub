import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';

import '../orders/order_history_screen.dart';
import '../profile/addresses_screen.dart';
import '../support/support_screen.dart';
import 'edit_profile_screen.dart';
import '../notifications/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Neumorphic Design Constants
  static const Color kBackgroundColor = AppTheme.softUiBackground;
  static const Color kTextColor = AppTheme.softUiTextColor;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).fetchProfile();
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 500,
    );

    if (image != null && mounted) {
      final success = await Provider.of<UserProvider>(context, listen: false)
          .updateProfileImage(image);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        final error =
            Provider.of<UserProvider>(context, listen: false).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to update profile image'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    onTap: widget.onBack ??
                        () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                    padding: const EdgeInsets.all(10),
                    shape: BoxShape.circle,
                    child: const Icon(Icons.arrow_back, color: kTextColor),
                  )
                else
                  const SizedBox(width: 44),
                Expanded(
                  child: Center(
                    child: Text(
                      'Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                    ),
                  ),
                ),
                // Left balanced spacer
                const SizedBox(width: 44),
              ],
            ),
          ),
        ),
      ),
      body: Consumer2<UserProvider, AuthProvider>(
        builder: (context, userProvider, authProvider, child) {
          final user = userProvider.user ?? authProvider.user;

          if (user == null && userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Could not load profile',
                      style: TextStyle(color: kTextColor)),
                  const SizedBox(height: 16),
                  _NeumorphicButton(
                    onTap: () => userProvider.fetchProfile(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    child: const Text('Retry',
                        style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _NeumorphicContainer(
                          padding: const EdgeInsets.all(4),
                          shape: BoxShape.circle,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: kBackgroundColor,
                            backgroundImage: user.profileImage != null
                                ? CachedNetworkImageProvider(user.profileImage!)
                                : null,
                            child: user.profileImage == null
                                ? Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: kTextColor,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (userProvider.isLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _NeumorphicButton(
                            onTap: _pickAndUploadImage,
                            padding: const EdgeInsets.all(8),
                            shape: BoxShape.circle,
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextColor.withOpacity(0.7),
                      ),
                      maxLines: 1,
                    ),
                    if (authProvider.isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          borderRadius: BorderRadius.circular(20),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Menu Items
              _NeumorphicMenuItem(
                icon: Icons.edit,
                title: 'Edit Profile',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.location_on_outlined,
                title: 'Addresses',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddressesScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Orders',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.headset_mic_outlined,
                title: 'Support',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SupportScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                textColor: const Color(0xFFEF5350), // Soft Red
                iconColor: const Color(0xFFEF5350),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout')),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await Provider.of<AuthProvider>(context, listen: false)
                        .logout();
                    if (mounted)
                      Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final bool pressed;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.softUiBackground,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: pressed
            // Concave/Pressed effect (Inner shadow simulation or effectively flat/inset look)
            ? [] // No outer shadow creates a "flat" or "pressed" interaction relative to elevated
            : [
                const BoxShadow(
                  color: AppTheme.softUiShadowDark,
                  offset: Offset(6, 6),
                  blurRadius: 16,
                ),
                const BoxShadow(
                  color: AppTheme.softUiShadowLight,
                  offset: Offset(-6, -6),
                  blurRadius: 16,
                ),
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
              ? [] // Pressed state (flat)
              : [
                  const BoxShadow(
                    color: AppTheme.softUiShadowDark,
                    offset: Offset(6, 6),
                    blurRadius: 16,
                  ),
                  const BoxShadow(
                    color: AppTheme.softUiShadowLight,
                    offset: Offset(-6, -6),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _NeumorphicMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _NeumorphicMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return _NeumorphicButton(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Icon(icon,
              color:
                  iconColor ?? _ProfileScreenState.kTextColor.withOpacity(0.8),
              size: 22),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor ?? _ProfileScreenState.kTextColor,
              ),
            ),
          ),
          Icon(Icons.chevron_right,
              color: _ProfileScreenState.kTextColor.withOpacity(0.4), size: 20),
        ],
      ),
    );
  }
}
