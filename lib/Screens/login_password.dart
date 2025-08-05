import 'package:flutter/material.dart';

import '../Auth/auth_helper.dart';
import '../widgets/custom_textformfield.dart';
import 'dashboard.dart';

class LoginPassword extends StatefulWidget {
  final String emailAddress;
  const LoginPassword({super.key, required this.emailAddress});

  @override
  State<LoginPassword> createState() => _LoginPasswordState();
}

class _LoginPasswordState extends State<LoginPassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  bool isPassValid = false;
  bool _isObsecure=true;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(validatePass);
    // Auto focus when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      passwordFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    passwordController.removeListener(validatePass);
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  // Pass Validator
  void validatePass() {
    final password = passwordController.text;
    final bool isValid = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$'
    ).hasMatch(password);
    setState(() {
      isPassValid = isValid;
    });
  }


  // Login Functionality
  void _loginUser(String email, BuildContext context,String password) {
    final authHelper = OauthHelper();
    authHelper.logIn(context, email, password);




    final user = OauthHelper.currentUser();
    if (user == null) {
      return;


    } else {
      //   after login go to direct Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Dashboard(user:user)),
            (Route<dynamic> route) => false,
      );
    }











  }













  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xff4169e1),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        forceMaterialTransparency: true,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
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
                       SizedBox(height: size.height*0.1),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Enter Your Password",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      CustomTextField(
                        controller: passwordController,
                        obscureText: _isObsecure,
                        hintText: "********",
                        icon: IconButton(
                          onPressed: () {
                            setState(() => _isObsecure = !_isObsecure);
                          },
                          icon: Icon(
                            _isObsecure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white,
                          ),
                        ),
                        suffixIcon: Icon(
                          isPassValid
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          color: isPassValid ? Colors.green : Colors.grey,
                        ),
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.text,
                        focusNode: passwordFocusNode,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password field cannot be empty';
                          } else if (!isPassValid) {
                            return "Invalid Password";
                          }
                          return null;
                        },
                        onChanged: (value) {
                          validatePass();
                          _formKey.currentState!.validate();
                        },
                      ),
                       SizedBox(height:size.height*0.39),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPassValid
                              ? Color(0xffffc146)
                              : Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: isPassValid ? 4 : 0,
                          shadowColor: Colors.black54,
                        ),
                        onPressed: isPassValid
                            ? () {
                                if (_formKey.currentState!.validate()) {



                                  _loginUser(widget.emailAddress, context,passwordController.text.trim());





                                }
                              }
                            : null,
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

                      SizedBox(height: 15),

                      // Forgot Password Button
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () async {
                            //Forgot Page goes here

                          },
                          style: TextButton.styleFrom(
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: Colors.black,
                          ),
                          child: const Text(
                            'Forgot Password ?',
                            style: TextStyle(color: Color(0xffffc146)),
                          ),
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
