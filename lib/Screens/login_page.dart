import 'package:companion/Screens/login_password.dart';
import 'package:flutter/material.dart';
import '../Auth/auth_helper.dart';
import '../widgets/custom_textformfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  bool isEmailValid = false;


  @override
  void initState() {
    super.initState();
    emailController.addListener(validateEmail);

    // Auto focus when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      emailFocusNode.requestFocus();
    });
  }


  // on widget tree dispose dispose all controller
  @override
  void dispose() {
    emailController.removeListener(validateEmail);
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }

  // Email Validator
  void validateEmail() {
    final email = emailController.text;
    final bool isValid = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
    setState(() {
      isEmailValid = isValid;
    });
  }


  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(

      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xff4169e1),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(
              parent: NeverScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height -
                  (MediaQuery.of(context).padding.top + kToolbarHeight),),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.08,
                  vertical: size.height * 0.08,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Welcome back 👋",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Enter Your Email",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: emailController,
                        hintText: "example@email.com",
                        icon: Icon(Icons.email_outlined),
                        suffixIcon: Icon(
                          isEmailValid
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          color: isEmailValid ? Colors.green : Colors.grey,
                        ),
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.emailAddress,
                        focusNode: emailFocusNode,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email cannot be empty';
                          } else if (!isEmailValid) {
                            return "Please enter a valid email address";
                          }
                          return null;
                        },
                        onChanged: (value) {
                           validateEmail();
                          _formKey.currentState!.validate();
                        },
                      ),
                       SizedBox(height: size.height*0.4),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEmailValid ? Color(0xffffc146):Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: isEmailValid ? 4 : 0,
                          shadowColor: Colors.black54,
                        ),
                        onPressed: isEmailValid
                            ? () {

                          if (_formKey.currentState!.validate()) {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPassword(emailAddress: emailController.text,)));
                          }
                        } : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward),
                            SizedBox(width: 8),
                            Text("Continue"),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 15,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffffc146),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:BorderRadius.circular(30),
                          ),
                          elevation: 4 ,
                          shadowColor: Colors.black54,
                        ),
                        onPressed: () async {
                         // Google sign_in
                           await OauthHelper().loginWithGoogle(context);
                        } ,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            const Text("Continue with Gmail"),
                          ],
                        ),
                      ),









                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
