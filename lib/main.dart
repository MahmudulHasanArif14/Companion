import 'package:app_links/app_links.dart';
import 'package:companion/Auth/auth_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Providers/journey_provider.dart';
import 'Providers/profile_image_provider.dart';
import 'Providers/theme_provider.dart';
import 'Screens/landing_page.dart';
import 'Services/background_journey_service.dart';
import 'Services/notification_service.dart';
import 'database/database_helper.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> msgHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// Global navigator key for deep link navigation anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseKey == null) {
    throw Exception('Missing Supabase credentials in .env');
  }

  FirebaseMessaging.onBackgroundMessage(msgHandler);
  BackgroundJourneyService().initialize();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProfileImageProvider(context)),
        ChangeNotifierProvider(create: (_) => DatabaseHelperProvider()),
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Initialize notifications and deep links AFTER the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeNotificationsAndDeepLinks();
    });
  }

  Future<void> _initializeNotificationsAndDeepLinks() async {
    try {
      final notificationService = NotificationService();
      // Use navigatorKey.currentContext so context exists
      await notificationService.initialize(navigatorKey.currentContext!);
      // Configure deep links
      OauthHelper.configDeepLink();
    } catch (e) {
      debugPrint('Notification / deep link initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          title: 'Companion',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: kIsWeb ? 'Arial' : null,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: kIsWeb ? 'Arial' : null,
          ),
          home: const LandingPage(),
        );
      },
    );
  }
}
