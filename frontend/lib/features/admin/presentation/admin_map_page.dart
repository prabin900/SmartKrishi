import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/firebase/firestore_tracking_service.dart';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final ApiClient _apiClient = ApiClient();
  final MapController _mapController = MapController();
  final LatLng _centerLocation = const LatLng(27.7172, 85.3240); // Kathmandu
  List<dynamic> _farmers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    try {
      final res = await _apiClient.dio.get('/public/farmers');
      setState(() {
        _farmers = res.data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load farmers for admin map: $e");
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard Map',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreTrackingService.streamAllActiveDeliveries(),
        builder: (context, snapshot) {
          final markers = <Marker>[];

          // 1. Add static Farmer locations
          for (var farmer in _farmers) {
            final lat = farmer['latitude'] as double?;
            final lng = farmer['longitude'] as double?;
            if (lat != null && lng != null) {
              markers.add(
                Marker(
                  point: LatLng(lat, lng),
                  child: const Tooltip(
                    message: "Farm: Green Valley",
                    child: Icon(Icons.agriculture, color: Colors.green, size: 30),
                  ),
                ),
              );
            }
          }

          // 2. Add dynamic active delivery partner locations
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data();
              final lat = data['latitude'] as double?;
              final lng = data['longitude'] as double?;
              if (lat != null && lng != null) {
                markers.add(
                  Marker(
                    point: LatLng(lat, lng),
                    child: const Tooltip(
                      message: "Active Courier",
                      child: Icon(Icons.delivery_dining, color: Colors.red, size: 36),
                    ),
                  ),
                );
              }
            }
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerLocation,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
