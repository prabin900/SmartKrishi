import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

String _roleLabel(String? role) {
  switch (role?.toUpperCase()) {
    case 'FARMER': return 'Farmer Account';
    case 'CUSTOMER': return 'Customer Account';
    case 'BUSINESS': return 'Business Account';
    case 'DELIVERY_PARTNER': return 'Delivery Partner';
    case 'ADMIN': return 'Admin Account';
    default: return 'SmartKrishi User';
  }
}


class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    final userName = state.userId != null ? 'SmartKrishi User' : 'Guest';

    void showPersonalInfoDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_outline, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Personal Information'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Color(0xFF2E7D32)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

    void showSavedAddressesSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.home_outlined, color: Color(0xFF2E7D32)),
                title: const Text('Home'),
                subtitle: const Text('Kathmandu, Bagmati Province'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.work_outline, color: Color(0xFF2E7D32)),
                title: const Text('Office'),
                subtitle: const Text('Lalitpur, Bagmati Province'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () {},
              ),
              const Divider(),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
              ),
            ],
          ),
        ),
      );
    }

    void showPaymentMethodsSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.payments_outlined, color: Colors.orange),
                title: Text('Cash on Delivery'),
                subtitle: Text('Pay when you receive'),
                trailing: Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.green),
                title: Text('eSewa'),
                subtitle: Text('Connected'),
                trailing: Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.wallet, color: Colors.purple),
                title: const Text('Khalti'),
                subtitle: const Text('Not connected'),
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('Connect'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

    void showHelpFAQ() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Help & FAQ'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FaqItem(q: 'How do I place an order?', a: 'Browse products, add to cart, and proceed to checkout. Fill in delivery address and choose a payment method.'),
                _FaqItem(q: 'Can I cancel an order?', a: 'Yes, you can cancel orders with PENDING status from the Orders tab.'),
                _FaqItem(q: 'How do I contact a farmer?', a: 'Go to the farm profile by tapping on any product, then use the Message button.'),
                _FaqItem(q: 'Is the produce organic?', a: 'Products marked with the ORGANIC badge are certified organic by the farmer.'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }

    void showPrivacyPolicy() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'SmartKrishi respects your privacy. We collect your name, email, phone number, and delivery address to process orders. Your data is never sold to third parties. We use industry-standard encryption to protect your information.\n\nBy using SmartKrishi, you agree to our terms of service and consent to data processing as described in this policy.\n\nFor any privacy concerns, contact us at privacy@smartkrishi.com.np.',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }

    void showAbout() {
      showAboutDialog(
        context: context,
        applicationName: 'SmartKrishi',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 40),
        children: [
          const Text('SmartKrishi is a digital marketplace connecting farmers directly with consumers across Nepal.'),
          const SizedBox(height: 8),
          const Text('Built with ❤️ for Nepal\'s agricultural community.'),
        ],
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with profile image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: const Color(0xFFA3F69C),
                        ),
                        child: const Icon(Icons.person, size: 44, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        _roleLabel(state.role),
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: showPersonalInfoDialog,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  const Row(
                    children: [
                      _StatCard(label: 'Orders', value: '24', icon: Icons.shopping_bag_outlined),
                      SizedBox(width: 12),
                      _StatCard(label: 'Wishlist', value: '8', icon: Icons.favorite_border),
                      SizedBox(width: 12),
                      _StatCard(label: 'Reviews', value: '12', icon: Icons.star_border),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account Section
                  const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF707A6C))),
                  const SizedBox(height: 8),
                  _SettingsItem(icon: Icons.person_outline, title: 'Personal Information', onTap: showPersonalInfoDialog),
                  _SettingsItem(icon: Icons.location_on_outlined, title: 'Saved Addresses', onTap: showSavedAddressesSheet),
                  _SettingsItem(icon: Icons.payment_outlined, title: 'Payment Methods', onTap: showPaymentMethodsSheet),
                  _SettingsItem(icon: Icons.favorite_border, title: 'Wishlist', onTap: () => context.push('/wishlist')),

                  const SizedBox(height: 16),

                  // Orders Section
                  const Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF707A6C))),
                  const SizedBox(height: 8),
                  _SettingsItem(icon: Icons.receipt_long_outlined, title: 'Order History', onTap: () => context.push('/orders/history')),
                  _SettingsItem(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () => context.push('/notifications')),
                  _SettingsItem(icon: Icons.chat_bubble_outline, title: 'Messages', onTap: () => context.push('/chat/conversations')),

                  const SizedBox(height: 16),

                  // Support Section
                  const Text('Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF707A6C))),
                  const SizedBox(height: 8),
                  _SettingsItem(icon: Icons.help_outline, title: 'Help & FAQ', onTap: showHelpFAQ),
                  _SettingsItem(icon: Icons.policy_outlined, title: 'Privacy Policy', onTap: showPrivacyPolicy),
                  _SettingsItem(icon: Icons.info_outline, title: 'About SmartKrishi', onTap: showAbout),

                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                      label: const Text('Log Out', style: TextStyle(color: Color(0xFFBA1A1A))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBA1A1A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFCABA)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 22),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              const Icon(Icons.help_outline, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.q,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 4, bottom: 8),
            child: Text(widget.a, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ),
        const Divider(height: 16),
      ],
    );
  }
}
