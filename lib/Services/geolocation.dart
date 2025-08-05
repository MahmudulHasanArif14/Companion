import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../widgets/custom_consent.dart';
import '../widgets/custom_snackbar.dart';

class LocationHelper {
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;

  final CustomConsentBox _customAlert = CustomConsentBox();

  // user consent dialog box
  Future<bool> _showDisclosureDialog(BuildContext context) async {
    final completer = Completer<bool>();

    _customAlert.showCustomConsentAlert(
      context: context,
      title: 'Allow Background Location Access',
      label:
          'We need your permission to access location in the background so we can track attendance when you enter or leave the office. Your data is secure and private.',
      onResult: (result) => completer.complete(result),
    );

    return completer.future;
  }

  Future<bool> isUserAgreed(BuildContext context) {
    final userAgreedStatus = Completer<bool>();

    _customAlert.showCustomConsentAlert(
      context: context,
      title: 'Location Service Disabled',
      label: 'Please enable location services to use this feature.',
      onResult: (result) {
        userAgreedStatus.complete(result);
      },
    );
    return userAgreedStatus.future;
  }

  // check location Service Enable or not
  Future<bool> _isServiceEnable(BuildContext context) async {
    ///Check location service isEnable or not
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (context.mounted) {
        if (await isUserAgreed(context)) {
          // if not open location setting
          Geolocator.openLocationSettings();
        }
      }
      return false;
    } else {
      return true;
    }
  }

  // Location Permission Status Check
  Future<bool> _isLocationPermissionAllowed(BuildContext context) async {
    ///Check/request permission
    if (await _isServiceEnable(context)) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            CustomSnackbar.show(
              context: context,
              title: 'Location Permission Denied',
              label: 'This app needs location permissions to work properly.',
            );
          }
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          bool userAgreedStatus = await isUserAgreed(context);
          if (userAgreedStatus) {
            Geolocator.openAppSettings();
          }
        }
        return false;
      }
      return true;
    }
    return false;
  }

  // Get Current Location Coordinates
  Future<Position?> determinePosition(BuildContext context) async {
    // checking the service and permission status
    bool permissionStatus = await _isLocationPermissionAllowed(context);

    // if not true return
    if (!permissionStatus) return null;

    //get position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return position;
    } on TimeoutException {
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Location request timed out. Try again.',
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Error getting location: $e',
        );
      }
      return null;
    }
  }

  // getting current address name using position lat,lng
  Future<Placemark?> currentAddressName(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        return place;

        // setState(() {
        //   address =
        //   '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        // });
      } else {
        return null;
      }

      // setState(() {
      //   _center = LatLng(lat, lng);
      //   _currentLocationMarker = Marker(
      //     markerId: const MarkerId('currentLocation'),
      //     position: _center,
      //     infoWindow: InfoWindow(title: 'Your Location', snippet: address),
      //     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      //   );
      //   _isLoading = false;
      // });

      // mapController?.animateCamera(
      //   CameraUpdate.newLatLngZoom(_center, 15),
      // );
    } on PlatformException catch (e) {
      debugPrint('Error: ${e.message}');
      return null;

      // setState(() {
      //   address = 'Could not fetch address';
      //   _isLoading = false;
      // });
    }
  }

  Future<Placemark?> reverseGeocode(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        return place;
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return null;
  }

  /// Start continuous tracking.
  void startTracking({
    required void Function(Position) onData,
    void Function(ServiceStatus)? onServiceStatus,
    LocationSettings? customSettings,
  }) {
    final settings =
        customSettings ??
        const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 10,
        );

    /// [onData] is called whenever a new [Position] is available.
    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(onData);

    ///Check if the user has turn off the service status or not
    /// [onServiceStatus] can be used to listen to GPS on/off changes
    if (onServiceStatus != null) {
      _serviceStatusSub = Geolocator.getServiceStatusStream().listen(
        onServiceStatus,
      );
    }
  }

  ///Distance Calculation user and user office location
  static double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Stop any active position or service‐status subscriptions.
  void stopTracking() {
    _positionSub?.cancel();
    _serviceStatusSub?.cancel();
    _positionSub = null;
    _serviceStatusSub = null;
  }
}
