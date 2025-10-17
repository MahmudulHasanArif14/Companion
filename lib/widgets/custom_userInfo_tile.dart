import 'package:flutter/material.dart';

import '../core/utils/constant.dart';

Widget buildUserInfoTile(String lastName,BuildContext context) {

  final safeName = (lastName.isNotEmpty) ? lastName : "Unknown";
  final nameFirstLett = safeName[0].toUpperCase();




  return ListTile(
    leading: CircleAvatar(
      backgroundColor: Colors.blue[200],
      child:  Text(
        nameFirstLett,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
    title:  Text(safeName?? "Unknown",
      style: TextStyle(fontWeight: FontWeight.w600,color: AppColors.textPrimaryColor(context)),

    ),
    subtitle: const Text(
      'Battery optimization on\nSince 4:19 pm',
      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
    ),
    trailing: const Icon(Icons.error_outline, color: Colors.red),
  );
}