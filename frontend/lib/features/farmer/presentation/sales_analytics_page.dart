import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class SalesAnalyticsPage extends ConsumerStatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  ConsumerState<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends ConsumerState<SalesAnalyticsPage> {
  String _period = 'Week';
  final _apiClient = ApiClient();

  bool _isLoading = true;
  List<dynamic> _orders = [];

  // Computed KPIs
  double _totalRevenue = 0;
  int _orderCount = 0;
  double _unitsSold = 0;
  int _newCustomers = 0;

  // Bar chart data
  List<double> _barValues = List.filled(7, 0.0);
  List<String> _barLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Top products
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profileRes = await _apiClient.dio.get('/farmer/profile');
      final farmerProfileId = profileRes.data['id'];

      final ordersRes = await _apiClient.dio.get(
        '/farmer/orders',
        queryParameters: {'farmerProfileId': farmerProfileId},
      );

      _orders = ordersRes.data;

      _computeMetrics();
    } catch (e) {
      debugPrint('Analytics load error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _computeMetrics() {
    // Filter by selected period
    final now = DateTime.now();
    final int daysBack = _period == 'Day' ? 1 : _period == 'Week' ? 7 : 30;

    final filtered = _orders.where((o) {
      try {
        final created = DateTime.parse(o['createdAt'] as String? ?? '');
        final matchesDate = now.difference(created).inDays <= daysBack;
        final isDelivered = o['status'] == 'DELIVERED';
        return matchesDate && isDelivered;
      } catch (_) {
        return false;
      }
    }).toList();

    _totalRevenue = filtered.fold(0.0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0.0));
    _orderCount = filtered.length;
    _unitsSold = filtered.fold(0.0, (s, o) {
      final items = o['items'] as List? ?? [];
      return s + items.fold(0.0, (si, it) => si + ((it['quantity'] as num?)?.toDouble() ?? 0.0));
    });
    _newCustomers = filtered.map((o) => o['customerId']).toSet().length;

    // Bar chart: last 7 days
    final int bars = _period == 'Day' ? 24 : _period == 'Month' ? 4 : 7;
    _barValues = List.filled(bars, 0.0);
    if (_period == 'Week') {
      _barLabels = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
      });
      for (final o in filtered) {
        try {
          final created = DateTime.parse(o['createdAt'] as String? ?? '').toLocal();
          final diff = now.difference(created).inDays;
          if (diff >= 0 && diff < 7) {
            _barValues[6 - diff] += ((o['total'] as num?)?.toDouble() ?? 0.0);
          }
        } catch (_) {}
      }
    } else if (_period == 'Day') {
      _barLabels = List.generate(24, (i) => '${i}h');
      for (final o in filtered) {
        try {
          final created = DateTime.parse(o['createdAt'] as String? ?? '').toLocal();
          final h = created.hour.clamp(0, 23);
          _barValues[h] += ((o['total'] as num?)?.toDouble() ?? 0.0);
        } catch (_) {}
      }
    } else {
      // Month: group by week
      _barLabels = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      for (final o in filtered) {
        try {
          final created = DateTime.parse(o['createdAt'] as String? ?? '').toLocal();
          final diff = now.difference(created).inDays;
          final weekIdx = (diff ~/ 7).clamp(0, 3);
          _barValues[3 - weekIdx] += ((o['total'] as num?)?.toDouble() ?? 0.0);
        } catch (_) {}
      }
    }

    // Top products: aggregate from order items
    final Map<String, Map<String, dynamic>> productStats = {};
    for (final o in filtered) {
      for (final item in (o['items'] as List? ?? [])) {
        final pid = item['productId'] as String? ?? '';
        final name = item['productName'] as String? ?? 'Unknown';
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
        final unit = item['unit'] as String? ?? 'kg';
        final rev = ((item['totalPrice'] ?? item['unitPrice']) as num?)?.toDouble() ?? 0.0;
        if (!productStats.containsKey(pid)) {
          productStats[pid] = {'name': name, 'units': 0.0, 'unit': unit, 'revenue': 0.0};
        }
        productStats[pid]!['units'] = (productStats[pid]!['units'] as double) + qty;
        productStats[pid]!['revenue'] = (productStats[pid]!['revenue'] as double) + rev;
      }
    }

    final sorted = productStats.entries.toList()
      ..sort((a, b) => (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));
    final totalRev = sorted.fold(0.0, (s, e) => s + (e.value['revenue'] as double));

    _topProducts = sorted.take(4).map((e) {
      final rev = e.value['revenue'] as double;
      return {
        'name': e.value['name'],
        'units': '${(e.value['units'] as double).toStringAsFixed(0)} ${e.value['unit']}',
        'revenue': 'रू ${rev.toStringAsFixed(0)}',
        'share': totalRev > 0 ? (rev / totalRev).clamp(0.0, 1.0) : 0.0,
      };
    }).toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'DELIVERED': return const Color(0xFF2E7D32);
      case 'OUT_FOR_DELIVERY':
      case 'PICKED_UP': return const Color(0xFF0054A7);
      default: return const Color(0xFF8B5000);
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'DELIVERED': return const Color(0xFFE8F5E9);
      case 'OUT_FOR_DELIVERY':
      case 'PICKED_UP': return const Color(0xFFE3F2FD);
      default: return const Color(0xFFFFF3E0);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'DELIVERED': return 'Delivered';
      case 'OUT_FOR_DELIVERY': return 'In Transit';
      case 'PICKED_UP': return 'Picked Up';
      case 'PENDING': return 'Pending';
      case 'ACCEPTED': return 'Accepted';
      case 'CANCELLED': return 'Cancelled';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kpiData = [
      {'icon': Icons.payments, 'label': 'Total Revenue', 'value': 'रू ${_totalRevenue.toStringAsFixed(0)}', 'change': '$_orderCount orders', 'up': true, 'color': 0xFF2E7D32},
      {'icon': Icons.shopping_cart_outlined, 'label': 'Orders', 'value': '$_orderCount', 'change': 'This $_period', 'up': _orderCount > 0, 'color': 0xFF0054A7},
      {'icon': Icons.inventory_2_outlined, 'label': 'Units Sold', 'value': '${_unitsSold.toStringAsFixed(0)} kg', 'change': 'Approx.', 'up': _unitsSold > 0, 'color': 0xFF8B5000},
      {'icon': Icons.person_outline, 'label': 'Customers', 'value': '$_newCustomers', 'change': 'Unique buyers', 'up': _newCustomers > 0, 'color': 0xFF2E7D32},
    ];

    final maxBar = _barValues.isEmpty ? 1.0 : (_barValues.reduce((a, b) => a > b ? a : b)).clamp(1.0, double.infinity);
    final recentOrders = _orders.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Sales Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C))),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Color(0xFF40493D)),
            onPressed: _loadData,
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
                  // Period selector
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Track your farm\'s performance',
                            style: TextStyle(color: Color(0xFF40493D), fontSize: 13)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFCABA)),
                        ),
                        child: Row(
                          children: ['Day', 'Week', 'Month'].map((p) {
                            final active = p == _period;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _period = p);
                                _computeMetrics();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: active ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                  border: active ? Border.all(color: const Color(0xFFBFCABA)) : null,
                                  boxShadow: active
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                      : [],
                                ),
                                child: Text(p,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: active ? const Color(0xFF0D631B) : const Color(0xFF40493D),
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // KPI cards 2x2
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: kpiData.map((kpi) => _KpiCard(kpi: kpi)).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Revenue Bar Chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bar_chart, color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: 6),
                            Text('Revenue — $_period View',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: _barValues.every((v) => v == 0)
                              ? const Center(
                                  child: Text('No revenue data for this period',
                                      style: TextStyle(color: Colors.grey)))
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(_barValues.length, (i) {
                                    final ratio = _barValues[i] / maxBar;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Tooltip(
                                              message: 'रू ${_barValues[i].toStringAsFixed(0)}',
                                              child: AnimatedContainer(
                                                duration: Duration(milliseconds: 400 + i * 40),
                                                curve: Curves.easeOut,
                                                height: 120 * ratio,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2E7D32),
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (_barLabels.length > _barValues.length ~/ 2)
                                              Text(i < _barLabels.length ? _barLabels[i] : '',
                                                  style: const TextStyle(fontSize: 9, color: Color(0xFF707A6C))),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Top Products
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.emoji_events_outlined, color: Color(0xFFFF9800), size: 20),
                            SizedBox(width: 6),
                            Text('Top Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_topProducts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: Text('No product sales yet', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          ...(_topProducts.map((p) => _ProductRow(product: p))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recent Transactions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt_long_outlined, color: Color(0xFF2E7D32), size: 20),
                                SizedBox(width: 6),
                                Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            TextButton(
                              onPressed: () => context.push('/farmer/orders/incoming'),
                              child: const Text('View All', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (recentOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: Text('No orders yet', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          ...recentOrders.map((o) {
                            final status = o['status'] as String? ?? 'PENDING';
                            final items = (o['items'] as List? ?? []);
                            final buyerRef = 'Customer #${(o['customerId'] as String? ?? '').substring(0, 6).toUpperCase()}';
                            final amount = 'रू ${((o['total'] as num?)?.toStringAsFixed(0) ?? '0')}';
                            final orderId = '#${(o['id'] as String? ?? '').substring(0, 8).toUpperCase()}';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE8F5E9),
                                child: Text(
                                  items.isNotEmpty ? (items.first['productName'] as String? ?? 'O')[0] : 'O',
                                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(buyerRef, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('$orderId · ${items.length} item(s)',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusBg(status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(_statusLabel(status),
                                        style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final Map<String, dynamic> kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final up = kpi['up'] as bool;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(kpi['icon'] as IconData, color: Color(kpi['color'] as int), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(kpi['label'] as String,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF40493D))),
              ),
            ],
          ),
          Text(kpi['value'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C1C))),
          Row(
            children: [
              Icon(
                up ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: up ? const Color(0xFF2E7D32) : const Color(0xFFBA1A1A),
              ),
              const SizedBox(width: 2),
              Text(
                kpi['change'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: up ? const Color(0xFF2E7D32) : const Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final share = product['share'] as double;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(product['revenue'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product['units'] as String,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
              Text('${(share * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              backgroundColor: const Color(0xFFF3F3F3),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D32)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
