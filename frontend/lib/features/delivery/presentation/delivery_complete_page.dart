import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeliveryCompletePage extends StatefulWidget {
  final String? orderId;
  final double? earnings;
  final double? distanceKm;
  final int? timeMins;

  const DeliveryCompletePage({
    super.key,
    this.orderId,
    this.earnings,
    this.distanceKm,
    this.timeMins,
  });

  @override
  State<DeliveryCompletePage> createState() => _DeliveryCompletePageState();
}

class _DeliveryCompletePageState extends State<DeliveryCompletePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earnings = widget.earnings ?? 45.0;
    final distance = widget.distanceKm ?? 5.2;
    final mins = widget.timeMins ?? 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Animated success icon
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4F0D4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 64),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(_slideAnim),
                      child: FadeTransition(
                        opacity: _slideAnim,
                        child: Column(
                          children: [
                            const Text(
                              'Delivery Successful!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Great job completing this trip safely.',
                              style: TextStyle(fontSize: 15, color: Color(0xFF40493D)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Earnings card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFBFCABA), width: 2),
                              ),
                              child: Column(
                                children: [
                                  const Text('EARNINGS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF707A6C),
                                        letterSpacing: 1.5,
                                      )),
                                  const SizedBox(height: 4),
                                  Text(
                                    'रू ${earnings.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Icon(Icons.route_outlined, color: Color(0xFF246DC8), size: 28),
                                            const SizedBox(height: 4),
                                            const Text('Distance',
                                                style: TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
                                            Text('${distance.toStringAsFixed(1)} km',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                      Container(width: 1, height: 48, color: const Color(0xFFEEEEEE)),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Icon(Icons.schedule_outlined, color: Color(0xFF246DC8), size: 28),
                                            const SizedBox(height: 4),
                                            const Text('Time Taken',
                                                style: TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
                                            Text('$mins mins',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Bonus info
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FFF0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF9CF49C)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.stars_outlined, color: Color(0xFF2E7D32), size: 22),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Keep it up!',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                                        Text('5 deliveries to unlock Platinum Partner badge',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF40493D))),
                                      ],
                                    ),
                                  ),
                                ],
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

            // Fixed bottom actions
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 2)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/delivery/today'),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Next Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/delivery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
