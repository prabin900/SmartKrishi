import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import 'cart_provider.dart';
import 'search_page.dart';
import 'profile_page.dart';
import '../../../core/firebase/analytics_service.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _orders = [];
  List<dynamic> _farms = [];
  List<dynamic> _scheduledVisits = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final catRes = await _apiClient.dio.get('/public/categories');
      final prodRes = await _apiClient.dio.get('/public/products');
      
      // Seed some categories if empty
      List<dynamic> cats = catRes.data;
      if (cats.isEmpty) {
        await _apiClient.dio.post('/admin/categories', data: {
          'name': 'Vegetables',
          'description': 'Fresh organic vegetables',
          'imageUrl': 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=500'
        });
        await _apiClient.dio.post('/admin/categories', data: {
          'name': 'Fruits',
          'description': 'Sweet organic orchard fruits',
          'imageUrl': 'https://images.unsplash.com/photo-1610832958506-ee5633619141?w=500'
        });
        final catResRetry = await _apiClient.dio.get('/public/categories');
        cats = catResRetry.data;
      }

      // Seed dummy products if empty (mapped to a mock farmer)
      List<dynamic> prods = prodRes.data;
      if (prods.isEmpty) {
        // Find or register a mock farmer
        await _apiClient.dio.post('/auth/register', data: {
          'email': 'farmer@smartkrishi.com.np',
          'password': 'password123',
          'fullName': 'Ram Prasad Shrestha',
          'phoneNumber': '9841234567',
          'role': 'FARMER',
          'farmName': 'Shrestha Organic Farm',
          'farmAddress': 'Lalitpur, Nepal',
          'farmDescription': 'Growing organic tomatoes and greens.',
          'latitude': 27.6710,
          'longitude': 85.3120,
        });
        
        final loginFarmerResponse = await _apiClient.dio.post('/auth/login', data: {
          'email': 'farmer@smartkrishi.com.np',
          'password': 'password123',
        });
        
        final farmerToken = loginFarmerResponse.data['token'];

        final farmerDio = ApiClient().dio;
        farmerDio.options.headers['Authorization'] = 'Bearer $farmerToken';

        if (cats.isNotEmpty) {
          await farmerDio.post('/farmer/products', data: {
            'name': 'Organic Tomatoes',
            'description': 'Fresh handpicked organic tomatoes directly from Shrestha Organic Farm.',
            'categoryId': cats[0]['id'],
            'imageUrls': ['https://images.unsplash.com/photo-1595855759920-86582396756a?w=500'],
            'price': 120.0,
            'unit': 'kg',
            'availableQuantity': 150.0,
            'organic': true,
            'city': 'Lalitpur',
            'district': 'Lalitpur',
            'pickupAvailable': true,
            'harvestOnDemand': true,
            'farmVisitAvailable': true,
          });

          await farmerDio.post('/farmer/products', data: {
            'name': 'Fresh Nepalese Apples',
            'description': 'Crisp apples from Mustang orchards.',
            'categoryId': cats.length > 1 ? cats[1]['id'] : cats[0]['id'],
            'imageUrls': ['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500'],
            'price': 220.0,
            'unit': 'kg',
            'availableQuantity': 80.0,
            'organic': true,
            'city': 'Kathmandu',
            'district': 'Kathmandu',
            'pickupAvailable': true,
            'harvestOnDemand': false,
            'farmVisitAvailable': true,
          });
        }
        
        final prodResRetry = await _apiClient.dio.get('/public/products');
        prods = prodResRetry.data;
      }

      // Load farms from API or fallback
      List<dynamic> farms = [];
      try {
        final farmerProfilesRes = await _apiClient.dio.get('/public/farmers');
        if (farmerProfilesRes.data != null && (farmerProfilesRes.data as List).isNotEmpty) {
          farms = (farmerProfilesRes.data as List).map((f) {
            return {
              'id': f['id'],
              'farmName': f['farmName'] ?? 'Organic Farm',
              'farmerName': 'Verified Farmer',
              'address': f['farmAddress'] ?? 'Nepal',
              'rating': f['rating'] ?? 4.8,
              'latitude': f['latitude'] ?? 27.6710,
              'longitude': f['longitude'] ?? 85.3120,
            };
          }).toList();
        }
      } catch (_) {}

      if (farms.isEmpty) {
        farms = [
          {
            'id': 'farm_1',
            'farmName': 'Shrestha Organic Farm',
            'farmerName': 'Ram Prasad Shrestha',
            'address': 'Lalitpur, Nepal',
            'rating': 4.8,
            'latitude': 27.6710,
            'longitude': 85.3120,
          },
          {
            'id': 'farm_2',
            'farmName': 'Himalayan Organic Orchard',
            'farmerName': 'Maya Sherpa',
            'address': 'Kathmandu, Nepal',
            'rating': 4.9,
            'latitude': 27.7320,
            'longitude': 85.3350,
          }
        ];
      }

      // Load active orders
      final ordersRes = await _apiClient.dio.get('/customer/orders');
      List<dynamic> orders = List.from(ordersRes.data);

      // Enrich orders with farmerUserId (needed for chat) and delivery rider details
      // Cache lookups to avoid redundant API calls
      final Map<String, String> farmerProfileToUserIdCache = {};
      final Map<String, String> farmerProfileToNameCache = {};
      final Map<String, Map<String, dynamic>> deliveryPartnerCache = {};
      for (int i = 0; i < orders.length; i++) {
        final farmerProfileId = orders[i]['farmerProfileId'] as String?;
        if (farmerProfileId != null && farmerProfileId.isNotEmpty) {
          if (!farmerProfileToUserIdCache.containsKey(farmerProfileId)) {
            try {
              final farmerRes = await _apiClient.dio.get('/public/farmers/$farmerProfileId');
              farmerProfileToUserIdCache[farmerProfileId] =
                  farmerRes.data['userId'] as String? ?? '';
              farmerProfileToNameCache[farmerProfileId] =
                  farmerRes.data['farmName'] as String? ?? 'Farmer';
            } catch (_) {
              farmerProfileToUserIdCache[farmerProfileId] = '';
              farmerProfileToNameCache[farmerProfileId] = 'Farmer';
            }
          }
          // Inject farmerUserId and farmerName into the order map
          orders[i] = Map<String, dynamic>.from(orders[i] as Map)
            ..['farmerUserId'] = farmerProfileToUserIdCache[farmerProfileId]
            ..['farmerName'] = farmerProfileToNameCache[farmerProfileId];
        }

        final partnerId = orders[i]['deliveryPartnerId'] as String?;
        if (partnerId != null && partnerId.isNotEmpty) {
          if (!deliveryPartnerCache.containsKey(partnerId)) {
            try {
              final partnerRes = await _apiClient.dio.get('/public/users/$partnerId');
              deliveryPartnerCache[partnerId] = Map<String, dynamic>.from(partnerRes.data);
            } catch (_) {
              deliveryPartnerCache[partnerId] = {'fullName': 'Delivery Partner', 'phoneNumber': '9803124567'};
            }
          }
          final partnerData = deliveryPartnerCache[partnerId];
          orders[i] = Map<String, dynamic>.from(orders[i] as Map)
            ..['deliveryPartnerName'] = partnerData?['fullName']
            ..['deliveryPartnerPhone'] = partnerData?['phoneNumber'];
        }
      }

      setState(() {
        _categories = cats;
        _products = prods;
        _farms = farms;
        _orders = orders;
        _isLoading = false;
      });

      await _loadVisits();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVisits() async {
    try {
      final visitsRes = await _apiClient.dio.get('/visits/customer');
      List<dynamic> visits = List.from(visitsRes.data ?? []);
      for (int i = 0; i < visits.length; i++) {
        final visit = Map<String, dynamic>.from(visits[i] as Map);
        final farmerProfileId = visit['farmerProfileId'] as String?;
        final farmMatch = _farms.firstWhere(
          (f) => f['id'] == farmerProfileId,
          orElse: () => null,
        );
        if (farmMatch != null) {
          visit['farmName'] = farmMatch['farmName'];
          visit['farmerName'] = farmMatch['farmerName'];
          visit['address'] = farmMatch['address'];
          visit['latitude'] = farmMatch['latitude'];
          visit['longitude'] = farmMatch['longitude'];
        } else if (farmerProfileId != null && farmerProfileId.isNotEmpty) {
          try {
            final fRes = await _apiClient.dio.get('/public/farmers/$farmerProfileId');
            visit['farmName'] = fRes.data['farmName'] ?? 'Organic Farm';
            visit['farmerName'] = 'Verified Farmer';
            visit['address'] = fRes.data['farmAddress'] ?? 'Nepal';
            visit['latitude'] = fRes.data['latitude'] ?? 27.6710;
            visit['longitude'] = fRes.data['longitude'] ?? 85.3120;
          } catch (_) {
            visit['farmName'] = 'Organic Farm';
            visit['farmerName'] = 'Verified Farmer';
            visit['address'] = 'Nepal';
            visit['latitude'] = 27.6710;
            visit['longitude'] = 85.3120;
          }
        } else {
          visit['farmName'] = 'Organic Farm';
          visit['farmerName'] = 'Verified Farmer';
          visit['address'] = 'Nepal';
          visit['latitude'] = 27.6710;
          visit['longitude'] = 85.3120;
        }
        visits[i] = visit;
      }
      if (context.mounted) {
        setState(() {
          _scheduledVisits = visits;
        });
      }
    } catch (e) {
      debugPrint('Failed to load customer scheduled visits: $e');
    }
  }

  void _openFarmLocationMapModal(Map<String, dynamic> farm) {
    final double lat = (farm['latitude'] is num) ? (farm['latitude'] as num).toDouble() : 27.6710;
    final double lng = (farm['longitude'] is num) ? (farm['longitude'] as num).toDouble() : 85.3120;
    final String farmName = farm['farmName'] ?? farm['name'] ?? 'Farm Location';
    final String farmerName = farm['farmerName'] ?? farm['farmer'] ?? 'Local Farmer';
    final String address = farm['address'] ?? farm['city'] ?? 'Nepal';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          farmName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text('Farmer: $farmerName', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('📍 $address', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartkrishi.frontend',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 120,
                        height: 70,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: Text(
                                farmName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.location_on, color: Colors.red, size: 36),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
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
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Navigate Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
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

  Future<void> _cancelVisit(String visitId) async {
    try {
      await _apiClient.dio.patch('/visits/$visitId/status', queryParameters: {'status': 'CANCELLED'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm visit cancelled.'), backgroundColor: Colors.orange),
        );
      }
      await _loadVisits();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel visit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _bookVisit(Map<String, dynamic> farm) {
    final farmId = farm['id'] ?? '';
    final farmName = farm['farmName'] ?? 'Organic Farm';
    context.push('/book-visit?farmId=$farmId&farmName=${Uri.encodeComponent(farmName)}');
  }

  void _addToCart(dynamic product) {
    ref.read(cartProvider.notifier).addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart!'),
        backgroundColor: const Color(0xFF0D631B),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _showCheckoutBottomSheet() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final formKey = GlobalKey<FormState>();
    final streetController = TextEditingController(text: 'Main Street 10');
    final cityController = TextEditingController(text: 'Kathmandu');
    final districtController = TextEditingController(text: 'Kathmandu');
    String fulfillmentMode = 'HOME_DELIVERY';
    DateTime visitDate = DateTime.now().add(const Duration(days: 1));
    int visitGuests = 1;
    final bool isFarmVisitEligible = cart.any((item) =>
        item.product['farmVisitAvailable'] == true || item.product['pickupAvailable'] == true);
    String paymentMethod = 'COD';
    double latitude = 27.7172;
    double longitude = 85.3240;
    bool gpsLocked = false;
    bool isLocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: Color(0xFF0D631B)),
                          SizedBox(width: 8),
                          Text(
                            'Confirm Order & Delivery',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D631B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Fulfillment Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        tileColor: fulfillmentMode == 'HOME_DELIVERY' ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                        leading: Radio<String>(
                          value: 'HOME_DELIVERY',
                          groupValue: fulfillmentMode,
                          activeColor: const Color(0xFF0D631B),
                          onChanged: (val) => setSheetState(() => fulfillmentMode = val!),
                        ),
                        title: const Text('Home Delivery (Standard)'),
                        subtitle: const Text('Delivered to your doorstep (Delivery Fee: Rs. 100)'),
                        trailing: const Icon(Icons.local_shipping_outlined),
                        onTap: () => setSheetState(() => fulfillmentMode = 'HOME_DELIVERY'),
                      ),
                      if (isFarmVisitEligible) ...[
                        const SizedBox(height: 8),
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: fulfillmentMode == 'FARM_VISIT' ? const Color(0xFFFFF3E0) : Colors.grey.shade50,
                          leading: Radio<String>(
                            value: 'FARM_VISIT',
                            groupValue: fulfillmentMode,
                            activeColor: const Color(0xFFE65100),
                            onChanged: (val) => setSheetState(() => fulfillmentMode = val!),
                          ),
                          title: const Row(
                            children: [
                              Text('Direct Field Purchase / Farm Visit Buy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(width: 6),
                              Icon(Icons.nature_people, color: Color(0xFFE65100), size: 18),
                            ],
                          ),
                          subtitle: const Text('Visit the farmer field to pick & buy items directly (Zero Delivery Fee!)'),
                          onTap: () => setSheetState(() => fulfillmentMode = 'FARM_VISIT'),
                        ),
                      ],
                      if (fulfillmentMode == 'FARM_VISIT') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Schedule Farm Visit Pick', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE65100))),
                              const SizedBox(height: 8),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.calendar_month, color: Color(0xFFE65100)),
                                title: Text('Visit Date: ${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}'),
                                trailing: const Icon(Icons.edit, size: 18),
                                onTap: () async {
                                  final dt = await showDatePicker(
                                    context: context,
                                    initialDate: visitDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (dt != null) setSheetState(() => visitDate = dt);
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
                                    onPressed: () { if (visitGuests > 1) setSheetState(() => visitGuests--); },
                                  ),
                                  Text('$visitGuests', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    onPressed: () => setSheetState(() => visitGuests++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: streetController,
                        decoration: InputDecoration(
                          labelText: fulfillmentMode == 'FARM_VISIT' ? 'Farm Pick Address' : 'Street Address',
                          prefixIcon: const Icon(Icons.home_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cityController,
                              decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city)),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: districtController,
                              decoration: const InputDecoration(labelText: 'District', prefixIcon: Icon(Icons.map_outlined)),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter district' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Geolocator GPS location button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Coordinates:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                LocationPermission permission = await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission = await Geolocator.requestPermission();
                                }
                                if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Location permission denied.')),
                                    );
                                  }
                                  return;
                                }

                                setSheetState(() => isLocating = true);
                                Position position = await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );

                                String resolvedStreet = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
                                String resolvedCity = 'Kathmandu';
                                String resolvedDistrict = 'Kathmandu';

                                try {
                                  final geoRes = await _apiClient.dio.get(
                                    'https://nominatim.openstreetmap.org/reverse',
                                    queryParameters: {
                                      'lat': position.latitude,
                                      'lon': position.longitude,
                                      'format': 'json',
                                    },
                                    options: Options(
                                      headers: {
                                        'User-Agent': 'SmartKrishiApp/1.0',
                                      },
                                    ),
                                  );
                                  if (geoRes.data != null && geoRes.data['address'] != null) {
                                    final addr = geoRes.data['address'];
                                    resolvedStreet = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? resolvedStreet;
                                    resolvedCity = addr['city'] ?? addr['town'] ?? addr['village'] ?? resolvedCity;
                                    resolvedDistrict = addr['county'] ?? addr['district'] ?? resolvedDistrict;
                                  }
                                } catch (_) {}

                                setSheetState(() {
                                  latitude = position.latitude;
                                  longitude = position.longitude;
                                  streetController.text = resolvedStreet;
                                  cityController.text = resolvedCity;
                                  districtController.text = resolvedDistrict;
                                  isLocating = false;
                                  gpsLocked = true;
                                });
                              } catch (e) {
                                setSheetState(() => isLocating = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to get location: $e')),
                                  );
                                }
                              }
                            },
                            icon: isLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D631B)),
                                  )
                                : Icon(Icons.my_location, color: gpsLocked ? Colors.green : const Color(0xFF0D631B)),
                            label: Text(
                              gpsLocked ? 'GPS Location Locked' : 'Use Current Location',
                              style: TextStyle(
                                  color: gpsLocked ? Colors.green : const Color(0xFF0D631B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (gpsLocked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            '📍 Latitude: ${latitude.toStringAsFixed(6)}, Longitude: ${longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        tileColor: paymentMethod == 'COD' ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                        leading: Radio<String>(
                          value: 'COD',
                          groupValue: paymentMethod,
                          activeColor: const Color(0xFF0D631B),
                          onChanged: (val) => setSheetState(() => paymentMethod = val!),
                        ),
                        title: Text(fulfillmentMode == 'FARM_VISIT' ? 'Pay at Farm Field / Cash on Pick' : 'Cash on Delivery (COD)'),
                        trailing: const Icon(Icons.payments_outlined),
                        onTap: () => setSheetState(() => paymentMethod = 'COD'),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        tileColor: paymentMethod == 'ESEWA' ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                        leading: Radio<String>(
                          value: 'ESEWA',
                          groupValue: paymentMethod,
                          activeColor: const Color(0xFF0D631B),
                          onChanged: (val) => setSheetState(() => paymentMethod = val!),
                        ),
                        title: const Text('eSewa Wallet (Online)'),
                        trailing: const Icon(Icons.account_balance_wallet, color: Colors.green),
                        onTap: () => setSheetState(() => paymentMethod = 'ESEWA'),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        tileColor: paymentMethod == 'KHALTI' ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                        leading: Radio<String>(
                          value: 'KHALTI',
                          groupValue: paymentMethod,
                          activeColor: const Color(0xFF0D631B),
                          onChanged: (val) => setSheetState(() => paymentMethod = val!),
                        ),
                        title: const Text('Khalti SDK (Online)'),
                        trailing: const Icon(Icons.wallet, color: Colors.purple),
                        onTap: () => setSheetState(() => paymentMethod = 'KHALTI'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context); // close sheet

                              if (paymentMethod == 'ESEWA' || paymentMethod == 'KHALTI') {
                                await _showOnlinePaymentLoading(paymentMethod);
                              }

                              await _placeOrder(
                                streetAddress: fulfillmentMode == 'FARM_VISIT' ? 'Direct Field Pick (Farmer Orchard)' : streetController.text.trim(),
                                city: cityController.text.trim(),
                                district: districtController.text.trim(),
                                paymentMethod: paymentMethod,
                                deliveryMethod: fulfillmentMode,
                                visitDate: visitDate,
                                visitGuests: visitGuests,
                                latitude: latitude,
                                longitude: longitude,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: fulfillmentMode == 'FARM_VISIT' ? const Color(0xFFE65100) : const Color(0xFF0D631B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            fulfillmentMode == 'FARM_VISIT' ? 'Confirm Order & Schedule Field Visit' : 'Place Order & Pay',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showOnlinePaymentLoading(String method) async {
    final isEsewa = method == 'ESEWA';
    final primaryColor = isEsewa ? const Color(0xFF60BB46) : Colors.purple;
    final title = isEsewa ? 'eSewa Secure Payment' : 'Khalti Payment Gateway';
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.security, color: primaryColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 20),
              Text('Connecting to $method portal...', style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text('Please do not close or refresh this page.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.pop(context); // close connecting dialog

    // Success Screen Dialogue
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text('Payment Authorized!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Successfully debited from $method wallet.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Proceed to Order Placement', style: TextStyle(color: Color(0xFF0D631B))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _placeOrder({
    required String streetAddress,
    required String city,
    required String district,
    required String paymentMethod,
    required String deliveryMethod,
    required DateTime visitDate,
    required int visitGuests,
    required double latitude,
    required double longitude,
  }) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final isFarmVisit = deliveryMethod == 'FARM_VISIT';
    final double deliveryFee = isFarmVisit ? 0.0 : 100.0;
    final totalVal = ref.read(cartProvider.notifier).getCartTotal();

    try {
      setState(() => _isLoading = true);
      final farmerId = cart[0].product['farmerProfileId'];
      final itemsReq = cart.map((item) {
        return {
          'productId': item.product['id'],
          'productName': item.product['name'],
          'productImage': (item.product['imageUrls'] as List).isEmpty ? '' : item.product['imageUrls'][0],
          'unitPrice': item.product['price'],
          'quantity': item.quantity * 1.0,
          'unit': item.product['unit'],
        };
      }).toList();

      final String notes = isFarmVisit
          ? 'Direct Field Purchase & Visit Pick on ${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}'
          : 'Deliver fresh after 10 AM';

      final response = await _apiClient.dio.post('/customer/orders', data: {
        'farmerProfileId': farmerId,
        'items': itemsReq,
        'subtotal': totalVal,
        'deliveryFee': deliveryFee,
        'discount': 0.0,
        'total': totalVal + deliveryFee,
        'deliveryMethod': deliveryMethod,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'isBulkOrder': false,
        'shippingAddress': {
          'streetAddress': streetAddress,
          'city': city,
          'district': district,
          'state': 'Bagmati',
          'latitude': latitude,
          'longitude': longitude,
        }
      });

      if (isFarmVisit && farmerId != null && (farmerId as String).isNotEmpty) {
        final String cropNames = cart.map((item) => (item.product['name'] ?? 'Produce').toString()).join(', ');
        final double totalUnits = cart.fold(0.0, (sum, item) => sum + item.quantity);
        try {
          await _apiClient.dio.post('/visits', data: {
            'farmerProfileId': farmerId,
            'visitDate': visitDate.toUtc().toIso8601String(),
            'numberOfGuests': visitGuests,
            'visitType': 'FIELD_PURCHASE',
            'targetCrop': cropNames,
            'targetQuantity': totalUnits,
            'unit': 'kg',
            'notes': 'Order #${response.data['id']} - Direct Field Purchase & Pick',
          });
          await _loadVisits();
        } catch (_) {}
      }

      AnalyticsService.logOrderPlaced(
        response.data['id']?.toString() ?? '',
        (response.data['total'] as num?)?.toDouble() ?? 0.0,
        cart.length,
      );

      if (!context.mounted) return;
      ref.read(cartProvider.notifier).clearCart();
      setState(() {
        _orders.insert(0, response.data);
        _currentIndex = 4; // Shift to Orders tracking tab
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isFarmVisit ? 'Order & Field Visit Booked!' : 'Order Placed Successfully'),
          content: Text(
            isFarmVisit
                ? 'Your order and field visit have been booked with the farmer. You can visit the farm on ${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')} to collect your fresh produce directly!\n\nOrder ID: ${response.data['id']}'
                : 'Your order has been sent to the farmer. Tracking ID: ${response.data['id']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D631B))),
      );
    }

    final pages = [
      _buildHomeTab(),
      const SearchPage(),
      _buildVisitTab(),
      _buildCartTab(),
      _buildOrdersTab(),
      const ProfilePage(),
    ];

    final cartCount = ref.watch(cartProvider.notifier).getCartCount();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Color(0xFF2E7D32), size: 22),
            SizedBox(width: 8),
            Text('SmartKrishi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF40493D)),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFA3F69C),
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2E7D32)),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Color(0xFF2E7D32)),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: _scheduledVisits.length,
              isLabelVisible: _scheduledVisits.isNotEmpty,
              child: const Icon(Icons.agriculture_outlined),
            ),
            selectedIcon: Badge.count(
              count: _scheduledVisits.length,
              isLabelVisible: _scheduledVisits.isNotEmpty,
              child: const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
            ),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart, color: Color(0xFF2E7D32)),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2E7D32)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final filteredProducts = _products.where((p) {
      final name = p['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter Row
          TextField(
            decoration: InputDecoration(
              hintText: 'Search fresh vegetables & fruits...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.push('/farms/map'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.map_outlined, color: Color(0xFF2E7D32), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explore Nearby Farms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
                        SizedBox(height: 2),
                        Text('Find local organic producers on map', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1B5E20)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Categories Grid
          const Text('Browse Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D631B))),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(cat['imageUrl'] ?? 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=500'),
                      ),
                      const SizedBox(height: 4),
                      Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Products List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Produce',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D631B)),
              ),
              Text(
                '${filteredProducts.length} items',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          filteredProducts.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No products available matching criteria.')))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive: 2 cols mobile, 3 cols tablet, 4 cols desktop
                    final double w = constraints.maxWidth;
                    final int cols = w > 900 ? 4 : (w > 600 ? 3 : 2);
                    final double itemWidth = (w - (cols - 1) * 14) / cols;
                    // Fixed card height: image(~55%) + info(~45%)
                    const double imgH = 155;
                    const double infoH = 100;
                    const double cardH = imgH + infoH;
                    final double ratio = itemWidth / cardH;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: ratio,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, idx) {
                        final product = filteredProducts[idx];
                        final imgs = product['imageUrls'] as List? ?? [];
                        final imgUrl = imgs.isNotEmpty
                            ? imgs[0] as String
                            : 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500';
                        final city = product['city'] as String? ?? '';
                        final district = product['district'] as String? ?? '';
                        final locationText = [city, district].where((s) => s.isNotEmpty).join(', ');
                        final isOrganic = product['organic'] == true;
                        final price = product['price'];
                        final unit = product['unit'] ?? 'unit';

                        return GestureDetector(
                          onTap: () => context.push('/product/${product['id']}'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Image ──────────────────────────────
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        imgUrl,
                                        height: imgH,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (_, child, progress) =>
                                            progress == null
                                                ? child
                                                : Container(
                                                    height: imgH,
                                                    color: Colors.grey.shade100,
                                                    child: const Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Color(0xFF2E7D32),
                                                      ),
                                                    ),
                                                  ),
                                        errorBuilder: (_, __, ___) => Container(
                                          height: imgH,
                                          color: Colors.green.shade50,
                                          child: const Center(
                                            child: Icon(Icons.image_not_supported_outlined,
                                                color: Colors.grey, size: 32),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Organic badge
                                    if (isOrganic)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1B5E20),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: const Text(
                                            '🌱 ORGANIC',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Add to cart floating button
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _addToCart(product),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2E7D32),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF2E7D32).withOpacity(0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add_shopping_cart,
                                                  size: 13, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text(
                                                'ADD',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // ── Product Info ───────────────────────
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          product['name']?.toString() ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF1A1A2E),
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Rs. $price',
                                                  style: const TextStyle(
                                                    color: Color(0xFF2E7D32),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '/$unit',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (locationText.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on,
                                                      size: 11,
                                                      color: Colors.grey.shade400),
                                                  const SizedBox(width: 2),
                                                  Expanded(
                                                    child: Text(
                                                      locationText,
                                                      style: TextStyle(
                                                        color: Colors.grey.shade500,
                                                        fontSize: 10,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildVisitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: My Scheduled Visits
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Scheduled Farm Visits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D631B)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF0D631B)),
                onPressed: _loadVisits,
                tooltip: 'Refresh Visits',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_scheduledVisits.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.grey.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No farm visits scheduled yet. Choose a farm below to schedule a visit!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scheduledVisits.length,
              itemBuilder: (context, idx) {
                final visit = _scheduledVisits[idx];
                final status = (visit['status'] ?? 'PENDING').toString().toUpperCase();

                Color statusBg;
                Color statusText;
                String statusDisplay;
                switch (status) {
                  case 'COMPLETED':
                  case 'PURCHASED':
                    statusBg = Colors.green.shade100;
                    statusText = Colors.green.shade900;
                    statusDisplay = 'Completed & Purchased';
                    break;
                  case 'ACCEPTED':
                  case 'CONFIRMED':
                    statusBg = Colors.blue.shade100;
                    statusText = Colors.blue.shade900;
                    statusDisplay = 'Visit Confirmed';
                    break;
                  case 'DECLINED':
                  case 'CANCELLED':
                    statusBg = Colors.red.shade100;
                    statusText = Colors.red.shade900;
                    statusDisplay = '❌ Declined by Farmer';
                    break;
                    statusDisplay = '❌ Declined by Farmer';
                    break;
                    statusText = Colors.red.shade900;
                    statusDisplay = '❌ Declined by Farmer';
                    break;
                  case 'PENDING':
                  default:
                    statusBg = Colors.amber.shade100;
                    statusText = Colors.amber.shade900;
                    statusDisplay = 'Pending Approval';
                    break;
                }

                String dateFormatted = '';
                if (visit['visitDate'] != null) {
                  try {
                    final dt = DateTime.parse(visit['visitDate']).toLocal();
                    dateFormatted =
                        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  } catch (_) {
                    dateFormatted = visit['visitDate'].toString();
                  }
                }

                final bool isAccepted = status == 'ACCEPTED' || status == 'CONFIRMED';
                final bool isCompleted = status == 'COMPLETED' || status == 'PURCHASED';

                final bool isFieldPurchase = visit['visitType'] == 'FIELD_PURCHASE';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      visit['farmName'] ?? 'Farm Visit',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isFieldPurchase ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isFieldPurchase ? '🛒 Field Purchase & Pickup' : '🌿 Farm Tour',
                                      style: TextStyle(
                                        color: isFieldPurchase ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusDisplay,
                                style: TextStyle(color: statusText, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (visit['farmerName'] != null)
                          Text('Farmer: ${visit['farmerName']}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        if (isFieldPurchase && visit['targetCrop'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Target Crop to Buy: ${visit['targetCrop']} (${visit['targetQuantity'] ?? ''} ${visit['unit'] ?? 'kg'})',
                              style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                        if (isAccepted && isFieldPurchase) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pin, color: Color(0xFFE65100), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Show Farmer OTP PIN: ${visit['otpCode'] ?? '1234'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (status == 'DECLINED' || status == 'CANCELLED') ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    (visit['declineReason'] != null && (visit['declineReason'] as String).isNotEmpty)
                                        ? 'Reason for decline: ${visit['declineReason']}'
                                        : 'Reason for decline: Farmer was unable to accept this farm visit / buy request at this time.',
                                    style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Date: $dateFormatted', style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 16),
                            const Icon(Icons.people, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Guests: ${visit['numberOfGuests'] ?? 1}', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        if (visit['notes'] != null && (visit['notes'] as String).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Notes: ${visit['notes']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openFarmLocationMapModal(visit),
                              icon: const Icon(Icons.map, size: 16),
                              label: const Text('Open Map & Navigate', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            if (isAccepted)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await _apiClient.dio.patch('/visits/${visit['id']}/status', queryParameters: {'status': 'COMPLETED'});
                                    await _loadVisits();
                                    await _loadData();
                                  } catch (_) {}
                                  if (context.mounted) {
                                    setState(() => visit['status'] = 'COMPLETED');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Field purchase marked COMPLETED! Updated in your Order History.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Mark Field Purchase Completed', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE65100),
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            if (!isCompleted && status != 'DECLINED' && status != 'CANCELLED')
                              OutlinedButton.icon(
                                onPressed: () => _cancelVisit(visit['id']),
                                icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                label: const Text('Cancel Visit', style: TextStyle(color: Colors.red, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // Section 2: Browse Farms & Schedule Visits
          const Text(
            'Book Farm visits & Direct Harvesting',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D631B)),
          ),
          const SizedBox(height: 8),
          const Text('Browse certified farms and schedule visits to purchase directly from field.'),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _farms.length,
            itemBuilder: (context, idx) {
              final farm = _farms[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(farm['farmName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Farmer: ${farm['farmerName']}', style: TextStyle(color: Colors.grey.shade700)),
                      Text('Location: ${farm['address']}', style: TextStyle(color: Colors.grey.shade600)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('${farm['rating']}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openFarmLocationMapModal(farm),
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: const Text('View Farm Map'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _bookVisit(farm),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D631B),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Book Visit'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildCartTab() {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (cart.isEmpty) {
      return const Center(child: Text('Your shopping cart is empty.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, idx) {
                final item = cart[idx];
                final prod = item.product;
                final qty = item.quantity;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(prod['name']),
                    subtitle: Text('Rs. ${prod['price']} x $qty'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            cartNotifier.decreaseQuantity(prod['id']);
                          },
                        ),
                        Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            cartNotifier.increaseQuantity(prod['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cart Subtotal:', style: TextStyle(fontSize: 16)),
                      Text('Rs. ${cartNotifier.getCartTotal()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery Logistics Fee:', style: TextStyle(fontSize: 16)),
                      Text('Rs. 100.0', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Sum:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Rs. ${cartNotifier.getCartTotal() + 100.0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D631B))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showCheckoutBottomSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D631B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Checkout Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFBFCABA)),
            const SizedBox(height: 12),
            const Text('No active orders yet',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _currentIndex = 0),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D631B), foregroundColor: Colors.white),
              child: const Text('Browse Products'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, idx) {
        final order = _orders[idx];
        final farmerUserId = order['farmerUserId'] as String? ?? '';
        final orderId = order['id'] as String? ?? '';
        final isFarmVisit = order['deliveryMethod'] == 'FARM_VISIT';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  child: Text('Order #${orderId.substring(0, 8).toUpperCase()}'),
                ),
                if (isFarmVisit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text('🚜 DIRECT FIELD BUY', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (order['status'] == 'CANCELLED' || order['status'] == 'DECLINED')
                      ? 'Status: ❌ Declined by Farmer • रू ${order['total']}'
                      : (isFarmVisit
                          ? 'Fulfillment: Farm Pick • Status: ${order['status']} • रू ${order['total']}'
                          : 'Status: ${order['status']} • रू ${order['total']}'),
                  style: TextStyle(
                    color: (order['status'] == 'CANCELLED' || order['status'] == 'DECLINED')
                        ? Colors.red.shade800
                        : null,
                    fontWeight: (order['status'] == 'CANCELLED' || order['status'] == 'DECLINED')
                        ? FontWeight.bold
                        : null,
                  ),
                ),
                if ((order['status'] == 'CANCELLED' || order['status'] == 'DECLINED') && order['declineReason'] != null && (order['declineReason'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Reason: ${order['declineReason']}', style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order['status'] == 'CANCELLED' || order['status'] == 'DECLINED') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 18),
                                const SizedBox(width: 6),
                                Text('Order Declined by Farmer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (order['declineReason'] != null && (order['declineReason'] as String).isNotEmpty)
                                  ? 'Reason: ${order['declineReason']}'
                                  : 'Reason: Farmer was unable to fulfill this order request.',
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Text('Order Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(order['items'] as List).map((it) {
                      return Text('• ${it['productName']} (x${it['quantity']}) - रू ${it['totalPrice']}');
                    }),
                    const SizedBox(height: 16),
                    Text('Delivery OTP: ${order['otpCode']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D631B))),
                    const SizedBox(height: 8),
                    Text('QR: ${order['qrCodeData']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    if (order['deliveryPartnerName'] != null) ...[
                      const SizedBox(height: 16),
                      const Text('Assigned Rider:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${order['deliveryPartnerName']}'),
                              Text('Phone: ${order['deliveryPartnerPhone']}'),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32)),
                            onPressed: () => context.push('/chat?recipient=${order['deliveryPartnerId']}&name=${order['deliveryPartnerName']}'),
                            tooltip: 'Chat with Rider',
                          )
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Order Timeline:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildTimelineStep('PENDING', 'Order placed', true),
                    if (order['status'] == 'CANCELLED' || order['status'] == 'DECLINED')
                      _buildTimelineStep('CANCELLED', 'Declined by farmer', true)
                    else ...[
                      _buildTimelineStep('ACCEPTED', 'Accepted by farmer', order['status'] != 'PENDING'),
                      _buildTimelineStep('HARVEST_STARTED', 'Fresh harvesting started', order['status'] == 'HARVEST_STARTED' || order['status'] == 'HARVEST_COMPLETED' || order['status'] == 'DELIVERED'),
                      _buildTimelineStep('DELIVERED', 'Delivered to customer', order['status'] == 'DELIVERED'),
                    ],
                    const SizedBox(height: 16),
                    // Action buttons row
                    Row(
                      children: [
                        if (farmerUserId.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final farmerName = order['farmerName'] as String? ?? 'Farmer';
                                context.push(
                                    '/chat?recipient=$farmerUserId&name=${Uri.encodeComponent(farmerName)}&orderId=$orderId');
                              },
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 16, color: Color(0xFF2E7D32)),
                              label: const Text('Chat Farmer',
                                  style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2E7D32)),
                              ),
                            ),
                          ),
                        if (farmerUserId.isNotEmpty) const SizedBox(width: 8),
                        if (order['status'] == 'ACCEPTED' || order['status'] == 'HARVEST_STARTED' || order['status'] == 'HARVEST_COMPLETED' || order['status'] == 'OUT_FOR_DELIVERY')
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/order/tracking/$orderId'),
                              icon: const Icon(Icons.location_on, color: Colors.white, size: 16),
                              label: const Text('Track Order', style: TextStyle(color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D631B)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineStep(String step, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            color: active ? const Color(0xFF0D631B) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
