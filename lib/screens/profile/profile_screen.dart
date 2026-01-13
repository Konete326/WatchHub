import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../notifications/notifications_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/addresses_screen.dart';
import '../support/support_screen.dart';
import 'edit_profile_screen.dart';
import 'payment_methods_screen.dart';
import 'rewards_screen.dart';
import '../../widgets/neumorphic_widgets.dart';

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
                  NeumorphicButtonSmall(
                    onTap: widget.onBack ??
                        () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                    icon: Icons.arrow_back,
                    tooltip: 'Back',
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: Text(
                      'Profile',
                      style: GoogleFonts.playfairDisplay(
                        color: kTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
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
                  NeumorphicButton(
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
                        NeumorphicContainer(
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
                                    user.name.isNotEmpty
                                        ? user.name
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : '?',
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
                          child: NeumorphicButtonSmall(
                            onTap: _pickAndUploadImage,
                            icon: Icons.camera_alt,
                            iconSize: 20,
                            padding: 12, // Ensure 44dp+ hit area
                            tooltip: 'Change Profile Picture',
                            iconColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildLoyaltyCard(user),
              const SizedBox(height: 32),

              _buildSectionHeader('Account Settings'),
              const SizedBox(height: 12),
              _NeumorphicMenuItem(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.location_on_outlined,
                title: 'My Addresses',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddressesScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Order History',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.credit_card_outlined,
                title: 'Payment Methods',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentMethodsScreen())),
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Personalization'),
              const SizedBox(height: 12),
              _NeumorphicMenuItem(
                icon: Icons.straighten_outlined,
                title: 'Saved Sizes & Preferences',
                subtitle: user.savedStrapSize ?? 'Set your strap size',
                onTap: _showSavedSizesDialog,
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.card_giftcard_outlined,
                title: 'Refer a Friend',
                onTap: _showReferralDialog,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('More'),
              const SizedBox(height: 12),
              _NeumorphicMenuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.headset_mic_outlined,
                title: 'Support Center',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SupportScreen())),
              ),
              const SizedBox(height: 16),
              _NeumorphicMenuItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                textColor: AppTheme.errorColor,
                iconColor: AppTheme.errorColor,
                onTap: () => _handleLogout(authProvider),
              ),
              const SizedBox(height: 120),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: kTextColor.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(user) {
    final int points = user.loyaltyPoints;
    final String tier = user.loyaltyTier;

    return _NeumorphicIndicatorContainer(
      isSelected: true,
      borderRadius: BorderRadius.circular(25),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: AppTheme.goldColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '$tier Member',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$points Points available',
                  style: TextStyle(
                      fontSize: 14, color: kTextColor.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                NeumorphicButton(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RewardsScreen())),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: BorderRadius.circular(10),
                  child: const Text(
                    'Redeem Points',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: (points % 1000) / 1000,
                  strokeWidth: 6,
                  backgroundColor: kBackgroundColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${((points % 1000) / 10).toInt()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kTextColor),
                  ),
                  const Text('to next',
                      style: TextStyle(fontSize: 8, color: kTextColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSavedSizesDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Strap Size',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextColor)),
            const SizedBox(height: 8),
            const Text(
                'We will use this to recommend watches that fit you perfectly.'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                'Small (150-165mm)',
                'Medium (170-185mm)',
                'Large (190-205mm)'
              ].map((size) {
                return NeumorphicButton(
                  onTap: () async {
                    final success =
                        await Provider.of<UserProvider>(context, listen: false)
                            .updateSavedSize(size);
                    if (mounted) Navigator.pop(context);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Saved strap size updated to $size')));
                    }
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: BorderRadius.circular(15),
                  child: Text(size,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showReferralDialog() {
    final String referralCode =
        Provider.of<UserProvider>(context, listen: false).user?.referralCode ??
            'WATCHHUB50';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text('Refer a Friend',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Share your code and you both get \$50 credit on your next purchase!'),
            const SizedBox(height: 24),
            NeumorphicContainer(
              isConcave: true,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      referralCode.isEmpty ? 'WATCHHUB50' : referralCode,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied!')));
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
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
      await authProvider.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

class _NeumorphicIndicatorContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const _NeumorphicIndicatorContainer({
    required this.child,
    required this.isSelected,
    required this.padding,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.softUiBackground,
        borderRadius: borderRadius,
        boxShadow: [
          const BoxShadow(
              color: AppTheme.softUiShadowDark,
              offset: Offset(4, 4),
              blurRadius: 10),
          const BoxShadow(
              color: AppTheme.softUiShadowLight,
              offset: Offset(-4, -4),
              blurRadius: 10),
        ],
      ),
      child: child,
    );
  }
}

class _NeumorphicMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _NeumorphicMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Icon(icon,
              color:
                  iconColor ?? AppTheme.softUiTextColor.withValues(alpha: 0.8),
              size: 22),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? AppTheme.softUiTextColor)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              AppTheme.softUiTextColor.withValues(alpha: 0.5))),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: AppTheme.softUiTextColor.withValues(alpha: 0.4), size: 20),
        ],
      ),
    );
  }
}
