
import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WalkingMarkerController {
  List<BitmapDescriptor> walkingFrames = [];
  int _currentFrame = 0;
  Timer? _animationTimer;
  LatLng? _currentPosition;
  double _currentBearing = 0.0;
  Function(Marker marker)? _onMarkerUpdated;
  bool _isAnimating = false;

  Future<void> loadFrames() async {
    try {
      walkingFrames.clear();
      const ImageConfiguration config = ImageConfiguration(
        devicePixelRatio: 2.5,

      );

      for (int i = 1; i <= 10; i++) {
        final icon = await BitmapDescriptor.asset(
          config,
          "assets/images/walking/walking$i.png",
          width: 50,
          height: 60,
        );
        walkingFrames.add(icon);
      }
    } catch (e) {
      debugPrint("Error loading walking frames: $e");
      walkingFrames.add(BitmapDescriptor.defaultMarker);
    }
  }

  void startAnimation({
    required Function(Marker marker) onMarkerUpdated,
  }) {
    _onMarkerUpdated = onMarkerUpdated;
    _isAnimating = true;

    _animationTimer ??= Timer.periodic(
      const Duration(milliseconds: 200),
          (_) {
        if (_isAnimating) {
          _currentFrame = (_currentFrame + 1) % walkingFrames.length;
          _updateMarker();
        }
      },
    );
  }

  void stopAnimation() {
    _isAnimating = false;
    _animationTimer?.cancel();
    _animationTimer = null;

    if (_currentPosition != null && walkingFrames.isNotEmpty && _onMarkerUpdated != null) {
      final marker = Marker(
        markerId: const MarkerId('walking_marker'),
        position: _currentPosition!,
        rotation: _currentBearing,
        icon: walkingFrames[0],
        anchor: const Offset(0.5, 1.0),
      );
      _onMarkerUpdated!(marker);
    }
  }

  void updatePosition(LatLng newPosition) {
    if (_currentPosition != null) {
      _currentBearing = _bearingBetween(_currentPosition!, newPosition);
    }

    _currentPosition = newPosition;
    _updateMarker();
  }

  void _updateMarker() {
    if (_currentPosition == null || walkingFrames.isEmpty || _onMarkerUpdated == null) {
      return;
    }

    final marker = Marker(
      markerId: const MarkerId('walking_marker'),
      position: _currentPosition!,
      rotation: _currentBearing,
      icon: walkingFrames[_currentFrame],
      anchor: const Offset(0.5, 1.0),
    );

    _onMarkerUpdated!(marker);
  }

  void stop() {
    _isAnimating = false;
    _animationTimer?.cancel();
    _animationTimer = null;
    _currentFrame = 0;
    _onMarkerUpdated = null;
  }

  double _bearingBetween(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x) * 180 / pi;
    bearing = bearing - 90;
    bearing = (bearing + 360) % 360;

    return bearing;
  }
}