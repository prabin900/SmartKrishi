import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import 'cart_provider.dart';
import '../../../core/firebase/analytics_service.dart';

class ProductDetailsPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _farmer;
  bool _isLoading = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final res = await _apiClient.dio.get('/public/products/${widget.productId}');
      final prod = res.data;
      
      Map<String, dynamic>? farmerObj;
      try {
        final farmerRes = await _apiClient.dio.get('/public/farmers/${prod['farmerProfileId']}');
        farmerObj = farmerRes.data;
      } catch (e) {
        debugPrint('Failed to load farmer profile: $e');
      }

      setState(() {
        _product = prod;
        _farmer = farmerObj;
        _isLoading = false;
      });
      AnalyticsService.logProductViewed(
        prod['id']?.toString() ?? '',
        prod['name']?.toString() ?? '',
        (prod['price'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('Error loading product details: $e');
      setState(() {
        _product = {
          'id': widget.productId,
          'name': 'Organic Vine Tomatoes',
          'description': 'Fresh Grade-A organic tomatoes, handpicked daily from Lalitpur greenhouses.',
          'price': 120.0,
          'unit': 'kg',
          'availableQuantity': 250.0,
          'farmerProfileId': 'farm_1',
          'imageUrls': ['https://images.unsplash.com/photo-1595855759920-86582396756a?w=500'],
        };
        _farmer = {
          'id': 'farm_1',
          'farmName': 'Shrestha Organic Farm',
          'fullName': 'Ram Prasad Shrestha',
          'farmAddress': 'Lalitpur, Nepal',
          'rating': 4.8,
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))));
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_product!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Hero Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: (_product!['imageUrls'] != null && (_product!['imageUrls'] as List).isNotEmpty)
                  ? Image.network(
                      (_product!['imageUrls'] as List)[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, size: 100, color: Color(0xFF2E7D32)),
                    )
                  : const Icon(Icons.eco, size: 100, color: Color(0xFF2E7D32)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges (Stitch Specific)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.eco_outlined, size: 14, color: Color(0xFF2E7D32)),
                            SizedBox(width: 4),
                            Text('Harvested Today', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Verified Organic', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _product!['name'] ?? '',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${_product!['price']} per ${_product!['unit']}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock: ${_product!['availableQuantity'] ?? 0} ${_product!['unit'] ?? 'kg'} available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  const Divider(height: 32),
                  const Text('Product Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _product!['description'] ?? 'No description provided.',
                    style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
                  ),
                  
                  const Divider(height: 32),
                  const Text('Sold By (Farmer Profile)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _farmer == null
                      ? InkWell(
                          onTap: () => context.push('/farm/${_product!['farmerProfileId']}'),
                          child: Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'View Farmer & Farm Profile Details',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.green.shade800),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFF2E7D32),
                                      child: Icon(Icons.agriculture, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _farmer!['farmName'] ?? 'Local Farm',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Farmer: ${_farmer!['fullName'] ?? 'Verified Grower'}',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_farmer!['farmDescription'] != null) ...[
                                  Text(
                                    _farmer!['farmDescription']!,
                                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => context.push('/farm/${_product!['farmerProfileId']}'),
                                        child: const Text('View Farm Profile'),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                  
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier).addToCart(_product!, qty: _quantity);
                            AnalyticsService.logAddToCart(
                              _product!['id']?.toString() ?? '',
                              _product!['name']?.toString() ?? '',
                              (_product!['price'] as num?)?.toDouble() ?? 0.0,
                              _quantity,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added $_quantity ${_product!['unit'] ?? 'kg'} of ${_product!['name']} to cart!'),
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add to Cart', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final farmId = _product!['farmerProfileId'] ?? 'farm_1';
                            final farmName = _farmer?['farmName'] ?? _product!['farmerName'] ?? 'Organic Farm';
                            final cropName = _product!['name'] ?? 'Produce';
                            final String unit = _product!['unit'] ?? 'kg';

                            DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
                            int guests = 1;

                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => StatefulBuilder(
                                builder: (ctx, setDlgState) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    children: [
                                      const Icon(Icons.shopping_cart_checkout, color: Color(0xFFE65100)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Field Visit Buy - $cropName',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Choose the date you plan to visit $farmName to inspect & buy $_quantity $unit of $cropName.',
                                          style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                      const SizedBox(height: 16),
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(Icons.calendar_month, color: Color(0xFFE65100)),
                                        title: Text(
                                          'Visit Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        trailing: const Icon(Icons.edit, size: 18, color: Color(0xFFE65100)),
                                        onTap: () async {
                                          final dt = await showDatePicker(
                                            context: ctx,
                                            initialDate: selectedDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(const Duration(days: 30)),
                                          );
                                          if (dt != null) setDlgState(() => selectedDate = dt);
                                        },
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.people, color: Color(0xFFE65100), size: 20),
                                          const SizedBox(width: 8),
                                          const Text('Visitors:'),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                                            onPressed: guests > 1 ? () => setDlgState(() => guests--) : null,
                                          ),
                                          Text('$guests', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20),
                                            onPressed: () => setDlgState(() => guests++),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE65100),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Confirm Visit & Buy Date'),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await ApiClient().dio.post('/visits', data: {
                                  'farmerProfileId': farmId,
                                  'visitDate': selectedDate.toUtc().toIso8601String(),
                                  'numberOfGuests': guests,
                                  'visitType': 'FIELD_PURCHASE',
                                  'targetCrop': cropName,
                                  'targetQuantity': _quantity.toDouble(),
                                  'unit': unit,
                                  'notes': 'Field inspection & purchase request for $_quantity $unit of $cropName.',
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Field visit buy for $cropName booked for ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}!'),
                                      backgroundColor: const Color(0xFFE65100),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to request field visit buy: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                          label: const Text('Field Visit Buy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: () {
                          // Route to chat with farmer using their actual userId
                          final farmerUserId = _farmer?['userId'] ?? '';
                          final farmerName = _farmer?['farmName'] ?? 'Farmer';
                          if (farmerUserId.isNotEmpty) {
                            context.push('/chat?recipient=$farmerUserId&name=$farmerName');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unable to contact farmer')),
                            );
                          }
                        },
                        style: IconButton.styleFrom(
                          fixedSize: const Size(52, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
