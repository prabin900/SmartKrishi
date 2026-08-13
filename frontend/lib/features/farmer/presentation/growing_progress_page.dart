import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class GrowingProgressPage extends StatefulWidget {
  const GrowingProgressPage({super.key});

  @override
  State<GrowingProgressPage> createState() => _GrowingProgressPageState();
}

class _GrowingProgressPageState extends State<GrowingProgressPage> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;

  List<dynamic> _myContracts = [];
  List<dynamic> _openContracts = [];
  final Map<String, Map<String, dynamic>> _businesses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContracts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final myContractsRes = await _apiClient.dio.get('/contracts/farmer');
      final openContractsRes = await _apiClient.dio.get('/contracts/available');

      setState(() {
        _myContracts = myContractsRes.data ?? [];
        _openContracts = openContractsRes.data ?? [];
        _isLoading = false;
      });

      final businessIds = <String>{};
      for (final c in _myContracts) {
        if (c['businessProfileId'] != null) {
          businessIds.add(c['businessProfileId'] as String);
        }
      }
      for (final c in _openContracts) {
        if (c['businessProfileId'] != null) {
          businessIds.add(c['businessProfileId'] as String);
        }
      }
      for (final id in businessIds) {
        _fetchBusinessProfile(id);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBusinessProfile(String businessId) async {
    if (_businesses.containsKey(businessId)) return;
    try {
      final res = await _apiClient.dio.get('/public/businesses/$businessId');
      setState(() {
        _businesses[businessId] = res.data;
      });
    } catch (_) {}
  }

  Future<void> _acceptContract(String contractId) async {
    try {
      await _apiClient.dio.post('/contracts/$contractId/accept');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contract Accepted Successfully!'), backgroundColor: Color(0xFF2E7D32)),
      );
      _loadContracts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept contract: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddMilestoneDialog(String contractId, double currentGrowth) {
    final descCtrl = TextEditingController();
    double growth = currentGrowth;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Growth Progress Milestone', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report current crop growth to the business partner:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Milestone Description',
                  hintText: 'e.g. Sowing completed, sprouting observed',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Growth Completion', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${growth.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ],
              ),
              Slider(
                value: growth,
                min: 0,
                max: 100,
                divisions: 10,
                activeColor: const Color(0xFF2E7D32),
                label: '${growth.toStringAsFixed(0)}%',
                onChanged: (val) => setDialogState(() => growth = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final desc = descCtrl.text.trim();
                if (desc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a description'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _apiClient.dio.post('/contracts/$contractId/milestones', data: {
                    'description': desc,
                    'growthPercentage': growth,
                    'imageUrl': 'https://images.unsplash.com/photo-1593113630400-ea4288922497?w=500', // default image
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress Milestone Added Successfully!'), backgroundColor: Color(0xFF2E7D32)),
                  );
                  _loadContracts();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add milestone: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('Report Progress'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => context.pop(),
        ),
        title: const Text('B2B Contract Farming', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C))),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2E7D32),
          tabs: const [
            Tab(icon: Icon(Icons.handshake), text: 'My Contracts'),
            Tab(icon: Icon(Icons.search), text: 'Open Requisitions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyContractsTab(),
                _buildOpenContractsTab(),
              ],
            ),
    );
  }

  Widget _buildMyContractsTab() {
    if (_myContracts.isEmpty) {
      return const Center(child: Text('No active contracts or pending requests.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myContracts.length,
      itemBuilder: (context, idx) {
        final contract = _myContracts[idx];
        final bus = _businesses[contract['businessProfileId']];
        final isAccepted = contract['accepted'] == true;
        final milestones = contract['progressMilestones'] as List? ?? [];
        final double currentGrowth = milestones.isNotEmpty
            ? ((milestones.last['growthPercentage'] as num?)?.toDouble() ?? 0.0)
            : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            title: Text(contract['cropName'] ?? 'Crop', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target: ${contract['targetQuantity']} ${contract['unit']} • Harvest: ${contract['harvestMonth']}'),
                Text(
                  isAccepted ? 'Status: ${contract['status']}' : 'Status: PENDING BUSINESS REQUEST',
                  style: TextStyle(
                    color: isAccepted ? const Color(0xFF2E7D32) : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    if (bus != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Buyer Business', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              Text(bus['companyName'] ?? 'Business', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/chat?recipient=${bus['userId']}&name=${Uri.encodeComponent(bus['companyName'] ?? 'Business')}'),
                            icon: const Icon(Icons.chat_bubble_outline, size: 14),
                            label: const Text('Chat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Price Target', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Rs. ${contract['expectedPrice']} per ${contract['unit']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isAccepted)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _acceptContract(contract['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Accept & Sign Contract', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Growth Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${currentGrowth.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: currentGrowth / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D32)),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (milestones.isNotEmpty) ...[
                        const Text('Recent Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        ...milestones.reversed.take(2).map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Growth: ${(m['growthPercentage'] as num?)?.toStringAsFixed(0) ?? '0'}%',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(m['description'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddMilestoneDialog(contract['id'], currentGrowth),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Growth Milestone', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpenContractsTab() {
    if (_openContracts.isEmpty) {
      return const Center(child: Text('No open requisitions available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _openContracts.length,
      itemBuilder: (context, idx) {
        final contract = _openContracts[idx];
        final bus = _businesses[contract['businessProfileId']];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(contract['cropName'] ?? 'Crop', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Open Request', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Target Yield: ${contract['targetQuantity']} ${contract['unit']} • Harvest Month: ${contract['harvestMonth']}'),
                Text('Offered Price: Rs. ${contract['expectedPrice']} per ${contract['unit']}'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (bus != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Requested By', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(bus['companyName'] ?? 'Business', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      )
                    else
                      const SizedBox(),
                    Row(
                      children: [
                        if (bus != null) ...[
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32)),
                            onPressed: () => context.push('/chat?recipient=${bus['userId']}&name=${Uri.encodeComponent(bus['companyName'] ?? 'Business')}'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton(
                          onPressed: () => _acceptContract(contract['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Accept Requisition'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
