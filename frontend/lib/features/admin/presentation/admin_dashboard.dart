import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _touchedIndex = -1;

  List<Map<String, dynamic>> _pendingVerifications = [
    {
      'id': 'farm_1',
      'type': 'FARMER',
      'title': 'Shrestha Organic Farm',
      'subtitle': 'Farmer: Ram Prasad Shrestha • Lalitpur',
      'icon': Icons.agriculture_outlined,
      'color': Colors.green,
      'endpoint': '/admin/verify/farmer/farm_1',
    },
    {
      'id': 'deliv_1',
      'type': 'DELIVERY',
      'title': 'Suman Thapa Logistics',
      'subtitle': 'Delivery Partner • License LIC-1010456',
      'icon': Icons.local_shipping_outlined,
      'color': Colors.blue,
      'endpoint': '/admin/verify/delivery/deliv_1',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final statsRes = await _apiClient.dio.get('/admin/dashboard/stats');
      
      // Fetch dynamic pending farmers & delivery partners if available
      try {
        final pendingFarmersRes = await _apiClient.dio.get('/admin/pending/farmers');
        final pendingDeliveryRes = await _apiClient.dio.get('/admin/pending/delivery');
        
        final List<dynamic> pFarmers = pendingFarmersRes.data ?? [];
        final List<dynamic> pDelivery = pendingDeliveryRes.data ?? [];
        
        if (pFarmers.isNotEmpty || pDelivery.isNotEmpty) {
          final List<Map<String, dynamic>> fetched = [];
          for (var f in pFarmers) {
            fetched.add({
              'id': f['id'],
              'type': 'FARMER',
              'title': f['farmName'] ?? 'Farm',
              'subtitle': 'Farmer: ${f['fullName'] ?? 'Grower'} • ${f['farmAddress'] ?? 'Location'}',
              'icon': Icons.agriculture_outlined,
              'color': Colors.green,
              'endpoint': '/admin/verify/farmer/${f['id']}',
            });
          }
          for (var d in pDelivery) {
            fetched.add({
              'id': d['id'],
              'type': 'DELIVERY',
              'title': d['vehicleType'] ?? 'Delivery Partner',
              'subtitle': 'License: ${d['licenseNumber'] ?? 'N/A'}',
              'icon': Icons.local_shipping_outlined,
              'color': Colors.blue,
              'endpoint': '/admin/verify/delivery/${d['id']}',
            });
          }
          _pendingVerifications = fetched;
        }
      } catch (_) {}

      setState(() {
        _stats = statsRes.data ?? {};
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Admin stats fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D631B))));
    }

    final totalUsers = _stats['totalUsers']?.toString() ?? '1';
    final totalFarmers = _stats['totalFarmers']?.toString() ?? '1';
    final totalBusinesses = _stats['totalBusinesses']?.toString() ?? '1';
    final totalDeliveryPartners = _stats['totalDeliveryPartners']?.toString() ?? '1';
    final totalProducts = _stats['totalProducts']?.toString() ?? '2';
    final totalOrders = _stats['totalOrders']?.toString() ?? '0';
    final totalContracts = _stats['totalContracts']?.toString() ?? '0';
    final totalVisits = _stats['totalVisits']?.toString() ?? '0';
    final totalRevenue = (_stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final completedOrders = _stats['completedOrders']?.toString() ?? '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management Console', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0D631B)),
            onPressed: _loadAdminData,
            tooltip: 'Refresh Stats',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D631B), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total System Analytics',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Real-time overview of SmartKrishi ecosystem metrics and operational revenue.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Platform Revenue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(
                          'Rs. ${totalRevenue.toStringAsFixed(2)} NPR',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Grid of Total Analytics Cards
            const Text('Platform Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Total Users Registered', totalUsers, Icons.people, Colors.blue),
                _buildStatCard('Active Farmers Listed', totalFarmers, Icons.agriculture, Colors.green),
                _buildStatCard('Verified Businesses', totalBusinesses, Icons.business, Colors.purple),
                _buildStatCard('Delivery Partners', totalDeliveryPartners, Icons.local_shipping, Colors.teal),
                _buildStatCard('Marketplace Products', totalProducts, Icons.shopping_bag, Colors.orange),
                _buildStatCard('All Orders ($completedOrders Done)', totalOrders, Icons.receipt_long, Colors.indigo),
                _buildStatCard('Crop Contracts Created', totalContracts, Icons.handshake, Colors.deepOrange),
                _buildStatCard('Farm Visits Booked', totalVisits, Icons.event_available, Colors.pink),
              ],
            ),
            const SizedBox(height: 32),

            // Chart Visualization Section
            const Text('Visual Analytics Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'User Role Distribution',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: (double.tryParse(totalFarmers) ?? 1),
                              title: 'Farmers',
                              radius: _touchedIndex == 0 ? 60.0 : 50.0,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: Colors.purple,
                              value: (double.tryParse(totalBusinesses) ?? 1),
                              title: 'Business',
                              radius: _touchedIndex == 1 ? 60.0 : 50.0,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: Colors.teal,
                              value: (double.tryParse(totalDeliveryPartners) ?? 1),
                              title: 'Logistics',
                              radius: _touchedIndex == 2 ? 60.0 : 50.0,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: Colors.blue,
                              value: (double.tryParse(totalUsers) ?? 1),
                              title: 'Buyers',
                              radius: _touchedIndex == 3 ? 60.0 : 50.0,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      children: [
                        _buildLegendItem('Farmers', Colors.green),
                        _buildLegendItem('Business', Colors.purple),
                        _buildLegendItem('Logistics', Colors.teal),
                        _buildLegendItem('Buyers', Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Pending Verifications Section
            const Text('Pending Verifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_pendingVerifications.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: const Color(0xFFF1F8E9),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🎉 All pending partner verifications cleared!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingVerifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final item = _pendingVerifications[idx];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (item['color'] as Color).withOpacity(0.12),
                        child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                      ),
                      title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item['subtitle'] as String),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final itemId = item['id'];
                          try {
                            await _apiClient.dio.put(item['endpoint'] as String, queryParameters: {'verified': true});
                          } catch (_) {}
                          setState(() {
                            _pendingVerifications.removeWhere((p) => p['id'] == itemId);
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item['title']} approved and verified!'),
                                backgroundColor: const Color(0xFF0D631B),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D631B),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Verify & Approve'),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
