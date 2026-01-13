import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings_models.dart';
import '../../providers/settings_provider.dart';

class ManageTaxRulesScreen extends StatefulWidget {
  const ManageTaxRulesScreen({super.key});

  @override
  State<ManageTaxRulesScreen> createState() => _ManageTaxRulesScreenState();
}

class _ManageTaxRulesScreenState extends State<ManageTaxRulesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsProvider>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTaxDialog(),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final rules = provider.settings?.taxRules ?? [];

          if (rules.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.percent, size: 20)),
                  title: Text(rule.name),
                  subtitle: Text(
                      '${rule.country}${rule.state != null ? " (${rule.state})" : ""}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(rule.rate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRule(index),
                      ),
                    ],
                  ),
                  onTap: () => _showTaxDialog(rule: rule, index: index),
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
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No tax rules configured',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showTaxDialog(),
            child: const Text('Add Tax Rule'),
          ),
        ],
      ),
    );
  }

  void _showTaxDialog({TaxRule? rule, int? index}) {
    final nameController = TextEditingController(text: rule?.name);
    final rateController = TextEditingController(
        text: rule != null ? (rule.rate * 100).toString() : '');
    final countryController = TextEditingController(text: rule?.country);
    final stateController = TextEditingController(text: rule?.state);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rule == null ? 'Add Tax Rule' : 'Edit Tax Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Rule Name (e.g. VAT)')),
            TextField(
                controller: rateController,
                decoration: const InputDecoration(labelText: 'Rate (%)'),
                keyboardType: TextInputType.number),
            TextField(
                controller: countryController,
                decoration: const InputDecoration(labelText: 'Country')),
            TextField(
                controller: stateController,
                decoration: const InputDecoration(
                    labelText: 'State/Region (Optional)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newRules = List<TaxRule>.from(
                  context.read<SettingsProvider>().settings?.taxRules ?? []);
              final updatedRule = TaxRule(
                id: rule?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                rate: (double.tryParse(rateController.text) ?? 0.0) / 100,
                country: countryController.text,
                state:
                    stateController.text.isEmpty ? null : stateController.text,
              );

              if (index != null) {
                newRules[index] = updatedRule;
              } else {
                newRules.add(updatedRule);
              }

              context.read<SettingsProvider>().updateTaxRules(newRules);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteRule(int index) {
    final newRules = List<TaxRule>.from(
        context.read<SettingsProvider>().settings?.taxRules ?? []);
    newRules.removeAt(index);
    context.read<SettingsProvider>().updateTaxRules(newRules);
  }
}
