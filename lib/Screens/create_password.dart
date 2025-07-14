import 'package:flutter/material.dart';
import '../widgets/custom_textformfield.dart';
import 'dashboard.dart';

class CreatePassword extends StatefulWidget {
  const CreatePassword({super.key});

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
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xff4169e1),
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isLengthValid && isPatternValid)
                              ? const Color(0xffffc146)
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
                          elevation: (isLengthValid && isPatternValid) ? 4 : 0,
                          shadowColor: Colors.black54,
                        ),
                        onPressed: (isLengthValid && isPatternValid)
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Dashboard(),
                                    ),
                                  );
                                }
                              }
                            : () {
                                _triggerShake();
                              },
                        child: const Text("Continue"),
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
