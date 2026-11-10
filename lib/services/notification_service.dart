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

  bool _initialized = false;

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
    if (_initialized) return;

    // 1. Request OS notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
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
      _messaging.onTokenRefresh
          .listen((newToken) => _saveToken(userId, newToken));

      // 5. Show foreground messages as local notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null && android != null) {
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
            ),
          );
        }

        // Also save to Firestore for in-app notification centre
        if (notification != null) {
          saveNotification(
            userId: userId,
            title: notification.title ?? 'Notification',
            body: notification.body ?? '',
            type: message.data['type'] as String?,
            appointmentId: message.data['appointmentId'] as String?,
          );
        }
      });
    }

    _initialized = true;
  }

  // ── Token management ───────────────────────────────────────────────────────

  Future<void> _saveToken(String userId, String token) async {
    try {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': token});
    } catch (_) {
      // Non-fatal — token will be refreshed on next login
    }
  }

  // ── In-app notifications ───────────────────────────────────────────────────

  /// Persist a notification record so the in-app notification centre can
  /// display it even if the push was missed.
  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    String? appointmentId,
  }) async {
    await _db.collection(AppConstants.notificationsCollection).add({
      'userId': userId,
      'title': title,
      'body': body,
      if (type != null) 'type': type,
      if (appointmentId != null) 'appointmentId': appointmentId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
