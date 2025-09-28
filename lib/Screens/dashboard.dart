import 'package:companion/Screens/places_screen.dart';
import 'package:companion/Services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Services/geolocation.dart';
import '../Services/get_Service_key.dart';
import 'add_journey.dart';
import 'companionsscreen.dart';

class Dashboard extends StatefulWidget {
  final User? user;
  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}



class _DashboardState extends State<Dashboard> {





  GoogleMapController? mapController;
  LatLng _center = LatLng(24.9, 22.3);
  String address = 'Fetching location...';
  bool _isLoading = true;
  Marker? _currentLocationMarker;
  Position? currentCoordinates;
  Placemark? placeName;


  final TextEditingController _searchController = TextEditingController();

  // will store all user markers
  final Map<String, Marker> _markers = {};
  Set<String> _allowedUserIds = {};





  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // storing user device fcm token to send notifications
      NotificationService().registerDeviceToken();
    });

    getCurrentAddressName();
    _loadFriendsAndListen();
  }








  // getting the current address coordinates and updating the map
  Future<void> getCurrentAddressName() async {
    try {
      currentCoordinates = await LocationHelper().determinePosition(context);
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final supabase = Supabase.instance.client;
      if (currentCoordinates != null) {
        await updateLocation(
          LatLng(currentCoordinates!.latitude, currentCoordinates!.longitude),
          updateCamera: true,
        );
        await supabase
            .from('user_locations')
            .update({'latitude': currentCoordinates!.latitude, 'longitude': currentCoordinates!.longitude})
            .eq('user_id', userId);

        if (kDebugMode) {
          print('current coordinate is : $currentCoordinates');
        }


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
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Get current user's avatar URL from profiles table
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url, full_name')
          .eq('id', userId)
          .maybeSingle();

      final avatarUrl = profile?['avatar_url'] ?? '';
      final markerIcon = await LocationHelper().getMarkerFromUrl(avatarUrl);
      // Create or update current user marker with avatar
      final currentMarker = Marker(
        markerId: MarkerId(userId),
        position: newLocation,
        infoWindow: InfoWindow(title: profile?['full_name'] ?? 'You'),
        icon: markerIcon,
      );

      _markers[userId] = currentMarker;
      setState(() {
        _center = newLocation;
        address = placeName != null
            ? '${placeName!.name ?? ''},${placeName!.street ?? ''},${placeName!.thoroughfare ?? ''},${placeName!.subThoroughfare ?? ''},${placeName!.locality ?? ''},${placeName!.administrativeArea ?? ''},${placeName!.country ?? ''}'
            : 'Could not fetch address';
        _searchController.text = address;
        _currentLocationMarker = currentMarker;
        _isLoading = false;
      });

      if (updateCamera && mapController != null) {
        await mapController!.animateCamera(CameraUpdate.newLatLngZoom(_center, 14));
      }
    } catch (e) {
      setState(() => address = 'Error updating location');
    }
  }

  // --- Load friends who allow location sharing ---
  Future<void> _loadFriendsAndListen() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final supabase = Supabase.instance.client;

    final result = await supabase
        .from('friends')
        .select('user_id_1, user_id_2, can_share_location')
        .or('user_id_1.eq.$userId,user_id_2.eq.$userId')
        .eq('can_share_location', true);

    final friends = <String>{};
    for (final row in result) {
      final id1 = row['user_id_1'] as String;
      final id2 = row['user_id_2'] as String;
      if (id1 == userId) {
        friends.add(id2);
      } else {
        friends.add(id1);
      }
    }

    _allowedUserIds = {userId, ...friends};

    _listenToFriendLocations();
    _updateMyLocation();
  }




  // --- Listen to friends locations ---
  void _listenToFriendLocations() {
    final supabase = Supabase.instance.client;

    supabase.from('user_locations')
        .stream(primaryKey: ['user_id'])
        .order('updated_at')
        .listen((List<Map<String, dynamic>> dataList) async {
      for (var data in dataList) {
        final userId = data['user_id'] as String;
        if (!_allowedUserIds.contains(userId)) continue;

        final lat = (data['latitude'] as num).toDouble();
        final lng = (data['longitude'] as num).toDouble();

        final profile = await supabase
            .from('profiles')
            .select('avatar_url, full_name')
            .eq('id', userId)
            .maybeSingle();

        final avatarUrl = profile?['avatar_url'] ?? '';
        final name = profile?['full_name'] ?? 'User';
        final markerIcon =  await LocationHelper().getMarkerFromUrl(avatarUrl);

        _animateMarker(userId, LatLng(lat, lng), markerIcon, name);
      }
    });
  }

  // --- Animate marker smoothly ---
  Future<void> _animateMarker(String userId, LatLng newPosition, BitmapDescriptor icon, String title) async {
    //markesr<String,marker>
    final oldMarker = _markers[userId];
    if (oldMarker == null) {
      setState(() {
        _markers[userId] = Marker(
          markerId: MarkerId(userId),
          position: newPosition,
          icon: icon,
          infoWindow: InfoWindow(title: title),
        );
      });
      _fitBounds();
      return;
    }

    final oldPosition = oldMarker.position;
    const steps = 20;
    const duration = Duration(milliseconds: 300);

    for (int i = 1; i <= steps; i++) {
      final lat = oldPosition.latitude + (newPosition.latitude - oldPosition.latitude) * i / steps;
      final lng = oldPosition.longitude + (newPosition.longitude - oldPosition.longitude) * i / steps;

      setState(() {
        _markers[userId] = Marker(
          markerId: MarkerId(userId),
          position: LatLng(lat, lng),
          icon: icon,
          infoWindow: InfoWindow(title: title),
        );
      });

      await Future.delayed(duration ~/ steps);
    }
    _fitBounds();
  }

  // --- Update current user location ---
  Future<void> _updateMyLocation() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final supabase = Supabase.instance.client;

    Position pos = await Geolocator.getCurrentPosition();
    final latLng = LatLng(pos.latitude, pos.longitude);

    await supabase.from('user_locations').upsert({
      'user_id': userId,
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    });

    Geolocator.getPositionStream().listen((pos) async {
      final newLatLng = LatLng(pos.latitude, pos.longitude);
      await supabase.from('user_locations').upsert({
        'user_id': userId,
        'latitude': newLatLng.latitude,
        'longitude': newLatLng.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // --- Auto-zoom map to fit markers ---
  void _fitBounds() {
    if (_markers.isEmpty || mapController == null) return;

    final positions = _markers.values.map((m) => m.position).toList();
    double x0 = positions.first.latitude, x1 = positions.first.latitude;
    double y0 = positions.first.longitude, y1 = positions.first.longitude;

    for (LatLng pos in positions) {
      if (pos.latitude > x1) x1 = pos.latitude;
      if (pos.latitude < x0) x0 = pos.latitude;
      if (pos.longitude > y1) y1 = pos.longitude;
      if (pos.longitude < y0) y0 = pos.longitude;
    }

    final bounds = LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  // --- Dummy dropdown values ---
  String selectedLocation = 'Kyouma';
  List<String> locations = ['Kyouma'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            onMapCreated: (controller) => mapController = controller,
            markers: _currentLocationMarker != null
                ? {..._markers.values, _currentLocationMarker!}
                : _markers.values.toSet(),
            zoomControlsEnabled: false,
            myLocationEnabled: true,
          ),

          // --- Top-left settings icon with red notification dot ---
          Positioned(
            top: 40,
            left: 20,
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, size: 30, color: Colors.black87),
                  onPressed: () async {
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
                ),
              ],
            ),
          ),

          // --- Top-center dropdown ---
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

          // --- Top-right mail icon ---
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.mail_outline, size: 30, color: Colors.black87),
              onPressed: () {},
            ),
          ),

          // --- Bottom-right Check-in and SOS buttons ---
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

          // --- Draggable bottom sheet ---
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
                      color: const Color(0xFF220046),
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
                                const Icon(Icons.close, color: Colors.white70),
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
                      onTap: () {

                        Navigator.push(context, MaterialPageRoute(builder: (context) =>  PlacesScreen()));

                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.assistant_navigation, color: Colors.deepPurple,size: 30,),
                      title: const Text('Begin Journey'),
                      onTap: () {

                        Navigator.push(context, MaterialPageRoute(builder: (context) =>  AddJourney()));

                      },
                    ),

                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
