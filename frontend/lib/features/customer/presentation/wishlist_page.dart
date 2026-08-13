import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class WishlistPage extends ConsumerStatefulWidget {
  const WishlistPage({super.key});

  @override
  ConsumerState<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends ConsumerState<WishlistPage> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _wishlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final response = await _apiClient.dio.get('/products');
      final list = response.data as List<dynamic>;

      // Mock user wishlist items
      setState(() {
        _wishlistItems = list.take(2).toList(); // grab first two products as mock wishlist
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _removeItem(String id) {
    setState(() {
      _wishlistItems.removeWhere((item) => item['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item removed from wishlist')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _wishlistItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Your wishlist is empty.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wishlistItems.length,
                  itemBuilder: (context, idx) {
                    final item = _wishlistItems[idx];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Rs. ${item['price']} per ${item['unit']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF2E7D32)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Added to Shopping Cart!'), backgroundColor: Color(0xFF2E7D32)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeItem(item['id']),
                            )
                          ],
                        ),
                        onTap: () => context.push('/product/${item['id']}'),
                      ),
                    );
                  },
                ),
    );
  }
}
