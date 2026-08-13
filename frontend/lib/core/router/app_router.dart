import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/customer/presentation/customer_dashboard.dart';
import '../../features/customer/presentation/product_details_page.dart';
import '../../features/customer/presentation/farm_profile_page.dart';
import '../../features/customer/presentation/wishlist_page.dart';
import '../../features/customer/presentation/notifications_page.dart';
import '../../features/customer/presentation/checkout_page.dart';
import '../../features/customer/presentation/order_history_page.dart';
import '../../features/customer/presentation/search_page.dart';
import '../../features/customer/presentation/profile_page.dart';
import '../../features/farmer/presentation/farmer_dashboard.dart';
import '../../features/business/presentation/business_dashboard.dart';
import '../../features/business/presentation/create_contract_page.dart';
import '../../features/delivery/presentation/delivery_dashboard.dart';
import '../../features/delivery/presentation/todays_deliveries_page.dart';
import '../../features/admin/presentation/admin_dashboard.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/chat/presentation/conversations_list_page.dart';
import '../../features/farmer/presentation/sales_analytics_page.dart';
import '../../features/farmer/presentation/incoming_orders_page.dart';
import '../../features/farmer/presentation/harvest_schedule_page.dart';
import '../../features/farmer/presentation/farm_gallery_page.dart';
import '../../features/customer/presentation/booking_confirmed_page.dart';
import '../../features/delivery/presentation/delivery_complete_page.dart';
import '../../features/customer/presentation/book_visit_page.dart';
import '../../features/delivery/presentation/todays_earnings_page.dart';
import '../../features/farmer/presentation/growing_progress_page.dart';
import '../../features/customer/presentation/order_tracking_page.dart';
import '../../features/customer/presentation/nearby_farms_map_page.dart';
import '../../features/farmer/presentation/farm_location_picker_page.dart';
import '../../features/delivery/presentation/delivery_map_page.dart';
import '../../features/admin/presentation/admin_map_page.dart';
import '../network/api_client.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    final token = await SecureStorage.getToken();
    final role = await SecureStorage.getRole();
    
    final isLoggingIn = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/register' || 
                         state.matchedLocation == '/onboarding';
    final isSplash = state.matchedLocation == '/';

    if (token == null) {
      if (isLoggingIn || isSplash) return null;
      return '/onboarding';
    }

    if (isLoggingIn || isSplash) {
      return switch (role?.toUpperCase()) {
        'CUSTOMER' => '/customer',
        'FARMER' => '/farmer',
        'BUSINESS' => '/business',
        'DELIVERY_PARTNER' => '/delivery',
        'ADMIN' => '/admin',
        _ => '/login',
      };
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/customer',
      builder: (BuildContext context, GoRouterState state) => const CustomerDashboard(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (BuildContext context, GoRouterState state) => ProductDetailsPage(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/farm/:id',
      builder: (BuildContext context, GoRouterState state) => FarmProfilePage(farmId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/wishlist',
      builder: (BuildContext context, GoRouterState state) => const WishlistPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (BuildContext context, GoRouterState state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/farmer',
      builder: (BuildContext context, GoRouterState state) => const FarmerDashboard(),
    ),
    GoRoute(
      path: '/business',
      builder: (BuildContext context, GoRouterState state) => const BusinessDashboard(),
    ),
    GoRoute(
      path: '/delivery',
      builder: (BuildContext context, GoRouterState state) => const DeliveryDashboard(),
    ),
    GoRoute(
      path: '/admin',
      builder: (BuildContext context, GoRouterState state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/chat',
      builder: (BuildContext context, GoRouterState state) => ChatPage(
        recipientUserId: state.uri.queryParameters['recipient'] ?? '',
        orderId: state.uri.queryParameters['orderId'],
        recipientName: state.uri.queryParameters['name'],
      ),
    ),
    GoRoute(
      path: '/chat/conversations',
      builder: (BuildContext context, GoRouterState state) => const ConversationsListPage(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (BuildContext context, GoRouterState state) => const CheckoutPage(),
    ),
    GoRoute(
      path: '/orders/history',
      builder: (BuildContext context, GoRouterState state) => const OrderHistoryPage(),
    ),
    GoRoute(
      path: '/contracts/create',
      builder: (BuildContext context, GoRouterState state) => const CreateContractPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) => const SearchPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/analytics/sales',
      builder: (BuildContext context, GoRouterState state) => const SalesAnalyticsPage(),
    ),
    GoRoute(
      path: '/farmer/orders/incoming',
      builder: (BuildContext context, GoRouterState state) => const IncomingOrdersPage(),
    ),
    GoRoute(
      path: '/delivery/today',
      builder: (BuildContext context, GoRouterState state) => const TodaysDeliveriesPage(),
    ),
    GoRoute(
      path: '/farmer/harvest/schedule',
      builder: (BuildContext context, GoRouterState state) => const HarvestSchedulePage(),
    ),
    GoRoute(
      path: '/farmer/gallery',
      builder: (BuildContext context, GoRouterState state) => const FarmGalleryPage(),
    ),
    GoRoute(
      path: '/booking/confirmed',
      builder: (BuildContext context, GoRouterState state) => const BookingConfirmedPage(),
    ),
    GoRoute(
      path: '/delivery/complete',
      builder: (BuildContext context, GoRouterState state) => const DeliveryCompletePage(),
    ),
    GoRoute(
      path: '/farm/book-visit',
      builder: (BuildContext context, GoRouterState state) {
        final farmId = state.uri.queryParameters['farmId'] ?? '';
        final farmName = state.uri.queryParameters['farmName'] ?? '';
        return BookVisitPage(farmId: farmId, farmName: farmName);
      },
    ),
    GoRoute(
      path: '/earnings/today',
      builder: (BuildContext context, GoRouterState state) => const TodaysEarningsPage(),
    ),
    GoRoute(
      path: '/farmer/growing-progress',
      builder: (BuildContext context, GoRouterState state) => const GrowingProgressPage(),
    ),
    GoRoute(
      path: '/order/tracking/:orderId',
      builder: (BuildContext context, GoRouterState state) => OrderTrackingPage(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/farms/map',
      builder: (BuildContext context, GoRouterState state) => const NearbyFarmsMapPage(),
    ),
    GoRoute(
      path: '/farmer/location-picker',
      builder: (BuildContext context, GoRouterState state) => const FarmLocationPickerPage(),
    ),
    GoRoute(
      path: '/delivery/map/:orderId',
      builder: (BuildContext context, GoRouterState state) => DeliveryMapPage(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/admin/map',
      builder: (BuildContext context, GoRouterState state) => const AdminMapPage(),
    ),
  ],
);
