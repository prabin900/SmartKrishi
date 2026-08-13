import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class CreateContractPage extends ConsumerStatefulWidget {
  const CreateContractPage({super.key});

  @override
  ConsumerState<CreateContractPage> createState() => _CreateContractPageState();
}

class _CreateContractPageState extends ConsumerState<CreateContractPage> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController(text: 'Organic Vine Tomatoes');
  final _quantityController = TextEditingController(text: '500');
  final _priceController = TextEditingController(text: '100');
  String _harvestMonth = 'September';
  String? _selectedFarmerId;

  // Quality Standards Tick Options
  bool _organicOnly = true;
  bool _aGradeOnly = true;
  bool _directPickupRequired = false;

  List<dynamic> _farmers = [];
  bool _loadingFarmers = true;
  bool _isSubmitting = false;

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _fetchFarmers();
  }

  Future<void> _fetchFarmers() async {
    try {
      final res = await _apiClient.dio.get('/public/farmers');
      if (!context.mounted) return;
      final queryParams = GoRouterState.of(context).uri.queryParameters;
      final paramFarmerId = queryParams['farmerProfileId'];
      setState(() {
        _farmers = res.data ?? [];
        if (paramFarmerId != null) {
          _selectedFarmerId = paramFarmerId;
        }
        _loadingFarmers = false;
      });
    } catch (e) {
      setState(() => _loadingFarmers = false);
    }
  }

  Future<void> _submitContract() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _apiClient.dio.post('/contracts/business', data: {
        'cropName': _cropController.text.trim(),
        'targetQuantity': double.tryParse(_quantityController.text) ?? 0.0,
        'unit': 'kg',
        'harvestMonth': _harvestMonth,
        'expectedPrice': double.tryParse(_priceController.text) ?? 0.0,
        'farmerProfileId': _selectedFarmerId,
        'organicOnly': _organicOnly,
        'aGradeOnly': _aGradeOnly,
        'directPickupRequired': _directPickupRequired,
        'qualityStandards': [
          if (_organicOnly) 'Organic Cultivation Only',
          if (_aGradeOnly) 'A-Grade Certified Check',
          if (_directPickupRequired) 'Direct Farm Pickup Required',
        ],
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Requisition Created Successfully with Quality Checklists!'), backgroundColor: Color(0xFF2E7D32)),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create requisition: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Requisition', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loadingFarmers
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Crop Requisition', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Post a new contract demand so verified farmers can accept or fulfill it.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _cropController,
                      decoration: const InputDecoration(
                        labelText: 'Crop Name',
                        prefixIcon: Icon(Icons.grass),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Crop name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity (kg)',
                              prefixIcon: Icon(Icons.scale),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Quantity required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Target Price (per kg)',
                              prefixIcon: Icon(Icons.payments),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Price required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _harvestMonth,
                      decoration: const InputDecoration(
                        labelText: 'Target Harvest Month',
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      items: [
                        'January',
                        'February',
                        'March',
                        'April',
                        'May',
                        'June',
                        'July',
                        'August',
                        'September',
                        'October',
                        'November',
                        'December'
                      ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => _harvestMonth = val!),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String?>(
                      value: _selectedFarmerId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Specific Farmer (Optional)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any Farmer (Open Requisition)'),
                        ),
                        ..._farmers.map((f) => DropdownMenuItem<String?>(
                              value: f['id'] as String?,
                              child: Text(f['farmName'] as String? ?? 'Farm ID: ${f['id']}'),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedFarmerId = val),
                    ),
                    const SizedBox(height: 24),

                    const Text('Quality Standards Checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Tick options required for this harvesting contract:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _organicOnly,
                            onChanged: (val) => setState(() => _organicOnly = val ?? false),
                            title: const Text('Organic cultivation only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('No synthetic fertilizers or chemical pesticides'),
                            activeColor: const Color(0xFF2E7D32),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const Divider(height: 1),
                          CheckboxListTile(
                            value: _aGradeOnly,
                            onChanged: (val) => setState(() => _aGradeOnly = val ?? false),
                            title: const Text('Certified grading checks (A-Grade only)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Strict size, color, and fresh post-harvest inspection'),
                            activeColor: const Color(0xFF2E7D32),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const Divider(height: 1),
                          CheckboxListTile(
                            value: _directPickupRequired,
                            onChanged: (val) => setState(() => _directPickupRequired = val ?? false),
                            title: const Text('Direct farm pickup availability required', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Logistics team or buyer can pick up directly from site'),
                            activeColor: const Color(0xFF2E7D32),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitContract,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Post Requisition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
