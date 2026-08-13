import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/firebase/analytics_service.dart';

class NearbyFarmsMapPage extends StatefulWidget {
  const NearbyFarmsMapPage({super.key});

  @override
  State<NearbyFarmsMapPage> createState() => _NearbyFarmsMapPageState();
}

class _NearbyFarmsMapPageState extends State<NearbyFarmsMapPage> {
  final ApiClient _apiClient = ApiClient();
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(27.7172, 85.3240); // default Kathmandu
  List<dynamic> _farms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmsAndLocation();
  }

  Future<void> _loadFarmsAndLocation() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentLocation = LatLng(position.latitude, position.longitude);

      // 2. Fetch all farmer profiles from backend
      final res = await _apiClient.dio.get('/public/farmers');
      setState(() {
        _farms = res.data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load location or farms: $e");
      // Fallback: still show map with default location
      try {
        final res = await _apiClient.dio.get('/public/farmers');
        setState(() {
          _farms = res.data;
        });
      } catch (_) {}
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    final markers = <Marker>[
      // Customer current location marker
      Marker(
        point: _currentLocation,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
      ),
    ];

    // Farmer location markers
    for (var farm in _farms) {
      final lat = farm['latitude'] as double?;
      final lng = farm['longitude'] as double?;
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            child: GestureDetector(
              onTap: () {
                AnalyticsService.logProductViewed(
                    farm['id'] ?? '', farm['farmName'] ?? 'Farm', 0.0);
                _showFarmDetails(farm);
              },
              child: const Icon(Icons.agriculture, color: Color(0xFF2E7D32), size: 36),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farms Near Me',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  void _showFarmDetails(dynamic farm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: Color(0xFF2E7D32), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    farm['farmName'] ?? 'SmartKrishi Farm',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Farmer: ${farm['fullName'] ?? 'Grower'}',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Address: ${farm['farmAddress'] ?? 'Nepal'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              farm['farmDescription'] ?? 'No description provided.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/farm/${farm['id']}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Farm Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
