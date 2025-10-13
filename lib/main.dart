import 'package:companion/test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Providers/profile_image_provider.dart';
import 'Providers/theme_provider.dart';
import 'Screens/landing_page.dart';
import 'Services/notification_service.dart';
import 'database/database_helper.dart';
import 'firebase_options.dart';





@pragma('vm:entry-point')
Future<void> msgHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // loading the credential data
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseKey == null) {
    throw Exception('Missing Supabase credentials in .env');
  }


  FirebaseMessaging.onBackgroundMessage(msgHandler);

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(

    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
         ChangeNotifierProvider(
           create: (context) => ProfileImageProvider(context),
         ),
        ChangeNotifierProvider(create: (context) => DatabaseHelperProvider()),
        // ChangeNotifierProvider(create: (_) => NotificationProvider()),

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

  Future<void>? _notificationInitialization;

  @override
  void initState() {
    super.initState();
    _notificationInitialization = initializeNotification();
  }

  Future<void> initializeNotification() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize(context);
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }




  @override
  Widget build(BuildContext context) {
    print("files are ${dotenv.env}");
    return FutureBuilder(
      future: Future.wait([
        _notificationInitialization ?? Future.value(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: Text('Initialization error: ${snapshot.error}'),
                ),
              ),
            );
          }
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
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
                home: LandingPage(),
                // home: MyHomePage(),
              );
            },
          );
        }
        // Show a loading screen while initializing
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
