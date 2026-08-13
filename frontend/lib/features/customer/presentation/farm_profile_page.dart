import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';

class FarmProfilePage extends ConsumerStatefulWidget {
  final String farmId;

  const FarmProfilePage({super.key, required this.farmId});

  @override
  ConsumerState<FarmProfilePage> createState() => _FarmProfilePageState();
}

class _FarmProfilePageState extends ConsumerState<FarmProfilePage> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _farm;
  List<dynamic> _crops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmProfile();
  }

  Future<void> _loadFarmProfile() async {
    try {
      final farmerRes = await _apiClient.dio.get('/public/farmers/${widget.farmId}');
      final farmData = farmerRes.data;

      final cropsRes = await _apiClient.dio.get('/public/products');
      final allCrops = cropsRes.data as List<dynamic>;

      // Match crops of this farmer
      final farmCrops = allCrops.where((p) => p['farmerProfileId'] == widget.farmId).toList();

      setState(() {
        final List<dynamic> backendGallery = farmData['galleryImageUrls'] != null && (farmData['galleryImageUrls'] as List).isNotEmpty
            ? farmData['galleryImageUrls']
            : [
                'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&q=80&w=600',
                'https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&q=80&w=600',
              ];

        _farm = {
          'id': widget.farmId,
          'farmName': farmData['farmName'] ?? 'Local Farm',
          'farmerName': farmData['fullName'] ?? 'Grower',
          'location': farmData['farmAddress'] ?? 'Nepal',
          'description': farmData['farmDescription'] ?? 'No description provided.',
          'latitude': farmData['latitude'] ?? 27.7,
          'longitude': farmData['longitude'] ?? 85.3,
          'rating': 4.8,
          'gallery': backendGallery,
        };
        _crops = farmCrops;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading farm profile: $e');
      setState(() {
        _farm = {
          'id': widget.farmId,
          'userId': '',
          'farmName': 'Shrestha Organic Farm',
          'farmerName': 'Ram Prasad Shrestha',
          'location': 'Lalitpur, Nepal',
          'description': 'Certified organic farm producing high grade fresh produce using sustainable greenhouses.',
          'latitude': 27.6710,
          'longitude': 85.3120,
          'rating': 4.8,
          'gallery': [
            'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&q=80&w=600',
            'https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&q=80&w=600',
          ],
        };
        _isLoading = false;
      });
    }
  }

  void _bookVisit() {
    final farmId = widget.farmId.isNotEmpty ? widget.farmId : (_farm?['id'] ?? '');
    final farmName = _farm?['farmName'] ?? 'Organic Farm';
    context.push('/book-visit?farmId=$farmId&farmName=${Uri.encodeComponent(farmName)}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))));
    }

    if (_farm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farm Profile')),
        body: const Center(child: Text('Farm details not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_farm!['farmName'], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              final farmerUserId = _farm!['userId'] as String? ?? '';
              final farmerName = _farm!['farmName'] as String? ?? 'Farmer';
              if (farmerUserId.isNotEmpty) {
                context.push('/chat?recipient=$farmerUserId&name=$farmerName');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to contact farmer')),
                );
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel Gallery
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (_farm!['gallery'] as List).length,
                itemBuilder: (context, idx) {
                  final imgUrl = _farm!['gallery'][idx];
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF2E7D32),
                        child: Icon(Icons.agriculture, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_farm!['farmerName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Rating: ⭐ ${_farm!['rating']} • Certified Local', style: const TextStyle(color: Colors.grey)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('About the Farm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_farm!['description'], style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15)),
                  const Divider(height: 40),
                  const Text('Location Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Address: ${_farm!['location']}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  // OpenStreetMap view
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(_farm!['latitude'], _farm!['longitude']),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_farm!['latitude'], _farm!['longitude']),
                                child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final double lat = (_farm!['latitude'] is num) ? (_farm!['latitude'] as num).toDouble() : 27.6710;
                        final double lng = (_farm!['longitude'] is num) ? (_farm!['longitude'] as num).toDouble() : 85.3120;
                        final Uri googleMapsUrl = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
                        );
                        if (await canLaunchUrl(googleMapsUrl)) {
                          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not launch Google Maps navigation')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Open Map & Start Navigation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Crops Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${_crops.length} items', style: const TextStyle(color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _crops.isEmpty
                      ? const Text('No crops listed under this farm inventory currently.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _crops.length,
                          itemBuilder: (context, idx) {
                            final crop = _crops[idx];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                                title: Text(crop['name'] ?? ''),
                                subtitle: Text('Rs. ${crop['price']} per ${crop['unit']}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/product/${crop['id']}'),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _bookVisit,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Schedule Farm Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
