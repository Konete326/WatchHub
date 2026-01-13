import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings_models.dart';
import '../../providers/settings_provider.dart';

class ManageChannelsScreen extends StatefulWidget {
  const ManageChannelsScreen({super.key});

  @override
  State<ManageChannelsScreen> createState() => _ManageChannelsScreenState();
}

class _ManageChannelsScreenState extends State<ManageChannelsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsProvider>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storefront Channels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showChannelDialog(),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final channels = provider.settings?.channels ?? [];

          if (channels.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Card(
                child: SwitchListTile(
                  secondary: CircleAvatar(
                    child: Icon(channel.name.toLowerCase().contains('app')
                        ? Icons.phone_android
                        : Icons.web_rounded),
                  ),
                  title: Text(channel.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(channel.isEnabled ? 'Enabled' : 'Disabled'),
                  value: channel.isEnabled,
                  onChanged: (v) => _toggleChannel(index, v),
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
          Icon(Icons.devices_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No sales channels configured',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showChannelDialog(),
            child: const Text('Add Channel'),
          ),
        ],
      ),
    );
  }

  void _showChannelDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Channel'),
        content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
                labelText: 'Channel Name (e.g. Android App)')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newChannels = List<AppChannel>.from(
                  context.read<SettingsProvider>().settings?.channels ?? []);
              newChannels.add(AppChannel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
              ));
              context.read<SettingsProvider>().updateChannels(newChannels);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleChannel(int index, bool isEnabled) {
    final newChannels = List<AppChannel>.from(
        context.read<SettingsProvider>().settings?.channels ?? []);
    final channel = newChannels[index];
    newChannels[index] = AppChannel(
      id: channel.id,
      name: channel.name,
      isEnabled: isEnabled,
      config: channel.config,
    );
    context.read<SettingsProvider>().updateChannels(newChannels);
  }
}
