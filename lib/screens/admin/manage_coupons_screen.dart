import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/coupon.dart';
import '../../utils/theme.dart';

class ManageCouponsScreen extends StatefulWidget {
  const ManageCouponsScreen({super.key});

  @override
  State<ManageCouponsScreen> createState() => _ManageCouponsScreenState();
}

class _ManageCouponsScreenState extends State<ManageCouponsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminProvider>(context, listen: false).fetchAllCoupons();
    });
  }

  void _showAddCouponDialog() {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minAmountController = TextEditingController();
    String type = 'percentage';
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Coupon'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                        labelText: 'Coupon Code (e.g. WATCH20)'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'percentage', child: Text('Percentage (%)')),
                      DropdownMenuItem(
                          value: 'fixed', child: Text('Fixed Amount (\$')),
                    ],
                    onChanged: (v) => setDialogState(() => type = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'percentage'
                          ? 'Discount Percentage'
                          : 'Discount Amount',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: minAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Min Order Amount (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(selectedDate == null
                        ? 'Select Expiry Date'
                        : 'Expires: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null)
                        setDialogState(() => selectedDate = date);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final coupon = Coupon(
                    id: '',
                    code: codeController.text.toUpperCase(),
                    type: type,
                    value: double.parse(valueController.text),
                    minAmount: minAmountController.text.isNotEmpty
                        ? double.parse(minAmountController.text)
                        : null,
                    expiryDate: selectedDate,
                  );
                  final success =
                      await Provider.of<AdminProvider>(context, listen: false)
                          .createCoupon(coupon);
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupon created')));
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Coupons'),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.coupons.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.coupons.isEmpty) {
            return const Center(child: Text('No coupons yet'));
          }

          return ListView.builder(
            itemCount: adminProvider.coupons.length,
            itemBuilder: (context, index) {
              final coupon = adminProvider.coupons[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    coupon.code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${coupon.type == 'percentage' ? '${coupon.value}% off' : '\$${coupon.value} off'}'
                    '${coupon.minAmount != null ? ' (Min: \$${coupon.minAmount})' : ''}'
                    '\nExpires: ${coupon.expiryDate != null ? DateFormat('yyyy-MM-dd').format(coupon.expiryDate!) : 'Never'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Coupon'),
                          content: const Text('Are you sure?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await adminProvider.deleteCoupon(coupon.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCouponDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
