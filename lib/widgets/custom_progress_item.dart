import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';

Widget buildProgressItem(BuildContext context,VoidCallback? onPressed) {
  final provider=Provider.of<DatabaseHelperProvider>(context);
  final profileData=provider.userInfo;
  final avatarLink=profileData?["avatar_url"];
  final phoneNo=profileData?["phone"];
  final isAvatarPresent=(avatarLink!=null && avatarLink.toString().isNotEmpty) ? true:false;
  final isPhonePresent=(phoneNo!=null && phoneNo.toString().isNotEmpty) ? true:false;


  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      if(!isAvatarPresent)
      Text(
        'Add a profile photo',
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
      ),
      if(isAvatarPresent)
        Text(
          'Add a Phone Number',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
      IconButton(
        onPressed:onPressed,
        icon:const Icon( Icons.close,
                   color: Colors.white70,
        ),
      ),
    ],
  );
}



Widget buildProgressIndicator(BuildContext context) {
  final provider=Provider.of<DatabaseHelperProvider>(context);
  final profileData=provider.userInfo;
  final avatarLink=profileData?["avatar_url"];
  final phoneNo=profileData?["phone"];
  final isAvatarPresent=(avatarLink!=null && avatarLink.toString().isNotEmpty) ? true:false;
  final isPhonePresent=(phoneNo!=null && phoneNo.toString().isNotEmpty) ? true:false;
  var progressVal=0.0;

  if(isAvatarPresent && !isPhonePresent){
    progressVal=0.5;
  }else if(!isAvatarPresent && isPhonePresent){
    progressVal=0.5;
  }else if(isAvatarPresent && isPhonePresent){
    progressVal=1.0;
  }


  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: LinearProgressIndicator(
      value:progressVal,
      color: Colors.yellow[600],
      backgroundColor: Colors.white24,
      minHeight: 8,
    ),
  );
}