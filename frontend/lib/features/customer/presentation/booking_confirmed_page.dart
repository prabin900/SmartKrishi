import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Booking Confirmed — farm visit success screen
class BookingConfirmedPage extends StatefulWidget {
  const BookingConfirmedPage({super.key});

  @override
  State<BookingConfirmedPage> createState() => _BookingConfirmedPageState();
}

class _BookingConfirmedPageState extends State<BookingConfirmedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24)],
              ),
              child: Column(
                children: [
                  // Green gradient top
                  Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD4F0D4), Colors.white],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4F0D4),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          const Text(
                            'Booking Confirmed!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF1A1C1C)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(fontSize: 15, color: Color(0xFF40493D), height: 1.5),
                              children: [
                                TextSpan(text: 'Your farm visit to '),
                                TextSpan(
                                  text: 'Highland Organic Orchards',
                                  style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: ' has been successfully scheduled.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Details bento card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFBFCABA).withOpacity(0.5)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: _DetailRow(
                                        icon: Icons.calendar_month,
                                        label: 'DATE',
                                        value: 'Thursday, Nov 12',
                                      ),
                                    ),
                                    Container(width: 1, height: 48, color: const Color(0xFFBFCABA)),
                                    const Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 12),
                                        child: _DetailRow(
                                          icon: Icons.schedule,
                                          label: 'TIME',
                                          value: '10:00 AM – 12:00 PM',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                                const _DetailRow(icon: Icons.location_on_outlined, label: 'LOCATION', value: 'Sindhupalchok, Bagmati Province'),
                                const SizedBox(height: 12),
                                const _DetailRow(icon: Icons.confirmation_number_outlined, label: 'BOOKING REF', value: 'BK-2024-7821'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Reminder row
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.notifications_outlined, color: Color(0xFFE65100), size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "You'll receive a reminder 2 hours before the visit.",
                                    style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action buttons
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/'),
                              icon: const Icon(Icons.home_outlined),
                              label: const Text('Go to Home', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: const Text('View Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(color: Color(0xFF2E7D32)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF707A6C), fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1C1C))),
            ],
          ),
        ),
      ],
    );
  }
}
