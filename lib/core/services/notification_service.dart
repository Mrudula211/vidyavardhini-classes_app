import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Must be a top-level function so the Firebase SDK can invoke it when the
/// app is launched from a terminated state by a background push.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM message received: ${message.messageId}');
}

/// Registers the device for push notifications and keeps the FCM token in
/// sync with `users.fcm_token` so server-side sends can target this device.
class NotificationService {
  NotificationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      // Foreground messages — OS does not auto-display these on Android.
      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? message.data['title'];
        final body = message.notification?.body ?? message.data['body'];
        debugPrint('Foreground FCM: $title — $body');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('FCM opened app: ${message.messageId}');
      });

      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
      _messaging.onTokenRefresh.listen(_saveToken);

      // Token save at cold start often runs before login — re-save when the
      // session appears so `users.fcm_token` is populated after OTP auth.
      _client.auth.onAuthStateChange.listen((data) async {
        if (data.session == null) return;
        final refreshed = await _messaging.getToken();
        if (refreshed != null) {
          await _saveToken(refreshed);
        }
      });
    } catch (e) {
      debugPrint('NotificationService initialization skipped: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('users').update({
        'fcm_token': token,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Could not save FCM token: $e');
    }
  }

  /// Messages received while the app is in the foreground.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  /// Fired when the user taps a notification that opened the app.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
