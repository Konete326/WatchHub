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
    final usageLimitController = TextEditingController();
    final limitPerUserControlller = TextEditingController();
    final abTestIdController = TextEditingController();

    String type = 'percentage';
    DateTime? startDate;
    DateTime? expiryDate;
    bool isStackable = false;
    List<String> selectedSegments = [];
    String? abVersion;

    final segments = ['CHAMPION', 'LOYAL', 'AT RISK', 'HIBERNATING', 'VIP'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Coupon Rule'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(
                          labelText: 'Coupon Code', hintText: 'e.g. SUMMER25'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: type,
                            decoration:
                                const InputDecoration(labelText: 'Type'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'percentage',
                                  child: Text('Percent (%)')),
                              DropdownMenuItem(
                                  value: 'fixed', child: Text('Fixed (\$)')),
                            ],
                            onChanged: (v) => setDialogState(() => type = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: valueController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: type == 'percentage'
                                    ? 'Value (%)'
                                    : 'Value (\$)'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: minAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Min Order Amount (Optional)'),
                    ),
                    const Divider(height: 32),
                    const Text('Usage Limits',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: usageLimitController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Global Limit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: limitPerUserControlller,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Per User'),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Stackable with others',
                          style: TextStyle(fontSize: 14)),
                      value: isStackable,
                      onChanged: (v) => setDialogState(() => isStackable = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 32),
                    const Text('Target Segments (Audience)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Wrap(
                      spacing: 8,
                      children: segments
                          .map((s) => FilterChip(
                                label: Text(s,
                                    style: const TextStyle(fontSize: 10)),
                                selected: selectedSegments.contains(s),
                                onSelected: (v) => setDialogState(() {
                                  if (v)
                                    selectedSegments.add(s);
                                  else
                                    selectedSegments.remove(s);
                                }),
                              ))
                          .toList(),
                    ),
                    const Divider(height: 32),
                    const Text('Validity Schedule',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                                startDate == null
                                    ? 'Start'
                                    : DateFormat('MM/dd').format(startDate!),
                                style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.event, size: 16),
                            contentPadding: EdgeInsets.zero,
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)));
                              if (d != null)
                                setDialogState(() => startDate = d);
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                                expiryDate == null
                                    ? 'End'
                                    : DateFormat('MM/dd').format(expiryDate!),
                                style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.event, size: 16),
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now()
                                      .add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)));
                              if (d != null)
                                setDialogState(() => expiryDate = d);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text('A/B Testing (Optional)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: abTestIdController,
                            decoration: const InputDecoration(
                                labelText: 'Group ID', hintText: 'TEST_01'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: DropdownButtonFormField<String>(
                          value: abVersion,
                          decoration: const InputDecoration(labelText: 'Ver'),
                          items: const [
                            DropdownMenuItem(value: 'A', child: Text('A')),
                            DropdownMenuItem(value: 'B', child: Text('B'))
                          ],
                          onChanged: (v) => setDialogState(() => abVersion = v),
                        )),
                      ],
                    ),
                  ],
                ),
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
                    startDate: startDate,
                    expiryDate: expiryDate,
                    isStackable: isStackable,
                    usageLimit: int.tryParse(usageLimitController.text),
                    limitPerUser: int.tryParse(limitPerUserControlller.text),
                    allowedSegments:
                        selectedSegments.isNotEmpty ? selectedSegments : null,
                    abTestId: abTestIdController.text.isNotEmpty
                        ? abTestIdController.text
                        : null,
                    version: abVersion,
                  );
                  final success =
                      await Provider.of<AdminProvider>(context, listen: false)
                          .createCoupon(coupon);
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupon logic saved')));
                  }
                }
              },
              child: const Text('Save Rule'),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(
                          coupon.code,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (coupon.abTestId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('TEST: ${coupon.version}',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${coupon.type == 'percentage' ? '${coupon.value}% off' : '\$${coupon.value} off'}'
                          '${coupon.minAmount != null ? ' (Min: \$${coupon.minAmount})' : ''}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        if (coupon.allowedSegments != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                                'Audience: ${coupon.allowedSegments!.join(', ')}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.blue.shade700)),
                          ),
                        Text(
                          'Usage: ${coupon.usageCount}${coupon.usageLimit != null ? '/${coupon.usageLimit}' : ''} | '
                          'Expires: ${coupon.expiryDate != null ? DateFormat('MM/dd/yy').format(coupon.expiryDate!) : 'Never'}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Switch(
                          value: coupon.isActive,
                          onChanged: (v) => adminProvider
                              .updateCoupon(coupon.id, {'isActive': v}),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Coupon'),
                                content: const Text('Are you sure?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await adminProvider.deleteCoupon(coupon.id);
                            }
                          },
                        ),
                      ],
                    ),
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
