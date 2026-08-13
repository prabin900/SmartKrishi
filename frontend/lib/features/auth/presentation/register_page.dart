import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  // Role-specific controllers
  String _selectedRole = 'CUSTOMER';
  final _farmNameController = TextEditingController();
  final _farmDescController = TextEditingController();
  final _farmAddrController = TextEditingController();
  
  final _companyNameController = TextEditingController();
  final _regNumController = TextEditingController();
  String _businessType = 'GROCERY_STORE';
  
  String _vehicleType = 'MOTORCYCLE';
  final _vehicleNumController = TextEditingController();
  final _licenseNumController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _farmDescController.dispose();
    _farmAddrController.dispose();
    _companyNameController.dispose();
    _regNumController.dispose();
    _vehicleNumController.dispose();
    _licenseNumController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final registerData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'role': _selectedRole,
        
        // Conditional Profile fields
        if (_selectedRole == 'FARMER') ...{
          'farmName': _farmNameController.text.trim(),
          'farmDescription': _farmDescController.text.trim(),
          'farmAddress': _farmAddrController.text.trim(),
          'latitude': 27.7172, // Kathmandu center default
          'longitude': 85.3240,
        },
        if (_selectedRole == 'BUSINESS') ...{
          'companyName': _companyNameController.text.trim(),
          'registrationNumber': _regNumController.text.trim(),
          'businessType': _businessType,
        },
        if (_selectedRole == 'DELIVERY_PARTNER') ...{
          'vehicleType': _vehicleType,
          'vehicleNumber': _vehicleNumController.text.trim(),
          'licenseNumber': _licenseNumController.text.trim(),
        }
      };

      final success = await ref.read(authProvider.notifier).register(registerData);
      if (mounted) {
        if (success) {
          _showEmailVerificationDialog(_emailController.text.trim());
        } else {
          final errorMsg = ref.read(authProvider).error ?? 'Registration failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showEmailVerificationDialog(String email) async {
    final codeController = TextEditingController();
    bool isVerifying = false;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: Color(0xFF0D631B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Confirm Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email verification is required. You will NOT be able to log in until you enter the 6-digit code.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF795548)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A 6-digit confirmation code has been sent to $email. Please enter the code below to complete registration.',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                      decoration: InputDecoration(
                        hintText: '000000',
                        labelText: '6-digit OTP Code',
                        errorText: errorText,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).resendCode(email);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('New confirmation code sent to your email.'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Resend OTP Email', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text('Cancel Verification?'),
                        content: const Text('Without entering the 6-digit OTP code, your account cannot be activated and you will be blocked from logging in.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Stay & Verify')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(c);
                              Navigator.pop(ctx);
                              context.pop();
                            },
                            child: const Text('Cancel Account Creation', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.length < 6) {
                            setDialogState(() => errorText = 'Enter 6-digit code');
                            return;
                          }
                          setDialogState(() {
                            isVerifying = true;
                            errorText = null;
                          });

                          final verified = await ref.read(authProvider.notifier).verifyEmail(email, code);
                          if (ctx.mounted) {
                            if (verified) {
                              Navigator.pop(ctx); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Registration confirmed! Please log in with your credentials.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              context.pop(); // Return to login page
                            } else {
                              final err = ref.read(authProvider).error ?? 'Invalid confirmation code';
                              setDialogState(() {
                                isVerifying = false;
                                errorText = err;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D631B), foregroundColor: Colors.white),
                  child: isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Registration'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (val) => val == null || val.isEmpty ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || val.isEmpty || !val.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // Role Selector
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Select Role', prefixIcon: Icon(Icons.switch_account_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer / Buyer')),
                      DropdownMenuItem(value: 'FARMER', child: Text('Farmer / Grow Partner')),
                      DropdownMenuItem(value: 'BUSINESS', child: Text('Business (Hotels/Wholesalers)')),
                      DropdownMenuItem(value: 'DELIVERY_PARTNER', child: Text('Delivery Logistics Partner')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRole = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Role Fields
                  if (_selectedRole == 'FARMER') ...[
                    const Text('Farmer & Farm Profile Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D631B))),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _farmNameController,
                      decoration: const InputDecoration(labelText: 'Farm Name', prefixIcon: Icon(Icons.agriculture_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Farm name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _farmDescController,
                      decoration: const InputDecoration(labelText: 'Farm Description', prefixIcon: Icon(Icons.description_outlined)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _farmAddrController,
                      decoration: const InputDecoration(labelText: 'Farm Address (Nepal Location)', prefixIcon: Icon(Icons.location_on_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Farm address is required' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedRole == 'BUSINESS') ...[
                    const Text('Business / Wholesale Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D631B))),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(labelText: 'Company / Business Name', prefixIcon: Icon(Icons.business_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Company name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _regNumController,
                      decoration: const InputDecoration(labelText: 'PAN / Business Registration No.', prefixIcon: Icon(Icons.assignment_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'PAN registration is required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _businessType,
                      decoration: const InputDecoration(labelText: 'Business Category', prefixIcon: Icon(Icons.storefront_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'GROCERY_STORE', child: Text('Grocery Store / Supermarket')),
                        DropdownMenuItem(value: 'HOTEL', child: Text('Hotel')),
                        DropdownMenuItem(value: 'RESTAURANT', child: Text('Restaurant')),
                        DropdownMenuItem(value: 'WHOLESALER', child: Text('Wholesaler / Corporate Buyer')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _businessType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedRole == 'DELIVERY_PARTNER') ...[
                    const Text('Delivery Logistics Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D631B))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _vehicleType,
                      decoration: const InputDecoration(labelText: 'Vehicle Type', prefixIcon: Icon(Icons.pedal_bike_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'MOTORCYCLE', child: Text('Motorcycle / Scooter')),
                        DropdownMenuItem(value: 'BICYCLE', child: Text('Bicycle')),
                        DropdownMenuItem(value: 'VAN', child: Text('Delivery Van')),
                        DropdownMenuItem(value: 'TRUCK', child: Text('Pick-up Truck')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _vehicleType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleNumController,
                      decoration: const InputDecoration(labelText: 'Vehicle Registration Number', prefixIcon: Icon(Icons.tag_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Vehicle registration is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseNumController,
                      decoration: const InputDecoration(labelText: 'Driving License Number', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'License number is required' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    onPressed: state.isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D631B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
