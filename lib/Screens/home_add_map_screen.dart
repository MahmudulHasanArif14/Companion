import 'package:companion/Screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/geolocation.dart';

class HomeAddMapScreen extends StatefulWidget {
  final User user;
  const HomeAddMapScreen({super.key, required this.user});

  @override
  State<HomeAddMapScreen> createState() => _HomeAddMapScreenState();
}

class _HomeAddMapScreenState extends State<HomeAddMapScreen> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(0, 0);
  String address = 'Fetching location...';
  double _mapHeightRatio = 0.7;
  bool _isLoading = true;
  Marker? _currentLocationMarker;
  final TextEditingController _searchController = TextEditingController();
  Position? currentCoordinates;
  Placemark? placeName;

  @override
  void initState() {
    super.initState();
    getCurrentAddressName();
  }

  Future<void> getCurrentAddressName() async {
    try {
      currentCoordinates = await LocationHelper().determinePosition(context);
      if (currentCoordinates != null) {
        await updateLocation(
          LatLng(currentCoordinates!.latitude, currentCoordinates!.longitude),
          updateCamera: true,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        address = 'Error getting location';
      });
    }
  }

  Future<void> updateLocation(LatLng newLocation, {bool updateCamera = false}) async {
    try {
      placeName = await LocationHelper().reverseGeocode(newLocation);


      setState(() {
        _center = newLocation;
        address = placeName != null
            ? '${placeName!.name ?? ''},${placeName!.street ?? ''},${placeName!.thoroughfare ?? ''}, ${placeName!.subThoroughfare ?? ''},${placeName!.locality ?? ''}, ${placeName!.administrativeArea ?? ''}, ${placeName!.country ?? ''}'
            : 'Could not fetch address';

        _searchController.text = address;
        _currentLocationMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position: _center,
          infoWindow: InfoWindow(title: 'Home Address', snippet: address),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        );
        _isLoading = false;
      });

      if (updateCamera && mapController != null) {
        await mapController!.animateCamera(CameraUpdate.newLatLngZoom(_center, 14));
      }
    } catch (e) {
      setState(() => address = 'Error updating location');
    }
  }

  Future<List<Placemark>> _getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isEmpty) return [];

      List<Placemark> allPlacemarks = [];

      for (var loc in locations) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );
        allPlacemarks.addAll(placemarks);
      }

      return allPlacemarks;
    } catch (e) {
      return [];
    }
  }


  void _updateMapHeight(double newHeightRatio) {
    setState(() => _mapHeightRatio = newHeightRatio.clamp(0.3, 0.9));
  }

  @override
  void dispose() {
    _searchController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topSectionHeight = screenSize.height * (1 - _mapHeightRatio);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Top container with search
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            height: topSectionHeight,
            width: screenSize.width,
            decoration: const BoxDecoration(color: Color(0xFF3267E3)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Add your home",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TypeAheadField<Placemark>(
                    controller: _searchController,
                    //suggestion will fetch after this time
                    debounceDuration: const Duration(milliseconds: 100),
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search for address...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      );
                    },
                    suggestionsCallback: _getPlaceSuggestions,
                    itemBuilder: (context, Placemark suggestion) {
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(
                          suggestion.street?.isNotEmpty == true && suggestion.thoroughfare!.isNotEmpty==true
                              ? '${suggestion.street!},${suggestion.thoroughfare!},${suggestion.locality!}'
                              : suggestion.name?.isNotEmpty == true
                              ? suggestion.name!
                              : 'Unknown location',
                          style: const TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          '${suggestion.locality}, ${suggestion.administrativeArea}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      );
                    },
                    onSelected: (Placemark selected) async {
                      try {
                        List<Location> locations = await locationFromAddress(
                            '${selected.street}, ${selected.locality}, ${selected.administrativeArea}, ${selected.country}'
                        );
                        if (locations.isNotEmpty) {
                          await updateLocation(
                            LatLng(locations.first.latitude, locations.first.longitude),
                            updateCamera: true,
                          );
                        }
                      } catch (e) {
                        setState(() => address = 'Error finding location');
                      }
                    },
                    emptyBuilder: (context) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No locations found',
                          style: TextStyle(color: Colors.black)),
                    ),
                    loadingBuilder: (context) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(),
                    ),
                    hideOnEmpty: true,
                    hideOnLoading: true,
                    hideOnError: true,
                    hideOnSelect: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    address,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Drag handle
          GestureDetector(
            onVerticalDragUpdate: (details) {
              _updateMapHeight(1 - (details.globalPosition.dy / screenSize.height));
            },
            child: AnimatedContainer(
              width: screenSize.width,
              color: const Color(0xFF2E004C),
              padding: const EdgeInsets.all(10),
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Drag up/down to resize map',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Map section
          Expanded(
            child: GoogleMap(

              initialCameraPosition: CameraPosition(target: _center, zoom: 14),
              circles: {
                Circle(
                  circleId: const CircleId("Current Location"),
                  center: _center,
                  radius: 300,
                  fillColor: Colors.blue.withOpacity(0.3),
                  strokeColor: Colors.blue,
                  strokeWidth: 2,
                ),
              },
              onMapCreated: (controller) => mapController = controller,
              markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
              zoomControlsEnabled: false,
              myLocationEnabled: true,
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: screenSize.width,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB93A),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  debugPrint("Saved location at $_center\nAddress: $address");
                  // Add your save logic here
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Dashboard(user: widget.user)),
                        (Route<dynamic> route) => false,
                  );

                  },
                child: const Text("Save Location"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}