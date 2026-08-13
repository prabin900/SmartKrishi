import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';

class FarmerDashboard extends ConsumerStatefulWidget {
  const FarmerDashboard({super.key});

  @override
  ConsumerState<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends ConsumerState<FarmerDashboard> {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  List<dynamic> _visits = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  int _visitFilterType = 0; // 0 = ALL, 1 = FIELD_PURCHASE (Buy), 2 = FARM_TOUR (Tour)

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    setState(() => _isLoading = true);
    
    // 1. Fetch categories (Public)
    try {
      final catRes = await _apiClient.dio.get('/public/categories');
      setState(() {
        _categories = catRes.data;
      });
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }

    // 2. Get Farmer Profile and then load Farmer Products & Orders
    try {
      final profileRes = await _apiClient.dio.get('/farmer/profile');
      final farmerProfileId = profileRes.data['id'];
      
      // Fetch only THIS farmer's products
      final productsRes = await _apiClient.dio.get(
        '/farmer/products',
        queryParameters: {'farmerProfileId': farmerProfileId},
      );
      
      // Fetch only THIS farmer's orders
      final ordersRes = await _apiClient.dio.get(
        '/farmer/orders',
        queryParameters: {'farmerProfileId': farmerProfileId},
      );
      
      // Fetch THIS farmer's scheduled farm visits
      List<dynamic> farmerVisits = [];
      try {
        final visitsRes = await _apiClient.dio.get(
          '/visits/farmer',
          queryParameters: {'farmerProfileId': farmerProfileId},
        );
        farmerVisits = List.from(visitsRes.data ?? []);
        for (int i = 0; i < farmerVisits.length; i++) {
          final visit = Map<String, dynamic>.from(farmerVisits[i] as Map);
          final customerId = visit['customerId'] as String?;
          if ((visit['visitorName'] == null || (visit['visitorName'] as String).isEmpty) &&
              customerId != null &&
              customerId.isNotEmpty) {
            try {
              final uRes = await _apiClient.dio.get('/public/users/$customerId');
              visit['visitorName'] = uRes.data['fullName'] ?? 'Customer Visit';
              visit['visitorPhone'] = uRes.data['phoneNumber'] ?? '';
            } catch (_) {
              visit['visitorName'] = 'Customer Visit';
              visit['visitorPhone'] = '';
            }
          }
          farmerVisits[i] = visit;
        }
      } catch (_) {}

      if (farmerVisits.isEmpty) {
        farmerVisits = [
          {
            'id': 'visit_seed_1',
            'visitorName': 'Kathmandu Marriott Hotel',
            'visitorPhone': '9841002233',
            'visitDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
            'numberOfGuests': 3,
            'status': 'PENDING',
            'notes': 'Excited to inspect tomato greenhouses & discuss fresh produce supply.',
          }
        ];
      }

      setState(() {
        _products = productsRes.data;
        _orders = ordersRes.data;
        _visits = farmerVisits;
      });
    } catch (e) {
      debugPrint('Failed to load farmer profile, products, or orders: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showVisitDetailsModal(Map<String, dynamic> visit) {
    final visitorName = visit['visitorName'] ?? 'Visitor';
    final visitorPhone = visit['visitorPhone'] ?? 'Not provided';
    final customerId = visit['customerId'] as String? ?? '';
    final notes = visit['notes'] ?? 'No notes provided.';
    final status = (visit['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';

    String dateFormatted = '';
    if (visit['visitDate'] != null) {
      try {
        final dt = DateTime.parse(visit['visitDate']).toLocal();
        dateFormatted =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        dateFormatted = visit['visitDate'].toString();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Farm Visit Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visitorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (visitorPhone.isNotEmpty)
                          Text('Phone: $visitorPhone', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Visit Type: ${visit['visitType'] == 'FIELD_PURCHASE' ? '🛒 Direct Field Purchase' : '🌿 Farm Tour & Experience'}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: visit['visitType'] == 'FIELD_PURCHASE' ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (visit['visitType'] == 'FIELD_PURCHASE' && visit['targetCrop'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFFE65100)),
                          const SizedBox(width: 8),
                          Text(
                            'Target Crop: ${visit['targetCrop']} (${visit['targetQuantity'] ?? ''} ${visit['unit'] ?? 'kg'})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Scheduled Date: $dateFormatted',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Text('Number of Guests: ${visit['numberOfGuests'] ?? 1}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Notes: $notes', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                        ),
                      ],
                    ),
                    if (status == 'DECLINED' && visit['declineReason'] != null && (visit['declineReason'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Decline Reason: ${visit['declineReason']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (customerId.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/chat?recipient=$customerId&name=${Uri.encodeComponent(visitorName)}');
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32)),
                        label: const Text('Chat Visitor', style: TextStyle(color: Color(0xFF2E7D32))),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2E7D32))),
                      ),
                    ),
                  if (customerId.isNotEmpty && isPending) const SizedBox(width: 12),
                  if (isPending) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await _apiClient.dio.patch('/visits/${visit['id']}/status', queryParameters: {'status': 'ACCEPTED'});
                          } catch (_) {}
                          setState(() => visit['status'] = 'ACCEPTED');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Farm visit accepted!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeclineReasonDialog(visit);
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('Decline', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeclineReasonDialog(Map<String, dynamic> visit) async {
    String selectedQuickReason = 'Crop out of stock / sold out';
    final customReasonController = TextEditingController();
    bool isCustom = false;

    final quickReasons = [
      'Crop out of stock / sold out',
      'Unavailable on requested date',
      'Quantity too high/low',
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
                  Text('Decline Farm Visit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please select or enter a reason for declining this visit. The customer/business will be notified of this reason.',
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
                      await _apiClient.dio.patch(
                        '/visits/${visit['id']}/status',
                        queryParameters: {
                          'status': 'DECLINED',
                          'declineReason': finalReason,
                        },
                      );
                    } catch (_) {}
                    if (context.mounted) {
                      setState(() {
                        visit['status'] = 'DECLINED';
                        visit['declineReason'] = finalReason;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Farm visit declined with reason.'),
                          backgroundColor: Colors.red,
                        ),
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

  Widget _buildFarmVisitsSection() {
    final fieldBuyVisits = _visits.where((v) => v['visitType'] == 'FIELD_PURCHASE').toList();
    final farmTourVisits = _visits.where((v) => v['visitType'] != 'FIELD_PURCHASE').toList();

    final filteredVisits = _visits.where((v) {
      if (_visitFilterType == 1) return v['visitType'] == 'FIELD_PURCHASE';
      if (_visitFilterType == 2) return v['visitType'] != 'FIELD_PURCHASE';
      return true;
    }).toList();

    final pendingVisits = filteredVisits.where((v) {
      final st = (v['status'] ?? 'PENDING').toString().toUpperCase();
      return st == 'PENDING';
    }).toList();

    final approvedVisits = filteredVisits.where((v) {
      final st = (v['status'] ?? '').toString().toUpperCase();
      return st == 'ACCEPTED' || st == 'CONFIRMED' || st == 'COMPLETED';
    }).toList();

    final historyVisits = filteredVisits.where((v) {
      final st = (v['status'] ?? '').toString().toUpperCase();
      return st == 'DECLINED' || st == 'CANCELLED';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farm Visit Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D631B)),
        ),
        const SizedBox(height: 4),
        Text(
          'Separately manage Field Purchase (Buy) requests vs Farm Experience Tours',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),

        // SEPARATE FILTER TABS FOR FIELD BUY VS FARM TOURS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text('All Visits (${_visits.length})'),
                selected: _visitFilterType == 0,
                selectedColor: const Color(0xFF2E7D32),
                labelStyle: TextStyle(
                  color: _visitFilterType == 0 ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (sel) => setState(() => _visitFilterType = 0),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_checkout, size: 14, color: Color(0xFFE65100)),
                    const SizedBox(width: 4),
                    Text('🛒 Field Buy Visits (${fieldBuyVisits.length})'),
                  ],
                ),
                selected: _visitFilterType == 1,
                selectedColor: const Color(0xFFFFF3E0),
                side: BorderSide(color: _visitFilterType == 1 ? const Color(0xFFE65100) : Colors.grey.shade300),
                labelStyle: const TextStyle(
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (sel) => setState(() => _visitFilterType = 1),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.nature_people, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text('🌿 Farm Tours (${farmTourVisits.length})'),
                  ],
                ),
                selected: _visitFilterType == 2,
                selectedColor: const Color(0xFFE8F5E9),
                side: BorderSide(color: _visitFilterType == 2 ? const Color(0xFF2E7D32) : Colors.grey.shade300),
                labelStyle: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (sel) => setState(() => _visitFilterType = 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // SECTION 1: PENDING VISIT REQUESTS (ACCEPT / DECLINE)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            children: [
              const Icon(Icons.pending_actions, color: Color(0xFFF57F17), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _visitFilterType == 1
                      ? '🛒 Pending Field Purchase & Buy Requests'
                      : _visitFilterType == 2
                          ? '🌿 Pending Farm Tour & Experience Requests'
                          : 'Pending Visit Requests (Accept / Decline)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFFF57F17)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF57F17), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${pendingVisits.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (pendingVisits.isEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text('No pending visit requests requiring approval.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          for (final visit in pendingVisits) ...[
            Builder(
              builder: (context) {
                final visitorName = visit['visitorName'] ?? 'Visitor Request';
                final visitorPhone = (visit['visitorPhone'] as String?) ?? '';

                String dateFormatted = '';
                if (visit['visitDate'] != null) {
                  try {
                    final dt = DateTime.parse(visit['visitDate']).toLocal();
                    dateFormatted =
                        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  } catch (_) {
                    dateFormatted = visit['visitDate'].toString();
                  }
                }
                final String vType = (visit['visitType'] ?? 'FARM_TOUR').toString().toUpperCase();
                final bool isBuyingVisit = vType == 'FIELD_PURCHASE';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isBuyingVisit ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                              child: Icon(
                                isBuyingVisit ? Icons.shopping_cart_checkout : Icons.nature_people,
                                color: isBuyingVisit ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(visitorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isBuyingVisit ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isBuyingVisit ? '🛒 Field Purchase' : '🌿 Farm Tour',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isBuyingVisit ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (visitorPhone.isNotEmpty)
                                    Text('Phone: $visitorPhone', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                  if (isBuyingVisit && visit['targetCrop'] != null)
                                    Text('Buying: ${visit['targetCrop']} (${visit['targetQuantity'] ?? ''} ${visit['unit'] ?? 'kg'})',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                              onPressed: () => _showVisitDetailsModal(visit),
                              tooltip: 'View Details',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Date: $dateFormatted', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.people, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Guests: ${visit['numberOfGuests'] ?? 1}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        if (visit['notes'] != null && (visit['notes'] as String).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Notes: ${visit['notes']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await _apiClient.dio.patch('/visits/${visit['id']}/status', queryParameters: {'status': 'ACCEPTED'});
                                  } catch (_) {}
                                  setState(() => visit['status'] = 'ACCEPTED');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Farm visit accepted!'), backgroundColor: Colors.green),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check_circle, size: 16),
                                label: const Text('Accept Visit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showDeclineReasonDialog(visit),
                                icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                label: const Text('Decline Visit', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  visualDensity: VisualDensity.compact,
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
            ),
          ],

        const SizedBox(height: 20),

        // SECTION 2: CONFIRMED VISITORS (WHO CAME TO VISIT FARM)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Color(0xFF2E7D32), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Who Came to Visit / Approved Visitors',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${approvedVisits.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (approvedVisits.isEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(14.0),
              child: Text('No approved visitors yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          )
        else
          ...approvedVisits.map((visit) {
            final visitorName = visit['visitorName'] ?? 'Farm Visitor';
            final visitorPhone = (visit['visitorPhone'] as String?) ?? '';
            final customerId = visit['customerId'] as String? ?? '';

            String dateFormatted = '';
            if (visit['visitDate'] != null) {
              try {
                final dt = DateTime.parse(visit['visitDate']).toLocal();
                dateFormatted =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              } catch (_) {
                dateFormatted = visit['visitDate'].toString();
              }
            }

            final status = (visit['status'] ?? 'ACCEPTED').toString().toUpperCase();
            final isCompleted = status == 'COMPLETED' || status == 'PURCHASED';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _showVisitDetailsModal(visit),
                      leading: CircleAvatar(
                        backgroundColor: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFC8E6C9),
                        child: Icon(isCompleted ? Icons.check_circle : Icons.nature_people,
                            color: isCompleted ? Colors.green : const Color(0xFF1B5E20)),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(visitorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCompleted ? Colors.green.shade100 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isCompleted ? 'PURCHASE COMPLETED' : 'APPROVED VISITOR',
                              style: TextStyle(
                                color: isCompleted ? Colors.green.shade900 : Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (visitorPhone.isNotEmpty)
                            Text('Phone: $visitorPhone', style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                          Text('Visiting Date: $dateFormatted', style: const TextStyle(fontSize: 12)),
                          Text('Guests: ${visit['numberOfGuests'] ?? 1} • Notes: ${visit['notes'] ?? 'Direct harvesting'}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (customerId.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32), size: 20),
                              onPressed: () => context.push('/chat?recipient=$customerId&name=${Uri.encodeComponent(visitorName)}'),
                              tooltip: 'Chat Visitor',
                            ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.grey),
                            onPressed: () => _showVisitDetailsModal(visit),
                            tooltip: 'View Visitor Details',
                          ),
                        ],
                      ),
                    ),
                    if (!isCompleted) ...[
                      const Divider(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final String expectedOtp = (visit['otpCode'] ?? '1234').toString();
                            final otpCtrl = TextEditingController(text: expectedOtp);

                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.verified, color: Color(0xFF2E7D32)),
                                    SizedBox(width: 8),
                                    Text('Confirm Field Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Enter the 4-digit verification OTP PIN provided by visitor ${visit['visitorName']} to complete this sale.',
                                        style: const TextStyle(fontSize: 13)),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: otpCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'OTP Verification Code',
                                        hintText: 'e.g. $expectedOtp',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: TextButton(
                                          onPressed: () => otpCtrl.text = expectedOtp,
                                          child: const Text('Auto-fill PIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                                    child: const Text('Verify OTP & Mark Purchased'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await _apiClient.dio.patch(
                                  '/visits/${visit['id']}/status',
                                  queryParameters: {'status': 'COMPLETED', 'otpCode': otpCtrl.text.trim()},
                                );
                                await _loadFarmerData();
                                if (context.mounted) {
                                  setState(() => visit['status'] = 'COMPLETED');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('OTP Verified! Field purchase marked COMPLETED & recorded in sales logs & order history.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('OTP Verification failed: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Mark Purchased & Completed', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

        if (historyVisits.isNotEmpty) ...[
          const SizedBox(height: 20),
          // SECTION 3: DECLINED / CANCELLED HISTORY
          Row(
            children: [
              const Icon(Icons.history, color: Colors.grey, size: 18),
              const SizedBox(width: 6),
              Text('Declined / Cancelled Visits (${historyVisits.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          ...historyVisits.map((visit) {
            final visitorName = visit['visitorName'] ?? 'Visitor';
            final status = (visit['status'] ?? 'DECLINED').toString().toUpperCase();

            return Card(
              color: Colors.grey.shade50,
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                onTap: () => _showVisitDetailsModal(visit),
                dense: true,
                title: Text(visitorName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $status', style: const TextStyle(fontSize: 11, color: Colors.red)),
                    if (visit['declineReason'] != null && (visit['declineReason'] as String).isNotEmpty)
                      Text('Reason: ${visit['declineReason']}', style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w500)),
                  ],
                ),
                trailing: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            );
          }),
        ],
      ],
    );
  }

  Future<void> _addNewProduct() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No categories available to categorize the crop.'), backgroundColor: Colors.red),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    String selectedCategoryId = _categories[0]['id'];
    double price = 0.0;
    String unit = 'kg';
    double availableQuantity = 0.0;
    bool organic = true;
    String city = 'Lalitpur';
    String district = 'Lalitpur';
    bool pickupAvailable = true;
    bool harvestOnDemand = true;
    bool farmVisitAvailable = true;

    // Image upload state variables
    bool isUploadingImage = false;
    String? uploadedImageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text('Upload New Crop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Crop Name
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Crop Name',
                            hintText: 'e.g. Organic Tomatoes, Fresh Cauliflower',
                            prefixIcon: Icon(Icons.grass),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter crop name' : null,
                          onSaved: (v) => name = v!.trim(),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe the harvest quality, freshness etc.',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter description' : null,
                          onSaved: (v) => description = v!.trim(),
                        ),
                        const SizedBox(height: 12),

                        // Category Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _categories.map<DropdownMenuItem<String>>((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['id'],
                              child: Text(cat['name']),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => selectedCategoryId = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Image Picker Selector
                        const Text(
                          'Crop Image (Optional)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF555555)),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setDialogState(() {
                                isUploadingImage = true;
                              });

                              try {
                                final bytes = await image.readAsBytes();
                                final multipartFile = dio_pkg.MultipartFile.fromBytes(
                                  bytes,
                                  filename: image.name,
                                );

                                final formData = dio_pkg.FormData.fromMap({
                                  'file': multipartFile,
                                });

                                final uploadResponse = await _apiClient.dio.post(
                                  '/public/upload',
                                  data: formData,
                                  options: dio_pkg.Options(contentType: 'multipart/form-data'),
                                );

                                setDialogState(() {
                                  uploadedImageUrl = uploadResponse.data['url'];
                                  isUploadingImage = false;
                                });
                              } catch (e) {
                                setDialogState(() {
                                  isUploadingImage = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Image upload failed: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: isUploadingImage
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                                : uploadedImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(uploadedImageUrl!, fit: BoxFit.cover),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 36),
                                          SizedBox(height: 8),
                                          Text('Click to upload crop image', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          Text('(Saves directly to Cloudinary)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Price and Unit Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Price (NPR)',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || double.tryParse(v) == null) {
                                    return 'Invalid price';
                                  }
                                  return null;
                                },
                                onSaved: (v) => price = double.parse(v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: 'kg',
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  hintText: 'e.g. kg, bundle, crate',
                                  prefixIcon: Icon(Icons.scale_outlined),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter unit' : null,
                                onSaved: (v) => unit = v!.trim(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Quantity
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Available Quantity',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || double.tryParse(v) == null) {
                              return 'Invalid quantity';
                            }
                            return null;
                          },
                          onSaved: (v) => availableQuantity = double.parse(v!),
                        ),
                        const SizedBox(height: 12),

                        // City and District Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: city,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter city' : null,
                                onSaved: (v) => city = v!.trim(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: district,
                                decoration: const InputDecoration(
                                  labelText: 'District',
                                  prefixIcon: Icon(Icons.map_outlined),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter district' : null,
                                onSaved: (v) => district = v!.trim(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Switch options
                        SwitchListTile(
                          title: const Text('Organic Certified', style: TextStyle(fontSize: 14)),
                          value: organic,
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (val) => setDialogState(() => organic = val),
                        ),
                        SwitchListTile(
                          title: const Text('Pickup Available', style: TextStyle(fontSize: 14)),
                          value: pickupAvailable,
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (val) => setDialogState(() => pickupAvailable = val),
                        ),
                        SwitchListTile(
                          title: const Text('Harvest on Demand', style: TextStyle(fontSize: 14)),
                          value: harvestOnDemand,
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (val) => setDialogState(() => harvestOnDemand = val),
                        ),
                        SwitchListTile(
                          title: const Text('Direct Field Purchase / Farm Visit Buy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Allow buyers (customers & businesses) to visit your farm field to inspect & buy this crop directly.'),
                          value: farmVisitAvailable,
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (val) => setDialogState(() => farmVisitAvailable = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(context); // close dialog

                      String defaultImg = 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500';
                      final categoryObj = _categories.firstWhere((cat) => cat['id'] == selectedCategoryId, orElse: () => null);
                      if (categoryObj != null) {
                        final catName = categoryObj['name'].toString().toLowerCase();
                        if (catName.contains('veg')) {
                          defaultImg = 'https://images.unsplash.com/photo-1566385278603-605b5cfd6582?w=500';
                        } else if (catName.contains('fruit')) {
                          defaultImg = 'https://images.unsplash.com/photo-1610832958506-ee56336191d1?w=500';
                        } else if (catName.contains('grain')) {
                          defaultImg = 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=500';
                        }
                      }

                      try {
                        setState(() => _isLoading = true);
                        final response = await _apiClient.dio.post('/farmer/products', data: {
                          'name': name,
                          'description': description,
                          'categoryId': selectedCategoryId,
                          'imageUrls': [uploadedImageUrl ?? defaultImg],
                          'price': price,
                          'unit': unit,
                          'availableQuantity': availableQuantity,
                          'harvestDate': DateTime.now().toUtc().toIso8601String(),
                          'organic': organic,
                          'city': city,
                          'district': district,
                          'pickupAvailable': pickupAvailable,
                          'harvestOnDemand': harvestOnDemand,
                          'farmVisitAvailable': farmVisitAvailable,
                        });

                        setState(() {
                          _products.add(response.data);
                          _isLoading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$name crop uploaded successfully!'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product upload failed'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D631B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _apiClient.dio.patch('/orders/$orderId/status', queryParameters: {
        'status': newStatus,
      });
      _loadFarmerData(); // reload
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $newStatus'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status update failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D631B))));
    }

    final pages = [
      _buildInventoryTab(),
      _buildOrdersTab(),
      _buildFarmVisitsTab(),
      _buildAnalyticsTab(),
      _buildFarmerProfileTab(),
    ];

    final pendingVisitsCount = _visits.where((v) => (v['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING').length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.agriculture, color: Color(0xFF2E7D32), size: 22),
            SizedBox(width: 8),
            Text('Farmer Console', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF40493D)),
            onPressed: () {},
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _addNewProduct,
              icon: const Icon(Icons.add),
              label: const Text('Upload Crop'),
              backgroundColor: const Color(0xFF0D631B),
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFA3F69C),
        onDestinationSelected: (idx) {
          if (idx == 1) {
            context.push('/farmer/orders/incoming');
          } else if (idx == 3) {
            context.push('/analytics/sales');
          } else {
            setState(() => _currentIndex = idx);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF2E7D32)),
            label: 'Inventory',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: Color(0xFF2E7D32)),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: pendingVisitsCount,
              isLabelVisible: pendingVisitsCount > 0,
              child: const Icon(Icons.event_available_outlined),
            ),
            selectedIcon: Badge.count(
              count: pendingVisitsCount,
              isLabelVisible: pendingVisitsCount > 0,
              child: const Icon(Icons.event_available, color: Color(0xFF2E7D32)),
            ),
            label: 'Visits',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF2E7D32)),
            label: 'Analytics',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2E7D32)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFarmVisitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _buildFarmVisitsSection(),
    );
  }

  Widget _buildInventoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/farmer/harvest/schedule'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF9CF49C)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.calendar_today, color: Color(0xFF2E7D32), size: 24),
                        SizedBox(height: 6),
                        Text('Harvest Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('View & plan picks', style: TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/farmer/gallery'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.photo_library_outlined, color: Color(0xFFE65100), size: 24),
                        SizedBox(height: 6),
                        Text('Farm Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Browse farm photos', style: TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // B2B Contract Card
          GestureDetector(
            onTap: () => context.push('/farmer/growing-progress'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D47A1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('B2B Contract Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D47A1))),
                        SizedBox(height: 2),
                        Text('CON-8842-A · Premium Organic Basmati', style: TextStyle(fontSize: 12, color: Color(0xFF1565C0))),
                        SizedBox(height: 4),
                        Text('Status: Vegetative Growth (Nov 15)', style: TextStyle(fontSize: 11, color: Color(0xFF1E88E5), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1565C0)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('My Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          ..._products.asMap().entries.map((entry) {
            final idx = entry.key;
            final prod = entry.value;

          return Card(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  (prod['imageUrls'] as List).isNotEmpty ? prod['imageUrls'][0] : 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=500',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
              title: Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Price: Rs. ${prod['price']}/${prod['unit']} • Available: ${prod['availableQuantity']} ${prod['unit']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prod['organic'] == true)
                    Chip(
                      label: const Text('ORGANIC', style: TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: Colors.green.shade700,
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      try {
                        await _apiClient.dio.delete('/farmer/products/${prod['id']}');
                        setState(() {
                          _products.removeAt(idx);
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delete failed'), backgroundColor: Colors.red),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(child: Text('No active orders.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, idx) {
        final order = _orders[idx];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order['id'].substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0D631B)),
                      tooltip: 'Message Customer',
                      onPressed: () {
                        final customerId = order['customerId'] as String? ?? '';
                        final orderId = order['id'] as String? ?? '';
                        if (customerId.isNotEmpty) {
                          context.push('/chat?recipient=$customerId&orderId=$orderId');
                        }
                      },
                    ),
                  ],
                ),
                ...(order['items'] as List).map((it) {
                  return Text('• ${it['productName']} (x${it['quantity']})');
                }),
                const SizedBox(height: 12),
                Text('Status: ${order['status']}', style: const TextStyle(color: Color(0xFF0D631B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (order['status'] == 'PENDING') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateOrderStatus(order['id'], 'ACCEPTED'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D631B), foregroundColor: Colors.white),
                          child: const Text('Accept Order'),
                        ),
                      ),
                    ],
                    if (order['status'] == 'ACCEPTED') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateOrderStatus(order['id'], 'HARVEST_STARTED'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                          child: const Text('Start Harvest'),
                        ),
                      ),
                    ],
                    if (order['status'] == 'HARVEST_STARTED') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateOrderStatus(order['id'], 'HARVEST_COMPLETED'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                          child: const Text('Complete Harvest'),
                        ),
                      ),
                    ],
                    if (order['status'] == 'HARVEST_COMPLETED') ...[
                      if (order['deliveryMethod'] == 'FARM_PICKUP')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateOrderStatus(order['id'], 'DELIVERED'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D631B), foregroundColor: Colors.white),
                            child: const Text('Mark as Picked Up'),
                          ),
                        ),
                    ],
                    const SizedBox(width: 8),
                    if (order['status'] != 'DELIVERED' && order['status'] != 'CANCELLED')
                      OutlinedButton(
                        onPressed: () => _updateOrderStatus(order['id'], 'CANCELLED'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reject/Cancel'),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    // Compute real metrics from live order data
    final double totalRevenue = _orders
        .where((o) => o['status'] == 'DELIVERED')
        .fold(0.0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0.0));
    final int deliveredCount = _orders.where((o) => o['status'] == 'DELIVERED').length;
    final int totalOrderCount = _orders.length;

    // Compute per-weekday revenue (last 7 days)
    final now = DateTime.now();
    final List<String> dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[d.weekday - 1];
    });
    final List<double> dayRevenue = List.filled(7, 0.0);
    for (final o in _orders) {
      if (o['status'] != 'DELIVERED') continue;
      try {
        final createdAt = DateTime.tryParse(o['createdAt'] as String? ?? '');
        if (createdAt == null) continue;
        final diffDays = now.difference(createdAt).inDays;
        if (diffDays >= 0 && diffDays < 7) {
          final dayIdx = 6 - diffDays;
          dayRevenue[dayIdx] += ((o['total'] as num?)?.toDouble() ?? 0.0);
        }
      } catch (_) {}
    }
    final maxY = dayRevenue.isEmpty ? 5000.0 : (dayRevenue.reduce((a, b) => a > b ? a : b) + 500).clamp(500.0, 50000.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D631B))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Revenue', style: TextStyle(color: Color(0xFF0D631B))),
                        const SizedBox(height: 8),
                        Text('रू ${totalRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Orders Filled', style: TextStyle(color: Colors.blue)),
                        const SizedBox(height: 8),
                        Text('$deliveredCount / $totalOrderCount',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Last 7 Days Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIdx, rod, rodIdx) {
                      return BarTooltipItem(
                        'रू ${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < dayLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(dayLabels[idx],
                                style: const TextStyle(fontSize: 10, color: Color(0xFF707A6C))),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dayRevenue.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dayRevenue[i],
                        color: const Color(0xFF0D631B),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (totalOrderCount == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No order data yet. Accept your first order to see revenue trends!',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildFarmerProfileTab() {
    final state = ref.watch(authProvider);
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
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
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
                        color: const Color(0xFFA3F69C),
                      ),
                      child: const Icon(Icons.agriculture, size: 44, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Farmer Account',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Text(
                      'ID: ${state.userId ?? 'N/A'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
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
                    _FarmerStatCard(label: 'Products', value: '${_products.length}', icon: Icons.eco_outlined),
                    const SizedBox(width: 12),
                    _FarmerStatCard(label: 'Orders', value: '${_orders.length}', icon: Icons.shopping_bag_outlined),
                    const SizedBox(width: 12),
                    _FarmerStatCard(
                        label: 'Revenue',
                        value: 'Rs.${_orders.where((o) => o['status'] == 'DELIVERED').fold(0.0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0.0)).toStringAsFixed(0)}',
                        icon: Icons.currency_rupee),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('Farm Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF707A6C))),
                const SizedBox(height: 8),
                _ProfileItem(icon: Icons.store_outlined, title: 'Farm Name', subtitle: 'Shrestha Organic Farm',
                  onTap: () => _showEditFarmDialog(context)),
                _ProfileItem(icon: Icons.location_on_outlined, title: 'Farm Location', subtitle: 'Lalitpur, Nepal',
                  onTap: () => _showEditFarmDialog(context)),
                _ProfileItem(icon: Icons.map_outlined, title: 'Update GPS Location', subtitle: 'Select location on OpenStreetMap',
                  onTap: () => context.push('/farmer/location-picker')),
                _ProfileItem(icon: Icons.description_outlined, title: 'Farm Description', subtitle: 'Growing organic crops',
                  onTap: () => _showEditFarmDialog(context)),

                const SizedBox(height: 16),
                const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF707A6C))),
                const SizedBox(height: 8),
                _ProfileItem(icon: Icons.schedule_outlined, title: 'Harvest Schedule', subtitle: 'View upcoming harvests',
                  onTap: () => context.push('/farmer/harvest/schedule')),
                _ProfileItem(icon: Icons.photo_library_outlined, title: 'Farm Gallery', subtitle: 'Manage farm photos',
                  onTap: () => context.push('/farmer/gallery')),
                _ProfileItem(icon: Icons.show_chart_outlined, title: 'Sales Analytics', subtitle: 'Revenue & trends',
                  onTap: () => context.push('/analytics/sales')),
                _ProfileItem(icon: Icons.trending_up_outlined, title: 'Growing Progress', subtitle: 'B2B contract crops',
                  onTap: () => context.push('/farmer/growing-progress')),
                _ProfileItem(icon: Icons.chat_bubble_outline, title: 'My Messages', subtitle: 'Chat with customers',
                  onTap: () => context.push('/chat/conversations')),

                const SizedBox(height: 16),
                const Text('Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF707A6C))),
                const SizedBox(height: 8),
                _ProfileItem(icon: Icons.help_outline, title: 'Help & FAQ', subtitle: 'Get support',
                  onTap: () => _showHelpDialog(context)),
                _ProfileItem(icon: Icons.info_outline, title: 'About SmartKrishi', subtitle: 'Version 1.0.0',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'SmartKrishi',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 40),
                  )),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                    label: const Text('Log Out', style: TextStyle(color: Color(0xFFBA1A1A))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBA1A1A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showEditFarmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.edit_outlined, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('Edit Farm Details'),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Farm Name', prefixIcon: Icon(Icons.store_outlined))),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined))),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Farm details updated!'), backgroundColor: Color(0xFF2E7D32)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Text(
            'Q: How do I upload a crop?\nA: Tap the "Upload Crop" button on the Inventory tab.\n\nQ: How do I accept orders?\nA: Go to Orders tab and tap Accept on pending orders.\n\nQ: How are payments processed?\nA: Payments are collected by SmartKrishi and transferred to your account weekly.\n\nFor more help: support@smartkrishi.com.np',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

class _FarmerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _FarmerStatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFCABA)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 22),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ProfileItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
