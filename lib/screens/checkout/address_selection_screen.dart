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

  // Neumorphic Design Constants
  static const Color kBackgroundColor = Color(0xFFE0E5EC);
  static const Color kShadowDark = Color(0xFFA3B1C6);
  static const Color kShadowLight = Color(0xFFFFFFFF);
  static const Color kTextColor = Color(0xFF4A5568);
  static const Color kPrimaryColor = AppTheme.primaryColor;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.fetchAddresses();
      if (userProvider.defaultAddress != null) {
        setState(() {
          _selectedAddressId = userProvider.defaultAddress!.id;
        });
      }
    });
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
                _NeumorphicButton(
                  onTap: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(10),
                  shape: BoxShape.circle,
                  child: const Icon(Icons.arrow_back, color: kTextColor),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Select Address',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 44), // Balancer
              ],
            ),
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const ListShimmer();
          }

          if (userProvider.addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NeumorphicConcave(
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(30),
                      child: Icon(Icons.location_off_outlined,
                          size: 64, color: kTextColor.withOpacity(0.3)),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'No addresses found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please add a shipping address to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _NeumorphicButton(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddAddressScreen(),
                          ),
                        );
                        userProvider.fetchAddresses();
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      borderRadius: BorderRadius.circular(15),
                      child: const Text(
                        'Add Address',
                        style: TextStyle(
                            color: kPrimaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              const CheckoutProgressBar(currentStep: 0),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: userProvider.addresses.length,
                  itemBuilder: (context, index) {
                    final address = userProvider.addresses[index];
                    final isSelected = _selectedAddressId == address.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedAddressId = address.id),
                        child: _NeumorphicIndicatorContainer(
                          isSelected: isSelected,
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              _NeumorphicRadio(isSelected: isSelected),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (address.isDefault)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'DEFAULT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                kPrimaryColor.withOpacity(0.8),
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      address.fullAddress,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? kTextColor
                                            : kTextColor.withOpacity(0.8),
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Action Slab
              _NeumorphicContainer(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NeumorphicButton(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddAddressScreen(),
                            ),
                          );
                          userProvider.fetchAddresses();
                        },
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: BorderRadius.circular(15),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20, color: kTextColor),
                            SizedBox(width: 8),
                            Text(
                              'Add New Address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _NeumorphicButton(
                        onTap: _selectedAddressId != null
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PaymentScreen(
                                      addressId: _selectedAddressId!,
                                    ),
                                  ),
                                );
                              }
                            : () {},
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        borderRadius: BorderRadius.circular(15),
                        child: Center(
                          child: Text(
                            'Continue to Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedAddressId != null
                                  ? kPrimaryColor
                                  : kTextColor.withOpacity(0.3),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
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

// --- Neumorphic Components ---

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const _NeumorphicContainer({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFA3B1C6),
            offset: Offset(6, 6),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0xFFFFFFFF),
            offset: Offset(-6, -6),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: borderRadius,
        boxShadow: isSelected
            ? [] // Concave/Pressed simulation (simplified for basic flutter)
            : [
                const BoxShadow(
                  color: Color(0xFFA3B1C6),
                  offset: Offset(6, 6),
                  blurRadius: 16,
                ),
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  offset: Offset(-6, -6),
                  blurRadius: 16,
                ),
              ],
        border: isSelected
            ? Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5)
            : null,
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
          color: const Color(0xFFE0E5EC),
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
          boxShadow: _isPressed
              ? []
              : [
                  const BoxShadow(
                    color: Color(0xFFA3B1C6),
                    offset: Offset(6, 6),
                    blurRadius: 16,
                  ),
                  const BoxShadow(
                    color: Color(0xFFFFFFFF),
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

class _NeumorphicConcave extends StatelessWidget {
  final Widget child;
  final BoxShape shape;
  final EdgeInsetsGeometry padding;

  const _NeumorphicConcave({
    required this.child,
    this.shape = BoxShape.rectangle,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        shape: shape,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NeumorphicRadio extends StatelessWidget {
  final bool isSelected;

  const _NeumorphicRadio({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                const BoxShadow(
                  color: Color(0xFFA3B1C6),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  offset: Offset(-2, -2),
                  blurRadius: 4,
                ),
              ]
            : [
                // Recessed look
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 1,
                  offset: const Offset(1, 1),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 2,
                  spreadRadius: 1,
                  offset: Offset(-1, -1),
                ),
              ],
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
