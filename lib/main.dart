import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_keys.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/cache_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Fonts are bundled in assets/fonts: never download them at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Hive local cache
  await Hive.initFlutter();
  await CacheService.instance.init();
  await Hive.openBox<String>(LocaleNotifier.boxName);

  // Supabase
  await Supabase.initialize(
    url: SupabaseKeys.supabaseUrl,
    publishableKey: SupabaseKeys.supabaseAnonKey,
  );

  // Firebase (optional / platform-dependent)
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase initialization skipped or not configured: $e');
  }

  runApp(const ProviderScope(child: VidyavardhiniApp()));

  // Notifications are set up AFTER the first frame: the permission prompt and
  // the FCM token request (slow or stuck when offline) must never keep the
  // app on a blank screen.
  if (firebaseReady) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService().initialize());
    });
  }
}
