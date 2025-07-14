// ---------------------- CustomTextField ----------------------

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.focusNode, this.textInputAction,
    this.onChanged, this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,

      validator: validator,
      keyboardType: keyboardType,
      textInputAction:textInputAction,
      focusNode: focusNode,
      autofocus: true,
      showCursor: true,
      cursorColor: Colors.blue,
      style: const TextStyle(fontSize: 18, color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        errorStyle: TextStyle(
          fontSize: 15,
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon,
        suffix: suffixIcon,
        border:InputBorder.none,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      onChanged: onChanged,
    );
  }
}
