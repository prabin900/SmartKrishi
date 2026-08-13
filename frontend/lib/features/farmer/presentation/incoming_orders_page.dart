import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class IncomingOrdersPage extends ConsumerStatefulWidget {
  const IncomingOrdersPage({super.key});

  @override
  ConsumerState<IncomingOrdersPage> createState() => _IncomingOrdersPageState();
}

class _IncomingOrdersPageState extends ConsumerState<IncomingOrdersPage> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadIncomingOrders();
  }

  Future<void> _loadIncomingOrders() async {
    try {
      setState(() => _isLoading = true);
      // Get Farmer Profile first
      final profileRes = await _apiClient.dio.get('/farmer/profile');
      final farmerProfileId = profileRes.data['id'];

      // Fetch only THIS farmer's orders
      final ordersRes = await _apiClient.dio.get(
        '/farmer/orders',
        queryParameters: {'farmerProfileId': farmerProfileId},
      );

      setState(() {
        _orders = ordersRes.data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading incoming orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      setState(() => _isLoading = true);
      await _apiClient.dio.patch('/orders/$id/status', queryParameters: {
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $newStatus'), backgroundColor: Colors.green),
      );
      _loadIncomingOrders();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'Pending') {
      return _orders.where((o) => o['status'] == 'PENDING').toList();
    }
    if (_filter == 'Accepted') {
      return _orders.where((o) => o['status'] == 'ACCEPTED').toList();
    }
    if (_filter == 'Cancelled') {
      return _orders.where((o) => o['status'] == 'CANCELLED').toList();
    }
    return _orders;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _orders.where((o) => o['status'] == 'PENDING').length;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incoming Orders',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C), fontSize: 18),
            ),
            Text(
              'Review and process new requests.',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pendingCount Pending',
                  style: const TextStyle(
                    color: Color(0xFF93000A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D631B)))
          : Column(
              children: [
                // Filter bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: ['All', 'Pending', 'Accepted', 'Cancelled'].map((f) {
                      final active = f == _filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: active,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: const Color(0xFFA3F69C),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: active ? const Color(0xFF005312) : const Color(0xFF40493D),
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(color: active ? const Color(0xFF9CF49C) : const Color(0xFFBFCABA)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No $_filter orders found.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final order = filtered[i];
                            return _OrderCard(
                              order: order,
                              onAccept: () => _updateStatus(order['id'], 'ACCEPTED'),
                              onDecline: () => _showOrderDeclineDialog(order),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _showOrderDeclineDialog(Map<String, dynamic> order) async {
    String selectedQuickReason = 'Crop out of stock / sold out';
    final customReasonController = TextEditingController();
    bool isCustom = false;

    final quickReasons = [
      'Crop out of stock / sold out',
      'Delivery location unserviceable',
      'Insufficient quantity available',
      'Price mismatch / negotiation required',
      'Other',
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Decline Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please select or enter a reason for declining this order. The customer will be informed of this reason.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: quickReasons.map((reason) {
                        final isSelected = (!isCustom && selectedQuickReason == reason) ||
                            (isCustom && reason == 'Other');
                        return ChoiceChip(
                          label: Text(reason, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                          selected: isSelected,
                          selectedColor: Colors.red.shade700,
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                if (reason == 'Other') {
                                  isCustom = true;
                                } else {
                                  isCustom = false;
                                  selectedQuickReason = reason;
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customReasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Details / Custom Reason',
                        hintText: isCustom ? 'Type your decline reason here...' : 'Optional comment...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final finalReason = (isCustom || customReasonController.text.trim().isNotEmpty)
                        ? (customReasonController.text.trim().isNotEmpty
                            ? customReasonController.text.trim()
                            : selectedQuickReason)
                        : selectedQuickReason;

                    Navigator.pop(ctx);
                    try {
                      setState(() => _isLoading = true);
                      await _apiClient.dio.patch(
                        '/orders/${order['id']}/status',
                        queryParameters: {
                          'status': 'CANCELLED',
                          'declineReason': finalReason,
                        },
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order declined with reason.'), backgroundColor: Colors.red),
                      );
                      _loadIncomingOrders();
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Confirm Decline'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _OrderCard({
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status']?.toString().toUpperCase() ?? 'PENDING';
    final isPending = status == 'PENDING';
    final items = widget.order['items'] as List;

    String addrStr = 'Not provided';
    if (widget.order['shippingAddress'] != null) {
      final addr = widget.order['shippingAddress'];
      addrStr = '${addr['streetAddress'] ?? ''}, ${addr['city'] ?? ''}, ${addr['district'] ?? ''}';
    }

    final String paymentMethod = widget.order['paymentMethod'] ?? 'COD';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? const Color(0xFFBA1A1A) : const Color(0xFFBFCABA),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ribbon for Pending action
          if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFFBA1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'NEW – ACTION REQUIRED',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buyer row
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFD4F0D4),
                      radius: 22,
                      child: Text(
                        'B',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buyer Ref: #${widget.order['customerId']?.substring(0, 6).toUpperCase() ?? 'GUEST'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Ref ID: ${widget.order['id']?.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF707A6C)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Delivery Method: ${widget.order['deliveryMethod'] ?? 'HOME_DELIVERY'}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${widget.order['total']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Address & Payment Row
                const Divider(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Shipping Address: $addrStr',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.payment, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Payment Method: $paymentMethod',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                    ),
                  ],
                ),
                const Divider(),

                // Items (collapsed/expanded)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ITEMS REQUESTED',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF707A6C),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: const Color(0xFF707A6C),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...((_expanded ? items : items.take(1)).map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['productName'] as String,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    '${item['quantity']} ${item['unit']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ))),
                        if (!_expanded && items.length > 1)
                          Text(
                            '+${items.length - 1} more item(s)',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                          ),
                        if (widget.order['declineReason'] != null && (widget.order['declineReason'] as String).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Reason for Decline: ${widget.order['declineReason']}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons (only show if status is PENDING)
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onDecline,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBA1A1A)),
                            foregroundColor: const Color(0xFFBA1A1A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: widget.onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
