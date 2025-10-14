import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class BackgroundJourneyService {
  // single instance Created
  static final BackgroundJourneyService _instance = BackgroundJourneyService._internal();
  factory BackgroundJourneyService() => _instance;
  BackgroundJourneyService._internal();

  static const String journeyTask = "background_journey_tracking";


  Future<void> initialize() async {
    debugPrint('BackgroundJourneyService: Initializing...');
    await _initializeWorkmanager();
  }


  Future<void> _initializeWorkmanager() async {
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: false,
    );
  }



  // BackGround Journey Tracking
  static Future<void> startJourneyTracking({required String journeyId, required double destLat, required double destLng,}) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_journey_id', journeyId);
    await prefs.setDouble('destination_lat', destLat);
    await prefs.setDouble('destination_lng', destLng);
    await prefs.setBool('is_tracking_active', true);

    await Workmanager().registerPeriodicTask(
      "journey_$journeyId",//unique name
      journeyTask,//task name
      frequency: const Duration(minutes: 5),
      inputData: {
        'journeyId': journeyId,
        'destLat': destLat,
        'destLng': destLng,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );


    // After Journey Start On Background Send  A Notification
    await _instance._showTrackingNotification();
  }



  // After Reached Destination Background  Tracking off
  static Future<void> stopJourneyTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final journeyId = prefs.getString('current_journey_id');

    if (journeyId != null) {
      await Workmanager().cancelByTag("journey_$journeyId");
    }

    await prefs.remove('current_journey_id');
    await prefs.remove('destination_lat');
    await prefs.remove('destination_lng');
    await prefs.setBool('is_tracking_active', false);
    final notificationService = NotificationService();


    // Cancel The Notification As Well
    await notificationService.cancelManualNotification(title: 'Journey Tracking Active');

  }


  // Get The Status Of Tracking
  static Future<bool> isTrackingActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_tracking_active') ?? false;
  }


  // Get The Active Journey Details
  static Future<Map<String, dynamic>?> getActiveJourney() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive =await isTrackingActive();

    if (!isActive) return null;

    return {
      'journeyId': prefs.getString('current_journey_id'),
      'destLat': prefs.getDouble('destination_lat'),
      'destLng': prefs.getDouble('destination_lng'),
    };
  }












  // Notification Sending While Tracking
  Future<void> _showTrackingNotification() async {
    final notificationService = NotificationService();
    notificationService.showManualNotification(
      title: "Journey Tracking Active",
      body: "Your journey is being tracked in background",
    );
  }

  // Notification Sending While Arrival
  static Future<void> _showArrivalNotification() async {
    final notificationService = NotificationService();
    notificationService.showManualNotification(
      title:  'Arrived at Destination! 🎉',
      body: 'You have successfully reached your destination',
    );
  }



}





// Top-level callback function -
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case BackgroundJourneyService.journeyTask:
          return await _handleBackgroundJourneyUpdate(inputData);
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  });
}







// check location Service Enable or not
Future<bool> _isServiceEnable() async {
  ///Check location service isEnable or not
  if (!await Geolocator.isLocationServiceEnabled()) {
    // if not open location setting
    Geolocator.openLocationSettings();
    return false;
  }
  return true;
}


// Location Permission Status Check
Future<bool> _isLocationPermissionAllowed() async {
  ///Check/request permission
  if (await _isServiceEnable()) {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Geolocator.openAppSettings();
      return false;
    }
    return true;
  }
  return false;
}



// Get Current Location Coordinates
Future<Position?> determinePosition() async {
  // checking the service and permission status
  bool permissionStatus = await _isLocationPermissionAllowed();

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

    return null;
  } catch (e) {
    return null;
  }
}

















Future<bool> _handleBackgroundJourneyUpdate(Map<String, dynamic>? inputData) async {
  if (inputData == null) return false;

  final journeyId = inputData['journeyId'];
  final destLat = inputData['destLat'];
  final destLng = inputData['destLng'];

  try {

    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('Missing Supabase credentials in .env');
    }

    // Initialize Supabase in background
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    // Get current location
    final position = await determinePosition();
    if (position == null) return false;

    final currentPos = LatLng(position.latitude, position.longitude);

    // Update journey position in Supabase
    final response=await Supabase.instance.client.from('user_journey').update({
      'current_lat': currentPos.latitude,
      'current_lng': currentPos.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', journeyId);

    if(response!=null) {
      debugPrint('Journey position updated successfully in Supabase.');
    } else {
      debugPrint('Failed to update journey position in Supabase.');
    }

    final distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      destLat,
      destLng,
    );

    if (distance <= 25) {
      await Supabase.instance.client
          .from('user_journey')
          .update({
        'reached_dest': true,
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', journeyId);

      // Stop background tracking
      await BackgroundJourneyService.stopJourneyTracking();

      // Show arrival notification
      await BackgroundJourneyService._showArrivalNotification();

      return true;
    }

    return true;
  } catch (e) {
    return false;
  }
}