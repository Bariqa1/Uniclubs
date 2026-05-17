import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled automatically by the OS
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controller for in-app notification banners
  final ValueNotifier<RemoteMessage?> foregroundMessage = ValueNotifier(null);

  Future<void> initialize() async {
    if (kIsWeb) return;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions (required on iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and store token
    await _refreshToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      foregroundMessage.value = message;
      _saveNotificationToFirestore(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _refreshToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'type': message.data['type'] ?? 'general',
        'data': message.data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigation logic can be added here using a navigator key
    // For now the notifications screen will show the history
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }

  /// Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final unread = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Get unread notification count stream
  Stream<int> unreadCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Write a notification directly to Firestore.
  /// Use this for client-side triggers (no Cloud Functions needed).
  Future<void> createLocalNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Check for pending event reminders and feedback reminders.
  /// Called on app open — fires notifications if conditions are met.
  Future<void> checkAndSendReminders(String userId) async {
    try {
      final now = DateTime.now();

      // Load all existing reminders for this user once, filter in memory
      final allNotifsSnap = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final sentEventReminders = allNotifsSnap.docs
          .where((d) => (d.data() as Map)['type'] == 'event_reminder')
          .map((d) => (d.data() as Map)['eventId'] as String?)
          .whereType<String>()
          .toSet();

      final sentFeedbackReminders = allNotifsSnap.docs
          .where((d) => (d.data() as Map)['type'] == 'feedback_reminder')
          .map((d) => (d.data() as Map)['eventId'] as String?)
          .whereType<String>()
          .toSet();

      // ── Event reminders (upcoming registered events) ──────────────────────
      final registeredSnap = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'registered')
          .get();

      for (final reg in registeredSnap.docs) {
        final regData = reg.data();
        final eventId = regData['eventId'] as String?;
        if (eventId == null) continue;

        final eventDoc = await _firestore.collection('events').doc(eventId).get();
        if (!eventDoc.exists) continue;

        final eventData = eventDoc.data() as Map<String, dynamic>;
        if (eventData['status'] == 'cancelled') continue;

        final eventTitle = eventData['title'] ?? 'an event';
        final eventDate = (eventData['date'] as Timestamp).toDate();
        final hoursUntil = eventDate.difference(now).inHours;

        // Event reminder: send once when app is opened within 24 hours of event
        if (hoursUntil >= 1 && hoursUntil <= 24 && !sentEventReminders.contains(eventId)) {
          final reminderTitle = hoursUntil <= 3 ? 'Starting Soon!' : 'Event Today!';
          final reminderBody = hoursUntil <= 3
              ? '"$eventTitle" starts in about ${hoursUntil}h. Get ready!'
              : '"$eventTitle" is happening today. Don\'t forget!';
          await _firestore.collection('notifications').add({
            'userId': userId,
            'type': 'event_reminder',
            'eventId': eventId,
            'title': reminderTitle,
            'body': reminderBody,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          sentEventReminders.add(eventId);
        }
      }

      // ── Feedback reminders (attended events without feedback yet) ──────────
      final attendedSnap = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'attended')
          .get();

      for (final reg in attendedSnap.docs) {
        final regData = reg.data();
        final eventId = regData['eventId'] as String?;
        if (eventId == null) continue;

        if (sentFeedbackReminders.contains(eventId)) continue;

        final eventDoc = await _firestore.collection('events').doc(eventId).get();
        if (!eventDoc.exists) continue;

        final eventData = eventDoc.data() as Map<String, dynamic>;
        final eventTitle = eventData['title'] ?? 'an event';

        final feedbackSnap = await _firestore
            .collection('feedback')
            .where('userId', isEqualTo: userId)
            .where('eventId', isEqualTo: eventId)
            .limit(1)
            .get();

        if (feedbackSnap.docs.isEmpty) {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'type': 'feedback_reminder',
            'eventId': eventId,
            'title': 'How was the event?',
            'body': 'Share your experience for "$eventTitle". Your feedback matters!',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          sentFeedbackReminders.add(eventId);
        }
      }
    } catch (e) {
      debugPrint('checkAndSendReminders error: $e');
    }
  }

  /// Clear FCM token on logout
  Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
