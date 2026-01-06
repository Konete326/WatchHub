import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/address.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

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

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.address != null
              ? 'Address updated successfully'
              : 'Address added successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? 'Failed to add address'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address != null ? 'Edit Address' : 'Add Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _addressLineController,
                decoration: const InputDecoration(
                  labelText: 'Address Line',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
                validator: (value) => Validators.required(value, 'Address'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) => Validators.required(value, 'City'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) => Validators.required(value, 'State'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  prefixIcon: Icon(Icons.pin_drop),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.required(value, 'ZIP Code'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) => Validators.required(value, 'Country'),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAddress,
                child: const Text('Save Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
