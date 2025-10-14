import 'package:companion/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';

import '../Auth/auth_helper.dart';
import 'home_page.dart';
import 'onboarding_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToLoginPage());
  }

  // Navigating to Login Page or dashboard logic
  Future<void> _navigateToLoginPage() async {

    if (_isNavigating) return;
    _isNavigating = true;

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    try {
      final isLoggedIn = OauthHelper.isUserLoggedIn();
      final Widget destination = isLoggedIn
          ? HomePage(user: OauthHelper.currentUser()!)
          : const OnboardingScreen();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: Curves.easeInOut),
                ),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      // Handle any errors that might occur during navigation
      if (mounted) {
        CustomSnackbar.show(context: context, label: 'Error: $e');
      }
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Container(
        decoration: BoxDecoration(
          color: Color(0xFF097782),
        ),
        child: Center(
          child:  Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 200),
              SizedBox(height: 16),
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Initializing Companion...', style: TextStyle(fontSize: 16,color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}