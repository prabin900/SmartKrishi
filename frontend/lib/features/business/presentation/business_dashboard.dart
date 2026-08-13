import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../customer/presentation/cart_provider.dart';

class BusinessDashboard extends ConsumerStatefulWidget {
  const BusinessDashboard({super.key});

  @override
  ConsumerState<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends ConsumerState<BusinessDashboard> {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<dynamic> _contracts = [];
  List<dynamic> _suppliers = []; // filtered list of farmers
  List<dynamic> _allFarmers = []; // cached complete list of farmers

  final TextEditingController _farmerSearchController = TextEditingController();
  final TextEditingController _produceSearchController = TextEditingController();

  String _selectedFarmerFilter = 'All';
  String _selectedProduceCategory = 'All';
  List<dynamic> _businessVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  @override
  void dispose() {
    _farmerSearchController.dispose();
    _produceSearchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _seedProduce = [
    {
      'id': 'seed_prod_1',
      'name': 'Organic Vine Tomatoes',
      'description': 'Fresh Grade-A organic tomatoes, handpicked daily from Lalitpur greenhouses.',
      'price': 120.0,
      'unit': 'kg',
      'availableQuantity': 250.0,
      'city': 'Lalitpur',
      'organic': true,
      'imageUrls': ['https://images.unsplash.com/photo-1595855759920-86582396756a?w=500'],
      'farmerName': 'Shrestha Organic Farm',
      'category': 'Vegetables',
    },
    {
      'id': 'seed_prod_2',
      'name': 'Himalayan Organic Apples',
      'description': 'Crisp, sweet red apples harvested from Mustang mountain orchards.',
      'price': 220.0,
      'unit': 'kg',
      'availableQuantity': 180.0,
      'city': 'Mustang',
      'organic': true,
      'imageUrls': ['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500'],
      'farmerName': 'Himalayan Orchard',
      'category': 'Fruits',
    },
    {
      'id': 'seed_prod_3',
      'name': 'Fresh Red Onions',
      'description': 'High-quality cooking onions grown using traditional organic composting.',
      'price': 85.0,
      'unit': 'kg',
      'availableQuantity': 500.0,
      'city': 'Bhaktapur',
      'organic': true,
      'imageUrls': ['https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=500'],
      'farmerName': 'Bhaktapur Agro',
      'category': 'Vegetables',
    },
    {
      'id': 'seed_prod_4',
      'name': 'Premium Basmati Rice',
      'description': 'Aromatic long-grain basmati rice processed directly from Terai mills.',
      'price': 150.0,
      'unit': 'kg',
      'availableQuantity': 1000.0,
      'city': 'Chitwan',
      'organic': false,
      'imageUrls': ['https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500'],
      'farmerName': 'Terai Grain Co.',
      'category': 'Grains',
    },
  ];

  void _bookDirectFieldVisit(Map<String, dynamic> product) {
    final farmName = product['farmerName'] ?? 'Farmer Field';
    final cropName = product['name'] ?? 'Crop';
    final farmerProfileId = product['farmerProfileId'] ?? '';

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int guestCount = 2;
    TextEditingController notesController = TextEditingController(
      text: 'Business inspection & direct field purchase of $cropName.',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Direct Field Purchase - $cropName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schedule a field visit to inspect and buy $cropName directly from $farmName.',
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month, color: Color(0xFF2E7D32)),
                title: Text('Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () async {
                  final dt = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (dt != null) setDlgState(() => selectedDate = dt);
                },
              ),
              Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 12),
                  const Text('Inspectors/Buyers:'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (guestCount > 1) setDlgState(() => guestCount--);
                    },
                  ),
                  Text('$guestCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setDlgState(() => guestCount++),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Visit Notes / Target Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final double qty = (product['availableQuantity'] as num?)?.toDouble() ?? 100.0;
                  final String unitStr = product['unit'] ?? 'kg';
                  await _apiClient.dio.post('/visits', data: {
                    'farmerProfileId': farmerProfileId.isNotEmpty ? farmerProfileId : 'farm_1',
                    'visitDate': selectedDate.toUtc().toIso8601String(),
                    'numberOfGuests': guestCount,
                    'visitType': 'FIELD_PURCHASE',
                    'targetCrop': cropName,
                    'targetQuantity': qty,
                    'unit': unitStr,
                    'notes': notesController.text,
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Field purchase visit request submitted!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('Confirm Field Visit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);
    try {
      try {
        await _apiClient.dio.post('/auth/register', data: {
          'email': 'business@smartkrishi.com.np',
          'password': 'password123',
          'fullName': 'Kathmandu Marriott Hotel',
          'phoneNumber': '01-5970050',
          'role': 'BUSINESS',
          'companyName': 'Kathmandu Marriott Hotel',
          'registrationNumber': 'PAN-60601243',
          'businessType': 'HOTEL',
        });
      } catch (_) {}

      final contractsRes = await _apiClient.dio.get('/contracts/business');
      final farmersRes = await _apiClient.dio.get('/public/farmers');
      final prodsRes = await _apiClient.dio.get('/public/products');

      final List<dynamic> realFarmers = farmersRes.data ?? [];
      final List<dynamic> realProducts = prodsRes.data ?? [];
      final List<dynamic> combinedProducts = realProducts.isNotEmpty ? realProducts : _seedProduce;

      List<dynamic> realVisits = [];
      try {
        final visitsRes = await _apiClient.dio.get('/visits/customer');
        realVisits = List.from(visitsRes.data ?? []);
      } catch (_) {}

      setState(() {
        _contracts = contractsRes.data ?? [];
        _allFarmers = realFarmers;
        _suppliers = realFarmers;
        _products = combinedProducts;
        _filteredProducts = combinedProducts;
        _businessVisits = realVisits;
        _isLoading = false;
      });
      _filterFarmers(_farmerSearchController.text);
      _filterProduce(_produceSearchController.text);
    } catch (e) {
      setState(() {
        _products = _seedProduce;
        _filteredProducts = _seedProduce;
        _isLoading = false;
      });
    }
  }

  void _filterFarmers(String query) {
    List<dynamic> results = _allFarmers;

    if (_selectedFarmerFilter == 'Verified') {
      results = results.where((f) => f['verified'] == true).toList();
    }

    if (query.trim().isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      results = results.where((f) {
        final name = (f['farmName'] as String? ?? '').toLowerCase();
        final desc = (f['farmDescription'] as String? ?? '').toLowerCase();
        final address = (f['farmAddress'] as String? ?? '').toLowerCase();
        return name.contains(lowercaseQuery) ||
            desc.contains(lowercaseQuery) ||
            address.contains(lowercaseQuery);
      }).toList();
    }

    setState(() {
      _suppliers = results;
    });
  }

  void _filterProduce(String query) {
    List<dynamic> results = _products;

    if (_selectedProduceCategory != 'All') {
      results = results.where((p) => (p['category'] ?? p['categoryName'] ?? 'Vegetables') == _selectedProduceCategory).toList();
    }

    if (query.trim().isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      results = results.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final desc = (p['description'] as String? ?? '').toLowerCase();
        final city = (p['city'] as String? ?? '').toLowerCase();
        return name.contains(lowercaseQuery) ||
            desc.contains(lowercaseQuery) ||
            city.contains(lowercaseQuery);
      }).toList();
    }

    setState(() {
      _filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D631B))));
    }

    final cartCount = ref.watch(cartProvider.notifier).getCartCount();

    final pages = [
      _buildProduceMarketplaceTab(),
      _buildContractsTab(),
      _buildSuppliersTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/checkout'),
                tooltip: 'Business Cart & Checkout',
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/contracts/create');
                if (mounted) {
                  _loadBusinessData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Request Pre-Crop'),
              backgroundColor: const Color(0xFF0D631B),
              foregroundColor: Colors.white,
            )
          : _currentIndex == 0 && cartCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/checkout'),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text('Checkout Cart ($cartCount)'),
                  backgroundColor: const Color(0xFF0D631B),
                  foregroundColor: Colors.white,
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Produce Orders'),
          NavigationDestination(icon: Icon(Icons.handshake_outlined), label: 'Contract Farming'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Find Farmers'),
        ],
      ),
    );
  }

  Widget _buildProduceMarketplaceTab() {
    final categories = ['All', 'Vegetables', 'Fruits', 'Grains'];

    return Column(
      children: [
        // Produce Header & Search Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bulk Produce Marketplace',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D631B)),
              ),
              const SizedBox(height: 4),
              const Text('Search and order fresh farm produce directly for your business.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: _produceSearchController,
                decoration: InputDecoration(
                  labelText: 'Search produce (e.g. Tomatoes, Apples, Terai)...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0D631B)),
                  suffixIcon: _produceSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _produceSearchController.clear();
                            _filterProduce('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (q) => _filterProduce(q),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final selected = _selectedProduceCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: const Color(0xFFD4F0D4),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedProduceCategory = cat);
                            _filterProduce(_produceSearchController.text);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        _buildBusinessVisitsSection(),

        // Product Grid / List
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(child: Text('No produce found matching your search.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, idx) {
                    final p = _filteredProducts[idx];
                    final String imageUrl = (p['imageUrls'] != null && (p['imageUrls'] as List).isNotEmpty)
                        ? p['imageUrls'][0]
                        : 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=500';

                    final double price = (p['price'] as num?)?.toDouble() ?? 100.0;
                    final String unit = p['unit'] ?? 'kg';
                    final double qty = (p['availableQuantity'] as num?)?.toDouble() ?? 100.0;
                    final bool isOrganic = p['organic'] == true;

                    final farmProfileId = p['farmerProfileId'] ?? 'farm_1';
                    final farmerName = p['farmerName'] ?? 'Local Farmer';
                    final productId = p['id'] ?? 'seed_prod_1';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => context.push('/product/$productId'),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.eco, color: Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p['name'] ?? 'Fresh Crop',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (isOrganic)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                                child: const Text('🌿 Organic', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                              ),
                                            if (p['farmVisitAvailable'] == true || p['pickupAvailable'] == true) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                                child: const Text('📍 Direct Field Buy', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Clickable Farmer Badge
                                    InkWell(
                                      onTap: () => context.push('/farm/$farmProfileId'),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.agriculture, size: 14, color: Color(0xFF0D631B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            farmerName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D631B),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right, size: 14, color: Color(0xFF0D631B)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rs. $price / $unit • Available: $qty $unit',
                                      style: const TextStyle(color: Color(0xFF0D631B), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p['description'] ?? 'Direct farm produce',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => context.push('/farm/$farmProfileId'),
                                          icon: const Icon(Icons.store, size: 14),
                                          label: const Text('Farmer Profile'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1B5E20),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            ref.read(cartProvider.notifier).addToCart(p);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Added ${p['name']} to Business Cart!'),
                                                backgroundColor: const Color(0xFF0D631B),
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                                          label: const Text('Add to Cart'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF0D631B),
                                            side: const BorderSide(color: Color(0xFF0D631B)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        if (p['farmVisitAvailable'] == true || p['pickupAvailable'] == true)
                                          ElevatedButton.icon(
                                            onPressed: () => _bookDirectFieldVisit(p),
                                            icon: const Icon(Icons.nature_people, size: 14),
                                            label: const Text('Field Visit Buy'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFE65100),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                          ),
                                        ElevatedButton(
                                          onPressed: () {
                                            ref.read(cartProvider.notifier).addToCart(p);
                                            context.push('/checkout');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0D631B),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: const Text('Order Now'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildContractsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pre-Planting Crop Contracts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D631B)),
          ),
          const SizedBox(height: 8),
          const Text('Secure your supply chain by entering pre-harvest crop contracts directly with certified local farmers.'),
          const SizedBox(height: 20),
          _contracts.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No crop requisitions created yet.')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _contracts.length,
                  itemBuilder: (context, idx) {
                    final contract = _contracts[idx];
                    final bool organic = contract['organicOnly'] ?? true;
                    final bool aGrade = contract['aGradeOnly'] ?? true;
                    final bool directPickup = contract['directPickupRequired'] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Crop: ${contract['cropName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: contract['accepted'] == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    contract['status'] ?? 'REQUESTED',
                                    style: TextStyle(
                                      color: contract['accepted'] == true ? const Color(0xFF0D631B) : Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Target: ${contract['targetQuantity']} ${contract['unit']} • Harvest Month: ${contract['harvestMonth']}'),
                            Text('Proposed Price: Rs. ${contract['expectedPrice']} per ${contract['unit']}'),
                            const SizedBox(height: 10),

                            // Quality Standards Badges
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (organic)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('🌿 Organic Only', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ),
                                if (aGrade)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('⭐ A-Grade Certified', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ),
                                if (directPickup)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('🚜 Direct Pickup Required', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSuppliersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _farmerSearchController,
                decoration: InputDecoration(
                  labelText: 'Search Farmers by name, location, or crop focus...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0D631B)),
                  suffixIcon: _farmerSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _farmerSearchController.clear();
                            _filterFarmers('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (query) => _filterFarmers(query),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Farmers'),
                    selected: _selectedFarmerFilter == 'All',
                    selectedColor: const Color(0xFFD4F0D4),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFarmerFilter = 'All');
                        _filterFarmers(_farmerSearchController.text);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Verified Only'),
                    selected: _selectedFarmerFilter == 'Verified',
                    selectedColor: const Color(0xFFD4F0D4),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFarmerFilter = 'Verified');
                        _filterFarmers(_farmerSearchController.text);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _suppliers.isEmpty
              ? const Center(child: Text('No farmers found matching search.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _suppliers.length,
                  itemBuilder: (context, idx) {
                    final supplier = _suppliers[idx];
                    final farmId = supplier['id'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: farmId.isNotEmpty
                            ? () => context.push('/farm/$farmId')
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFE8F5E9),
                                    radius: 24,
                                    child: Icon(Icons.agriculture, color: Color(0xFF0D631B), size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          supplier['farmName'] ?? 'Unnamed Farm',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              supplier['farmAddress'] ?? 'No address',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (supplier['verified'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.verified, size: 12, color: Color(0xFF2E7D32)),
                                          SizedBox(width: 4),
                                          Text('Verified', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (supplier['farmDescription'] != null && (supplier['farmDescription'] as String).isNotEmpty) ...[
                                Text(
                                  supplier['farmDescription'],
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // View Profile Button
                                  ElevatedButton.icon(
                                    onPressed: farmId.isNotEmpty
                                        ? () => context.push('/farm/$farmId')
                                        : null,
                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                    label: const Text('View Profile'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => context.push('/chat?recipient=${supplier['userId']}&name=${Uri.encodeComponent(supplier['farmName'] ?? 'Farmer')}'),
                                    icon: const Icon(Icons.chat_outlined, size: 16),
                                    label: const Text('Chat'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0D631B),
                                      side: const BorderSide(color: Color(0xFF0D631B)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await context.push('/contracts/create?farmerProfileId=${supplier['id']}');
                                      _loadBusinessData();
                                    },
                                    icon: const Icon(Icons.handshake_outlined, size: 16),
                                    label: const Text('Contract'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0D631B),
                                      side: const BorderSide(color: Color(0xFF0D631B)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBusinessVisitsSection() {
    if (_businessVisits.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.shopping_cart_checkout, color: Color(0xFFE65100)),
        title: Text(
          'My Field Purchase Visits (${_businessVisits.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
        ),
        subtitle: const Text('Track direct farm visit buying requests & farmer status', style: TextStyle(fontSize: 11, color: Colors.black87)),
        children: _businessVisits.map((visit) {
          final String status = (visit['status'] ?? 'PENDING').toString().toUpperCase();
          final bool isAccepted = status == 'ACCEPTED' || status == 'CONFIRMED';
          final bool isCompleted = status == 'COMPLETED' || status == 'PURCHASED';
          final bool isDeclined = status == 'DECLINED' || status == 'CANCELLED';

          Color statusBg = Colors.amber.shade100;
          Color statusText = Colors.amber.shade900;
          String statusDisplay = 'Pending Approval';

          if (isDeclined) {
            statusBg = Colors.red.shade100;
            statusText = Colors.red.shade900;
            statusDisplay = '❌ Declined by Farmer';
          } else if (isCompleted) {
            statusBg = Colors.green.shade100;
            statusText = Colors.green.shade900;
            statusDisplay = '🎉 Purchased & Completed';
          } else if (isAccepted) {
            statusBg = Colors.blue.shade100;
            statusText = Colors.blue.shade900;
            statusDisplay = '✅ Approved by Farmer (Ready)';
          }

          String dateFormatted = '';
          if (visit['visitDate'] != null) {
            try {
              final dt = DateTime.parse(visit['visitDate']).toLocal();
              dateFormatted = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            } catch (_) {
              dateFormatted = visit['visitDate'].toString();
            }
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Target Crop: ${visit['targetCrop'] ?? 'Fresh Produce'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(statusDisplay, style: TextStyle(color: statusText, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Target Quantity: ${visit['targetQuantity'] ?? ''} ${visit['unit'] ?? 'kg'} • Date: $dateFormatted',
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                if (visit['notes'] != null && (visit['notes'] as String).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Notes: ${visit['notes']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                ],
                if (isAccepted) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pin, size: 14, color: Color(0xFFE65100)),
                        const SizedBox(width: 4),
                        Text('Show Farmer OTP PIN: ${visit['otpCode'] ?? '1234'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFE65100))),
                      ],
                    ),
                  ),
                ],
                if (isDeclined) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (visit['declineReason'] != null && (visit['declineReason'] as String).isNotEmpty)
                                ? 'Reason for decline: ${visit['declineReason']}'
                                : 'Reason for decline: Farmer was unable to accept this field purchase buy request at this time.',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
