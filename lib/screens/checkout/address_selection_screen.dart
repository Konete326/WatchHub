import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../profile/add_address_screen.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/checkout_progress_bar.dart';
import 'payment_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.fetchAddresses();
      if (userProvider.defaultAddress != null) {
        _selectedAddressId = userProvider.defaultAddress!.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Address'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const ListShimmer();
          }

          if (userProvider.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No addresses found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddAddressScreen(),
                        ),
                      );
                      userProvider.fetchAddresses();
                    },
                    child: const Text('Add Address'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              const CheckoutProgressBar(currentStep: 0),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: userProvider.addresses.length,
                  itemBuilder: (context, index) {
                    final address = userProvider.addresses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: RadioListTile<String>(
                        value: address.id,
                        groupValue: _selectedAddressId,
                        onChanged: (value) {
                          setState(() {
                            _selectedAddressId = value;
                          });
                        },
                        title: Text(address.fullAddress,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: address.isDefault
                            ? const Text(
                                'Default Address',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddAddressScreen(),
                            ),
                          );
                          userProvider.fetchAddresses();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Address'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _selectedAddressId != null
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PaymentScreen(
                                      addressId: _selectedAddressId!,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Continue to Payment'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
