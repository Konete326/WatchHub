import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import '../../utils/theme.dart';
import '../../widgets/admin/admin_drawer.dart';

class ShippingSettingsScreen extends StatefulWidget {
  const ShippingSettingsScreen({super.key});

  @override
  State<ShippingSettingsScreen> createState() => _ShippingSettingsScreenState();
}

class _ShippingSettingsScreenState extends State<ShippingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deliveryChargeController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _amountThresholdController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  String _selectedCurrency = 'USD';

  final List<String> _currencies = ['USD', 'PKR', 'EUR', 'GBP', 'INR'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.fetchSettings();
      if (adminProvider.settings != null && mounted) {
        setState(() {
          _deliveryChargeController.text =
              adminProvider.settings!.deliveryCharge.toString();
          _thresholdController.text =
              adminProvider.settings!.freeDeliveryThreshold.toString();
          _amountThresholdController.text =
              adminProvider.settings!.freeDeliveryAmountThreshold?.toString() ??
                  '';
          _exchangeRateController.text =
              adminProvider.settings!.currencyExchangeRate.toString();
          _selectedCurrency = adminProvider.settings!.currencyCode;
        });
      }
    });
  }

  @override
  void dispose() {
    _deliveryChargeController.dispose();
    _thresholdController.dispose();
    _amountThresholdController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = AppSettings(
      deliveryCharge: double.parse(_deliveryChargeController.text),
      freeDeliveryThreshold: int.parse(_thresholdController.text),
      freeDeliveryAmountThreshold: _amountThresholdController.text.isNotEmpty
          ? double.parse(_amountThresholdController.text)
          : null,
      currencyCode: _selectedCurrency,
      currencyExchangeRate: double.parse(_exchangeRateController.text),
    );

    final success = await Provider.of<AdminProvider>(context, listen: false)
        .updateSettings(settings);

    if (success && mounted) {
      // Refresh global settings
      await Provider.of<SettingsProvider>(context, listen: false)
          .fetchSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      drawer: const AdminDrawer(),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.settings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Currency Settings Section
                  const Text(
                    'Currency Settings',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'Primary Store Currency',
                              prefixIcon: Icon(Icons.currency_exchange),
                            ),
                            items: _currencies
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCurrency = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _exchangeRateController,
                            decoration: const InputDecoration(
                              labelText: 'Exchange Rate (Rel. to USD)',
                              helperText: 'e.g. 280 for PKR, 0.92 for EUR',
                              prefixIcon: Icon(Icons.rate_review),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Required';
                              if (double.tryParse(value) == null)
                                return 'Invalid number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delivery Settings Section
                  const Text(
                    'Shipping & Delivery',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _deliveryChargeController,
                            decoration: InputDecoration(
                              labelText: 'Delivery Charge ($_selectedCurrency)',
                              prefixIcon: const Icon(Icons.delivery_dining),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Required';
                              if (double.tryParse(value) == null)
                                return 'Invalid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _thresholdController,
                            decoration: const InputDecoration(
                              labelText: 'Free Delivery Threshold (Items)',
                              hintText: 'e.g. 3 items',
                              prefixIcon: Icon(Icons.shopping_basket),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Required';
                              if (int.tryParse(value) == null)
                                return 'Invalid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountThresholdController,
                            decoration: InputDecoration(
                              labelText:
                                  'Free Delivery Amount ($_selectedCurrency)',
                              hintText: 'e.g. 500',
                              prefixIcon: const Icon(Icons.monetization_on),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: adminProvider.isLoading ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: adminProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save All Settings',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
