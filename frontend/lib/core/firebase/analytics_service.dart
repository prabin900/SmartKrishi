import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver getObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
      debugPrint("Logged App Open event");
    } catch (e) {
      debugPrint("Failed to log App Open: $e");
    }
  }

  static Future<void> logLogin(String userId, String role) async {
    try {
      await _analytics.logLogin(loginMethod: 'email');
      await _analytics.setUserId(id: userId);
      await _analytics.setUserProperty(name: 'user_role', value: role);
      debugPrint("Logged Login event for user: $userId (Role: $role)");
    } catch (e) {
      debugPrint("Failed to log Login: $e");
    }
  }

  static Future<void> logProductViewed(String productId, String productName, double price) async {
    try {
      await _analytics.logEvent(
        name: 'product_viewed',
        parameters: {
          'product_id': productId,
          'product_name': productName,
          'price': price,
        },
      );
      debugPrint("Logged Product Viewed event: $productName");
    } catch (e) {
      debugPrint("Failed to log Product Viewed: $e");
    }
  }

  static Future<void> logAddToCart(String productId, String productName, double price, int quantity) async {
    try {
      await _analytics.logEvent(
        name: 'product_added_to_cart',
        parameters: {
          'product_id': productId,
          'product_name': productName,
          'price': price,
          'quantity': quantity,
        },
      );
      debugPrint("Logged Add To Cart event: $productName (x$quantity)");
    } catch (e) {
      debugPrint("Failed to log Add To Cart: $e");
    }
  }

  static Future<void> logOrderPlaced(String orderId, double totalAmount, int itemsCount) async {
    try {
      await _analytics.logEvent(
        name: 'order_placed',
        parameters: {
          'order_id': orderId,
          'total_amount': totalAmount,
          'items_count': itemsCount,
        },
      );
      debugPrint("Logged Order Placed event: $orderId");
    } catch (e) {
      debugPrint("Failed to log Order Placed: $e");
    }
  }

  static Future<void> logOrderDelivered(String orderId, double totalAmount) async {
    try {
      await _analytics.logEvent(
        name: 'order_delivered',
        parameters: {
          'order_id': orderId,
          'total_amount': totalAmount,
        },
      );
      debugPrint("Logged Order Delivered event: $orderId");
    } catch (e) {
      debugPrint("Failed to log Order Delivered: $e");
    }
  }

  static Future<void> logFarmVisitBooked(String farmId, String farmName, String date) async {
    try {
      await _analytics.logEvent(
        name: 'farm_visit_booked',
        parameters: {
          'farm_id': farmId,
          'farm_name': farmName,
          'booking_date': date,
        },
      );
      debugPrint("Logged Farm Visit Booked event at: $farmName");
    } catch (e) {
      debugPrint("Failed to log Farm Visit Booked: $e");
    }
  }

  static Future<void> logHarvestRequestCreated(String cropName, double area) async {
    try {
      await _analytics.logEvent(
        name: 'harvest_request_created',
        parameters: {
          'crop_name': cropName,
          'farm_area': area,
        },
      );
      debugPrint("Logged Harvest Request Created event: $cropName");
    } catch (e) {
      debugPrint("Failed to log Harvest Request: $e");
    }
  }
}
