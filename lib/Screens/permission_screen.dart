import 'package:companion/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

import '../Auth/auth_helper.dart';
import 'home_add_screen.dart';

class PermissionScreen extends StatefulWidget {
  final User user;
  const PermissionScreen({super.key, required this.user});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final List<Map<String, dynamic>> permissions = [];
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    dataBaseUpdate();
    _initializePermissions();
  }

  Future<void> dataBaseUpdate() async {
    final updatedUser = widget.user;
    if(updatedUser.userMetadata == null) return;

    final displayName = updatedUser.userMetadata?['name'] ?? 'User';
    final lastName = displayName.split(' ').last;

    await OauthHelper().setUsernameOnce(defaultUsername: lastName);

    if(mounted) {
      await OauthHelper.updateName(context, displayName);
      if(mounted) {
        await OauthHelper.updatePhoneNo(context);
      }
    }
  }

  void _initializePermissions() {
    permissions.addAll([
      {
        'title': 'Location',
        'description': 'Location data is used to enable the in-app map, place alerts and location sharing.',
        'icon': Icons.location_on,
        'permissionType': 'location',
        'onTap': () async {
          final status = await Permission.locationAlways.request();
          print("Status of this is ${status.toString()}");

          _refreshUI();

          if(mounted && status.isGranted) {
            CustomSnackbar.show(
              context: context,
              label: 'Location permission: ${status.toString().split('.').last}',
              title: 'Location',
              color: Color(0xE04CAF50),
              svgColor: Color(0xE0178327),
            );
          } else {
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
        'permissionType': 'activity',
        'onTap': () async {
          final status = await Permission.activityRecognition.request();
          _refreshUI();

          if(mounted && status.isGranted) {
            CustomSnackbar.show(
              context: context,
              label: 'Physical Activity permission: ${status.toString().split('.').last}',
              title: 'Physical Activity',
              color: Color(0xE04CAF50),
              svgColor: Color(0xE0178327),
            );
          } else {
            if(!mounted) return;
            CustomSnackbar.show(
              context: context,
              label: 'Physical Activity permission: ${status.toString().split('.').last}',
              title: 'Physical Activity',
            );
          }
        },
      },
      {
        'title': 'Notifications',
        'description': 'Stay up-to-date with check-ins alerts and messages from your companions.',
        'icon': Icons.notifications,
        'permissionType': 'notification',
        'onTap': () async {
          final PermissionStatus status;
          if (Platform.isAndroid && await Permission.notification.isDenied) {
            status = await Permission.notification.request();
          } else if (Platform.isIOS) {
            status = await Permission.notification.request();
          } else {
            status = PermissionStatus.granted;
          }

          _refreshUI();

          if(mounted && status.isGranted) {
            CustomSnackbar.show(
              context: context,
              label: 'Notifications permission: ${status.toString().split('.').last}',
              title: 'Notifications',
              color: Color(0xE04CAF50),
              svgColor: Color(0xE0178327),
            );
          } else {
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
        'permissionType': 'bluetooth',
        'onTap': () async {
          final PermissionStatus status;
          if (Platform.isAndroid) {
            await Permission.bluetoothConnect.request();
            status = await Permission.bluetoothScan.request();
          } else {
            status = await Permission.bluetooth.request();
          }

          _refreshUI();

          if(mounted && status.isGranted) {
            CustomSnackbar.show(
              context: context,
              label: 'Bluetooth permission: ${status.toString().split('.').last}',
              title: 'Bluetooth',
              color: Color(0xE04CAF50),
              svgColor: Color(0xE0178327),
            );
          } else {
            if(!mounted) return;
            CustomSnackbar.show(
                context: context,
                label: 'Bluetooth permission: ${status.toString().split('.').last}',
                title: 'Bluetooth'
            );
          }
        },
      },
    ]);
  }

  void _refreshUI() {
    setState(() {
      _refreshCounter++;
    });
  }

  Future<PermissionStatus> _getPermissionStatus(String permissionName) async {
    switch (permissionName) {
      case 'Location':
        return await Permission.locationAlways.status;
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

  Future<bool> _checkAllPermissionsGranted() async {
    for (var permission in permissions) {
      final status = await _getPermissionStatus(permission['title'] as String);
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
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
                child: ListView.builder(
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    final item = permissions[index];
                    return PermissionItemWidget(
                      item: item,
                      refreshCounter: _refreshCounter,
                      onStatusChange: _refreshUI,
                    );
                  },
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
                    debugPrint("All permissions granted");
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomeAddScreen(user: widget.user)),
                          (Route<dynamic> route) => false,
                    );
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeAddScreen(user: widget.user)),
                        (Route<dynamic> route) => false,
                  );
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

class PermissionItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final int refreshCounter;
  final VoidCallback onStatusChange;

  const PermissionItemWidget({
    super.key,
    required this.item,
    required this.refreshCounter,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: _getPermissionStatus(item['title'] as String),
      builder: (context, snapshot) {
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
                onPressed: () async {
                  if (item['onTap'] != null) {
                    await (item['onTap'] as Future<void> Function())();
                  }
                },
                child: Text(isGranted ? "Granted" : "Enable"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<PermissionStatus> _getPermissionStatus(String permissionName) async {
    switch (permissionName) {
      case 'Location':
        return await Permission.locationAlways.status;
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
}