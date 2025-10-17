import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Auth/auth_helper.dart';
import '../widgets/custom_form_textfield.dart';

class ResetPasswordScreen extends StatefulWidget {

  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form Key

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool validPass = false;
  bool _isSubmitted = false;


  // Checking both pass are same or not
  void isSamePass() {
    final pass = _newPasswordController.text.toString().trim();
    final confirmPass = _confirmPasswordController.text.toString().trim();
    setState(() {
      validPass =
          pass.isNotEmpty && confirmPass.isNotEmpty && pass == confirmPass;
    });
  }

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(isSamePass);
    _confirmPasswordController.addListener(isSamePass);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _newPasswordController.removeListener(isSamePass);
    _confirmPasswordController.removeListener(isSamePass);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        forceMaterialTransparency: true,

      ),
      body: SafeArea(

        child: SizedBox(
          height: screenHeight,
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(
                parent: NeverScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "Enter New Password",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Please enter your new password",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    SizedBox(
                      height: screenHeight * 0.3,
                      child: SvgPicture.asset(
                        'assets/images/newpassword.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    // Password Field
                    CustomFormTextField(
                      textController: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      labelText: 'Enter New Password',
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                                () => _obscureNewPassword = !_obscureNewPassword,
                          );
                        },
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),

                      suffix:
                      (validPass)
                          ? Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      )
                          : null,
                      validator: (value) {
                        if (!_isSubmitted) return null;
                        if (value == null || value.isEmpty) {
                          return "Password Can't be Empty! ";
                        }
                        if(!validPass){
                          return "Both Password Should be Same!";
                        }

                        return null;
                      },

                      onChanged: (value) {
                        setState(() {
                          _isSubmitted = false;
                          _formKey.currentState!.validate();
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    // Confirm_Password Field
                    CustomFormTextField(
                      textController: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      labelText: 'Re-Enter Password',
                      hintText: 'Confirm Password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),

                      suffix:
                      (validPass)
                          ? Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      )
                          : null,

                      validator: (value) {
                        if (!_isSubmitted) return null;
                        if (value == null || value.isEmpty) {
                          return "Password Can't be Empty!";
                        }
                        if(!validPass){
                          return "Both Password Should be Same!";
                        }
                        return null;
                      },

                      onChanged: (value) {
                        setState(() {
                          _isSubmitted = false;
                          _formKey.currentState!.validate();
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    SizedBox(height: screenHeight * 0.01),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isSubmitted = true;
                          });

                          // Handle update password logic
                          if (_formKey.currentState!.validate() && validPass) {
                            // Perform password reset
                            OauthHelper.updatePassword(_newPasswordController.text.toString().trim(),context);

                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Update Password",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}