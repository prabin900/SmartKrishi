import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    Timer(const Duration(milliseconds: 2500), () {
      final authState = ref.read(authProvider);
      if (authState.userId != null) {
        final role = authState.role?.toUpperCase();
        context.go(switch (role) {
          'CUSTOMER' => '/customer',
          'FARMER' => '/farmer',
          'BUSINESS' => '/business',
          'DELIVERY_PARTNER' => '/delivery',
          'ADMIN' => '/admin',
          _ => '/login',
        });
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Radial decorative shift
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    const Color(0xFF0D631B).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBmIWOIYfVkJjClwo3h6LOQ2nH6XbOU5EInJuYXsJXNKQ3P3m-XvPRKSjKi9MPRviWev4bAOrHW_gHEHjAGuVZxwc8p85nBQdC_wvExR6AD8FTSuJ9eZhbbguR47jjUJLS7pYZvgPphWGXXqyWTsq80AFc1y4pgOM49zbH6irTo4qe8eBH8jmOuZkOKhh3uomWsDFFpS6Yph9fHLReQgROMAe3J-kZ2zYYFrIfuL--Z_SXb1zXCHHsImzjrPbkek_RIrVTdM1Gu5yfk',
                    width: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.eco,
                        size: 80,
                        color: Color(0xFF0D631B),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Fresh From Farm To Your Doorstep',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF40493D),
                      letterSpacing: 0.15,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Progress Loading bar
                  SizedBox(
                    width: 180,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D631B)),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Organic Icons in Footer
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, color: Colors.grey.shade400.withOpacity(0.5), size: 24),
                const SizedBox(width: 16),
                Icon(Icons.yard_outlined, color: Colors.grey.shade400.withOpacity(0.5), size: 24),
                const SizedBox(width: 16),
                Icon(Icons.local_shipping_outlined, color: Colors.grey.shade400.withOpacity(0.5), size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
