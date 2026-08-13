import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/auth/presentation/splash_page.dart';

void main() {
  testWidgets('SmartKrishi splash page widget test', (WidgetTester tester) async {
    // Setup a mini GoRouter for testing redirection
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashPage()),
        GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('Login Page'))),
        GoRoute(path: '/onboarding', builder: (context, state) => const Scaffold(body: Text('Onboarding Page'))),
        GoRoute(path: '/customer', builder: (context, state) => const Scaffold(body: Text('Customer Dashboard'))),
        GoRoute(path: '/farmer', builder: (context, state) => const Scaffold(body: Text('Farmer Dashboard'))),
        GoRoute(path: '/business', builder: (context, state) => const Scaffold(body: Text('Business Dashboard'))),
        GoRoute(path: '/delivery', builder: (context, state) => const Scaffold(body: Text('Delivery Dashboard'))),
        GoRoute(path: '/admin', builder: (context, state) => const Scaffold(body: Text('Admin Dashboard'))),
      ],
    );

    // Build the SplashPage inside MaterialApp.router
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    
    // Let layout render and animation resolve initial frame
    await tester.pump();

    // Verify that the tagline text is displayed on the splash page.
    expect(find.text('Fresh From Farm To Your Doorstep'), findsOneWidget);

    // Let the 2.5 seconds splash page redirect timer run to completion
    await tester.pump(const Duration(milliseconds: 2500));
    
    // Re-pump to process redirection
    await tester.pumpAndSettle();

    // The timer redirects to /onboarding since we are not logged in during the test
    expect(find.text('Onboarding Page'), findsOneWidget);
  });
}
