import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_client.dart';

class FarmLocationPickerPage extends StatefulWidget {
  const FarmLocationPickerPage({super.key});

  @override
  State<FarmLocationPickerPage> createState() => _FarmLocationPickerPageState();
}

class _FarmLocationPickerPageState extends State<FarmLocationPickerPage> {
  final ApiClient _apiClient = ApiClient();
  LatLng _pickedLocation = const LatLng(27.7172, 85.3240); // default Kathmandu
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfileOrGPS();
  }

  Future<void> _loadCurrentProfileOrGPS() async {
    setState(() => _isLoading = true);
    try {
      // 1. Try to load location from profile
      final profileRes = await _apiClient.dio.get('/farmer/profile');
      final lat = profileRes.data['latitude'] as double?;
      final lng = profileRes.data['longitude'] as double?;

      if (lat != null && lng != null && lat != 0.0) {
        setState(() {
          _pickedLocation = LatLng(lat, lng);
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("Failed to load profile location: $e");
    }

    // 2. Fallback to current GPS location
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Could not determine GPS location: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveLocation() async {
    setState(() => _isSaving = true);
    try {
      await _apiClient.dio.put(
        '/farmer/profile/location',
        queryParameters: {
          'latitude': _pickedLocation.latitude,
          'longitude': _pickedLocation.longitude,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm location updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, _pickedLocation);
      }
    } catch (e) {
      debugPrint("Failed to save location in backend: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update farm location.'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isSaving = false);
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
        title: const Text('Select Farm Location',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, size: 28),
              onPressed: _saveLocation,
              tooltip: 'Save location',
            )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _pickedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedLocation,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 48),
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
                  children: [
                    const Text(
                      'Tap anywhere on the map to set your farm coordinates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_pickedLocation.latitude.toStringAsFixed(5)} • Lng: ${_pickedLocation.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Confirm & Save Location',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
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
