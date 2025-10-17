
import 'package:companion/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../Auth/auth_helper.dart';
import '../database/database_helper.dart';
import '../widgets/custom_profile_info_tile.dart';

class ProfileDetails extends StatefulWidget {
  const ProfileDetails({super.key});

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  String? _activeField;

  @override
  void initState() {
    super.initState();
    // Fetch profile once when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DatabaseHelperProvider>();
      provider.fetchUserInfo();
    });

  }


  ///UPDATE DATA TO THE DATABASE
  Future<void> _updateField(BuildContext context, String key, dynamic value) async {
    await Provider.of<DatabaseHelperProvider>(context, listen: false)
        .updateUserField(key, value);
  }




  @override
  Widget build(BuildContext context) {
    final dbProvider = Provider.of<DatabaseHelperProvider>(context);
    final currentUser=OauthHelper.currentUser();
    final email=currentUser?.email.toString().trim();

    final profile = dbProvider.userInfo;

    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _activeField = null);
        },
        child: dbProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : profile == null
            ? const Center(child: Text('No profile data available.'))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(5),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoTile(
                    value:profile["full_name"] ?? "",
                    readOnly:false,
                    title: "Full Name",
                    fieldKey: "full_name",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField(context, "full_name", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "full_name" : null);
                    },
                  ),
                  InfoTile(
                    value: email??"",
                    readOnly:true,
                    title: "Email Address",
                    fieldKey: "email",
                    activeField: _activeField,
                    onChanged: (newValue) {},
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "email" : null);
                    },
                  ),
                  // InfoTile(
                  //   value: profile["phone"] ?? "",
                  //   title: "Phone",
                  //   readOnly:false,
                  //   fieldKey: "phone",
                  //   activeField: _activeField,
                  //   onChanged: (newValue) {
                  //     // _updateField(context, "phone", newValue);
                  //   },
                  //   onFocusChange: (isFocused) {
                  //     setState(() => _activeField = isFocused ? "phone" : null);
                  //   },
                  // ),
                  // InfoTile(
                  //   value: profile["age"]?.toString() ?? "",
                  //   title: "Age",
                  //   fieldKey: "age",
                  //   activeField: _activeField,
                  //   onChanged: (newValue) {
                  //     _updateField(context, "age", newValue);
                  //   },
                  //   onFocusChange: (isFocused) {
                  //     setState(() => _activeField = isFocused ? "age" : null);
                  //   },
                  // ),
                  // InfoTile(
                  //   value: profile["address"] ?? "",
                  //   title: "Address",
                  //   fieldKey: "address",
                  //   activeField: _activeField,
                  //   onChanged: (newValue) {
                  //     _updateField(context, "address", newValue);
                  //   },
                  //   onFocusChange: (isFocused) {
                  //     setState(() => _activeField = isFocused ? "address" : null);
                  //   },
                  // ),
                  // InfoTile(
                  //   value: profile["blood_group"] ?? "",
                  //   title: "Blood Group",
                  //   fieldKey: "blood_group",
                  //   activeField: _activeField,
                  //   onChanged: (newValue) {
                  //     _updateField(context, "blood_group", newValue);
                  //   },
                  //   onFocusChange: (isFocused) {
                  //     setState(() => _activeField = isFocused ? "blood_group" : null);
                  //   },
                  // ),
                  InfoTile(
                    isDropdown: true,
                    value: profile["gender"] ?? "",
                    title: "Gender",
                    fieldKey: "gender",
                    activeField: _activeField,
                    onItemChanged: (newValue) {
                      _updateField(context, "gender", newValue!);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "gender" : null);
                    },
                  ),
                  InfoTile(
                    value: profile["emergency_contact"] ?? "",
                    title: "Emergency Contact Without County Code",
                    fieldKey: "emergency_contact",
                    activeField: _activeField,
                    onChanged: (newValue) {

                      if(newValue.length==11 && RegExp(r'^(013|014|015|016|017|018|019)\d{8}$').hasMatch(newValue)){
                            _updateField(context, "emergency_contact", newValue);
                      }
                      else{
                        CustomSnackbar.show(context: context, label: 'Invalid Phone Number');
                      }

                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "emergency_contact" : null);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
