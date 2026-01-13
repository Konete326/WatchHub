import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings_models.dart';
import '../../providers/settings_provider.dart';

class ManageReturnPoliciesScreen extends StatefulWidget {
  const ManageReturnPoliciesScreen({super.key});

  @override
  State<ManageReturnPoliciesScreen> createState() =>
      _ManageReturnPoliciesScreenState();
}

class _ManageReturnPoliciesScreenState
    extends State<ManageReturnPoliciesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsProvider>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Policies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPolicyDialog(),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final policies = provider.settings?.returnPolicies ?? [];

          if (policies.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: policies.length,
            itemBuilder: (context, index) {
              final policy = policies[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                      child: Icon(Icons.assignment_return, size: 20)),
                  title: Text(policy.title),
                  subtitle: Text(
                      '${policy.returnWindowDays} day window • ${policy.restockingFee ? "Fee applies" : "No fee"}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletePolicy(index),
                  ),
                  onTap: () => _showPolicyDialog(policy: policy, index: index),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_return_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No return policy templates',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showPolicyDialog(),
            child: const Text('Create Template'),
          ),
        ],
      ),
    );
  }

  void _showPolicyDialog({ReturnPolicyTemplate? policy, int? index}) {
    final titleController = TextEditingController(text: policy?.title);
    final contentController = TextEditingController(text: policy?.content);
    final windowController = TextEditingController(
        text: policy?.returnWindowDays.toString() ?? '30');
    final feeAmountController = TextEditingController(
        text: policy?.restockingFeeAmount.toString() ?? '0.0');
    bool hasFee = policy?.restockingFee ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              policy == null ? 'New Policy Template' : 'Edit Policy Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    decoration:
                        const InputDecoration(labelText: 'Policy Title')),
                TextField(
                    controller: contentController,
                    decoration:
                        const InputDecoration(labelText: 'Full Content'),
                    maxLines: 4),
                TextField(
                    controller: windowController,
                    decoration: const InputDecoration(
                        labelText: 'Return Window (Days)'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Charge Restocking Fee'),
                  value: hasFee,
                  onChanged: (v) => setDialogState(() => hasFee = v),
                ),
                if (hasFee)
                  TextField(
                      controller: feeAmountController,
                      decoration:
                          const InputDecoration(labelText: 'Fee Amount'),
                      keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final newPolicies = List<ReturnPolicyTemplate>.from(
                    context.read<SettingsProvider>().settings?.returnPolicies ??
                        []);
                final updatedPolicy = ReturnPolicyTemplate(
                  id: policy?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  content: contentController.text,
                  returnWindowDays: int.tryParse(windowController.text) ?? 30,
                  restockingFee: hasFee,
                  restockingFeeAmount:
                      double.tryParse(feeAmountController.text) ?? 0.0,
                );

                if (index != null) {
                  newPolicies[index] = updatedPolicy;
                } else {
                  newPolicies.add(updatedPolicy);
                }

                context
                    .read<SettingsProvider>()
                    .updateReturnPolicies(newPolicies);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePolicy(int index) {
    final newPolicies = List<ReturnPolicyTemplate>.from(
        context.read<SettingsProvider>().settings?.returnPolicies ?? []);
    newPolicies.removeAt(index);
    context.read<SettingsProvider>().updateReturnPolicies(newPolicies);
  }
}
