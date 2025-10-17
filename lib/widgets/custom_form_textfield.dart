import 'package:flutter/material.dart';

class CustomFormTextField extends StatelessWidget {
  final TextEditingController? textController;
  final TextInputType textKeyboardType;
  final String? labelText;
  final Widget? suffixIcon,suffix;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool obscureText;
  final Widget? prefix,prefixIcon;



  const CustomFormTextField({
    super.key,
    this.textController,
    this.textKeyboardType = TextInputType.text,
    required this.labelText,
    this.suffixIcon,
    this.hintText, this.validator, this.onChanged,
    this.obscureText=false,
    this.suffix, this.prefix,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textController,
      obscureText:obscureText,
      keyboardType: textKeyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefix: prefix,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        suffix: suffix,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x9B3386FE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0x2A3386FE)
                : const Color(0x9B3386FE),
            width: Theme.of(context).brightness == Brightness.dark ? 2 : 1,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
      ),

      validator: validator,
      onChanged: onChanged,


    );
  }
}











