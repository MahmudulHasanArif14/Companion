import 'dart:io';

import 'package:app_links/app_links.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supaBase;

import '../widgets/custom_snackbar.dart';

class OauthHelper {
  supaBase.SupabaseClient supabaseInstance = supaBase.Supabase.instance.client;

  // Register new user to the system
  Future<void> signUp({
    required String email,
    required String password,
    required BuildContext context,
    required String name,
    String? fullPhoneNumber,
  }) async {
    // UserName email or password Null check
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "Fields can't be null");
      }
      return;
    }

    try {
      final supaBase.AuthResponse res = await supabaseInstance.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: "io.supabase.flutterquickstart://login-callback",
        data: {"phone": fullPhoneNumber, "name": name},
      );

      // If not Email Verified goto verificationPage
      if (res.user != null && res.user?.emailConfirmedAt == null) {
        // Navigate to Verification Page
        if (context.mounted) {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) =>
          //         VerificationPage(user: res.user, phone: fullPhoneNumber),
          //   ),
          // );
        }
      }
    } on supaBase.AuthException catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: (e.message));
      }
    }
  }

  //   Send Verification Link to the user again
  static Future<void> sendVerificationEmail(BuildContext context) async {
    final user = supaBase.Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: "No user is logged in. Please log in first.",
        );
      }
      return;
    } else if (user.emailConfirmedAt == null) {
      // Resending the link
      await supaBase.Supabase.instance.client.auth.signInWithOtp(
        email: user.email,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback',
      );
      if (context.mounted) {
        CustomSnackbar.show(
          title: '🎉 Woohoo! All Done!',
          context: context,
          label: 'Verification email sent successfully!',
          color: Color(0xE04CAF50),
          svgColor: Color(0xE0178327),
        );
      }
    }
  }

  //   Login Functionality
  static const int maxRetries = 3;
  static int retryCount = 0;

  Future<void> logIn(
      BuildContext context,
      String email,
      String password,
      ) async {
    try {
      final supaBase.AuthResponse res = await supabaseInstance.auth
          .signInWithPassword(email: email, password: password);

      if (context.mounted) {
        final nameStatus = res.user!.userMetadata?['name']
            .toString()
            .trim()
            .split(' ');
        String? lastName = nameStatus!.isNotEmpty
            ? nameStatus.last
            : res.session?.user.email?.split('@').first;

      }
    } on supaBase.AuthException catch (error) {
      retryCount++;
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: (error.message));
      }
      if (retryCount > maxRetries || error.message == 'too-many-requests') {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "Too many failed attempts. Please try again later.",
          );
        }
        retryCount = 0;
      }
    }
  }

  //Login With Google Provider
  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      const webClientId =
          '1086961716031-mu5did4abp5br146us1ss84qa6ul21am.apps.googleusercontent.com';
      const iosClientId =
          '1086961716031-rb3fiiso5bv1954iqaccroagd58h6rsk.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "Sign-in canceled. Please try again.",
          );
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "Authentication failed. Please try again.",
          );
        }
        return;
      }

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final response = await supabaseInstance.auth.signInWithIdToken(
          provider: supaBase.OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        if (context.mounted) {
          final name = response.user!.userMetadata?['name']
              .toString()
              .trim()
              .split(' ');
          String? lastName = name!.isNotEmpty
              ? name.last
              : response.session?.user.email?.split('@').first;


        }
      }
      // for Web
      else {
        await supabaseInstance.auth.signInWithOAuth(
          supaBase.OAuthProvider.google,
        );
      }
    } on supaBase.AuthException catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: e.message);
      }
    }
  }

  static int resetSend = 0;

  //   Reset Password Functionality
  Future<void> resetPassword({
    required BuildContext context,
    required String email,
  }) async {
    if (email.isEmpty) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "Email can't be null");
      }
      return;
    }

    if (resetSend >= 3) {
      resetSend = 0;
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: "No User Found Under this User",
        );
      }
    }

    try {
      final _ = await supabaseInstance.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.example.companion://reset-password',
      );
      resetSend++;

      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: "📩 Boom! Reset instructions are flying to your inbox now!",
          color: Color(0xE04CAF50),
          svgColor: Color(0xE0178327),
        );
      }
    } on supaBase.AuthException catch (error) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: error.message);
      }
    }
  }

  //   deeplink configure

  static void configDeepLink(BuildContext context) {
    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen(
          (Uri? uri) {
        if (uri == null) return;

        if (kDebugMode) {
          print("Received URI: $uri");
        }

        if (uri.host == 'reset-password') {
          final code = uri.queryParameters['code'];

          if (code != null) {
            // if (context.mounted) {
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
            //   );
            // }
          } else {
            if (kDebugMode) {
              print("Recovery code is missing from URI");
            }
          }
        }
      },
      onError: (err) {
        if (kDebugMode) {
          print("Deep link error: $err");
        }
      },
    );
  }

  //update password

  static Future<void> updatePassword(
      String newPassword,
      BuildContext context,
      ) async {
    final supabase = supaBase.Supabase.instance.client;

    try {
      final response = await supabase.auth.updateUser(
        supaBase.UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        String lastName = "";
        final nameFromMeta = response.user?.userMetadata?['name'];

        if (nameFromMeta != null &&
            nameFromMeta is String &&
            nameFromMeta.trim().isNotEmpty) {
          lastName = nameFromMeta.trim().split(' ').last;
        }

        // Password updated successfully
        if (context.mounted) {

        }
      } else {
        // Handle error
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "Error updating password: ${response.user?.email}",
          );
        }
      }
    } on supaBase.AuthException catch (e) {
      // Handle exception
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Error updating password: ${e.message}',
        );
      }
    }
  }

  ///SignOut Functionality
  Future<void> signOutUser(BuildContext context) async {
    try {
      final supabase = supaBase.Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
        // Provider.of<DatabaseHelperProvider>(context, listen: false).clearData();
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  static bool isUserLoggedIn() {
    final supabase = supaBase.Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;

    return session != null && user != null;
  }

  static supaBase.User currentUser() {
    final supabase = supaBase.Supabase.instance.client;
    final user = supabase.auth.currentUser;
    return user!;
  }
}
