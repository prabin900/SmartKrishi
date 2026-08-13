import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _addressController = TextEditingController(text: 'Lalitpur, Nepal');
  final _phoneController = TextEditingController(text: '9841234567');
  String _fulfillmentMode = 'HOME_DELIVERY'; // 'HOME_DELIVERY' or 'FARM_VISIT'
  DateTime _visitDate = DateTime.now().add(const Duration(days: 1));
  int _visitGuests = 1;
  String _paymentMethod = 'COD';

  @override
  Widget build(BuildContext context) {
    final isFarmVisit = _fulfillmentMode == 'FARM_VISIT';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cart Summary Header
            const Text('Order Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Organic Vine Tomatoes x 2 kg'),
                        Text('Rs. 240.00'),
                      ],
                    ),
                    const Divider(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mustang Highland Apples x 1 kg'),
                        Text('Rs. 220.00'),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
                        Text(isFarmVisit ? 'Rs. 0.00 (Farm Pick)' : 'Rs. 50.00', style: TextStyle(color: isFarmVisit ? Colors.green : Colors.grey)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(isFarmVisit ? 'Rs. 460.00' : 'Rs. 510.00',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fulfillment Mode Selection
            const Text('Fulfillment Option', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: _fulfillmentMode == 'HOME_DELIVERY' ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
              leading: Radio<String>(
                value: 'HOME_DELIVERY',
                groupValue: _fulfillmentMode,
                activeColor: const Color(0xFF2E7D32),
                onChanged: (val) => setState(() => _fulfillmentMode = val!),
              ),
              title: const Text('Home Delivery (Standard)'),
              subtitle: const Text('Delivered to your address by local courier'),
              trailing: const Icon(Icons.local_shipping_outlined),
              onTap: () => setState(() => _fulfillmentMode = 'HOME_DELIVERY'),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: _fulfillmentMode == 'FARM_VISIT' ? const Color(0xFFFFF3E0) : Colors.grey.shade50,
              leading: Radio<String>(
                value: 'FARM_VISIT',
                groupValue: _fulfillmentMode,
                activeColor: const Color(0xFFE65100),
                onChanged: (val) => setState(() => _fulfillmentMode = val!),
              ),
              title: const Row(
                children: [
                  Text('Direct Field Purchase / Farm Visit Buy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(width: 6),
                  Icon(Icons.nature_people, color: Color(0xFFE65100), size: 18),
                ],
              ),
              subtitle: const Text('Visit the farmer field to inspect & pick produce directly (Zero Delivery Fee!)'),
              onTap: () => setState(() => _fulfillmentMode = 'FARM_VISIT'),
            ),
            if (isFarmVisit) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule Farm Visit Pick', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100))),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month, color: Color(0xFFE65100)),
                      title: Text('Visit Date: ${_visitDate.year}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: _visitDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (dt != null) setState(() => _visitDate = dt);
                      },
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people, color: Color(0xFFE65100), size: 20),
                        const SizedBox(width: 8),
                        const Text('Visitors:'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () { if (_visitGuests > 1) setState(() => _visitGuests--); },
                        ),
                        Text('$_visitGuests', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => setState(() => _visitGuests++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Delivery / Pick Details
            Text(isFarmVisit ? 'Farm Field Location' : 'Delivery Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: isFarmVisit ? 'Farm Pick Address' : 'Delivery Address',
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Contact Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Options
            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: Radio<String>(
                value: 'COD',
                groupValue: _paymentMethod,
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              title: Text(isFarmVisit ? 'Pay Cash at Farm Field' : 'Cash on Delivery'),
              trailing: const Icon(Icons.money),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'ESEWA',
                groupValue: _paymentMethod,
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              title: const Text('eSewa Wallet'),
              trailing: const Icon(Icons.account_balance_wallet, color: Colors.green),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'KHALTI',
                groupValue: _paymentMethod,
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              title: const Text('Khalti Wallet'),
              trailing: const Icon(Icons.wallet, color: Colors.purple),
            ),
            const SizedBox(height: 32),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFarmVisit
                          ? 'Order & Field Visit Booked for ${_visitDate.year}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}!'
                          : 'Order Placed Successfully!'),
                      backgroundColor: isFarmVisit ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    ),
                  );
                  context.go('/customer');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFarmVisit ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isFarmVisit ? 'Confirm Order & Schedule Field Visit' : 'Place Order',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
