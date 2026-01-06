import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/watch_provider.dart';
import '../../widgets/watch_card.dart';
import '../product/product_detail_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedBrandId;
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 5000);
  bool _isFilterApplied = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final watchProvider = Provider.of<WatchProvider>(context, listen: false);
      watchProvider.fetchBrands();
      watchProvider.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    Provider.of<WatchProvider>(context, listen: false).fetchWatches(
      refresh: true,
      search: query.isEmpty ? null : query.trim(),
      brandId: _selectedBrandId,
      category: _selectedCategory,
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 5000 ? _priceRange.end : null,
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final watchProvider = Provider.of<WatchProvider>(context);
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedBrandId = null;
                                _selectedCategory = null;
                                _priceRange = const RangeValues(0, 5000);
                                _isFilterApplied = false;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: watchProvider.categories.map((cat) {
                          final isSelected = _selectedCategory == cat.name;
                          return ChoiceChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedCategory = selected ? cat.name : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Brand',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: watchProvider.brands.map((brand) {
                          final isSelected = _selectedBrandId == brand.id;
                          return ChoiceChip(
                            label: Text(brand.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedBrandId = selected ? brand.id : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 5000,
                        divisions: 50,
                        labels: RangeLabels(
                          '\$${_priceRange.start.round()}',
                          '\$${_priceRange.end.round()}',
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isFilterApplied = _selectedBrandId != null ||
                                  _selectedCategory != null ||
                                  _priceRange.start > 0 ||
                                  _priceRange.end < 5000;
                            });
                            _performSearch(_searchController.text);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return await Provider.of<WatchProvider>(context, listen: false)
                    .getSuggestions(textEditingValue.text);
              },
              onSelected: (String selection) {
                _searchController.text = selection;
                _performSearch(selection);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                // Sync the local controller with autocomplete controller
                if (_searchController.text.isNotEmpty &&
                    controller.text.isEmpty) {
                  controller.text = _searchController.text;
                }
                controller.addListener(() {
                  _searchController.text = controller.text;
                });

                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search watches...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: const TextStyle(
                      color: AppTheme.textPrimaryColor, fontSize: 16),
                  onSubmitted: (value) {
                    _performSearch(value);
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 100,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return ListTile(
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_isFilterApplied)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: Consumer<WatchProvider>(
        builder: (context, watchProvider, child) {
          if (watchProvider.isLoading) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ProductCardShimmer(),
            );
          }

          if (watchProvider.watches.isEmpty) {
            final isInitial =
                _searchController.text.isEmpty && !_isFilterApplied;
            return EmptyState(
              icon: isInitial
                  ? Icons.manage_search_rounded
                  : Icons.search_off_rounded,
              title: isInitial ? 'Search Luxury Watches' : 'No results found',
              message: isInitial
                  ? 'Find your perfect timepiece by searching for brands, styles, or collections.'
                  : 'We couldn\'t find any watches matching your criteria. Try different keywords or reset filters.',
              actionLabel: isInitial ? null : 'Reset Filters',
              onActionPressed: isInitial
                  ? null
                  : () {
                      setState(() {
                        _searchController.clear();
                        _selectedBrandId = null;
                        _selectedCategory = null;
                        _priceRange = const RangeValues(0, 5000);
                        _isFilterApplied = false;
                      });
                      _performSearch('');
                    },
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: watchProvider.watches.length,
            itemBuilder: (context, index) {
              final watch = watchProvider.watches[index];
              return WatchCard(
                watch: watch,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(watchId: watch.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
