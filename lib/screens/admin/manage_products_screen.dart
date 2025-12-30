import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../models/watch.dart';
import '../../utils/theme.dart';

import 'add_edit_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<Watch> _watches = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadWatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWatches({int page = 1, String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
    });

    try {
      final result = await _adminService.getAllWatches(
        page: page,
        limit: 20,
        search: search,
      );

      if (mounted) {
        setState(() {
          final watchesData = result['watches'];
          _watches = watchesData != null && watchesData is List
              ? (watchesData as List)
                  .map((json) => Watch.fromJson(json as Map<String, dynamic>))
                  .toList()
              : [];

          final pagination = result['pagination'];
          if (pagination != null) {
            _totalPages = pagination['totalPages'] ?? 1;
            _total = pagination['total'] ?? 0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load watches: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteWatch(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Watch'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteWatch(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Watch deleted successfully')),
          );
          _loadWatches(page: _currentPage, search: _searchQuery);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete watch: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadWatches(page: 1, search: _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddEditProductScreen(),
                ),
              );
              if (result == true) {
                _loadWatches(page: _currentPage, search: _searchQuery);
              }
            },
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search watches...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _onSearch,
              onChanged: (value) {
                if (value.isEmpty) {
                  _onSearch('');
                }
              },
            ),
          ),

          // Results count
          if (!_isLoading && _watches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Found $_total watch${_total != 1 ? 'es' : ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),

          // Content
          Expanded(
            child: _isLoading && _watches.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadWatches(
                                  page: _currentPage, search: _searchQuery),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _watches.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.watch_off,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No watches found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadWatches(
                                page: _currentPage, search: _searchQuery),
                            child: ListView.builder(
                              itemCount: _watches.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final watch = _watches[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: watch.images.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: watch.images.first,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.watch,
                                                          size: 40),
                                            ),
                                          )
                                        : const Icon(Icons.watch, size: 40),
                                    title: Text(
                                      watch.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (watch.brand != null)
                                          Text('Brand: ${watch.brand!.name}'),
                                        Text(
                                            'Price: ${currencyFormat.format(watch.price)}'),
                                        Text('Stock: ${watch.stock}'),
                                        if (watch.isLowStock)
                                          Text(
                                            'Low Stock!',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () async {
                                            final result =
                                                await Navigator.of(context)
                                                    .push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AddEditProductScreen(
                                                        watch: watch),
                                              ),
                                            );
                                            if (result == true) {
                                              _loadWatches(
                                                  page: _currentPage,
                                                  search: _searchQuery);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteWatch(
                                              watch.id, watch.name),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),

          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () => _loadWatches(
                            page: _currentPage - 1, search: _searchQuery)
                        : null,
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () => _loadWatches(
                            page: _currentPage + 1, search: _searchQuery)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
