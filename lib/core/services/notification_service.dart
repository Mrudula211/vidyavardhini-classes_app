import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// One high-importance channel: notifications pop up with sound. The same
  /// id is set as Firebase's default channel (AndroidManifest) and in the
  /// send-push function, so closed-app pushes use it too.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'vidyavardhini_default',
    'Vidyavardhini Classes',
    description: 'Announcements, fees, homework and chat',
    importance: Importance.high,
  );

  Future<void> _initLocal() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    // Android 13+: ask for permission to post notifications.
    await android?.requestNotificationsPermission();
  }

  /// Android does not show FCM messages that arrive while the app is open,
  /// so show them in the status bar ourselves.
  Future<void> _showForeground(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;
    await _local.show(
      id: message.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
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

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _initLocal();
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
        if (kDebugMode) {
          debugPrint('Foreground FCM: ${message.notification?.title}');
        }
        _showForeground(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('FCM opened app: ${message.messageId}');
      });

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

      // Never wait forever for a token (no network, no Play services).
      final token = await _messaging
          .getToken()
          .timeout(const Duration(seconds: 15), onTimeout: () => null);
      if (token != null) {
        await _saveToken(token);
      }
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
