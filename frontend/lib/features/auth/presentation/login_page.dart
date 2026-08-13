import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/firebase/analytics_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      if (email.toLowerCase().startsWith('email:')) {
        email = email.substring(6).trim();
      }

      String password = _passwordController.text;
      if (password.toLowerCase().startsWith('password:')) {
        password = password.substring(9).trim();
      }

      final success = await ref.read(authProvider.notifier).login(
            email,
            password,
          );

      if (mounted) {
        if (success) {
          final authState = ref.read(authProvider);
          final role = authState.role?.toUpperCase();
          AnalyticsService.logLogin(authState.userId ?? 'unknown', role ?? 'CUSTOMER');
          context.go(switch (role) {
            'CUSTOMER' => '/customer',
            'FARMER' => '/farmer',
            'BUSINESS' => '/business',
            'DELIVERY_PARTNER' => '/delivery',
            'ADMIN' => '/admin',
            _ => '/login',
          });
        } else {
          final errorMsg = ref.read(authProvider).error ?? 'Authentication failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final codeCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    int step = 1;
    bool isSubmitting = false;
    bool obscureNewPassword = true;
    String? errorMsg;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.lock_reset, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Text(step == 1 ? 'Forgot Password' : 'Reset Password PIN',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (step == 1) ...[
                      const Text(
                        'Enter your registered email address below. We will send a 6-digit password reset code to your email.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText: errorMsg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'A 6-digit PIN has been sent to ${emailCtrl.text.trim()}. Enter the PIN and your new password below.',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                        decoration: InputDecoration(
                          labelText: '6-digit Reset Code',
                          hintText: '000000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPasswordCtrl,
                        obscureText: obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setDialogState(() => obscureNewPassword = !obscureNewPassword),
                          ),
                          errorText: errorMsg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            setDialogState(() => errorMsg = 'Enter a valid email address');
                            return;
                          }

                          if (step == 1) {
                            setDialogState(() {
                              isSubmitting = true;
                              errorMsg = null;
                            });
                            final sent = await ref.read(authProvider.notifier).sendForgotPasswordCode(email);
                            if (ctx.mounted) {
                              if (sent) {
                                setDialogState(() {
                                  step = 2;
                                  isSubmitting = false;
                                });
                              } else {
                                final err = ref.read(authProvider).error ?? 'Failed to send reset code';
                                setDialogState(() {
                                  isSubmitting = false;
                                  errorMsg = err;
                                });
                              }
                            }
                          } else {
                            final code = codeCtrl.text.trim();
                            final newPass = newPasswordCtrl.text.trim();
                            if (code.length < 6) {
                              setDialogState(() => errorMsg = 'Enter 6-digit code');
                              return;
                            }
                            if (newPass.length < 6) {
                              setDialogState(() => errorMsg = 'Password must be at least 6 characters');
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = true;
                              errorMsg = null;
                            });

                            final reset = await ref
                                .read(authProvider.notifier)
                                .resetPasswordWithCode(email, code, newPass);
                            if (ctx.mounted) {
                              if (reset) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset successfully! You can now log in.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                final err = ref.read(authProvider).error ?? 'Failed to reset password';
                                setDialogState(() {
                                  isSubmitting = false;
                                  errorMsg = err;
                                });
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: step == 1 ? const Color(0xFF0D631B) : const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(step == 1 ? 'Send Code' : 'Reset Password'),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.eco,
                    size: 80,
                    color: Color(0xFF0D631B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SmartKrishi Nepal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D631B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connecting Farmers Directly to Nepalese Homes & Businesses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF40493D),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
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
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D631B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Demo Accounts (No OTP Required)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildDemoChip('🌾 Farmer', 'farmer@smartkrishi.com.np'),
                      _buildDemoChip('🛒 Customer', 'customer@smartkrishi.com.np'),
                      _buildDemoChip('🏢 Business', 'business@smartkrishi.com.np'),
                      _buildDemoChip('🚚 Delivery', 'delivery@smartkrishi.com.np'),
                      _buildDemoChip('🛡️ Admin', 'admin@smartkrishi.com.np'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoChip(String label, String email) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D631B))),
      backgroundColor: const Color(0xFFE8F5E9),
      side: const BorderSide(color: Color(0xFFA5D6A7)),
      onPressed: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = 'password123';
        });
      },
    );
  }
}
