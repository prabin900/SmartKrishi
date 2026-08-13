import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

class FirebaseService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase App
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBjnV0WsMs3FhL9VC7kXxATwl3Du61fElg",
            authDomain: "smartkrishi-e068d.firebaseapp.com",
            projectId: "smartkrishi-e068d",
            storageBucket: "smartkrishi-e068d.firebasestorage.app",
            messagingSenderId: "662989758480",
            appId: "1:662989758480:web:8e3d6f78ea1b9bc3f1e6fd",
          ),
        );
      } else {
        await Firebase.initializeApp();
      }

      // 2. Setup Background Notification Handler
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      // 3. Initialize messaging features in the background so they don't block app startup
      _initializeMessagingInBackground();

      // 5. Initialize Local Notifications (For Foreground Messages)
      if (!kIsWeb) {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings =
            InitializationSettings(android: initializationSettingsAndroid);
        await _localNotificationsPlugin.initialize(initializationSettings);
      }
    } catch (e) {
      debugPrint("Failed to initialize Firebase: $e");
    }
  }

  static Future<void> _initializeMessagingInBackground() async {
    try {
      // Request permissions
      await requestPermissions();

      // Get FCM token
      await getAndStoreToken();

      // Setup Foreground notification presentation
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          _showLocalNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
      });
    } catch (e) {
      debugPrint("Failed to initialize messaging in background: $e");
    }
  }

  static Future<void> requestPermissions() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
    }
  }

  static Future<void> getAndStoreToken() async {
    try {
      String? token;
      if (kIsWeb) {
        const vapidKey = "BKe1M1G2-yXyq1bZ1d5fW_81G1o9eX9yK1o8mB1-u8mD1o8uB1-u8mD1o8uB1-u8mD1o8uB1-u8mD1o8u";
        // Check if VAPID key is a placeholder to avoid InvalidCharacterError: Failed to execute 'atob' on 'Window'
        if (vapidKey.startsWith("BKe1M1G2-yXyq1bZ1")) {
          debugPrint("Skipping FCM token retrieval on Web due to placeholder VAPID key");
          return;
        }
        token = await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null) {
        debugPrint("FCM Token: $token");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
    } catch (e) {
      debugPrint("Error getting FCM Token: $e");
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return; // Local notification plugin not supported on web directly

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smartkrishi_channel',
      'SmartKrishi Notifications',
      channelDescription: 'Notifications for SmartKrishi updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
    );
  }
}
