import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings_models.dart';
import '../../providers/settings_provider.dart';

class ManageShippingZonesScreen extends StatefulWidget {
  const ManageShippingZonesScreen({super.key});

  @override
  State<ManageShippingZonesScreen> createState() =>
      _ManageShippingZonesScreenState();
}

class _ManageShippingZonesScreenState extends State<ManageShippingZonesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsProvider>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Zones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showZoneDialog(),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final zones = provider.settings?.shippingZones ?? [];

          if (zones.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(zone.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${zone.countries.length} countries • ${zone.rates.length} rates'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Countries:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(zone.countries.join(', ')),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Rates:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Rate'),
                                onPressed: () => _showRateDialog(zone, index),
                              ),
                            ],
                          ),
                          ...zone.rates
                              .map((rate) => _buildRateTile(rate, zone, index))
                              .toList(),
                        ],
                      ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => _deleteZone(index),
                          child: const Text('Delete Zone',
                              style: TextStyle(color: Colors.red)),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _showZoneDialog(zone: zone, index: index),
                          child: const Text('Edit Zone'),
                        ),
                      ],
                    )
                  ],
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
          Icon(Icons.local_shipping_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No shipping zones configured',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showZoneDialog(),
            child: const Text('Create First Zone'),
          ),
        ],
      ),
    );
  }

  Widget _buildRateTile(ShippingRate rate, ShippingZone zone, int zoneIndex) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(rate.name),
      subtitle: Text(
          '${rate.minWeight}kg - ${rate.maxWeight ?? "∞"}kg • ${rate.estimatedDaysMin}-${rate.estimatedDaysMax} days'),
      trailing: Text('\$${rate.price.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showZoneDialog({ShippingZone? zone, int? index}) {
    final nameController = TextEditingController(text: zone?.name);
    final countriesController =
        TextEditingController(text: zone?.countries.join(', '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(zone == null ? 'Add Zone' : 'Edit Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Zone Name', hintText: 'e.g. North America'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countriesController,
              decoration: const InputDecoration(
                  labelText: 'Countries (Comma separated)',
                  hintText: 'USA, Canada, Mexico'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newZones = List<ShippingZone>.from(
                  context.read<SettingsProvider>().settings?.shippingZones ??
                      []);
              final updatedZone = ShippingZone(
                id: zone?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                countries: countriesController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList(),
                rates: zone?.rates ?? [],
              );

              if (index != null) {
                newZones[index] = updatedZone;
              } else {
                newZones.add(updatedZone);
              }

              context.read<SettingsProvider>().updateShippingZones(newZones);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(ShippingZone zone, int zoneIndex) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final minWController = TextEditingController(text: '0');
    final maxWController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Shipping Rate'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Rate Name')),
              TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: minWController,
                  decoration:
                      const InputDecoration(labelText: 'Min Weight (kg)'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: maxWController,
                  decoration: const InputDecoration(
                      labelText: 'Max Weight (kg, optional)'),
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
              final rate = ShippingRate(
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0.0,
                minWeight: double.tryParse(minWController.text) ?? 0.0,
                maxWeight: double.tryParse(maxWController.text),
              );

              final newZones = List<ShippingZone>.from(
                  context.read<SettingsProvider>().settings?.shippingZones ??
                      []);
              final updatedZone = ShippingZone(
                id: zone.id,
                name: zone.name,
                countries: zone.countries,
                rates: [...zone.rates, rate],
              );
              newZones[zoneIndex] = updatedZone;

              context.read<SettingsProvider>().updateShippingZones(newZones);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteZone(int index) {
    final newZones = List<ShippingZone>.from(
        context.read<SettingsProvider>().settings?.shippingZones ?? []);
    newZones.removeAt(index);
    context.read<SettingsProvider>().updateShippingZones(newZones);
  }
}
