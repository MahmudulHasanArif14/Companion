import 'dart:convert';
import 'package:companion/models/instruction.dart';
import 'package:companion/services/background_journey_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JourneyProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _currentJourneyId;
  bool _isTracking = false;
  Map<String, dynamic>? _activeJourneyData;

  // Map state
  LatLng? _fromLocation;
  LatLng? _toLocation;
  LatLng? _userLocation;
  String _travelMode="driving";
  List<Instruction> _instructions = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Getters
  String? get currentJourneyId => _currentJourneyId;
  String get travelMode=>_travelMode;
  bool get isTracking => _isTracking;
  Map<String, dynamic>? get activeJourneyData => _activeJourneyData;
  LatLng? get fromLocation => _fromLocation;
  LatLng? get toLocation => _toLocation;
  LatLng? get userLocation => _userLocation;
  List<Instruction> get instructions => _instructions;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;


  JourneyProvider() {
    _initialize();
  }

  /// 🔹 Restore previous active journey on app start
  Future<void> _initialize() async {
    final activeJourney = await BackgroundJourneyService.getActiveJourney();
    if (activeJourney != null) {
      _currentJourneyId = activeJourney['journeyId'];
      _isTracking = true;
      _activeJourneyData = activeJourney;
      notifyListeners();
    }
  }

  /// 🔹 Save active journey (local cache)
  Future<void> saveActiveJourney({
    required String journeyId,
    required LatLng pickup,
    required LatLng destination,
    required LatLng currentLocation,
    String? travelMode,
    required List<Instruction> instructions,
    required Set<Marker> markers,
    required Set<Polyline> polylines,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'journeyId': journeyId,
      'travelMode': travelMode,
      'fromLocation': {'lat': pickup.latitude, 'lng': pickup.longitude},
      'toLocation': {'lat': destination.latitude, 'lng': destination.longitude},
      'userLocation': {
        'lat': currentLocation.latitude,
        'lng': currentLocation.longitude,
      },
      'instructions': instructions.map((i) => i.toJson()).toList(),
      'markers': markers
          .map((m) => {
        'id': m.markerId.value,
        'lat': m.position.latitude,
        'lng': m.position.longitude,
        'title': m.infoWindow.title,
        'iconType': (m.markerId.value == 'user_current' ||
            m.markerId.value == 'pickup')
            ? 'pickup'
            : 'destination',
      })
          .toList(),
      'polylines': polylines
          .map((p) => {
        'id': p.polylineId.value,
        'points': p.points
            .map((pt) => {'lat': pt.latitude, 'lng': pt.longitude})
            .toList(),
      }).toList(),
    };

    await prefs.setString('active_journey', jsonEncode(data));
    await prefs.setBool('is_tracking_active', true);

    _isTracking = true;
    _currentJourneyId = journeyId;
    notifyListeners();
  }

  /// 🔹 Marker Icons
  Future<BitmapDescriptor> pickup() async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 2.5),
      "assets/images/pickup.png",
      width: 85,
      height: 70,
    );
  }

  Future<BitmapDescriptor> destinationIcon() async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 2.5),
      "assets/images/destination.png",
      width: 85,
      height: 70,
    );
  }

  /// 🔹 Load saved journey from SharedPreferences
  Future<void> loadActiveJourney() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool('is_tracking_active') ?? false;
    if (!isActive) return;

    final jsonString = prefs.getString('active_journey');
    if (jsonString == null) return;

    final data = jsonDecode(jsonString);

    final destIcon = await destinationIcon();
    final pickupIcon = await pickup();

    _currentJourneyId = data['journeyId'];
    _travelMode = data['travelMode'];
    _fromLocation =
        LatLng(data['fromLocation']['lat'], data['fromLocation']['lng']);
    _toLocation = LatLng(data['toLocation']['lat'], data['toLocation']['lng']);
    _userLocation =
        LatLng(data['userLocation']['lat'], data['userLocation']['lng']);

    _instructions = (data['instructions'] as List)
        .map((e) => Instruction.fromJson(e))
        .toList();

    _markers = (data['markers'] as List).map<Marker>((m) {
      BitmapDescriptor icon;
      if (m['iconType'] == 'pickup') {
        icon = pickupIcon;
      } else if (m['iconType'] == 'destination') {
        icon = destIcon;
      } else {
        icon = BitmapDescriptor.defaultMarker;
      }
      return Marker(
        markerId: MarkerId(m['id']),
        position: LatLng(m['lat'], m['lng']),
        infoWindow: InfoWindow(title: m['title']),
        icon: icon,
      );
    }).toSet();

    _polylines = (data['polylines'] as List)
        .map((p) => Polyline(
      polylineId: PolylineId(p['id']),
      points: (p['points'] as List)
          .map((pt) => LatLng(pt['lat'], pt['lng']))
          .toList(),
      color: Colors.blue,
      width: 5,
    ))
        .toSet();

    _isTracking = true;
    notifyListeners();
  }

  /// 🔹 Clear all active journey data
  Future<void> clearActiveJourney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_journey');
    await prefs.remove('is_tracking_active');

    _currentJourneyId = null;
    _travelMode = "driving";
    _fromLocation = null;
    _toLocation = null;
    _userLocation = null;
    _instructions = [];
    _markers = {};
    _polylines = {};
    _isTracking = false;
    _activeJourneyData = null;

    notifyListeners();
    debugPrint('✅ Active journey cleared successfully.');
  }

  /// 🔹 Start new journey
  Future<void> startNewJourney({
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('user_journey')
          .insert({
        'user_id': user.id,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'current_lat': pickupLat,
        'current_lng': pickupLng,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
        'reached_dest': false,
        'status': 'ongoing',
        'started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select('id')
          .single();

      // ✅ Ensure ID type safety
      _currentJourneyId = response['id'].toString();
      _isTracking = true;

      await BackgroundJourneyService.startJourneyTracking(
        journeyId: _currentJourneyId!,
        destLat: destinationLat,
        destLng: destinationLng,
      );

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to start journey: $e');
    }
  }

  /// 🔹 Stop current journey
  Future<void> stopCurrentJourney() async {
    if (_currentJourneyId == null) return;

    try {
      await _supabase
          .from('user_journey')
          .update({
        'status': 'cancelled',
        'ended_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', _currentJourneyId!);

      await BackgroundJourneyService.stopJourneyTracking();
      await clearActiveJourney();
    } catch (e) {
      throw Exception('Failed to stop journey: $e');
    }
  }

  /// 🔹 Complete journey
  Future<void> completeJourney() async {
    if (_currentJourneyId == null) return;

    try {
      await _supabase
          .from('user_journey')
          .update({
        'reached_dest': true,
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', _currentJourneyId!);

      await BackgroundJourneyService.stopJourneyTracking();
      await clearActiveJourney();
    } catch (e) {
      throw Exception('Failed to complete journey: $e');
    }
  }

  /// 🔹 Refresh journey status
  Future<void> refreshJourneyStatus() async {
    if (_currentJourneyId == null) return;

    try {
      final response = await _supabase
          .from('user_journey')
          .select('*')
          .eq('id', _currentJourneyId!)
          .maybeSingle();

      final status = response?['status'] as String?;
      if (status == 'completed' || status == 'cancelled') {
        await clearActiveJourney();
      }
    } catch (_) {
      await clearActiveJourney();
    }
  }
}
