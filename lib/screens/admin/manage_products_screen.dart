import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../models/watch.dart';
import 'add_edit_product_screen.dart';
import '../../widgets/admin/admin_layout.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<Watch> _watches = [];
  final Set<String> _selectedIds = {};
  bool _isBulkMode = false;
  bool _isLoading = false;
  // ignore: unused_field
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

  Future<void> _loadWatches(
      {int page = 1, String? search, bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _watches = [];
          _selectedIds.clear();
        });
      }
      page = 1;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = page;
      });
    }

    try {
      final result = await _adminService.getAllWatches(
        page: page,
        limit: 20,
        search: search,
      );

      if (mounted) {
        setState(() {
          final watchesData = result['watches'];
          if (watchesData != null && watchesData is List) {
            _watches = watchesData.cast<Watch>();
          } else {
            _watches = [];
          }

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

  // Removed duplicate _bulkDelete

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

    return AdminLayout(
      title: 'Manage Products',
      currentRoute: '/admin/products',
      actions: [
        if (_selectedIds.isNotEmpty) ...[
          // Bulk Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.blue),
            tooltip: 'Bulk Actions',
            onSelected: (value) => _performBulkAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'publish',
                  child: Row(children: [
                    Icon(Icons.public, size: 18),
                    SizedBox(width: 8),
                    Text('Publish Selected')
                  ])),
              const PopupMenuItem(
                  value: 'unpublish',
                  child: Row(children: [
                    Icon(Icons.public_off, size: 18),
                    SizedBox(width: 8),
                    Text('Unpublish Selected')
                  ])),
              const PopupMenuItem(
                  value: 'stock_add',
                  child: Row(children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Add Stock (+10)')
                  ])),
              const PopupMenuItem(
                  value: 'stock_reduce',
                  child: Row(children: [
                    Icon(Icons.remove, size: 18),
                    SizedBox(width: 8),
                    Text('Reduce Stock (-10)')
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete Selected', style: TextStyle(color: Colors.red))
                  ])),
            ],
          ),
        ],
        IconButton(
          icon: const Icon(Icons.add_rounded),
          onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddEditProductScreen()))
              .then((_) => _loadWatches(refresh: true)),
          tooltip: 'Add Product',
        ),
      ],
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products by name, SKU...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onSubmitted: _onSearch,
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionMenu(),
              ],
            ),
          ),

          // Count & Bulk Mode Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found $_total products',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _isBulkMode = !_isBulkMode;
                    if (!_isBulkMode) _selectedIds.clear();
                  }),
                  icon: Icon(
                      _isBulkMode
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18),
                  label: Text(_isBulkMode ? 'Disable Select' : 'Enable Select'),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading && _watches.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _watches.isEmpty
                    ? Center(
                        child: Text(_searchQuery != null
                            ? 'No matches found'
                            : 'No products available'))
                    : RefreshIndicator(
                        onRefresh: () => _loadWatches(
                            page: _currentPage, search: _searchQuery),
                        child: ListView.builder(
                          itemCount: _watches.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final watch = _watches[index];
                            bool isSelected = _selectedIds.contains(watch.id);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1),
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isBulkMode)
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              _selectedIds.add(watch.id);
                                            } else {
                                              _selectedIds.remove(watch.id);
                                            }
                                          });
                                        },
                                      ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: watch.images.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: watch.images.first,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey.shade100),
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Text(watch.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    if (watch.status != 'PUBLISHED')
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(watch.status,
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange.shade800,
                                                fontWeight: FontWeight.bold)),
                                      )
                                  ],
                                ),
                                subtitle: Text(
                                    'Stock: ${watch.stock} | ${currencyFormat.format(watch.price)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      AddEditProductScreen(
                                                          watch: watch)))
                                          .then((_) => _loadWatches()),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        if (value == 'export') {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exporting to Excel...')));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'export', child: Text('Export to Excel')),
        const PopupMenuItem(value: 'import', child: Text('Bulk Import (CSV)')),
      ],
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 1
                ? () =>
                    _loadWatches(page: _currentPage - 1, search: _searchQuery)
                : null,
          ),
          Text('Page $_currentPage of $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < _totalPages
                ? () =>
                    _loadWatches(page: _currentPage + 1, search: _searchQuery)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkAction(String action) async {
    setState(() => _isLoading = true);
    try {
      if (action == 'delete') {
        await _bulkDelete();
      } else if (action == 'publish') {
        await _adminService
            .bulkUpdateProducts(_selectedIds.toList(), {'status': 'PUBLISHED'});
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Products Published')));
      } else if (action == 'unpublish') {
        await _adminService
            .bulkUpdateProducts(_selectedIds.toList(), {'status': 'DRAFT'});
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Products Unpublished')));
      } else if (action == 'stock_add') {
        await _adminService.bulkUpdateStock(_selectedIds.toList(), 10);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Stock Increased')));
      } else if (action == 'stock_reduce') {
        await _adminService.bulkUpdateStock(_selectedIds.toList(), -10);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Stock Reduced')));
      }
      _loadWatches(refresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Action failed: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Delete'),
        content: Text(
            'Are you sure you want to delete ${_selectedIds.length} products?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _adminService.deleteMultipleWatches(_selectedIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected products deleted')),
        );
      }
    }
  }
}
