import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/firebase/firestore_tracking_service.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final MapController _mapController = MapController();
  LatLng _customerLocation = const LatLng(27.7172, 85.3240); // default Kathmandu
  final LatLng _farmLocation = const LatLng(27.6710, 85.3120); // default Lalitpur
  LatLng? _deliveryLocation;
  double _distance = 0.0;
  String _eta = "Calculating...";
  String _status = "ACCEPTED";

  @override
  void initState() {
    super.initState();
    _determineCustomerLocation();
  }

  Future<void> _determineCustomerLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _customerLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Could not get current location: $e");
    }
  }

  void _calculateDistanceAndEta(LatLng deliveryLoc) {
    // Basic calculation for live estimates
    double distanceInMeters = Geolocator.distanceBetween(
      deliveryLoc.latitude,
      deliveryLoc.longitude,
      _customerLocation.latitude,
      _customerLocation.longitude,
    );

    setState(() {
      _distance = distanceInMeters / 1000.0; // km
      // assume 25 km/h avg speed
      double timeInMinutes = (_distance / 25.0) * 60;
      if (timeInMinutes < 1) {
        _eta = "Arriving now";
      } else {
        _eta = "${timeInMinutes.toStringAsFixed(0)} mins";
      }
    });
  }

  Future<void> _launchExternalMap() async {
    final destination = _deliveryLocation ?? _farmLocation;
    final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch maps navigation")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Delivery Tracking',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreTrackingService.streamDeliveryLocation(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              final lat = data['latitude'] as double?;
              final lng = data['longitude'] as double?;
              if (lat != null && lng != null) {
                _deliveryLocation = LatLng(lat, lng);
                _calculateDistanceAndEta(_deliveryLocation!);
              }
              _status = data['onlineStatus'] == true ? "OUT_FOR_DELIVERY" : "ACCEPTED";
            }
          }

          final markers = <Marker>[
            Marker(
              point: _customerLocation,
              child: const Icon(Icons.home, color: Colors.blue, size: 36),
            ),
            Marker(
              point: _farmLocation,
              child: const Icon(Icons.agriculture, color: Colors.green, size: 36),
            ),
          ];

          if (_deliveryLocation != null) {
            markers.add(
              Marker(
                point: _deliveryLocation!,
                child: const Icon(Icons.delivery_dining, color: Colors.red, size: 40),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _deliveryLocation ?? _customerLocation,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ETA to Destination',
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(_eta,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Distance Remaining',
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('${_distance.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32))),
                              ],
                            )
                          ],
                        ),
                        const Divider(height: 24),
                        const Text('Delivery Status',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusDot('Order Placed', true),
                            _buildStatusLine(true),
                            _buildStatusDot('Out for Delivery', _status == "OUT_FOR_DELIVERY" || _status == "DELIVERED"),
                            _buildStatusLine(_status == "DELIVERED"),
                            _buildStatusDot('Delivered', _status == "DELIVERED"),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _launchExternalMap,
                            icon: const Icon(Icons.navigation, color: Colors.white),
                            label: const Text('Navigate (Google Maps)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusDot(String label, bool active) {
    return Column(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? const Color(0xFF2E7D32) : Colors.grey,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.black : Colors.grey)),
      ],
    );
  }

  Widget _buildStatusLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? const Color(0xFF2E7D32) : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }
}
