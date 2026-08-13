import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _activeFilter = 'Price';

  final List<String> _recentSearches = ['Fresh Broccoli', 'Himalayan Honey', 'Dairy Farm'];
  final List<String> _filters = ['Price', 'Rating 4.5+', 'Distance', 'Organic', 'Direct Pickup'];

  final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': '1',
      'name': 'Organic Fuji Apples',
      'price': 180.0,
      'unit': 'kg',
      'rating': 4.8,
      'reviewCount': 120,
      'farm': 'Sharma Orchards',
      'badge': 'Organic',
      'badgeColor': 0xFFE8F5E9,
      'badgeTextColor': 0xFF2E7D32,
      'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400',
    },
    {
      'id': '2',
      'name': 'Crisp Green Apples',
      'price': 140.0,
      'unit': 'kg',
      'rating': 4.5,
      'reviewCount': 86,
      'farm': 'Green Valley Farms',
      'badge': 'Direct Pickup',
      'badgeColor': 0xFFF3E5F5,
      'badgeTextColor': 0xFF7B1FA2,
      'image': 'https://images.unsplash.com/photo-1576179635662-9d1983e97e1e?w=400',
    },
    {
      'id': '3',
      'name': 'Kashmir Red Delicious',
      'price': 220.0,
      'unit': 'kg',
      'rating': 4.9,
      'reviewCount': 210,
      'farm': 'Alpine Orchards',
      'badge': 'Harvested Today',
      'badgeColor': 0xFFFFF3E0,
      'badgeTextColor': 0xFFE65100,
      'image': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=400',
    },
    {
      'id': '4',
      'name': 'Organic Vine Tomatoes',
      'price': 120.0,
      'unit': 'kg',
      'rating': 4.7,
      'reviewCount': 95,
      'farm': 'Shrestha Organic Farm',
      'badge': 'Organic',
      'badgeColor': 0xFFE8F5E9,
      'badgeTextColor': 0xFF2E7D32,
      'image': 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=400',
    },
    {
      'id': '5',
      'name': 'Himalayan Buckwheat',
      'price': 85.0,
      'unit': 'kg',
      'rating': 4.3,
      'reviewCount': 42,
      'farm': 'Mustang Grains Co.',
      'badge': 'Verified Farmer',
      'badgeColor': 0xFFE3F2FD,
      'badgeTextColor': 0xFF1565C0,
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
    },
    {
      'id': '6',
      'name': 'Organic Spinach Bunch',
      'price': 60.0,
      'unit': 'bunch',
      'rating': 4.6,
      'reviewCount': 73,
      'farm': 'Valley Greens Farm',
      'badge': 'Harvested Today',
      'badgeColor': 0xFFFFF3E0,
      'badgeTextColor': 0xFFE65100,
      'image': 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400',
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_query.isEmpty) return _mockProducts;
    return _mockProducts
        .where((p) => (p['name'] as String).toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search products, farms, or categories...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF707A6C)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Color(0xFF707A6C)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                fillColor: const Color(0xFFF3F4F5),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Filter chips row
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final active = f == _activeFilter;
                return ChoiceChip(
                  label: Text(f),
                  selected: active,
                  onSelected: (_) => setState(() => _activeFilter = f),
                  selectedColor: const Color(0xFF9CF49C),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: active ? const Color(0xFF19722B) : const Color(0xFF40493D),
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(color: active ? const Color(0xFF9CF49C) : const Color(0xFFBFCABA)),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _query.isEmpty
                // Show recent searches when no query
                ? _buildRecentSearches()
                // Show results grid
                : _buildResultsGrid(filtered),
          ),
        ],
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          ..._recentSearches.asMap().entries.map((entry) {
            final i = entry.key;
            final search = entry.value;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.history, color: Color(0xFF707A6C)),
              title: Text(search, style: const TextStyle(color: Color(0xFF40493D))),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF707A6C), size: 16),
                onPressed: () => setState(() => _recentSearches.removeAt(i)),
                splashRadius: 16,
                tooltip: 'Remove',
              ),
              onTap: () {
                _searchController.text = search;
                setState(() => _query = search);
              },
            );
          }),
          const Divider(height: 32),
          Text('All Products (${_mockProducts.length} items)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(child: _buildResultsGrid(_mockProducts)),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(List<Map<String, dynamic>> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Search Results (${products.length} found)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) => _ProductCard(product: products[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
                    product['image'] as String,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 130,
                      color: const Color(0xFFE8F5E9),
                      child: const Icon(Icons.grass, color: Color(0xFF2E7D32), size: 40),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(product['badgeColor'] as int),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product['badge'] as String,
                        style: TextStyle(
                          color: Color(product['badgeTextColor'] as int),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, size: 16, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(product['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('रू ${product['price']?.toStringAsFixed(0)}/${product['unit']}',
                      style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB870), size: 14),
                      const SizedBox(width: 2),
                      Text('${product['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(' (${product['reviewCount']})', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
