import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class FarmGalleryPage extends StatefulWidget {
  const FarmGalleryPage({super.key});

  @override
  State<FarmGalleryPage> createState() => _FarmGalleryPageState();
}

class _FarmGalleryPageState extends State<FarmGalleryPage> {
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();

  String _activeFilter = 'All';
  bool _isLoading = true;
  bool _isUploading = false;

  final List<String> _filters = ['All', 'Crops', 'Farm Life', 'Harvesting', 'Events'];

  // Default seed gallery items to display when starting or if profile is fresh
  final List<Map<String, dynamic>> _defaultItems = [
    {
      'id': 'seed-1',
      'url': 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&q=80&w=800',
      'title': 'Precision Agriculture',
      'subtitle': 'Drone surveying the spring crops.',
      'category': 'Crops',
      'color': 0xFF1B4332,
    },
    {
      'id': 'seed-2',
      'url': 'https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&q=80&w=800',
      'title': 'Morning Harvest',
      'subtitle': 'Fresh organic vegetables pick at dawn.',
      'category': 'Harvesting',
      'color': 0xFFE65100,
    },
    {
      'id': 'seed-3',
      'url': 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&q=80&w=800',
      'title': 'Hydroponic Setup',
      'subtitle': 'Indoor vertical nutrient farming.',
      'category': 'Farm Life',
      'color': 0xFF2E7D32,
    },
    {
      'id': 'seed-4',
      'url': 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19655?auto=format&fit=crop&q=80&w=800',
      'title': 'Organic Soil Prep',
      'subtitle': 'Getting high nitrogen fields ready.',
      'category': 'Farm Life',
      'color': 0xFF5D4037,
    },
    {
      'id': 'seed-5',
      'url': 'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?auto=format&fit=crop&q=80&w=800',
      'title': 'Community Field Day',
      'subtitle': 'Local farmers knowledge exchange.',
      'category': 'Events',
      'color': 0xFF0054A7,
    },
    {
      'id': 'seed-6',
      'url': 'https://images.unsplash.com/photo-1592878904946-b3cd8ae243d0?auto=format&fit=crop&q=80&w=800',
      'title': 'Greenhouse Tomatoes',
      'subtitle': 'Organic crop in full ripeness.',
      'category': 'Crops',
      'color': 0xFFBA1A1A,
    },
  ];

  List<Map<String, dynamic>> _userGalleryItems = [];

  @override
  void initState() {
    super.initState();
    _fetchGallery();
  }

  Future<void> _fetchGallery() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/farmer/profile');
      final data = response.data;
      if (data != null && data['galleryImageUrls'] != null) {
        final List<dynamic> urls = data['galleryImageUrls'];
        setState(() {
          _userGalleryItems = urls.map((urlStr) {
            return {
              'id': urlStr,
              'url': urlStr.toString(),
              'title': 'Farm Photo',
              'subtitle': 'Uploaded by farmer',
              'category': 'Farm Life',
              'color': 0xFF2E7D32,
              'isCustom': true,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching farmer profile gallery: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _allItems {
    final combined = [..._userGalleryItems, ..._defaultItems];
    if (_activeFilter == 'All') return combined;
    return combined.where((item) => item['category'] == _activeFilter).toList();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      _showAddPhotoDetailsDialog(imageFile: image);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddPhotoDetailsDialog({XFile? imageFile, String? initialUrl}) {
    final titleController = TextEditingController(text: 'My Farm Snapshot');
    final subtitleController = TextEditingController(text: 'Fresh view from our agricultural site.');
    final urlController = TextEditingController(text: initialUrl ?? '');
    String selectedCategory = 'Crops';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Photo to Farm Gallery',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share photos of your crops, farm life, or harvest events with buyers.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Image Preview
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageFile != null
                          ? (kIsWeb
                              ? Image.network(imageFile.path, fit: BoxFit.cover)
                              : Image.file(File(imageFile.path), fit: BoxFit.cover))
                          : (urlController.text.isNotEmpty
                              ? Image.network(
                                  urlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, size: 48, color: Color(0xFF2E7D32)),
                                      SizedBox(height: 8),
                                      Text('Selected Image Preview', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // URL Input if no local file selected
                  if (imageFile == null) ...[
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'Image Web URL',
                        hintText: 'https://example.com/photo.jpg',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Title Input
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Photo Title',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle Input
                  TextField(
                    controller: subtitleController,
                    decoration: InputDecoration(
                      labelText: 'Description / Subtitle',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selection
                  const Text('Select Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _filters.where((f) => f != 'All').map((cat) {
                      final selected = cat == selectedCategory;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: const Color(0xFFD4F0D4),
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF2E7D32) : Colors.black87,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _executePhotoUpload(
                                imageFile: imageFile,
                                customUrl: urlController.text,
                                title: titleController.text,
                                subtitle: subtitleController.text,
                                category: selectedCategory,
                              );
                            },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Upload & Save Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _executePhotoUpload({
    XFile? imageFile,
    required String customUrl,
    required String title,
    required String subtitle,
    required String category,
  }) async {
    setState(() => _isUploading = true);
    String finalUrl = '';

    try {
      if (imageFile != null) {
        // Upload via Dio multipart
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.name,
          ),
        });

        final uploadRes = await _apiClient.dio.post('/public/upload', data: formData);
        if (uploadRes.data != null && uploadRes.data['url'] != null) {
          finalUrl = uploadRes.data['url'].toString();
        }
      } else if (customUrl.trim().isNotEmpty) {
        finalUrl = customUrl.trim();
      }

      // Fallback if network upload fails or customUrl is empty
      if (finalUrl.isEmpty && imageFile != null) {
        finalUrl = imageFile.path;
      }

      if (finalUrl.isEmpty) {
        finalUrl = 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&q=80&w=800';
      }

      // Persist to backend farmer profile gallery
      try {
        await _apiClient.dio.post(
          '/farmer/profile/gallery',
          queryParameters: {'imageUrl': finalUrl},
        );
      } catch (e) {
        debugPrint('Backend sync error for gallery image: $e');
      }

      // Update local UI state
      setState(() {
        _userGalleryItems.insert(0, {
          'id': finalUrl,
          'url': finalUrl,
          'title': title.isNotEmpty ? title : 'Farm Snapshot',
          'subtitle': subtitle.isNotEmpty ? subtitle : 'Uploaded photo',
          'category': category,
          'color': 0xFF1B4332,
          'isCustom': true,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Photo successfully added to Farm Gallery!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAddOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Farm Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFD4F0D4),
                child: Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              ),
              title: const Text('Take Photo with Camera'),
              subtitle: const Text('Capture live farm activities'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE1F5FE),
                child: Icon(Icons.photo_library, color: Color(0xFF0288D1)),
              ),
              title: const Text('Choose from Photo Gallery'),
              subtitle: const Text('Pick high quality images from device'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.link, color: Color(0xFFE65100)),
              ),
              title: const Text('Add Image Link (URL)'),
              subtitle: const Text('Paste direct image web link'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddPhotoDetailsDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: Text('Are you sure you want to remove "${item['title']}" from your gallery?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final imgUrl = item['url'] as String;

      // Sync backend deletion
      try {
        await _apiClient.dio.delete(
          '/farmer/profile/gallery',
          queryParameters: {'imageUrl': imgUrl},
        );
      } catch (e) {
        debugPrint('Backend deletion error: $e');
      }

      setState(() {
        _userGalleryItems.removeWhere((i) => i['url'] == imgUrl);
        _defaultItems.removeWhere((i) => i['id'] == item['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted from gallery')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _allItems;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Farm Gallery',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF2E7D32)),
            onPressed: _showAddOptionsSheet,
            tooltip: 'Add Photo',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptionsSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Add Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header text
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Farm Showcase Gallery',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1C1C)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4F0D4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${items.length} Photos',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore daily life, vibrant harvests, and sustainable farming practices.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                    ),
                  ],
                ),
              ),

              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: _filters.map((f) {
                    final active = f == _activeFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFD4F0D4) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: active ? const Color(0xFF2E7D32) : const Color(0xFFBFCABA),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (f == 'All') ...[
                              const Icon(Icons.grid_view, size: 14, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active ? const Color(0xFF2E7D32) : const Color(0xFF707A6C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Gallery grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                    : items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 64, color: Color(0xFFBFCABA)),
                                const SizedBox(height: 12),
                                Text(
                                  'No photos in "$_activeFilter" category',
                                  style: const TextStyle(color: Color(0xFF707A6C), fontSize: 15),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showAddOptionsSheet,
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text('Add First Photo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: items.length,
                            itemBuilder: (ctx, i) {
                              final item = items[i];
                              return _GalleryTile(
                                item: item,
                                onTap: () => _showFullscreen(context, item),
                                onDelete: () => _deletePhoto(item),
                              );
                            },
                          ),
              ),
            ],
          ),

          // Uploading overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2E7D32)),
                        SizedBox(height: 16),
                        Text('Uploading farm photo...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullscreen(BuildContext context, Map<String, dynamic> item) {
    final imgUrl = item['url'] as String;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo Header Stack
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 260,
                    child: _buildNetworkOrFileImage(imgUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['category'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1C1C)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['subtitle'] as String,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deletePhoto(item);
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Delete Photo', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkOrFileImage(String pathOrUrl, {required BoxFit fit}) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        },
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF1B4332).withOpacity(0.1),
          child: const Center(child: Icon(Icons.agriculture, size: 48, color: Color(0xFF2E7D32))),
        ),
      );
    } else {
      return Image.file(
        File(pathOrUrl),
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
        ),
      );
    }
  }
}

class _GalleryTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GalleryTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final imgUrl = widget.item['url'] as String;

    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_hovered ? 0.96 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image Background
              _buildTileImage(imgUrl),

              // Bottom Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Category chip top left
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.item['category'] as String,
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Delete quick button top right
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                  ),
                ),
              ),

              // Title and Subtitle at bottom
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      widget.item['subtitle'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTileImage(String urlStr) {
    if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
      return Image.network(
        urlStr,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF1B4332).withOpacity(0.2),
          child: const Center(child: Icon(Icons.landscape, size: 40, color: Color(0xFF2E7D32))),
        ),
      );
    } else {
      return Image.file(
        File(urlStr),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
        ),
      );
    }
  }
}
