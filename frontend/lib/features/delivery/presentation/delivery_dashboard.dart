import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/firebase/analytics_service.dart';

class DeliveryDashboard extends ConsumerStatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  ConsumerState<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends ConsumerState<DeliveryDashboard> {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();

  bool _isOnline = false;
  List<dynamic> _assignedTasks = [];
  List<dynamic> _availableTasks = [];
  final Set<String> _declinedTaskIds = {};
  double _earnings = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
  }

  Future<void> _loadDeliveryData() async {
    setState(() => _isLoading = true);
    try {
      // Toggle status to online
      await _apiClient.dio
          .put('/delivery/status', queryParameters: {'online': true});
      final tasksRes = await _apiClient.dio.get('/delivery/history');
      final availableRes = await _apiClient.dio.get('/delivery/available');
      final earningsRes = await _apiClient.dio.get('/delivery/earnings');

      List<dynamic> tasks = List.from(tasksRes.data);
      List<dynamic> available = List.from(availableRes.data);

      // Fetch all farmers to resolve farm profiles
      final farmersRes = await _apiClient.dio.get('/public/farmers');
      final List<dynamic> farmersList = farmersRes.data;
      final Map<String, dynamic> farmerMap = {
        for (var f in farmersList) f['id']: f
      };

      final Map<String, Map<String, dynamic>> userProfilesCache = {};

      for (int i = 0; i < tasks.length; i++) {
        final fId = tasks[i]['farmerProfileId'];
        final farm = farmerMap[fId];
        final farmUserId = farm != null ? farm['userId'] as String? : null;
        final custId = tasks[i]['customerId'] as String?;

        String farmPhone = '9841234567';
        if (farmUserId != null && farmUserId.isNotEmpty) {
          if (!userProfilesCache.containsKey(farmUserId)) {
            try {
              final userRes =
                  await _apiClient.dio.get('/public/users/$farmUserId');
              userProfilesCache[farmUserId] =
                  Map<String, dynamic>.from(userRes.data);
            } catch (_) {
              userProfilesCache[farmUserId] = {
                'fullName': 'Farmer',
                'phoneNumber': '9841234567'
              };
            }
          }
          farmPhone =
              userProfilesCache[farmUserId]?['phoneNumber'] ?? farmPhone;
        }

        String custName = 'Customer';
        String custPhone = '+977-9841234567';
        if (custId != null && custId.isNotEmpty) {
          if (!userProfilesCache.containsKey(custId)) {
            try {
              final userRes = await _apiClient.dio.get('/public/users/$custId');
              userProfilesCache[custId] =
                  Map<String, dynamic>.from(userRes.data);
            } catch (_) {
              userProfilesCache[custId] = {
                'fullName': 'Hari Bahadur',
                'phoneNumber': '9841999888'
              };
            }
          }
          custName = userProfilesCache[custId]?['fullName'] ?? custName;
          custPhone = userProfilesCache[custId]?['phoneNumber'] ?? custPhone;
        }

        tasks[i] = Map<String, dynamic>.from(tasks[i] as Map)
          ..['farmName'] =
              farm != null ? farm['farmName'] : 'Shrestha Organic Farm'
          ..['farmAddress'] =
              farm != null ? farm['farmAddress'] : 'Lalitpur, Nepal'
          ..['farmPhone'] = farmPhone
          ..['farmerUserId'] = farmUserId ?? ''
          ..['customerName'] = custName
          ..['customerPhone'] = custPhone;
      }

      for (int i = 0; i < available.length; i++) {
        final fId = available[i]['farmerProfileId'];
        final farm = farmerMap[fId];
        final farmUserId = farm != null ? farm['userId'] as String? : null;
        final custId = available[i]['customerId'] as String?;

        String farmPhone = '9841234567';
        if (farmUserId != null && farmUserId.isNotEmpty) {
          if (!userProfilesCache.containsKey(farmUserId)) {
            try {
              final userRes =
                  await _apiClient.dio.get('/public/users/$farmUserId');
              userProfilesCache[farmUserId] =
                  Map<String, dynamic>.from(userRes.data);
            } catch (_) {
              userProfilesCache[farmUserId] = {
                'fullName': 'Farmer',
                'phoneNumber': '9841234567'
              };
            }
          }
          farmPhone =
              userProfilesCache[farmUserId]?['phoneNumber'] ?? farmPhone;
        }

        String custName = 'Customer';
        String custPhone = '+977-9841234567';
        if (custId != null && custId.isNotEmpty) {
          if (!userProfilesCache.containsKey(custId)) {
            try {
              final userRes = await _apiClient.dio.get('/public/users/$custId');
              userProfilesCache[custId] =
                  Map<String, dynamic>.from(userRes.data);
            } catch (_) {
              userProfilesCache[custId] = {
                'fullName': 'Hari Bahadur',
                'phoneNumber': '9841999888'
              };
            }
          }
          custName = userProfilesCache[custId]?['fullName'] ?? custName;
          custPhone = userProfilesCache[custId]?['phoneNumber'] ?? custPhone;
        }

        available[i] = Map<String, dynamic>.from(available[i] as Map)
          ..['farmName'] =
              farm != null ? farm['farmName'] : 'Shrestha Organic Farm'
          ..['farmAddress'] =
              farm != null ? farm['farmAddress'] : 'Lalitpur, Nepal'
          ..['farmPhone'] = farmPhone
          ..['farmerUserId'] = farmUserId ?? ''
          ..['customerName'] = custName
          ..['customerPhone'] = custPhone;
      }

      setState(() {
        _isOnline = true;
        _assignedTasks = tasks;
        _availableTasks = available;
        _earnings = earningsRes.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnline(bool val) async {
    try {
      await _apiClient.dio
          .put('/delivery/status', queryParameters: {'online': val});
      setState(() {
        _isOnline = val;
      });
      if (val) {
        await _loadDeliveryData();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _claimOrder(String orderId) async {
    try {
      setState(() => _isLoading = true);
      await _apiClient.dio
          .post('/delivery/claim', queryParameters: {'orderId': orderId});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Delivery Claimed Successfully!'),
            backgroundColor: Color(0xFF2E7D32)),
      );
      await _loadDeliveryData();
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to claim delivery: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _declineOrder(String orderId) {
    setState(() {
      _declinedTaskIds.add(orderId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Request declined and hidden.'),
          duration: Duration(seconds: 2)),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      setState(() => _isLoading = true);
      await _apiClient.dio.patch('/orders/$orderId/status',
          queryParameters: {'status': newStatus});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Order marked as $newStatus successfully!'),
            backgroundColor: const Color(0xFF2E7D32)),
      );
      await _loadDeliveryData();
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red),
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
                final response = await _apiClient.dio
                    .post('/delivery/verify-otp', queryParameters: {
                  'orderId': orderId,
                  'otp': controller.text.trim(),
                });

                if (response.data == true) {
                  AnalyticsService.logOrderDelivered(orderId, 0.0);
                  _loadDeliveryData();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Success'),
                        content: const Text(
                            'Delivery successfully verified and marked complete!'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'))
                        ],
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Invalid OTP code. Please try again.'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Verification failed.'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
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
                  final response = await _apiClient.dio
                      .post('/delivery/verify-qr', queryParameters: {
                    'orderId': orderId,
                    'qrCode': qrString,
                  });

                  if (response.data == true) {
                    AnalyticsService.logOrderDelivered(orderId, 0.0);
                    _loadDeliveryData();
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Success'),
                          content: const Text(
                              'QR Code verified! Delivery marked complete.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'))
                          ],
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Invalid QR code data.'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('QR Verification failed.'),
                          backgroundColor: Colors.red),
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0D631B))));
    }

    final pages = [
      _buildTasksTab(),
      const SizedBox.shrink(), // placeholder for index 1 (earnings route)
      const SizedBox.shrink(), // placeholder for index 2 (today's route)
      _buildDeliveryProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: Color(0xFF2E7D32), size: 22),
            SizedBox(width: 8),
            Text('Delivery Console',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          GestureDetector(
            onTap: () => _toggleOnline(!_isOnline),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: _isOnline
                    ? const Color(0xFFD4F0D4)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isOnline ? '● ONLINE' : '○ OFFLINE',
                style: TextStyle(
                  color: _isOnline ? const Color(0xFF2E7D32) : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF40493D)),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFA3F69C),
        onDestinationSelected: (idx) {
          if (idx == 1) {
            context.push('/earnings/today');
          } else if (idx == 2) {
            context.push('/delivery/today');
          } else {
            setState(() => _currentIndex = idx);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: Color(0xFF2E7D32)),
            label: 'Active Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments, color: Color(0xFF2E7D32)),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today, color: Color(0xFF2E7D32)),
            label: "Today's",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2E7D32)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    final filteredAvailable = _availableTasks
        .where((t) => !_declinedTaskIds.contains(t['id']))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF2E7D32),
              unselectedLabelColor: Color(0xFF707A6C),
              indicatorColor: Color(0xFF2E7D32),
              tabs: [
                Tab(text: 'Available requests'),
                Tab(text: 'Active dispatches'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableRequestsList(filteredAvailable),
                _buildActiveDispatchesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRequestsList(List<dynamic> list) {
    if (!_isOnline) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'You are Offline\nGo online to view available requests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No new available delivery requests around you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final task = list[idx];
        final id = task['id'] as String;
        final farm = task['farmName'] ?? 'Shrestha Organic Farm';
        final address = task['farmAddress'] ?? 'Lalitpur, Nepal';
        final farmPhone = task['farmPhone'] ?? '9841234567';
        final custName = task['customerName'] ?? 'Customer';
        final custPhone = task['customerPhone'] ?? '9841999888';
        final total = task['total'];
        final payment = task['paymentMethod'] as String;

        String customerAddr = 'Not provided';
        if (task['shippingAddress'] != null) {
          final sa = task['shippingAddress'];
          customerAddr =
              '${sa['streetAddress'] ?? ''}, ${sa['city'] ?? ''}, ${sa['district'] ?? ''}';
        }

        // Construct items text
        final itemsList = task['items'] as List? ?? [];
        String itemsText = 'No items';
        if (itemsList.isNotEmpty) {
          final firstItem = itemsList.first;
          itemsText =
              '${firstItem['productName']} (${firstItem['quantity']} ${firstItem['unit']})';
          if (itemsList.length > 1) {
            itemsText += ' + ${itemsList.length - 1} more';
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Request: #${id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NEW REQUEST',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Text('PICK UP FROM:',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 2),
                Text(farm,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Phone: $farmPhone',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
                const SizedBox(height: 12),
                const Text('DELIVER TO:',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 2),
                Text(custName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(customerAddr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Phone: $custPhone',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
                const SizedBox(height: 12),
                const Text('ITEMS:',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                Text(itemsText,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const Divider(height: 24),
                Text('Payment: $payment • Amount: Rs. $total',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _declineOrder(id),
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.red),
                        label: const Text('Decline',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _claimOrder(id),
                        icon: const Icon(Icons.check,
                            size: 16, color: Colors.white),
                        label: const Text('Accept Delivery',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveDispatchesList() {
    if (_assignedTasks.isEmpty) {
      return const Center(
          child: Text(
              'No active deliveries assigned yet. Claim one from available requests!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignedTasks.length,
      itemBuilder: (context, idx) {
        final task = _assignedTasks[idx];
        final id = task['id'] as String;
        final status = task['status'] as String;
        final payment = task['paymentMethod'] as String;
        final total = task['total'];
        final farm = task['farmName'] ?? 'Shrestha Organic Farm';
        final address = task['farmAddress'] ?? 'Lalitpur, Nepal';
        final farmPhone = task['farmPhone'] ?? '9841234567';
        final farmUserId = task['farmerUserId'] as String? ?? '';
        final custId = task['customerId'] as String? ?? '';
        final custName = task['customerName'] ?? 'Customer';
        final custPhone = task['customerPhone'] ?? '9841999888';

        String customerAddr = 'Not provided';
        if (task['shippingAddress'] != null) {
          final sa = task['shippingAddress'];
          customerAddr =
              '${sa['streetAddress'] ?? ''}, ${sa['city'] ?? ''}, ${sa['district'] ?? ''}';
        }

        // Construct items text
        final itemsList = task['items'] as List? ?? [];
        String itemsText = 'No items';
        if (itemsList.isNotEmpty) {
          final firstItem = itemsList.first;
          itemsText =
              '${firstItem['productName']} (${firstItem['quantity']} ${firstItem['unit']})';
          if (itemsList.length > 1) {
            itemsText += ' + ${itemsList.length - 1} more';
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Task: #${id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'DELIVERED'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status == 'DELIVERED'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFF57F17),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Pick up section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PICK UP FROM:',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(farm,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(address,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Text('Phone: $farmPhone',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                        ],
                      ),
                    ),
                    if (farmUserId.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: Color(0xFF2E7D32)),
                        onPressed: () => context
                            .push('/chat?recipient=$farmUserId&name=$farm'),
                        tooltip: 'Chat with Farmer',
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Deliver section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DELIVER TO:',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(custName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(customerAddr,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Text('Phone: $custPhone',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                        ],
                      ),
                    ),
                    if (custId.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: Color(0xFF2E7D32)),
                        onPressed: () => context
                            .push('/chat?recipient=$custId&name=$custName'),
                        tooltip: 'Chat with Customer',
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text('ITEMS:',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                Text(itemsText,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const Divider(height: 24),
                Text('Payment: $payment • Amount: Rs. $total',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Step-by-step Status Actions
                if (status == 'PICKUP_ASSIGNED') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(id, 'PICKED_UP'),
                      icon: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white),
                      label: const Text('Mark as Picked Up',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (status == 'PICKED_UP' ||
                    status == 'OUT_FOR_DELIVERY') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(id, 'DELIVERED'),
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      label: const Text('Mark as Delivered',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/delivery/map/$id'),
                        icon: const Icon(Icons.navigation,
                            color: Colors.white, size: 18),
                        label: const Text('View Route',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (status != 'DELIVERED') ...[
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner,
                            color: Color(0xFF0D631B)),
                        onPressed: () => _verifyQr(id),
                        tooltip: 'Scan QR Code Verification',
                      ),
                      IconButton(
                        icon: const Icon(Icons.pin_outlined,
                            color: Color(0xFF0D631B)),
                        onPressed: () => _verifyOtp(id),
                        tooltip: 'Enter OTP PIN Verification',
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryProfileTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF1B5E20),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: const Color(0xFFBBDEFB),
                      ),
                      child: const Icon(Icons.delivery_dining,
                          size: 44, color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Suman Thapa',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isOnline ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isOnline ? '● ONLINE' : '○ OFFLINE',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Row(
                  children: [
                    _DeliveryStatCard(
                        label: 'Deliveries',
                        value: '${_assignedTasks.length}',
                        icon: Icons.local_shipping_outlined),
                    const SizedBox(width: 12),
                    _DeliveryStatCard(
                        label: 'Earnings',
                        value: 'Rs.${_earnings.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee),
                    const SizedBox(width: 12),
                    const _DeliveryStatCard(
                        label: 'Rating',
                        value: '4.8★',
                        icon: Icons.star_outline),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('Personal Details',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF707A6C))),
                const SizedBox(height: 8),
                _DeliveryProfileItem(
                    icon: Icons.person_outline,
                    title: 'Full Name',
                    subtitle: 'Suman Thapa',
                    onTap: () => _showEditPersonalDialog(context)),
                _DeliveryProfileItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    subtitle: '+977 9803124567',
                    onTap: () => _showEditPersonalDialog(context)),
                _DeliveryProfileItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'delivery@smartkrishi.com.np',
                    onTap: () => _showEditPersonalDialog(context)),

                const SizedBox(height: 16),
                const Text('Vehicle Information',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF707A6C))),
                const SizedBox(height: 8),
                _DeliveryProfileItem(
                    icon: Icons.two_wheeler,
                    title: 'Vehicle Type',
                    subtitle: 'Motorcycle',
                    onTap: () {}),
                _DeliveryProfileItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Vehicle Number',
                    subtitle: 'Ba 3 Pa 1234',
                    onTap: () {}),
                _DeliveryProfileItem(
                    icon: Icons.badge_outlined,
                    title: 'License Number',
                    subtitle: 'LIC-1010456',
                    onTap: () {}),

                const SizedBox(height: 16),
                const Text('Quick Actions',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF707A6C))),
                const SizedBox(height: 8),
                _DeliveryProfileItem(
                    icon: Icons.history_outlined,
                    title: "Today's Deliveries",
                    subtitle: 'View delivery history',
                    onTap: () => context.push('/delivery/today')),
                _DeliveryProfileItem(
                    icon: Icons.payments_outlined,
                    title: "Today's Earnings",
                    subtitle: 'View earnings breakdown',
                    onTap: () => context.push('/earnings/today')),

                // Online/Offline toggle
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _isOnline
                            ? const Color(0xFFA5D6A7)
                            : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(_isOnline ? Icons.wifi : Icons.wifi_off,
                          color: _isOnline
                              ? const Color(0xFF2E7D32)
                              : Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _isOnline
                                    ? 'You are Online'
                                    : 'You are Offline',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isOnline
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey,
                                )),
                            Text(
                                _isOnline
                                    ? 'Receiving delivery requests'
                                    : 'Not accepting deliveries',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOnline,
                        onChanged: _toggleOnline,
                        activeColor: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                    label: const Text('Log Out',
                        style: TextStyle(color: Color(0xFFBA1A1A))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBA1A1A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditPersonalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.edit_outlined, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Text('Edit Personal Details'),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline))),
            SizedBox(height: 12),
            TextField(
                decoration: InputDecoration(
                    labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone),
            SizedBox(height: 12),
            TextField(
                decoration: InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Details updated!'),
                    backgroundColor: Color(0xFF1565C0)),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DeliveryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DeliveryStatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF90CAF9)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 22),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _DeliveryProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _DeliveryProfileItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1565C0)),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
