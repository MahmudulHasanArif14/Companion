import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Screens/add_companion.dart';
import 'Screens/onboarding_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (supabaseUrl == null || supabaseKey == null) {
    throw Exception('Missing Supabase credentials in .env');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff30a593)),
      ),
      home: OnboardingScreen(),
    );
  }
}
