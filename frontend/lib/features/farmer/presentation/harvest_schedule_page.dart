import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/analytics_service.dart';

class HarvestSchedulePage extends StatefulWidget {
  const HarvestSchedulePage({super.key});

  @override
  State<HarvestSchedulePage> createState() => _HarvestSchedulePageState();
}

class _HarvestSchedulePageState extends State<HarvestSchedulePage> {
  int _selectedDay = 1; // index into days list

  final List<Map<String, dynamic>> _days = [
    {'label': 'Mon', 'date': 12, 'hasDot': false},
    {'label': 'Tue', 'date': 13, 'hasDot': true},  // today / selected
    {'label': 'Wed', 'date': 14, 'hasDot': true},
    {'label': 'Thu', 'date': 15, 'hasDot': true},
    {'label': 'Fri', 'date': 16, 'hasDot': false},
    {'label': 'Sat', 'date': 17, 'hasDot': true},
    {'label': 'Sun', 'date': 18, 'hasDot': false},
  ];

  final List<Map<String, dynamic>> _harvests = [
    {
      'crop': 'Organic Tomatoes (Grade A)',
      'plot': 'Plot A – 0.5 acres',
      'time': '6:00 AM',
      'workers': 4,
      'estYield': '280 kg',
      'status': 'Scheduled',
      'statusColor': 0xFF2E7D32,
      'statusBg': 0xFFE8F5E9,
      'icon': Icons.eco_outlined,
      'color': 0xFF2E7D32,
    },
    {
      'crop': 'Red Onions (Grade B)',
      'plot': 'Plot C – 0.3 acres',
      'time': '8:30 AM',
      'workers': 3,
      'estYield': '150 kg',
      'status': 'In Progress',
      'statusColor': 0xFF0054A7,
      'statusBg': 0xFFE3F2FD,
      'icon': Icons.grass_outlined,
      'color': 0xFF8B5000,
    },
    {
      'crop': 'Fresh Spinach Bunch',
      'plot': 'Plot B – 0.2 acres',
      'time': '11:00 AM',
      'workers': 2,
      'estYield': '80 kg',
      'status': 'Scheduled',
      'statusColor': 0xFF2E7D32,
      'statusBg': 0xFFE8F5E9,
      'icon': Icons.local_florist_outlined,
      'color': 0xFF2E7D32,
    },
  ];

  void _showAddPlanDialog() {
    final cropCtrl = TextEditingController();
    final yieldCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Harvest Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cropCtrl, decoration: const InputDecoration(labelText: 'Crop Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: yieldCtrl, decoration: const InputDecoration(labelText: 'Est. Yield (kg)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (cropCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              AnalyticsService.logHarvestRequestCreated(cropCtrl.text, 0.5);
              setState(() {
                _harvests.add({
                  'crop': cropCtrl.text.trim(),
                  'plot': 'New Plot',
                  'time': '9:00 AM',
                  'workers': 2,
                  'estYield': yieldCtrl.text.trim().isEmpty ? '50 kg' : '${yieldCtrl.text.trim()} kg',
                  'status': 'Scheduled',
                  'statusColor': 0xFF2E7D32,
                  'statusBg': 0xFFE8F5E9,
                  'icon': Icons.eco_outlined,
                  'color': 0xFF2E7D32,
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Plan added: ${cropCtrl.text}'), backgroundColor: const Color(0xFF2E7D32)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Add Plan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Harvest Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C), fontSize: 18)),
            Text('Manage upcoming picks & inventory', style: TextStyle(color: Color(0xFF707A6C), fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: Color(0xFF40493D)), onPressed: () {}),
          TextButton.icon(
            onPressed: _showAddPlanDialog,
            icon: const Icon(Icons.add, color: Color(0xFF2E7D32), size: 18),
            label: const Text('New Plan', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date horizontal scroller
          Container(
            height: 104,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _days.length,
              itemBuilder: (ctx, i) {
                final d = _days[i];
                final selected = i == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFD4F0D4) : Colors.white,
                      border: Border.all(
                        color: selected ? const Color(0xFF2E7D32) : const Color(0xFFBFCABA),
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(d['label'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? const Color(0xFF2E7D32) : const Color(0xFF707A6C),
                                  )),
                              const SizedBox(height: 4),
                              Text('${d['date']}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: selected ? const Color(0xFF2E7D32) : const Color(0xFF1A1C1C),
                                  )),
                            ],
                          ),
                        ),
                        if (d['hasDot'] == true && !selected)
                          Positioned(
                            bottom: 6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        if (selected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9800),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Summary chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _SummaryChipH(label: 'Total Crops', value: '${_harvests.length}', color: const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                _SummaryChipH(
                  label: 'Completed',
                  value: '${_harvests.where((h) => h['status'] == 'Completed').length}',
                  color: const Color(0xFF0054A7),
                ),
                const SizedBox(width: 8),
                _SummaryChipH(
                  label: 'Workers',
                  value: '${_harvests.fold(0, (sum, h) => sum + (h['workers'] as int))}',
                  color: const Color(0xFF8B5000),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Harvest cards
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _harvests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _HarvestCard(
                harvest: _harvests[i],
                onUpdate: () => setState(() {}),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlanDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _SummaryChipH extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChipH({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF707A6C))),
          ],
        ),
      ),
    );
  }
}

class _HarvestCard extends StatefulWidget {
  final Map<String, dynamic> harvest;
  final VoidCallback onUpdate;
  const _HarvestCard({required this.harvest, required this.onUpdate});

  @override
  State<_HarvestCard> createState() => _HarvestCardState();
}

class _HarvestCardState extends State<_HarvestCard> {
  void _editHarvest() {
    final cropCtrl = TextEditingController(text: widget.harvest['crop']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Harvest'),
        content: TextField(controller: cropCtrl, decoration: const InputDecoration(labelText: 'Crop Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => widget.harvest['crop'] = cropCtrl.text);
              Navigator.pop(ctx);
              widget.onUpdate();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _markDone() {
    setState(() {
      widget.harvest['status'] = 'Completed';
      widget.harvest['statusColor'] = 0xFF707A6C;
      widget.harvest['statusBg'] = 0xFFF3F4F5;
    });
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(widget.harvest['color'] as int).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.harvest['icon'] as IconData, color: Color(widget.harvest['color'] as int), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.harvest['crop'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(widget.harvest['plot'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF707A6C))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(widget.harvest['statusBg'] as int),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.harvest['status'] as String,
                    style: TextStyle(
                      color: Color(widget.harvest['statusColor'] as int),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F5)),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(icon: Icons.schedule, label: widget.harvest['time'] as String),
                const SizedBox(width: 16),
                _InfoChip(icon: Icons.people_outline, label: '${widget.harvest['workers']} workers'),
                const SizedBox(width: 16),
                _InfoChip(icon: Icons.scale_outlined, label: widget.harvest['estYield'] as String),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _editHarvest,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBFCABA)),
                      foregroundColor: const Color(0xFF40493D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Update'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.harvest['status'] == 'Completed' ? null : _markDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: widget.harvest['status'] == 'Completed' 
                      ? const Icon(Icons.check)
                      : const Text('Mark Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF707A6C)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF40493D))),
      ],
    );
  }
}
