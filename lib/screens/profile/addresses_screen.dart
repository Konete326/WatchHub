import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import 'add_address_screen.dart';
import '../../widgets/neumorphic_widgets.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: NeumorphicTopBar(
          title: 'My Addresses',
          onBackTap: () => Navigator.of(context).pop(),
          actions: [
            NeumorphicButton(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddAddressScreen(),
                  ),
                );
              },
              padding: const EdgeInsets.all(10),
              shape: BoxShape.circle,
              child: const Icon(Icons.add_rounded,
                  color: AppTheme.primaryColor, size: 20),
            ),
          ],
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return _buildShimmerLoading();
          }

          if (userProvider.addresses.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: userProvider.addresses.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final address = userProvider.addresses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: NeumorphicContainer(
                  borderRadius: BorderRadius.circular(25),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Icon in Concave Well
                      NeumorphicContainer(
                        isConcave: true,
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          address.isDefault
                              ? Icons.home_rounded
                              : Icons.location_on_rounded,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Address Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.fullAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.softUiTextColor,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(height: 12),
                              NeumorphicPill(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                child: const Text(
                                  'Default Address',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Actions
                      Column(
                        children: [
                          NeumorphicButton(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddAddressScreen(address: address),
                                ),
                              );
                            },
                            padding: const EdgeInsets.all(8),
                            shape: BoxShape.circle,
                            child: const Icon(Icons.edit_outlined,
                                color: AppTheme.softUiTextColor, size: 18),
                          ),
                          const SizedBox(height: 12),
                          NeumorphicButton(
                            onTap: () => _showDeleteDialog(
                                context, userProvider, address.id),
                            padding: const EdgeInsets.all(8),
                            shape: BoxShape.circle,
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.errorColor, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(50),
              isConcave: true,
              child: Icon(
                Icons.location_off_rounded,
                size: 80,
                color: AppTheme.softUiTextColor.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'No addresses added',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.softUiTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please add an address to proceed with checkout and receive your orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.softUiTextColor.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            NeumorphicButton(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddAddressScreen(),
                  ),
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              borderRadius: BorderRadius.circular(20),
              child: const Text(
                'Add Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context, UserProvider userProvider, String addressId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (context) => NeumorphicDialog(
        title: 'Delete Address',
        content: 'Are you sure you want to remove this address?',
        confirmLabel: 'Delete',
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirm == true && mounted) {
      final success = await userProvider.deleteAddress(addressId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'Address deleted' : 'Failed to delete address'),
            backgroundColor:
                success ? AppTheme.successColor : AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
