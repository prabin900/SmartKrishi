import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 'SK-9081',
      'date': '16 July 2026',
      'product': 'Organic Vine Tomatoes',
      'quantity': '20 kg',
      'total': 1800.0,
      'status': 'Dispatched',
      'color': Colors.orange
    },
    {
      'id': 'SK-8972',
      'date': '12 July 2026',
      'product': 'Mustang Highland Apples',
      'quantity': '10 kg',
      'total': 2200.0,
      'status': 'Completed',
      'color': Colors.green
    },
    {
      'id': 'SK-8721',
      'date': '05 July 2026',
      'product': 'Organic Spinach (Rayoko Saag)',
      'quantity': '15 kg',
      'total': 1200.0,
      'status': 'Completed',
      'color': Colors.green
    },
    {
      'id': 'SK-8610',
      'date': '28 June 2026',
      'product': 'Highland Buckwheat (Phapar)',
      'quantity': '50 kg',
      'total': 7500.0,
      'status': 'Pending',
      'color': Colors.blue
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Color(0xFF2E7D32)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report exported successfully!'), backgroundColor: Color(0xFF2E7D32)),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Statistics (Bento Grid)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics_outlined, size: 20, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text('Total Orders', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('1,284', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.trending_up, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text('+12% this month', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 20, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 8),
                            Text('Revenue', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('रू 4.5L', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.trending_up, size: 16, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Text('+8% this month', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar & Headers
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search orders, crop name...',
                fillColor: const Color(0xFFF8F9FA),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Transactions Listing
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockOrders.length,
              itemBuilder: (context, idx) {
                final order = _mockOrders[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(order['id'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            Text(order['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(order['product'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Quantity: ${order['quantity']}', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rs. ${order['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (order['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                order['status'] ?? '',
                                style: TextStyle(color: order['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
