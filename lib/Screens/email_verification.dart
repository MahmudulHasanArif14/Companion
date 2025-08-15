import 'dart:async';
import 'package:companion/Screens/permission_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Auth/auth_helper.dart';
import '../widgets/custom_snackbar.dart';
import 'dashboard.dart';

class EmailVerification extends StatefulWidget {
   final User? user;
   const EmailVerification({super.key,this.user});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  bool isSend = false;
  Timer? _resendTimer;
  int _resendTime = 0;
  Timer? _emailCheckTimer;

  @override
  void initState() {
    super.initState();

    _emailCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      final session = Supabase.instance.client.auth.currentSession;
      await Supabase.instance.client.auth.refreshSession();
      final user = session?.user;

      if (user != null) {

        final updatedUserResponse = await Supabase.instance.client.auth.getUser();
        final updatedUser = updatedUserResponse.user;

        if (updatedUser != null && updatedUser.emailConfirmedAt != null) {
          timer.cancel();

          // store UniqueUserName
          final displayName = updatedUser.userMetadata?['full_name'] ?? 'user';

          await OauthHelper().setUsernameOnce(defaultUsername: displayName);



            //   Navigate to Consent Screen
            if(mounted){
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => PermissionScreen(user: user,)),
                    (Route<dynamic> route) => false,
              );
            }



        }
      }
    });

  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void resendLink() async {
    setState(() {
      isSend = true;
      _resendTime = 30;
    });

    //if prev any timer running at first canceling
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTime > 0) {
          _resendTime--;
        } else {
          timer.cancel();
        }
      });
    });

    try {
      await OauthHelper.sendVerificationEmail(context);
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Verification email sent again.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Failed to send verification email.',
        );
      }
    } finally {
      setState(() {
        isSend = false;
      });
    }
  }

  Future<void> openEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Could not launch email app',
        );
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF3F51B5),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        forceMaterialTransparency: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Image.asset(
              "assets/images/img.png",
              fit: BoxFit.cover,
              width: size.width * .2,
            ),

            const SizedBox(height: 24),

            const Text(
              'Check Your Email',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'To confirm your email address tap the button in the email we sent to\nlessahduf@gmail.com',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: openEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Open email app',
                style: TextStyle(color: Colors.black),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                children: [
                  const Text(
                    "Didn't receive the verification email?",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  isSend
                      ? const CircularProgressIndicator(color: Colors.white)
                      : TextButton(
                    onPressed: _resendTime == 0 ? resendLink : null,
                    child: Text(
                      _resendTime == 0
                          ? 'Resend Verification Email'
                          : 'Resend available in $_resendTime s',
                      style: TextStyle(
                        color: _resendTime == 0
                            ? Colors.amber[300]
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Add logic to sign in or go back
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'Check your spam folder or ',
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(color: Colors.pinkAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
