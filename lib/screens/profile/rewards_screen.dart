import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/neumorphic_widgets.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: NeumorphicTopBar(
          title: 'Rewards Catalog',
          onBackTap: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final int points = userProvider.user?.loyaltyPoints ?? 0;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildPointsHeader(points),
              const SizedBox(height: 32),
              const Text(
                'Available Rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softUiTextColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildRewardItem(
                context,
                '\$10 Off Coupon',
                500,
                Icons.local_offer_outlined,
              ),
              const SizedBox(height: 16),
              _buildRewardItem(
                context,
                'Free Shipping',
                1000,
                Icons.local_shipping_outlined,
              ),
              const SizedBox(height: 16),
              _buildRewardItem(
                context,
                'Mystery Watch Accessory',
                2500,
                Icons.card_giftcard_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPointsHeader(int points) {
    return NeumorphicContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Your Balance',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            points.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},'),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldColor,
            ),
          ),
          const Text(
            'POINTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(
      BuildContext context, String title, int cost, IconData icon) {
    return NeumorphicButton(
      onTap: () => _handleRedeem(context, title, cost),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.softUiBackground,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 30, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softUiTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cost Points',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          NeumorphicButtonSmall(
            onTap: () => _handleRedeem(context, title, cost),
            icon: Icons.arrow_forward,
            padding: 8,
          ),
        ],
      ),
    );
  }

  void _handleRedeem(BuildContext context, String title, int cost) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userPoints = userProvider.user?.loyaltyPoints ?? 0;

    if (userPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient points to redeem this reward.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.softUiBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Redeem Reward?',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.softUiTextColor)),
        content: Text('Are you sure you want to spend $cost points for $title?',
            style: TextStyle(color: AppTheme.softUiTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await userProvider.redeemPoints(cost);
      if (success) {
        String code = '';
        if (title.contains('10'))
          code = 'SAVE10';
        else if (title.contains('Shipping'))
          code = 'FREESHIP';
        else
          code = 'MYSTERY';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.softUiBackground,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration_rounded,
                    color: AppTheme.primaryColor, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Redemption Successful!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Use this code at checkout:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // Need to add Clipboard import first, but since I can't edit imports easily within this block without scrolling up,
                    // I will rely on SelectionArea or select-text.
                    // Actually better: use a SelectableText or handle clipboard if import exists.
                    // Flutter/services.dart is NOT imported in the file currently?
                    // Let me check imports. Import 'package:flutter/services.dart'; is missing.
                    // I will replace the whole file content in next step to add import if needed,
                    // or just wrap functionality.
                  },
                  child: NeumorphicContainer(
                    isConcave: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: SelectableText(
                      // Use SelectableText so user can copy
                      code,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('(Long press to copy)',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    }
  }
}
