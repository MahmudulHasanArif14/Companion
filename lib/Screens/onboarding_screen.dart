import 'package:companion/Screens/login_page.dart';
import 'package:companion/Screens/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../Auth/auth_helper.dart';
import 'dashboard.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // Navigating to Login Page
  void _navigateToLoginPage() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final bool isLoggedIn = OauthHelper.isUserLoggedIn();

    late final Widget destination;

    if (!isLoggedIn) {
      destination = const OnboardingScreen();
    } else {
      destination = Dashboard(user: OauthHelper.currentUser());
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(
              Tween(
                begin: 0.0,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.bounceIn)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  // Onboarding Screen Contexts
  final List<Map<String, String>> _pages = [
    {
      "title": "Location Sharing",
      "desc":
          "Keep track of each other by sharing and requesting location with one another",
      "image": "assets/images/pngwing.png",
      "centerImage": "assets/images/GPS Navigation.json",
    },
    {
      "title": "SOS Feature",
      "desc":
          "Feel secure with instant emergency support. With just one tap, our SOS feature will immediately notify your selected trusted contact and share your real-time location when you need help.",
      "image": "assets/images/pngwing.png",
      "centerImage": "assets/images/Sos Notification.json",
    },
    {
      "title": "Stay Connected Always",
      "desc":
          "Stay fully in the loop knowing you can connect with and contact any of your friend and families in any situation. at any time. ",
      "image": "assets/images/pngwing.png",
      "centerImage": "assets/images/friends.json",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (_, index) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Image.asset(
                            _pages[index]["image"]!,
                            width: size.width,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 20),
                        Lottie.asset(
                          _pages[index]["centerImage"]!,
                          width: size.width * 0.8,
                          height: size.height * 0.3,
                          repeat: true,
                          reverse: false,
                          animate: true,
                        ),
                        SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                _pages[index]["title"]!,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _pages[index]["desc"]!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.amber
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            /// Buttons
            _currentIndex < _pages.length - 1
                ? TextButton(
                    onPressed: () {
                      _controller.nextPage(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    },
                    child: Text(
                      "Next",
                      style: TextStyle(color: Color(0xff1782f5), fontSize: 18),
                    ),
                  )
                : Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          // Navigate to Registration Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistrationPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Get Started",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          // Navigate to login
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return LoginPage();
                              },
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account?',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
