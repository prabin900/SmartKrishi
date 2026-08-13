import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(const {
        'delivery_charge': 150.0,
        'promo_banner_url': 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=1000',
        'seasonal_offer_text': '20% OFF on all fresh organic green vegetables today!',
        'is_promo_active': true,
      });

      // Fetch configs with reasonable cache expiration for development (e.g. 10 seconds)
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 15),
      ));

      // Kick off the network fetch asynchronously so it doesn't block app startup
      fetchAndActivate();
    } catch (e) {
      debugPrint("Failed to initialize Remote Config: $e");
    }
  }

  static Future<void> fetchAndActivate() async {
    try {
      bool updated = await _remoteConfig.fetchAndActivate();
      debugPrint("Remote Config fetch and activate status: $updated");
    } catch (e) {
      debugPrint("Failed to fetch Remote Config: $e");
    }
  }

  static double getDeliveryCharge() {
    return _remoteConfig.getDouble('delivery_charge');
  }

  static String getPromoBannerUrl() {
    return _remoteConfig.getString('promo_banner_url');
  }

  static String getSeasonalOfferText() {
    return _remoteConfig.getString('seasonal_offer_text');
  }

  static bool isPromoActive() {
    return _remoteConfig.getBool('is_promo_active');
  }
}
