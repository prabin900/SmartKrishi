import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> updateDeliveryLocation({
    required String orderId,
    required String deliveryPartnerId,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
    required bool onlineStatus,
  }) async {
    try {
      await _firestore.collection('delivery_tracking').doc(orderId).set({
        'orderId': orderId,
        'deliveryPartnerId': deliveryPartnerId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'timestamp': FieldValue.serverTimestamp(),
        'onlineStatus': onlineStatus,
      }, SetOptions(merge: true));
      debugPrint("Updated delivery location in Firestore for order: $orderId");
    } catch (e) {
      debugPrint("Failed to update location in Firestore: $e");
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamDeliveryLocation(String orderId) {
    return _firestore.collection('delivery_tracking').doc(orderId).snapshots();
  }

  static Future<void> deleteDeliveryLocation(String orderId) async {
    try {
      await _firestore.collection('delivery_tracking').doc(orderId).delete();
      debugPrint("Deleted tracking document for order: $orderId");
    } catch (e) {
      debugPrint("Failed to delete tracking document: $e");
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamAllActiveDeliveries() {
    return _firestore
        .collection('delivery_tracking')
        .where('onlineStatus', isEqualTo: true)
        .snapshots();
  }
}
