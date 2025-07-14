import 'package:flutter/material.dart';
import '../widgets/custom_textformfield.dart';
import 'email_registration.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xff4169e1),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        forceMaterialTransparency: true,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(
              parent: NeverScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.08,
                  vertical: size.height * 0.05,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Step 1 of 3",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: const Text(
                          "What's Your Name?",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // First Name Field
                      CustomTextField(
                        controller: firstName,
                        hintText: "First Name",
                        icon: const Icon(Icons.person_outline, color: Colors.white),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        focusNode: nameFocusNode,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "First Name can't be empty";
                          }
                          return null;
                        },
                        onChanged: (_) => _formKey.currentState!.validate(),
                      ),

                      const SizedBox(height: 24),

                      // Last Name Field
                      CustomTextField(
                        controller: lastName,
                        hintText: "Last Name",
                        icon: const Icon(Icons.person_outline, color: Colors.white),
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Last Name can't be empty";
                          }
                          return null;
                        },
                        onChanged: (_) => _formKey.currentState!.validate(),
                      ),

                      SizedBox(height: size.height*.44),

                      // Continue Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffffc146),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black54,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>  EmailRegistration()),
                            );
                          }
                        },
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

                      const SizedBox(height: 20),
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
