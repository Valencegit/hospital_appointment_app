import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Top-level handler required by firebase_messaging for background/terminated
/// messages. Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs.
  // Background messages are shown automatically by the OS when the app is
  // terminated or in background — no local notification needed here.
}

/// Manages FCM token registration, foreground notification display via
/// flutter_local_notifications, and in-app notification Firestore records.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android notification channel for high-importance booking alerts
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hospital_appointments',
    'Appointment Notifications',
    description: 'Booking confirmations, reminders, and status updates.',
    importance: Importance.high,
  );

  String? _initializedUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Call once from main.dart after Firebase.initializeApp().
  /// Registers the background handler, creates the Android channel, and
  /// sets up foreground notification display.
  static Future<void> initializeBackground() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Call after the user has authenticated. Requests permission, saves the
  /// FCM token, and starts listening for foreground messages.
  Future<void> initialize(String userId) async {
    if (_initializedUserId == userId) return;
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();

    // 1. Request OS notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    // 2. Initialise flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // 3. Create the Android high-importance channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    if (granted) {
      // 4. Save / refresh FCM token
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(userId, token);

      // ignore: deprecated_member_use
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });

      // 5. Show foreground messages as local notifications
      _foregroundMessageSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });
    }

    _initializedUserId = userId;
  }

  /// Stops user-specific listeners and removes this device token before logout.
  Future<void> resetForSignOut(String? userId) async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _initializedUserId = null;

    if (userId == null) return;
    try {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': FieldValue.delete()});
    } catch (error) {
      debugPrint('[NotificationService] Could not clear FCM token: $error');
    }
  }

  // ── Token management ───────────────────────────────────────────────────────

  Future<void> _saveToken(String userId, String token) async {
    try {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': token});
    } catch (error) {
      debugPrint('[NotificationService] Could not save FCM token: $error');
    }
  }

  /// Mark all unread notifications as read for a user.
  Future<void> markAllRead(String userId) async {
    final batch = _db.batch();
    final snap = await _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
