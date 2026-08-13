import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class TodaysEarningsPage extends StatefulWidget {
  const TodaysEarningsPage({super.key});

  @override
  State<TodaysEarningsPage> createState() => _TodaysEarningsPageState();
}

class _TodaysEarningsPageState extends State<TodaysEarningsPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveries = [];

  // Earned per delivery (simple flat rate: Rs 150 base + 5 per km approx)
  static const double _baseRate = 150.0;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/delivery/history');
      final List<dynamic> orders = res.data;
      setState(() {
        _deliveries = _buildDeliveries(orders);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Earnings load error: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _buildDeliveries(List<dynamic> orders) {
    return orders.map((o) {
      final items = o['items'] as List? ?? [];
      final productName = items.isNotEmpty
          ? (items.first['productName'] as String? ?? 'Delivery')
          : 'Delivery';
      final qty = items.isNotEmpty
          ? '${(items.first['quantity'] as num?)?.toStringAsFixed(0) ?? '?'} ${items.first['unit'] ?? 'units'}'
          : '';
      final orderId = (o['id'] as String? ?? '').substring(0, 8).toUpperCase();
      final total = ((o['total'] as num?)?.toDouble() ?? 0.0);
      // Delivery fee is a portion of order total as commission
      final earned = (o['deliveryFee'] as num?)?.toDouble() ?? _baseRate;
      final createdAt = o['createdAt'] as String? ?? '';
      final timeLabel = _formatTime(createdAt);

      return {
        'title': productName,
        'qty': qty,
        'orderId': 'SK-$orderId',
        'amount': 'रू ${earned.toStringAsFixed(0)}',
        'earned': earned,
        'time': timeLabel,
        'orderTotal': total,
        'status': o['status'] as String? ?? 'DELIVERED',
      };
    }).toList();
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayDeliveries = _deliveries;

    final double totalEarned = todayDeliveries.fold(0.0, (s, d) => s + (d['earned'] as double));
    const double weeklyTarget = 7000.0;
    final double progress = (totalEarned / weeklyTarget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => context.pop(),
        ),
        title: const Text("Earnings Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C))),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Color(0xFF2E7D32)),
            onPressed: _loadEarnings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero earnings card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Earned',
                                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${todayDeliveries.length} deliveries',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'रू ${totalEarned.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1),
                        ),
                        const SizedBox(height: 16),
                        // Progress to weekly target
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Weekly Target',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('रू ${weeklyTarget.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${(progress * 100).toStringAsFixed(0)}% of weekly goal',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      _EarningsStat(
                        label: 'Base Pay',
                        value: 'रू ${(todayDeliveries.length * _baseRate).toStringAsFixed(0)}',
                        color: const Color(0xFF2E7D32),
                        icon: Icons.directions_bike_outlined,
                      ),
                      const SizedBox(width: 12),
                      _EarningsStat(
                        label: 'Bonuses',
                        value: 'रू ${(totalEarned - todayDeliveries.length * _baseRate).clamp(0.0, double.infinity).toStringAsFixed(0)}',
                        color: const Color(0xFFFF9800),
                        icon: Icons.star_border_outlined,
                      ),
                      const SizedBox(width: 12),
                      _EarningsStat(
                        label: 'Deliveries',
                        value: '${todayDeliveries.length}',
                        color: const Color(0xFF0054A7),
                        icon: Icons.local_shipping_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Delivery list
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: Color(0xFF2E7D32), size: 18),
                      const SizedBox(width: 6),
                      const Text('Delivery Log',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      if (_isLoading)
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (todayDeliveries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 48, color: Color(0xFFBFCABA)),
                            SizedBox(height: 12),
                            Text('No deliveries yet', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...todayDeliveries.map((d) => _DeliveryEarningCard(delivery: d)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _EarningsStat(
      {required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _DeliveryEarningCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  const _DeliveryEarningCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final status = delivery['status'] as String? ?? 'DELIVERED';
    final isDelivered = status == 'DELIVERED';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDelivered ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDelivered ? Icons.check_circle_outline : Icons.local_shipping_outlined,
              color: isDelivered ? const Color(0xFF2E7D32) : const Color(0xFFFF9800),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(delivery['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(delivery['orderId'] as String,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
                    if ((delivery['qty'] as String).isNotEmpty) ...[
                      const Text(' · ', style: TextStyle(color: Color(0xFF707A6C))),
                      Text(delivery['qty'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(delivery['time'] as String,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(delivery['amount'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32))),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDelivered ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDelivered ? 'Earned' : status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDelivered ? const Color(0xFF2E7D32) : const Color(0xFFFF9800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
