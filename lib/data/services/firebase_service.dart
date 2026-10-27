import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/config/firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get fieldTypesCollection =>
      firestore.collection('field_types');

  CollectionReference<Map<String, dynamic>> get fieldsCollection =>
      firestore.collection('fields');

  CollectionReference<Map<String, dynamic>> get timeSlotsCollection =>
      firestore.collection('time_slots');

  CollectionReference<Map<String, dynamic>> get promotionsCollection =>
      firestore.collection('promotions');

  CollectionReference<Map<String, dynamic>> get bookingsCollection =>
      firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get bookingDetailsCollection =>
      firestore.collection('booking_details');

  CollectionReference<Map<String, dynamic>> get paymentsCollection =>
      firestore.collection('payments');

  CollectionReference<Map<String, dynamic>> get reviewsCollection =>
      firestore.collection('reviews');

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _setupNotifications();
    } catch (_) {}
  }

  static Future<void> _setupNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}
  }
}
