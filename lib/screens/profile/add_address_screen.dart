import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/address.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/neumorphic_widgets.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address;
  const AddAddressScreen({super.key, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController(text: 'USA');
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _addressLineController.text = widget.address!.addressLine;
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _zipController.text = widget.address!.zip;
      _phoneController.text = widget.address!.phone ?? '';
      _countryController.text = widget.address!.country;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final address = Address(
      id: widget.address?.id ?? '',
      userId: widget.address?.userId ?? '',
      addressLine: InputSanitizer.sanitize(_addressLineController.text),
      city: InputSanitizer.sanitize(_cityController.text),
      state: InputSanitizer.sanitize(_stateController.text),
      zip: InputSanitizer.sanitize(_zipController.text),
      country: InputSanitizer.sanitize(_countryController.text),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : InputSanitizer.sanitizePhone(_phoneController.text),
      isDefault: _isDefault,
      createdAt: widget.address?.createdAt ?? DateTime.now(),
    );

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool success;
    if (widget.address != null) {
      success = await userProvider.updateAddress(widget.address!.id, address);
    } else {
      success = await userProvider.createAddress(address);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      _showSnackBar(widget.address != null
          ? 'Address updated successfully'
          : 'Address added successfully');
    } else {
      _showSnackBar(userProvider.errorMessage ?? 'Failed to save address',
          isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      body: SafeArea(
        child: Column(
          children: [
            NeumorphicTopBar(
              title: widget.address != null ? 'Edit Address' : 'New Address',
              onBackTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAutocompleteField(
                        controller: _addressLineController,
                        label: 'Street Address',
                        icon: Icons.map_outlined,
                        suggestions: [
                          '123 Rolex Way, Geneva, CH',
                          '456 Patek Philippe Plaza, London, UK',
                          '789 Audemars Piguet Ave, Le Brassus, CH',
                          '101 Vacheron Constantin Ct, Plan-les-Ouates, CH',
                          '202 Cartier Blvd, Paris, FR',
                          '303 Hublot St, Nyon, CH',
                          '404 Omega Lane, Biel/Bienne, CH',
                        ],
                        validator: (value) =>
                            Validators.required(value, 'Address'),
                        onSelected: (selection) {
                          final parts = selection.split(', ');
                          if (parts.length >= 2) {
                            _addressLineController.text = parts[0];
                            _cityController.text = parts[1];
                          }
                          if (parts.length >= 3) {
                            _countryController.text = parts[2];
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _cityController,
                              label: 'City',
                              icon: Icons.location_city_outlined,
                              validator: (value) =>
                                  Validators.required(value, 'City'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              controller: _stateController,
                              label: 'State',
                              icon: Icons.explore_outlined,
                              validator: (value) =>
                                  Validators.required(value, 'State'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _zipController,
                              label: 'ZIP Code',
                              icon: Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  Validators.required(value, 'ZIP'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              controller: _countryController,
                              label: 'Country',
                              icon: Icons.public_outlined,
                              validator: (value) =>
                                  Validators.required(value, 'Country'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInputField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_android_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 40),
                      _buildDefaultToggle(),
                      const SizedBox(height: 48),
                      NeumorphicButton(
                        onTap: _isLoading ? () {} : _saveAddress,
                        isPressed: _isLoading,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        borderRadius: BorderRadius.circular(20),
                        backgroundColor: AppTheme.primaryColor,
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Address',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> suggestions,
    String? Function(String?)? validator,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.softUiTextColor,
            ),
          ),
        ),
        NeumorphicContainer(
          isConcave: true,
          borderRadius: BorderRadius.circular(15),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '')
                return const Iterable<String>.empty();
              return suggestions.where((String option) => option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: onSelected,
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
              // Initial sync
              if (textController.text.isEmpty && controller.text.isNotEmpty) {
                textController.text = controller.text;
              }
              textController
                  .addListener(() => controller.text = textController.text);
              return TextFormField(
                controller: textController,
                focusNode: focusNode,
                validator: validator,
                style: const TextStyle(
                    color: AppTheme.softUiTextColor,
                    fontWeight: FontWeight.w600),
                cursorColor: AppTheme.primaryColor,
                decoration: InputDecoration(
                  icon: Icon(icon,
                      color: AppTheme.softUiTextColor.withOpacity(0.7),
                      size: 20),
                  border: InputBorder.none,
                  hintText: 'Enter $label',
                  hintStyle: TextStyle(
                      color: AppTheme.softUiTextColor.withOpacity(0.4),
                      fontSize: 14),
                  errorStyle:
                      const TextStyle(height: 0, color: Colors.transparent),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 48,
                    margin: const EdgeInsets.only(top: 8),
                    child: NeumorphicContainer(
                      borderRadius: BorderRadius.circular(15),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(option,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.softUiTextColor)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.softUiTextColor,
            ),
          ),
        ),
        NeumorphicContainer(
          isConcave: true,
          borderRadius: BorderRadius.circular(15),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              color: AppTheme.softUiTextColor,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: AppTheme.primaryColor,
            decoration: InputDecoration(
              icon: Icon(icon,
                  color: AppTheme.softUiTextColor.withOpacity(0.7), size: 20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                  color: AppTheme.softUiTextColor.withOpacity(0.4),
                  fontSize: 14),
              errorStyle: const TextStyle(height: 0, color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isDefault = !_isDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 32,
              child: NeumorphicContainer(
                isConcave: true,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(4),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment:
                      _isDefault ? Alignment.centerRight : Alignment.centerLeft,
                  child: NeumorphicContainer(
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: _isDefault
                        ? AppTheme.primaryColor
                        : AppTheme.softUiShadowDark.withOpacity(0.5),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: _isDefault
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set as Default',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softUiTextColor,
                  ),
                ),
                Text(
                  'Use this for all future orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.softUiTextColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
