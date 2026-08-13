import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/firebase/firestore_tracking_service.dart';
import '../../../../core/network/api_client.dart';

class DeliveryMapPage extends StatefulWidget {
  final String orderId;
  const DeliveryMapPage({super.key, required this.orderId});

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  final ApiClient _apiClient = ApiClient();
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(27.7172, 85.3240); // default Kathmandu
  LatLng _farmLocation = const LatLng(27.6710, 85.3120); // default Lalitpur
  LatLng _customerLocation = const LatLng(27.7192, 85.3340); // target customer
  bool _isLoading = true;
  Timer? _gpsTimer;

  @override
  void initState() {
    super.initState();
    _loadOrderLocationsAndStartTracking();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderLocationsAndStartTracking() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch current GPS location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentLocation = LatLng(position.latitude, position.longitude);

      // 2. Fetch order details from MongoDB backend to get delivery addresses & details
      final orderRes = await _apiClient.dio.get('/orders/${widget.orderId}');
      final orderData = orderRes.data;

      // Fetch farmer profile coordinates
      final farmerProfileId = orderData['farmerProfileId'] as String?;
      if (farmerProfileId != null && farmerProfileId.isNotEmpty) {
        try {
          final farmerRes = await _apiClient.dio.get('/public/farmers/$farmerProfileId');
          final fLat = farmerRes.data['latitude'];
          final fLng = farmerRes.data['longitude'];
          if (fLat != null && fLng != null) {
            _farmLocation = LatLng((fLat as num).toDouble(), (fLng as num).toDouble());
          }
        } catch (e) {
          debugPrint("Failed to load farmer location coordinates: $e");
        }
      }

      // Map locations if backend provides them, or keep realistic fallbacks around Kathmandu
      if (orderData['shippingAddress'] != null) {
        final sa = orderData['shippingAddress'];
        final lat = sa['latitude'];
        final lng = sa['longitude'];
        if (lat != null && lng != null) {
          _customerLocation = LatLng((lat as num).toDouble(), (lng as num).toDouble());
        }
      }

      setState(() {
        _isLoading = false;
      });

      // 3. Start GPS coordinates timer pushing to Firestore every 6 seconds
      _gpsTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
        try {
          Position pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
          });

          await FirestoreTrackingService.updateDeliveryLocation(
            orderId: widget.orderId,
            deliveryPartnerId: "suman_thapa_partner", // mock partner ID or fetch from auth
            latitude: pos.latitude,
            longitude: pos.longitude,
            speed: pos.speed,
            heading: pos.heading,
            onlineStatus: true,
          );
        } catch (e) {
          debugPrint("Failed to update GPS timer location: $e");
        }
      });
    } catch (e) {
      debugPrint("Failed to load order locations or get GPS: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchExternalMap() async {
    final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&origin=${_currentLocation.latitude},${_currentLocation.longitude}&destination=${_customerLocation.latitude},${_customerLocation.longitude}&travelmode=two_wheeler");
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Route Map',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1565C0)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    child: const Icon(Icons.navigation, color: Colors.blue, size: 36),
                  ),
                  Marker(
                    point: _farmLocation,
                    child: const Icon(Icons.agriculture, color: Colors.green, size: 36),
                  ),
                  Marker(
                    point: _customerLocation,
                    child: const Icon(Icons.home, color: Colors.red, size: 36),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Delivery Tracking Active',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your location is being updated to the customer in real-time.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchExternalMap,
                            icon: const Icon(Icons.navigation, color: Colors.white),
                            label: const Text('Navigate (Google Maps)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
