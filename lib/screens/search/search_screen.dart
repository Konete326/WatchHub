import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/watch_provider.dart';
import '../../widgets/watch_card.dart';
import '../product/product_detail_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/neumorphic_widgets.dart';

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
  final List<String> _recentSearches = ['Rolex', 'Omega', 'Luxury', 'Classic'];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softUiBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Filter and Search Icon
            NeumorphicTopBar(
              title: 'Search',
              onBackTap: () => Navigator.pop(context),
              actions: [
                NeumorphicButton(
                  onTap: _showFilterBottomSheet,
                  padding: const EdgeInsets.all(10),
                  shape: BoxShape.circle,
                  child: Stack(
                    children: [
                      const Icon(Icons.filter_list_rounded,
                          color: AppTheme.softUiTextColor, size: 20),
                      if (_isFilterApplied)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Search Input Field (Concave Well)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: NeumorphicContainer(
                isConcave: true,
                borderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return await Provider.of<WatchProvider>(context,
                            listen: false)
                        .getSuggestions(textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    _searchController.text = selection;
                    _performSearch(selection);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
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
                      decoration: InputDecoration(
                        hintText: 'Search watches...',
                        hintStyle: TextStyle(
                            color: AppTheme.softUiTextColor.withOpacity(0.3),
                            fontSize: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        icon: Icon(Icons.search_rounded,
                            color: AppTheme.softUiTextColor.withOpacity(0.4)),
                      ),
                      style: const TextStyle(
                          color: AppTheme.softUiTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      onSubmitted: (value) {
                        _performSearch(value);
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 48),
                        child: NeumorphicContainer(
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option,
                                  style: const TextStyle(
                                      color: AppTheme.softUiTextColor,
                                      fontWeight: FontWeight.w500),
                                ),
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

            // Recent Searches (Convex Chips)
            _buildRecentSearches(),

            // Search Results
            Expanded(
              child: Consumer<WatchProvider>(
                builder: (context, watchProvider, child) {
                  if (watchProvider.isLoading) {
                    return _buildLoadingState();
                  }

                  if (watchProvider.watches.isEmpty) {
                    return _buildEmptyState();
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    physics: const BouncingScrollPhysics(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _recentSearches.length,
        itemBuilder: (context, index) {
          final term = _recentSearches[index];
          final isSelected = _searchController.text == term;
          return Padding(
            padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
            child: NeumorphicButton(
              onTap: () {
                _searchController.text = term;
                _performSearch(term);
                setState(() {});
              },
              isPressed: isSelected,
              borderRadius: BorderRadius.circular(15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  term,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.softUiTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isInitial = _searchController.text.isEmpty && !_isFilterApplied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(50),
              child: Icon(
                isInitial
                    ? Icons.manage_search_rounded
                    : Icons.search_off_rounded,
                size: 80,
                color: AppTheme.softUiTextColor.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              isInitial ? 'Search Luxury Watches' : 'No results found',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.softUiTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isInitial
                  ? 'Find your perfect timepiece by searching for brands, styles, or collections.'
                  : 'We couldn\'t find any watches matching your criteria. Try different keywords or reset filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.softUiTextColor.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            if (!isInitial) ...[
              const SizedBox(height: 48),
              NeumorphicButton(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _selectedBrandId = null;
                    _selectedCategory = null;
                    _priceRange = const RangeValues(0, 5000);
                    _isFilterApplied = false;
                  });
                  _performSearch('');
                },
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                borderRadius: BorderRadius.circular(20),
                child: const Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => NeumorphicContainer(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final watchProvider = Provider.of<WatchProvider>(context);
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: AppTheme.softUiBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.softUiTextColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Filters',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.softUiTextColor,
                                ),
                              ),
                              NeumorphicButton(
                                onTap: () {
                                  setModalState(() {
                                    _selectedBrandId = null;
                                    _selectedCategory = null;
                                    _priceRange = const RangeValues(0, 5000);
                                    _isFilterApplied = false;
                                  });
                                },
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                borderRadius: BorderRadius.circular(10),
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    color: AppTheme.softUiTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          _buildFilterSection(
                            'Category',
                            watchProvider.categories.map((cat) {
                              final isSelected = _selectedCategory == cat.name;
                              return Padding(
                                padding: const EdgeInsets.only(
                                    right: 12, bottom: 12),
                                child: NeumorphicButton(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedCategory =
                                          isSelected ? null : cat.name;
                                    });
                                  },
                                  isPressed: isSelected,
                                  borderRadius: BorderRadius.circular(12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.softUiTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                          _buildFilterSection(
                            'Brand',
                            watchProvider.brands.map((brand) {
                              final isSelected = _selectedBrandId == brand.id;
                              return Padding(
                                padding: const EdgeInsets.only(
                                    right: 12, bottom: 12),
                                child: NeumorphicButton(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedBrandId =
                                          isSelected ? null : brand.id;
                                    });
                                  },
                                  isPressed: isSelected,
                                  borderRadius: BorderRadius.circular(12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Text(
                                    brand.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.softUiTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Price Range',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.softUiTextColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          NeumorphicContainer(
                            isConcave: true,
                            padding: const EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(20),
                            child: RangeSlider(
                              values: _priceRange,
                              min: 0,
                              max: 5000,
                              divisions: 50,
                              activeColor: AppTheme.primaryColor,
                              inactiveColor:
                                  AppTheme.softUiTextColor.withOpacity(0.1),
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
                          ),
                          const SizedBox(height: 48),
                          NeumorphicButton(
                            onTap: () {
                              setState(() {
                                _isFilterApplied = _selectedBrandId != null ||
                                    _selectedCategory != null ||
                                    _priceRange.start > 0 ||
                                    _priceRange.end < 5000;
                              });
                              _performSearch(_searchController.text);
                              Navigator.pop(context);
                            },
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            borderRadius: BorderRadius.circular(15),
                            child: const Center(
                              child: Text(
                                'Apply Filters',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
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
  }

  Widget _buildFilterSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.softUiTextColor,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(children: children),
      ],
    );
  }
}
