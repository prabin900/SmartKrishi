import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/firebase/analytics_service.dart';
import '../../../core/network/api_client.dart';

enum DeliveryStatus { readyPickup, inTransit, delivered, failed }

class TodaysDeliveriesPage extends ConsumerStatefulWidget {
  const TodaysDeliveriesPage({super.key});

  @override
  ConsumerState<TodaysDeliveriesPage> createState() => _TodaysDeliveriesPageState();
}

class _TodaysDeliveriesPageState extends ConsumerState<TodaysDeliveriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = true;
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _realOrders = [];
  Map<String, dynamic> _farmerMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    try {
      setState(() => _isLoading = true);

      // Fetch all farmers to map their farmerProfileId to farmName and farmAddress
      final farmersRes = await _apiClient.dio.get('/public/farmers');
      final List<dynamic> farmersList = farmersRes.data;
      final Map<String, dynamic> farmerMap = {
        for (var f in farmersList) f['id']: f
      };

      final response = await _apiClient.dio.get('/delivery/history');
      final List<dynamic> orders = response.data;

      // Cache customer/farmer user profile lookups to avoid duplicate API calls
      final Map<String, Map<String, dynamic>> userProfilesCache = {};
      final List<dynamic> enrichedOrders = List.from(orders);

      for (int i = 0; i < enrichedOrders.length; i++) {
        final custId = enrichedOrders[i]['customerId'] as String?;
        if (custId != null && custId.isNotEmpty) {
          if (!userProfilesCache.containsKey(custId)) {
            try {
              final custRes = await _apiClient.dio.get('/public/users/$custId');
              userProfilesCache[custId] = Map<String, dynamic>.from(custRes.data);
            } catch (_) {
              userProfilesCache[custId] = {'fullName': 'Customer', 'phoneNumber': '+977-9841234567'};
            }
          }
          final custData = userProfilesCache[custId];
          enrichedOrders[i] = Map<String, dynamic>.from(enrichedOrders[i] as Map)
            ..['customerName'] = custData?['fullName']
            ..['customerPhone'] = custData?['phoneNumber'];
        }

        final fId = enrichedOrders[i]['farmerProfileId'];
        final farm = farmerMap[fId];
        final farmUserId = farm != null ? farm['userId'] as String? : null;

        String farmPhone = '9841234567';
        if (farmUserId != null && farmUserId.isNotEmpty) {
          if (!userProfilesCache.containsKey(farmUserId)) {
            try {
              final userRes = await _apiClient.dio.get('/public/users/$farmUserId');
              userProfilesCache[farmUserId] = Map<String, dynamic>.from(userRes.data);
            } catch (_) {
              userProfilesCache[farmUserId] = {'fullName': 'Farmer', 'phoneNumber': '9841234567'};
            }
          }
          farmPhone = userProfilesCache[farmUserId]?['phoneNumber'] ?? farmPhone;
        }

        enrichedOrders[i] = Map<String, dynamic>.from(enrichedOrders[i] as Map)
          ..['farmPhone'] = farmPhone
          ..['farmerUserId'] = farmUserId ?? '';
      }

      setState(() {
        _realOrders = enrichedOrders;
        _farmerMap = farmerMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading deliveries: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      setState(() => _isLoading = true);
      await _apiClient.dio.patch('/orders/$orderId/status', queryParameters: {'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $newStatus successfully!'), backgroundColor: const Color(0xFF2E7D32)),
      );
      await _loadDeliveries();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyOtp(String orderId) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Customer OTP'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter 6-digit OTP code'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await _apiClient.dio.post('/delivery/verify-otp', queryParameters: {
                  'orderId': orderId,
                  'otp': controller.text.trim(),
                });

                if (response.data == true) {
                  AnalyticsService.logOrderDelivered(orderId, 0.0);
                  _loadDeliveries();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Success'),
                        content: const Text('Delivery successfully verified and marked complete!'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid OTP code. Please try again.'), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification failed.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _verifyQr(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: MobileScanner(
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final qrString = barcodes.first.rawValue;
                Navigator.pop(context);
                try {
                  final response = await _apiClient.dio.post('/delivery/verify-qr', queryParameters: {
                    'orderId': orderId,
                    'qrCode': qrString,
                  });

                  if (response.data == true) {
                    AnalyticsService.logOrderDelivered(orderId, 0.0);
                    _loadDeliveries();
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Success'),
                          content: const Text('QR Code verified! Delivery marked complete.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid QR code data.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR Verification failed.'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _ongoing {
    final ongoingOrders = _realOrders.where((o) {
      final status = o['status']?.toString().toUpperCase() ?? '';
      return status != 'DELIVERED' && status != 'CANCELLED';
    }).toList();
    return ongoingOrders.map((o) => _mapOrderToDelivery(o)).toList();
  }

  List<Map<String, dynamic>> get _completed {
    final completedOrders = _realOrders.where((o) {
      final status = o['status']?.toString().toUpperCase() ?? '';
      return status == 'DELIVERED';
    }).toList();
    return completedOrders.map((o) => _mapOrderToDelivery(o)).toList();
  }

  Map<String, dynamic> _mapOrderToDelivery(dynamic o) {
    final farmProfile = _farmerMap[o['farmerProfileId']];
    final farmName = farmProfile != null ? farmProfile['farmName'] : 'Shrestha Organic Farm';
    final farmAddress = farmProfile != null ? farmProfile['farmAddress'] : 'Lalitpur, Nepal';

    // Get customer address
    String customerAddr = 'Not provided';
    if (o['shippingAddress'] != null) {
      final sa = o['shippingAddress'];
      customerAddr = '${sa['streetAddress'] ?? ''}, ${sa['city'] ?? ''}, ${sa['district'] ?? ''}';
    }

    // Map Order status String to DeliveryStatus enum
    DeliveryStatus status = DeliveryStatus.readyPickup;
    final statusStr = o['status']?.toString().toUpperCase() ?? 'PENDING';
    if (statusStr == 'DELIVERED') {
      status = DeliveryStatus.delivered;
    } else if (statusStr == 'CANCELLED') {
      status = DeliveryStatus.failed;
    } else if (statusStr == 'PICKED_UP' || statusStr == 'OUT_FOR_DELIVERY') {
      status = DeliveryStatus.inTransit;
    }

    // Construct items text
    final itemsList = o['items'] as List? ?? [];
    String itemsText = 'No items';
    if (itemsList.isNotEmpty) {
      final firstItem = itemsList.first;
      itemsText = '${firstItem['productName']} (${firstItem['quantity']} ${firstItem['unit']})';
      if (itemsList.length > 1) {
        itemsText += ' + ${itemsList.length - 1} more';
      }
    }

    return {
      'id': '#${o['id'].toString().substring(0, 8).toUpperCase()}',
      'status': status,
      'farm': farmName,
      'address': farmAddress,
      'distance': 'Calculated',
      'items': itemsText,
      'customer': o['customerName'] != null ? '${o['customerName']} (#${o['customerId']?.toString().substring(0, 6).toUpperCase()})' : 'Customer Ref: #${o['customerId']?.toString().substring(0, 6).toUpperCase() ?? "GUEST"}',
      'phone': o['customerPhone'] ?? '+977-9841234567',
      'customerAddress': customerAddr,
      'rawOrderId': o['id'],
      'farmerUserId': o['farmerUserId'] ?? '',
      'customerId': o['customerId'] ?? '',
      'farmPhone': o['farmPhone'] ?? '9841234567',
      'rawStatus': statusStr,
      'paymentMethod': o['paymentMethod'] ?? 'CASH_ON_DELIVERY',
      'total': o['totalAmount'] ?? 0.0,
    };
  }

  Color _statusColor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.readyPickup: return const Color(0xFF5E4000);
      case DeliveryStatus.inTransit: return const Color(0xFF005312);
      case DeliveryStatus.delivered: return const Color(0xFF2E7D32);
      case DeliveryStatus.failed: return const Color(0xFFBA1A1A);
    }
  }

  Color _statusBg(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.readyPickup: return const Color(0xFFFFC107).withOpacity(0.2);
      case DeliveryStatus.inTransit: return const Color(0xFFE8F5E9);
      case DeliveryStatus.delivered: return const Color(0xFFE8F5E9);
      case DeliveryStatus.failed: return const Color(0xFFFFDAD6);
    }
  }

  String _statusLabel(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.readyPickup: return 'Ready for Pickup';
      case DeliveryStatus.inTransit: return 'In Transit';
      case DeliveryStatus.delivered: return 'Delivered';
      case DeliveryStatus.failed: return 'Failed';
    }
  }

  IconData _statusIcon(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.readyPickup: return Icons.inventory_2_outlined;
      case DeliveryStatus.inTransit: return Icons.local_shipping_outlined;
      case DeliveryStatus.delivered: return Icons.check_circle_outline;
      case DeliveryStatus.failed: return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    final ongoingList = _ongoing;
    final completedList = _completed;

    // Earnings summary
    final earned = completedList.length * 150;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: Color(0xFF2E7D32), size: 20),
            SizedBox(width: 6),
            Text('SmartKrishi',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: GestureDetector(
              onTap: () => setState(() => _isOnline = !_isOnline),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFFD4F0D4) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: _isOnline ? const Color(0xFF2E7D32) : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: const Color(0xFF707A6C),
          indicatorColor: const Color(0xFF2E7D32),
          tabs: [
            Tab(text: 'Ongoing (${ongoingList.length})'),
            Tab(text: 'Completed (${completedList.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Earnings summary bar
          Container(
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: _SummaryChip(label: 'Ongoing', value: '${ongoingList.length}', color: const Color(0xFF2E7D32))),
                const SizedBox(width: 8),
                Expanded(child: _SummaryChip(label: 'Completed', value: '${completedList.length}', color: const Color(0xFF0054A7))),
                const SizedBox(width: 8),
                Expanded(child: _SummaryChip(label: "Today's Earn", value: 'रू $earned', color: const Color(0xFFFF9800))),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeliveryList(ongoingList, showActions: true),
                _buildDeliveryList(completedList, showActions: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryList(List<Map<String, dynamic>> list, {required bool showActions}) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF2E7D32)),
            SizedBox(height: 12),
            Text('All done for now!', style: TextStyle(fontSize: 16, color: Color(0xFF40493D))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      color: const Color(0xFF2E7D32),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _DeliveryCard(
          delivery: list[i],
          statusColor: _statusColor(list[i]['status'] as DeliveryStatus),
          statusBg: _statusBg(list[i]['status'] as DeliveryStatus),
          statusLabel: _statusLabel(list[i]['status'] as DeliveryStatus),
          statusIcon: _statusIcon(list[i]['status'] as DeliveryStatus),
          showActions: showActions,
          onUpdateStatus: _updateOrderStatus,
          onVerifyOtp: _verifyOtp,
          onVerifyQr: _verifyQr,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF707A6C))),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final Color statusColor, statusBg;
  final String statusLabel;
  final IconData statusIcon;
  final bool showActions;
  final Function(String, String) onUpdateStatus;
  final Function(String) onVerifyOtp;
  final Function(String) onVerifyQr;

  const _DeliveryCard({
    required this.delivery,
    required this.statusColor,
    required this.statusBg,
    required this.statusLabel,
    required this.statusIcon,
    required this.showActions,
    required this.onUpdateStatus,
    required this.onVerifyOtp,
    required this.onVerifyQr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(delivery['id'] as String,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF707A6C))),
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 3),
                        Text(statusLabel,
                            style: TextStyle(
                                fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Farm pickup details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pick Up From:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    Text(delivery['farm'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF707A6C)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(delivery['address'] as String,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF707A6C))),
                        ),
                      ],
                    ),
                    Text('Phone: ${delivery['farmPhone']}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
              ),
              if ((delivery['farmerUserId'] as String).isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32)),
                  onPressed: () => context.push('/chat?recipient=${delivery['farmerUserId']}&name=${delivery['farm']}'),
                  tooltip: 'Chat with Farmer',
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer delivery details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deliver To:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    Text(delivery['customer'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32))),
                    Row(
                      children: [
                        const Icon(Icons.home_outlined, size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(delivery['customerAddress'] as String,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
                        ),
                      ],
                    ),
                    Text('Phone: ${delivery['phone']}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
              ),
              if ((delivery['customerId'] as String).isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32)),
                  onPressed: () => context.push('/chat?recipient=${delivery['customerId']}&name=${delivery['customer']}'),
                  tooltip: 'Chat with Customer',
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Items
          const Divider(),
          const Text('ITEMS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(delivery['items'] as String,
              style: const TextStyle(fontSize: 12, color: Color(0xFF40493D), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),

          // Actions
          if (showActions) ...[
            const SizedBox(height: 12),
            
            // Status progression buttons
            if (delivery['rawStatus'] == 'PICKUP_ASSIGNED') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onUpdateStatus(delivery['rawOrderId'] as String, 'PICKED_UP'),
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                  label: const Text('Mark as Picked Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (delivery['rawStatus'] == 'PICKED_UP' || delivery['rawStatus'] == 'OUT_FOR_DELIVERY') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onUpdateStatus(delivery['rawOrderId'] as String, 'DELIVERED'),
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  label: const Text('Mark as Delivered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final orderId = delivery['rawOrderId'] as String;
                      context.push('/delivery/map/$orderId');
                    },
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF246DC8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (delivery['rawStatus'] != 'DELIVERED' && delivery['rawStatus'] != 'CANCELLED') ...[
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0D631B)),
                    onPressed: () => onVerifyQr(delivery['rawOrderId'] as String),
                    tooltip: 'Scan QR Code Verification',
                  ),
                  IconButton(
                    icon: const Icon(Icons.pin_outlined, color: Color(0xFF0D631B)),
                    onPressed: () => onVerifyOtp(delivery['rawOrderId'] as String),
                    tooltip: 'Enter OTP PIN Verification',
                  ),
                ]
              ],
            ),
          ],
        ],
      ),
    );
  }
}
