import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/firebase/analytics_service.dart';

class BookVisitPage extends StatefulWidget {
  final String farmId;
  final String farmName;

  const BookVisitPage({super.key, required this.farmId, required this.farmName});

  @override
  State<BookVisitPage> createState() => _BookVisitPageState();
}

class _BookVisitPageState extends State<BookVisitPage> {
  String _visitType = 'FARM_TOUR'; // 'FARM_TOUR' or 'FIELD_PURCHASE'
  int _selectedDateIdx = 0;
  String _selectedTimeSlot = '10:00 AM - 12:00 PM';
  int _guests = 2;
  
  final _cropCtrl = TextEditingController(text: 'Fresh Organic Produce');
  final _qtyCtrl = TextEditingController(text: '100');
  final _notesCtrl = TextEditingController(text: 'We look forward to visiting your farm.');
  final _apiClient = ApiClient();
  bool _isSubmitting = false;

  late List<Map<String, dynamic>> _dates;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    _dates = List.generate(7, (i) {
      final date = now.add(Duration(days: i));
      return {
        'dateTime': date,
        'month': months[date.month - 1],
        'day': date.day.toString().padLeft(2, '0'),
        'weekday': weekdays[date.weekday - 1],
        'available': date.weekday != DateTime.sunday,
      };
    });
  }

  @override
  void dispose() {
    _cropCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  final List<String> _timeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
  ];

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);
    try {
      final selectedMap = _dates[_selectedDateIdx];
      final DateTime selectedDt = selectedMap['dateTime'] as DateTime;
      final String formattedDateStr = selectedDt.toIso8601String().split('T')[0];

      final double qty = double.tryParse(_qtyCtrl.text.trim()) ?? 100.0;

      await _apiClient.dio.post('/visits', data: {
        'farmerProfileId': widget.farmId.isNotEmpty ? widget.farmId : 'farm_1',
        'visitDate': selectedDt.toUtc().toIso8601String(),
        'numberOfGuests': _guests,
        'visitType': _visitType,
        if (_visitType == 'FIELD_PURCHASE') ...{
          'targetCrop': _cropCtrl.text.trim(),
          'targetQuantity': qty,
          'unit': 'kg',
        },
        'notes': '${_notesCtrl.text.trim()} (Slot: $_selectedTimeSlot)',
      });

      AnalyticsService.logFarmVisitBooked(widget.farmId, widget.farmName, formattedDateStr);

      if (mounted) {
        context.push('/booking/confirmed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book visit: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Book Farm Visit',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm summary hero card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.agriculture, color: Color(0xFF2E7D32), size: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.farmName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C1C))),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF707A6C)),
                            SizedBox(width: 2),
                            Text('Kathmandu Valley, Nepal',
                                style: TextStyle(fontSize: 12, color: Color(0xFF707A6C))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Color(0xFF0D47A1), size: 12),
                              SizedBox(width: 4),
                              Text('Verified Farmer',
                                  style: TextStyle(color: Color(0xFF0D47A1), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Visit Category / Type Selector
            const Text('Select Visit Purpose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _visitType = 'FARM_TOUR'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: _visitType == 'FARM_TOUR' ? const Color(0xFFE8F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _visitType == 'FARM_TOUR' ? const Color(0xFF2E7D32) : const Color(0xFFEEEEEE),
                          width: _visitType == 'FARM_TOUR' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.nature_people, color: Color(0xFF2E7D32), size: 24),
                          const SizedBox(height: 4),
                          const Text('🌿 Farm Tour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Meet farmer & see greenhouses', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _visitType = 'FIELD_PURCHASE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: _visitType == 'FIELD_PURCHASE' ? const Color(0xFFFFF3E0) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _visitType == 'FIELD_PURCHASE' ? const Color(0xFFE65100) : const Color(0xFFEEEEEE),
                          width: _visitType == 'FIELD_PURCHASE' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_cart_checkout, color: Color(0xFFE65100), size: 24),
                          const SizedBox(height: 4),
                          const Text('🛒 Field Purchase Buy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Inspect & buy crops directly', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_visitType == 'FIELD_PURCHASE') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Direct Field Purchase Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cropCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Target Crop / Produce Name',
                        hintText: 'e.g. Tomatoes, Apples, Basmati Rice',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Purchase Quantity (kg)',
                        hintText: 'e.g. 200',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Select Date Section
            const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                itemBuilder: (ctx, i) {
                  final d = _dates[i];
                  final active = i == _selectedDateIdx;
                  final available = d['available'] as bool;
                  return GestureDetector(
                    onTap: available ? () => setState(() => _selectedDateIdx = i) : null,
                    child: Opacity(
                      opacity: available ? 1.0 : 0.4,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 68,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFD4F0D4) : Colors.white,
                          border: Border.all(
                            color: active ? const Color(0xFF2E7D32) : const Color(0xFFEEEEEE),
                            width: active ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(d['month'] as String,
                                style: TextStyle(fontSize: 10, color: active ? const Color(0xFF2E7D32) : const Color(0xFF707A6C), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(d['day'] as String,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: active ? const Color(0xFF2E7D32) : const Color(0xFF1A1C1C))),
                            const SizedBox(height: 4),
                            Text(d['weekday'] as String,
                                style: TextStyle(fontSize: 10, color: active ? const Color(0xFF2E7D32) : const Color(0xFF707A6C))),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Select Time Slot
            const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: _timeSlots.map((slot) {
                final active = slot == _selectedTimeSlot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTimeSlot = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFD4F0D4) : Colors.white,
                      border: Border.all(
                        color: active ? const Color(0xFF2E7D32) : const Color(0xFFEEEEEE),
                        width: active ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        color: active ? const Color(0xFF2E7D32) : const Color(0xFF40493D),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Number of Guests
            const Text('Number of Guests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, color: Color(0xFF707A6C)),
                  const SizedBox(width: 12),
                  const Text('Guests', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF2E7D32)),
                    onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                  ),
                  Text('$_guests', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
                    onPressed: () => setState(() => _guests++),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes for Farmer
            const Text('Notes for Farmer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. We want to see the tomato green houses...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
              ),
            ),
            const SizedBox(height: 36),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
