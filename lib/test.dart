import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {

  late LatLng _currAdd =  LatLng(24.8889, 91.8815);

  @override
  Widget build(BuildContext context) {
    return Scaffold(



      body: GoogleMap(

        initialCameraPosition:CameraPosition(

          target: _currAdd,
           zoom: 20,



      ),

        markers: {
          Marker(markerId: MarkerId("a"),
          position: _currAdd,
            icon: BitmapDescriptor.defaultMarker,
            draggable: true,
            onDragEnd: (val){
            _currAdd=val;
            setState(() {

            });
            }




          )
        },




      ),



    );
  }
}























































// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
//
// class Demo extends StatefulWidget {
//   const Demo({super.key});
//
//   @override
//   State<Demo> createState() => _DemoState();
// }
//
// class _DemoState extends State<Demo> {
//   late GoogleMapController _mapController;
//   StreamSubscription<Position>? _positionStream;
//
//   LatLng _currAdd =  LatLng(24.8889, 91.8815);
//
//
//   final Set<Marker> _markers = {
//
//
//   };
//   final Set<Circle> _circles = {};
//   final Set<Polyline> _polylines = {};
//
//   String _mapStyle = '';
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Custom map style (JSON string)
//     _mapStyle = '''
//     [
//       {
//         "featureType": "all",
//         "elementType": "geometry.fill",
//         "stylers": [{"color": "#e0f7fa"}]
//       },
//       {
//         "featureType": "poi",
//         "stylers": [{"visibility": "off"}]
//       }
//     ]
//     ''';
//
//     _addInitialMapData();
//     _initLocationTracking();
//   }
//
//   void _addInitialMapData() {
//     _markers.add(
//       Marker(
//         markerId: const MarkerId('initial_marker'),
//         position: _currAdd,
//         infoWindow: const InfoWindow(title: 'Sylhet', snippet: 'Initial Location'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
//         draggable: true,
//          onDrag: (val){
//
//           _currAdd=val;
//         setState(() {
//
//         });
//           },
//         onDragEnd: (LatLng newPos) {
//           setState(() => _currAdd = newPos);
//         },
//       ),
//     );
//
//     _circles.add(
//       Circle(
//         circleId: const CircleId('radius'),
//         center: _currAdd,
//         radius: 500,
//         fillColor: Colors.blue.withOpacity(0.2),
//         strokeColor: Colors.blue,
//         strokeWidth: 2,
//       ),
//     );
//
//     _polylines.add(
//       Polyline(
//         polylineId: const PolylineId('polyline1'),
//         color: Colors.green,
//         width: 4,
//         jointType: JointType.round,
//         startCap: Cap.roundCap,
//         endCap: Cap.buttCap,
//         points: [
//           _currAdd,
//           const LatLng(24.8965, 91.8721),
//           const LatLng(24.8918, 91.8833),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _initLocationTracking() async {
//     // Check permission
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         print('Location permission denied');
//         return;
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       print('Location permissions are permanently denied');
//       return;
//     }
//
//     // Check if location services enabled
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       print('Location services are disabled.');
//       return;
//     }
//
//     // Get current position once
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     _updatePosition(position);
//
//     // Listen to position updates
//     _positionStream = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 10,
//       ),
//     ).listen((Position position) {
//       _updatePosition(position);
//     });
//   }
//
//   void _updatePosition(Position position) {
//     final newPosition = LatLng(position.latitude, position.longitude);
//
//     setState(() {
//       _currAdd = newPosition;
//
//       _markers.removeWhere((m) => m.markerId.value == 'user');
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('user'),
//           position: newPosition,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//           infoWindow: const InfoWindow(title: "You're Here"),
//         ),
//       );
//
//       _circles.removeWhere((c) => c.circleId.value == 'radius');
//       _circles.add(
//         Circle(
//           circleId: const CircleId('radius'),
//           center: newPosition,
//           radius: 500,
//           fillColor: Colors.blue.withOpacity(0.2),
//           strokeColor: Colors.blue,
//           strokeWidth: 2,
//         ),
//       );
//     });
//
//     _mapController.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: newPosition,
//           zoom: 16,
//           bearing: 90,
//           tilt: 45,
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(title: const Text("Dynamic Map with Styling")),
//         body: GoogleMap(
//           mapType: MapType.normal,
//           initialCameraPosition: CameraPosition(
//             target: _currAdd,
//             zoom: 13,
//             tilt: 30,
//             bearing: 90,
//           ),
//           onMapCreated: (GoogleMapController controller) {
//             _mapController = controller;
//             _mapController.setMapStyle(_mapStyle);
//           },
//
//           markers: _markers,
//           circles: _circles,
//           polylines: _polylines,
//           zoomControlsEnabled: true,
//           scrollGesturesEnabled: true,
//           rotateGesturesEnabled: true,
//           tiltGesturesEnabled: true,
//           zoomGesturesEnabled: true,
//           myLocationEnabled: true,
//           myLocationButtonEnabled: true,
//           compassEnabled: true,
//           trafficEnabled: false,
//           buildingsEnabled: true,
//           indoorViewEnabled: true,
//           onTap: (position) => print("Tapped on: $position"),
//           onLongPress: (position) => print("Long pressed on: $position"),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// //
// // class Demo extends StatefulWidget {
// //   Demo({super.key});
// //
// //   @override
// //   State<Demo> createState() => _DemoState();
// // }
// //
// // class _DemoState extends State<Demo> {
// //   late GoogleMapController mapController;
// //
// //   // Initial map location (Sylhet, BD)
// //   LatLng currAdd = LatLng(24.8889, 91.8815);
// //
// //   // Markers (pins on map)
// //   final Set<Marker> _markers = {
// //     Marker(
// //       markerId: MarkerId('marker1'),
// //       position: LatLng(24.8918, 91.8833),
// //       infoWindow: InfoWindow(title: 'Sylhet Central', snippet: 'Main Point'),
// //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
// //     ),
// //     Marker(
// //       markerId: MarkerId('marker2'),
// //       position: LatLng(24.8965, 91.8721),
// //       infoWindow: InfoWindow(title: 'Lamabazar'),
// //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
// //     ),
// //   };
// //
// //   // Circles (to highlight areas)
// //   final Set<Circle> _circles = {
// //     Circle(
// //       circleId: CircleId('circle1'),
// //       center: LatLng(24.8918, 91.8833),
// //       radius: 300,
// //       strokeColor: Colors.red,
// //       fillColor: Colors.red.withOpacity(0.2),
// //       strokeWidth: 2,
// //     ),
// //   };
// //
// //   // Polylines (routes/paths)
// //   final Set<Polyline> _polylines = {
// //     Polyline(
// //       polylineId: PolylineId('polyline1'),
// //       color: Colors.green,
// //       width: 5,
// //       startCap: Cap.roundCap,
// //       endCap: Cap.roundCap,
// //       jointType: JointType.round,
// //       points: [
// //         LatLng(24.8918, 91.8833),
// //         LatLng(24.8950, 91.8800),
// //         LatLng(24.8965, 91.8721),
// //       ],
// //     ),
// //   };
// //
// //   // Polygons (multi-point areas)
// //   final Set<Polygon> _polygons = {
// //     Polygon(
// //       polygonId: PolygonId("poly1"),
// //       points: [
// //         LatLng(24.8889, 91.8815),
// //         LatLng(24.8895, 91.8850),
// //         LatLng(24.8910, 91.8840),
// //         LatLng(24.8900, 91.8800),
// //       ],
// //       strokeColor: Colors.orange,
// //       fillColor: Colors.orange.withOpacity(0.2),
// //       strokeWidth: 3,
// //     ),
// //   };
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //
// //     // Add draggable marker
// //     _markers.add(
// //       Marker(
// //         markerId: MarkerId('current'),
// //         position: currAdd,
// //         infoWindow: InfoWindow(
// //           title: 'You are here',
// //           snippet: 'Drag to move',
// //         ),
// //         draggable: true,
// //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
// //         onDragEnd: (LatLng newPosition) {
// //           setState(() {
// //             currAdd = newPosition;
// //           });
// //           print("New position: $newPosition");
// //         },
// //       ),
// //     );
// //
// //     // Add circle around current location
// //     _circles.add(
// //       Circle(
// //         circleId: CircleId('circle_current'),
// //         center: currAdd,
// //         radius: 500,
// //         strokeColor: Colors.blue,
// //         fillColor: Colors.blue.withOpacity(0.3),
// //         strokeWidth: 2,
// //       ),
// //     );
// //
// //     // Add another polyline from current to a nearby point
// //     _polylines.add(
// //       Polyline(
// //         polylineId: PolylineId('route2'),
// //         points: [currAdd, LatLng(24.9, 91.87)],
// //         color: Colors.purple,
// //         width: 4,
// //         startCap: Cap.roundCap,
// //         endCap: Cap.squareCap,
// //         jointType: JointType.round,
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       home: Scaffold(
// //         appBar: AppBar(title: Text("Flutter Google Map Demo")),
// //         body: GoogleMap(
// //           // Map starts here with camera at current location
// //           initialCameraPosition: CameraPosition(
// //             target: currAdd, // Center point of the map
// //             zoom: 13, // Zoom level: 2 (world), 20 (building)
// //             tilt: 30, // Camera tilt in degrees
// //             bearing: 90, // Rotation in degrees (0 = North)
// //           ),
// //
// //           // Called when the map is created
// //           onMapCreated: (controller) {
// //             mapController = controller;
// //             print("Map initialized");
// //           },
// //
// //           // Allows showing markers (locations)
// //           markers: _markers,
// //
// //           // Circles (area highlight)
// //           circles: _circles,
// //
// //           // Polylines (routes)
// //           polylines: _polylines,
// //
// //           // Polygons (shapes/areas)
// //           polygons: _polygons,
// //
// //           // Map controls and gestures
// //           compassEnabled: true, // Show compass
// //           zoomControlsEnabled: true, // Show +/- buttons
// //           mapToolbarEnabled: true, // Enables toolbar when marker is tapped
// //           myLocationEnabled: true, // Show current location dot
// //           myLocationButtonEnabled: true, // Show button to go to your location
// //           scrollGesturesEnabled: true, // Pan the map
// //           zoomGesturesEnabled: true, // Pinch or double-tap
// //           tiltGesturesEnabled: true, // Use two-finger tilt
// //           rotateGesturesEnabled: true, // Two-finger rotate
// //           indoorViewEnabled: true, // Enable indoor map (if supported)
// //           buildingsEnabled: true, // Show 3D buildings
// //           trafficEnabled: false, // Turn on if you want live traffic
// //           liteModeEnabled: true, // Useful for low-performance devices
// //
// //           // Map tap callback
// //           onTap: (LatLng tappedPoint) {
// //             print("Map tapped at: $tappedPoint");
// //           },
// //
// //           // Map long press callback
// //           onLongPress: (LatLng longPressedPoint) {
// //             print("Map long-pressed at: $longPressedPoint");
// //           },
// //
// //           // Map type: normal, hybrid, satellite, terrain
// //           mapType: MapType.hybrid,
// //         ),
// //       ),
// //     );
// //   }
// // }
