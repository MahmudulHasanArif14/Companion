import 'package:companion/Services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Services/geolocation.dart';
import '../Services/get_Service_key.dart';
import 'companionsscreen.dart';

class Dashboard extends StatefulWidget {
  final User? user;
  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  GoogleMapController? mapController;
   LatLng _center =  LatLng(24.9, 22.3);
  String address = 'Fetching location...';
  double _mapHeightRatio = 0.7;
  bool _isLoading = true;
  Marker? _currentLocationMarker;
  final TextEditingController _searchController = TextEditingController();
  Position? currentCoordinates;
  Placemark? placeName;

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService().registerDeviceToken();

    });
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


  // Dummy dropdown values
  String selectedLocation = 'Kyouma';
  List<String> locations = ['Kyouma'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using Stack to overlay widgets on top of map
      body: Stack(
        children: [
          // Placeholder for Map (replace with GoogleMap or similar)
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


          // Top left settings icon with red notification dot
          Positioned(
            top: 40,
            left: 20,
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, size: 30, color: Colors.black87),
                  onPressed: () async {
                  //
                    print(await GetServiceKey().getServiceKey());



                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              ],
            ),
          ),

          // Top center dropdown (Kyouma)
          Positioned(
            top: 45,
            left: 70,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLocation,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: locations.map((loc) {
                    return DropdownMenuItem<String>(
                      value: loc,
                      child: Text(loc),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedLocation = val!;
                    });
                  },
                ),
              ),
            ),
          ),

          // Top right mail and chat icons
          Positioned(
            top: 40,
            right: 20,
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.mail_outline, size: 30, color: Colors.black87),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Purple alert banner below dropdown


          // Check-in and SOS buttons grouped near bottom right above bottom sheet
          Positioned(
            bottom: 270,
            right: 20,
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Check in'),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.sos_outlined, color: Colors.red),
                  label: const Text('SOS', style: TextStyle(color: Colors.red)),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Bottom draggable sheet - account setup & user info & options
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Account setup card
                    Card(
                      color: const Color(0xFF220046), // deep purple
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set up your account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '0/2 complete',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: 0.0,
                                color: Colors.yellow[600],
                                backgroundColor: Colors.white24,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Add a profile photo',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                                ),
                                Icon(Icons.close, color: Colors.white70),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // User info row
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[200],
                        child: const Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: const Text(
                        'Houoin',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Battery optimization on\nSince 4:19 pm',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.error_outline, color: Colors.red),
                    ),

                    const SizedBox(height: 20),

                    // Options list
                    ListTile(
                      leading: const Icon(Icons.people, color: Colors.deepPurple),
                      title: const Text('Companion Circle'),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>CompanionsScreen()));

                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.deepPurple),
                      title: const Text('Places'),
                      onTap: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.deepPurple.withOpacity(0.5),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

}

