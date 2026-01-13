import 'package:flutter/material.dart';
import '../../models/watch.dart';
import '../../models/order.dart';
import '../../services/admin_service.dart';

class AdminSearchDelegate extends SearchDelegate {
  final AdminService _adminService = AdminService();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
          child: Text("Search term must be longer than 2 letters."));
    }

    return FutureBuilder(
      future: Future.wait([
        _searchProducts(query),
        _searchOrders(query),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error searching'));
        }

        final products = snapshot.data?[0] as List<Watch>? ?? [];
        final orders = snapshot.data?[1] as List<Order>? ?? [];

        if (products.isEmpty && orders.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (products.isNotEmpty) ...[
              _buildSectionHeader(context, 'Products'),
              ...products.map((p) => ListTile(
                    leading: p.images.isNotEmpty
                        ? Image.network(p.images.first,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.watch))
                        : const Icon(Icons.watch),
                    title: Text(p.name),
                    subtitle: Text('\$${p.price}'),
                    onTap: () {
                      close(context, {'type': 'product', 'data': p});
                    },
                  )),
            ],
            if (orders.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Orders'),
              ...orders.map((o) => ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text('Order #${o.id.substring(0, 8)}...'),
                    subtitle: Text(o.statusDisplay),
                    trailing: Text('\$${o.totalAmount}'),
                    onTap: () {
                      close(context, {'type': 'order', 'data': o});
                    },
                  )),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.search),
          title: const Text('Search Products, Orders...'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
      ),
    );
  }

  Future<List<Watch>> _searchProducts(String query) async {
    try {
      final result =
          await _adminService.getAllWatches(search: query, limit: 10);
      return (result['watches'] as List?)?.cast<Watch>() ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Order>> _searchOrders(String query) async {
    // Orders don't have a direct search in AdminService yet.
    // For now, return empty. Can be enhanced later.
    return [];
  }
}
