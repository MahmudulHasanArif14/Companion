import 'package:companion/Auth/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/geolocation.dart';
import 'package:geocoding/geocoding.dart';

class JourneyViewers extends StatefulWidget {
  Set<Marker> markers;
  Set<Polyline> polylines;
  JourneyViewers({super.key, required this.markers, required this.polylines});

  @override
  State<JourneyViewers> createState() => _JourneyViewersState();
}

class _JourneyViewersState extends State<JourneyViewers> {
  LatLng? fromLocation;
  LatLng? toLocation;
  LatLng? userLocation;
  late GoogleMapController mapController;


  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // Friends list and loading state
  List<Map<String, dynamic>> _friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    markers = widget.markers;
    polylines = widget.polylines;
    _getUserLocation();
    _fetchFriends();
  }

  // Get user current location and add avatar marker
  Future<void> _getUserLocation() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final profile = await supabase
          .from('profiles')
          .select('avatar_url, full_name')
          .eq('id', userId!)
          .maybeSingle();

      final avatarUrl = profile?['avatar_url'] ?? '';
      final name = profile?['full_name'] ?? 'User';
      final markerIcon = await LocationHelper().getMarkerFromUrl(avatarUrl);

      if (!mounted) return;
      final loc = await LocationHelper().determinePosition(context);
      if (loc != null) {
        setState(() {
          userLocation = LatLng(loc.latitude, loc.longitude);
          markers.add(Marker(
            markerId: const MarkerId('user_current'),
            position: userLocation!,
            infoWindow: InfoWindow(title: 'You are here $name'),
            icon: markerIcon,
          ));
        });
      }
    } catch (e) {
      debugPrint('Error getting user location: $e');
    }
  }




  // Fetch friends from Supabase
  Future<void> _fetchFriends() async {
    final currentUserId = OauthHelper.currentUser()!.id;
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('friends')
          .select(
          'id, user_id_1, user_id_2, can_share_location, profiles!friends_user_id_2_fkey(id, username, full_name, avatar_url)')
          .or('user_id_1.eq.$currentUserId,user_id_2.eq.$currentUserId');

      List<Map<String, dynamic>> friendsList = [];

      for (var row in response) {
        Map<String, dynamic> friendProfile;
        if (row['user_id_1'] == currentUserId) {
          friendProfile = row['profiles'];
        } else {
          final profileRes = await supabase
              .from('profiles')
              .select('id, username, full_name, avatar_url')
              .eq('id', row['user_id_1'])
              .single();
          friendProfile = profileRes;
        }

        friendsList.add({
          'id': row['id'],
          'user_id': friendProfile['id'],
          'username': friendProfile['username'],
          'full_name': friendProfile['full_name'],
          'avatar_url': friendProfile['avatar_url'],
          'can_share_location': row['can_share_location'],
        });
      }

      if (mounted) {
        setState(() {
          _friends = friendsList;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching friends: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }




  @override
  Widget build(BuildContext context) {


    // Dummy watchers list for demo
    final List<Map<String, dynamic>> watchers = [
      {
        'name': 'Alice',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'active': true,
      },
      {
        'name': 'Bob',
        'avatar': 'https://i.pravatar.cc/150?img=2',
        'active': false,
      },
      {
        'name': 'Charlie',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'active': true,
      },
    ];





    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: userLocation ?? const LatLng(23.8103, 90.4125),
              zoom: 14,
            ),
            onMapCreated: (controller) => mapController = controller,
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Currently Watching',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Image.asset('assets/images/eyes.png', height: 24),

                    ],
                  ),


                  // List of watchers
                  ...watchers.map((watcher) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(watcher['avatar']),
                      ),
                      title: Text(watcher['name']),
                      trailing: Icon(
                        Icons.circle,
                        color: watcher['active'] ? Colors.green : Colors.grey,
                        size: 12,
                      ),
                    );
                  }),


                  const SizedBox(height: 16),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
