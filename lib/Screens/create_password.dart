import 'package:flutter/material.dart';
import '../Auth/auth_helper.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/custom_textformfield.dart';

class CreatePassword extends StatefulWidget {
  final String fullName,emailAddress;
  const CreatePassword({super.key, required this.fullName, required this.emailAddress});

  @override
  State<CreatePassword> createState() => _CreatePasswordState();
}

class _CreatePasswordState extends State<CreatePassword>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passFocusNode = FocusNode();

  bool isLengthValid = false;
  bool isPatternValid = false;
  bool obscurePassword = true;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(validatePassword);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      passFocusNode.requestFocus();
    });

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 12,
    ) .chain(CurveTween(curve: Curves.easeInOut)).animate(_shakeController);
  }

  @override
  void dispose() {
    passwordController.removeListener(validatePassword);
    passwordController.dispose();
    passFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void validatePassword() {
    final password = passwordController.text;
    setState(() {
      isLengthValid = password.length >= 8;
      isPatternValid = RegExp(
        r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@\$!%*?&])',
      ).hasMatch(password);
    });
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }




  final OauthHelper _authHelper = OauthHelper();

  void _registerUser(String email,String password,String name) async {

    if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
      await _authHelper.signUp(
        email: email,
        password: password,
        context: context,
        name: name,
      );


    } else {
      CustomSnackbar.show(
        context: context,
        label: "Email And Password Can't be Null",
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xff4169e1),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        forceMaterialTransparency: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Step 3 of 3",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Create Your Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 40),
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: CustomTextField(
                          controller: passwordController,
                          hintText: "Password",
                          obscureText: obscurePassword,
                          icon: const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                          ),
                          focusNode: passFocusNode,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password cannot be empty';
                            }
                            if (!isLengthValid || !isPatternValid) {
                              return 'Password doesn\'t meet the requirements';
                            }
                            return null;
                          },
                          onChanged: (_) {
                            validatePassword();
                            _formKey.currentState!.validate();
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Icon(
                            isLengthValid ? Icons.check_circle : Icons.cancel,
                            color: isLengthValid ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "At least 8 characters",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isPatternValid ? Icons.check_circle : Icons.cancel,
                            color: isPatternValid ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Letters, numbers, & special characters",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.25),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xffffc146),
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
                              elevation:   4,
                              shadowColor: Colors.black54,
                            ),
                            onPressed: (isLengthValid && isPatternValid)
                                ? () {
                                    if (_formKey.currentState!.validate()) {



                                      _registerUser(widget.emailAddress.trim(),passwordController.text.trim(),widget.fullName.trim());


                                    }
                                  }
                                : () {
                                    _triggerShake();
                                  },
                            child: const Text("Continue"),
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
