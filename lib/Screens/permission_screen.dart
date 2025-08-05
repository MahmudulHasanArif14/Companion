import 'package:companion/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

import 'home_add_screen.dart';

class PermissionScreen extends StatefulWidget {
  final User user;
  const PermissionScreen({super.key, required this.user});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final List<Map<String, dynamic>> permissions = [];

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  void _initializePermissions() {
    permissions.addAll([
      {
        'title': 'Location',
        'description': 'Location data is used to enable the in-app map, place alerts and location sharing.',
        'icon': Icons.location_on,
        'onTap': () async {
          final status = await Permission.locationWhenInUse.request();

          bool isGranted=status.isGranted;

          if(mounted && isGranted) {
            CustomSnackbar.show(
                context: context,
                label: 'Location permission: ${status.toString().split('.').last}',
                title: 'Location',
                color: Color(0xE04CAF50),
                svgColor: Color(0xE0178327),
            );
          }
          else{
            if(!mounted) return;
            CustomSnackbar.show(
              context: context,
              label: 'Location permission: ${status.toString().split('.').last}',
              title: 'Location',
            );
          }
        },
      },
      {
        'title': 'Physical Activity',
        'description': 'Monitor car travel, driver safety and Crash Alerts.',
        'icon': Icons.directions_run,
        'onTap': () async {
          final status = await Permission.activityRecognition.request();


          bool isGranted=status.isGranted;


          if(mounted && isGranted) {
            CustomSnackbar.show(
                context: context,
                label: 'Physical Activity permission: ${status.toString().split('.').last}',
                title: 'Physical Activity',
                color: Color(0xE04CAF50),
                svgColor: Color(0xE0178327),

            );
          }

          else{
            if(!mounted) return;
            CustomSnackbar.show(
              context: context,
              label: 'Location permission: ${status.toString().split('.').last}',
              title: 'Location',
            );
          }

        },
      },
      {
        'title': 'Notifications',
        'description': 'Stay up-to-date with check-ins alerts and messages from your companions.',
        'icon': Icons.notifications,
        'onTap': () async {
          final PermissionStatus status;
          if (Platform.isAndroid && await Permission.notification.isDenied) {
            status = await Permission.notification.request();
          } else if (Platform.isIOS) {
            status = await Permission.notification.request();
          } else {
            status = PermissionStatus.granted;
          }


          bool isGranted=status.isGranted;



          if(mounted && isGranted) {
            CustomSnackbar.show(
                context: context,
                label: 'Notifications permission: ${status.toString().split('.').last}',
                title: 'Notifications',
              color: Color(0xE04CAF50),
              svgColor: Color(0xE0178327),

            );
          }
          else{
            if(!mounted) return;
            CustomSnackbar.show(
              context: context,
              label: 'Notifications permission: ${status.toString().split('.').last}',
              title: 'Notifications',
            );
          }




        },
      },
      {
        'title': 'Bluetooth',
        'description': 'Help the companion circle locate your device if it gets lost.',
        'icon': Icons.bluetooth,
        'onTap': () async {
          final PermissionStatus status;
          if (Platform.isAndroid) {
            await Permission.bluetoothConnect.request();
            status = await Permission.bluetoothScan.request();
          } else {
            status = await Permission.bluetooth.request();
          }

          bool isGranted=status.isGranted;



          if(mounted && isGranted) {
            CustomSnackbar.show(
                context: context,
                label: 'Bluetooth permission: ${status.toString().split('.').last}',
                title: 'Bluetooth',
               color: Color(0xE04CAF50),
               svgColor: Color(0xE0178327),

            );
          }else{
            if(!mounted) return;
            CustomSnackbar.show(context: context, label: 'Bluetooth permission: ${status.toString().split('.').last}',title: 'Bluetooth');
          }

        },
      },
    ]);
  }



  Future<bool> _checkAllPermissionsGranted() async {
    for (var permission in permissions) {
      final status = await _getPermissionStatus(permission['title'] as String);
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }

  Future<PermissionStatus> _getPermissionStatus(String permissionName) async {
    switch (permissionName) {
      case 'Location':
        return await Permission.locationWhenInUse.status;
      case 'Physical Activity':
        return await Permission.activityRecognition.status;
      case 'Notifications':
        return await Permission.notification.status;
      case 'Bluetooth':
        if (Platform.isAndroid) {
          return await Permission.bluetoothScan.status;
        } else {
          return await Permission.bluetooth.status;
        }
      default:
        return PermissionStatus.denied;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3267E3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Companion requires these \n permissions to work',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 60),
              Expanded(
                child: ListView(
                  children: permissions.map((item) {
                    return FutureBuilder<PermissionStatus>(
                      future: _getPermissionStatus(item['title'] as String),
                      builder: (context, snapshot) {
                        //checking the status
                        final isGranted = snapshot.data?.isGranted ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 25.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(item['icon'] as IconData, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['description'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isGranted
                                      ? Color(0xE04CAF50)
                                      : const Color(0xFFFFB93A),
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: item['onTap'] as VoidCallback?,
                                child: Text(isGranted ? "Granted" : "Enable"),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB93A),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  if (await _checkAllPermissionsGranted()) {
                    // Navigate to next screen
                    debugPrint("All permissions granted");
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>HomeAddScreen(user: widget.user,)),    (Route<dynamic> route) => false,);

                  } else {

                    if(!context.mounted) return;
                    CustomSnackbar.show(
                      context: context,
                      label: 'Please grant all permissions to continue',
                    );



                  }
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  debugPrint("Remind me later tapped");
                  // Navigate with limited functionality
                },
                child: const Text(
                  "Remind me later",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}