
import 'package:companion/Auth/auth_helper.dart';
import 'package:companion/Providers/journey_provider.dart';
import 'package:companion/Screens/places_screen.dart';
import 'package:companion/Screens/settings.dart';
import 'package:companion/Services/notification_service.dart';
import 'package:companion/core/utils/constant.dart';
import 'package:companion/database/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Services/geolocation.dart';
import '../core/utils/maps_theme_manager.dart';
import '../models/location.dart';
import '../widgets/custom_progress_item.dart';
import '../widgets/custom_userInfo_tile.dart';
import 'add_journey.dart';
import 'companionsscreen.dart';
import 'journey_viewers.dart';

class Dashboard extends StatefulWidget {
  final User? user;
  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  GoogleMapController? _mapController;

  String _address = 'Fetching location...';
  bool _isLoading = true;
  Marker? _currentLocationMarker;
  Position? _currentCoordinates;
  Placemark? _placeName;

  final TextEditingController _searchController = TextEditingController();
  final Map<String, Marker> _markers = {};
  final Set<String> _allowedUserIds = {};
  bool _isDisposed = false;
  String lastName = "";

  bool isProfileComplete=false;


  final List<Locate> _locations = [
    Locate(
        locationName: "University",  lat: 24.86928,
      lng: 91.80473),
    Locate(locationName: "Home", lat: 24.9, lng: 91.8),
    Locate(locationName: "Work", lat: 24.76, lng: 92.8),



  ];

  late Locate _selectedLocation = _locations.first;



 LatLng _center=LatLng(24.86928, 91.80473);

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      NotificationService().registerDeviceToken();
      Provider.of<DatabaseHelperProvider>(context,listen: false).fetchUserInfo();

      _selectedLocation = _locations.first;

      NotificationService().registerDeviceToken();













      final nameFromMeta = widget.user?.userMetadata?['name'];
      final Map<String, dynamic>? profile = await _getUserProfile(widget.user!.id);

      if (nameFromMeta != null &&
          nameFromMeta is String &&
          nameFromMeta.trim().isNotEmpty) {
       final splitName = nameFromMeta.trim().split(' ').last;
       lastName = capitalize(splitName);
      }else{
       final String fullName= profile?['full_name'];
       final splitName=fullName.trim().split(' ').last;
       lastName=capitalize(splitName);
      }

      if (profile != null) {

      }

    });
    _getCurrentAddressName();
    _loadFriendsAndListen();
  }


  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentAddressName() async {
    try {
      _currentCoordinates = await LocationHelper().determinePosition(context);
      final String? userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null || !mounted) {
        _handleLocationError('User not authenticated');
        return;
      }

      if (_currentCoordinates != null) {
        await _updateLocation(
          LatLng(_currentCoordinates!.latitude, _currentCoordinates!.longitude),
          updateCamera: true,
        );

        await _updateUserLocationInDatabase(userId);

        if (kDebugMode) {
          print('Current coordinate: $_currentCoordinates');
        }
      } else {
        _handleLocationError('Could not get current coordinates');
      }
    } catch (e) {
      _handleLocationError('Error getting location: $e');
    }
  }

  void _handleLocationError(String error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _address = error;
    });
  }

  Future<void> _updateUserLocationInDatabase(String userId) async {
    try {
      await Supabase.instance.client
          .from('user_locations')
          .upsert({
        'user_id': userId,
        'latitude': _currentCoordinates!.latitude,
        'longitude': _currentCoordinates!.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      },onConflict: ("user_id"));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user location in database: $e');
      }
    }
  }

  Future<void> _updateLocation(
      LatLng newLocation, {
        bool updateCamera = false,
      }) async {
    try {
      _placeName = await LocationHelper().reverseGeocode(newLocation);
      final String? userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null || !mounted) return;

      final Map<String, dynamic>? profile = await _getUserProfile(userId);
      final BitmapDescriptor markerIcon = await _getUserMarkerIcon(profile?['avatar_url']);

      _updateCurrentUserMarker(userId, newLocation, markerIcon, profile?['full_name']);

      if (updateCamera && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 14),
        );
      }
    } catch (e) {
      _handleUpdateLocationError('Error updating location: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      return await Supabase.instance.client
          .from('profiles')
          .select('avatar_url, full_name')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  Future<BitmapDescriptor> _getUserMarkerIcon(String? avatarUrl) async {
    try {
      return await LocationHelper().getMarkerFromUrl(avatarUrl ?? '');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting marker icon: $e');
      }
      return BitmapDescriptor.defaultMarker;
    }
  }

  void _updateCurrentUserMarker(
      String userId,
      LatLng position,
      BitmapDescriptor icon,
      String? userName,
      ) {
    final Marker currentMarker = Marker(
      markerId: MarkerId(userId),
      position: position,
      infoWindow: InfoWindow(title: userName ?? 'You'),
      icon: icon,
    );

    _markers[userId] = currentMarker;

    if (!mounted) return;
    setState(() {
      _center = position;
      _address = _formatAddress(_placeName);
      _searchController.text = _address;
      _currentLocationMarker = currentMarker;
      _isLoading = false;
    });
  }

  String _formatAddress(Placemark? placemark) {
    if (placemark == null) return 'Could not fetch address';

    final List<String> addressParts = [
      placemark.name,
      placemark.street,
      placemark.thoroughfare,
      placemark.subThoroughfare,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country,
    ].where((part) => part != null && part.isNotEmpty).cast<String>().toList();

    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Address not available';
  }

  void _handleUpdateLocationError(String error) {
    if (!mounted) return;
    setState(() => _address = error);
  }

  Future<void> _loadFriendsAndListen() async {
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !mounted) return;

    try {
      final List<dynamic> friendsData = await _fetchFriendsData(userId);
      final Set<String> allowedFriends = _processFriendsData(friendsData, userId);

      if (!mounted) return;
      setState(() {
        _allowedUserIds.addAll({userId, ...allowedFriends});
      });

      _listenToFriendLocations();
      _startLocationUpdates();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading friends: $e');
      }
    }
  }

  Future<List<dynamic>> _fetchFriendsData(String userId) async {
    return await Supabase.instance.client
        .from('friends')
        .select('user_id_1, user_id_2, can_share_location')
        .or('user_id_1.eq.$userId,user_id_2.eq.$userId')
        .eq('can_share_location', true);
  }

  Set<String> _processFriendsData(List<dynamic> friendsData, String userId) {
    final Set<String> friends = <String>{};

    for (final dynamic row in friendsData) {
      final String id1 = row['user_id_1'] as String;
      final String id2 = row['user_id_2'] as String;

      if (id1 == userId) {
        friends.add(id2);
      } else {
        friends.add(id1);
      }
    }

    return friends;
  }

  void _listenToFriendLocations() {
    final SupabaseClient supabase = Supabase.instance.client;

    supabase
        .from('user_locations')
        .stream(primaryKey: ['user_id'])
        .order('updated_at')
        .listen(_handleFriendLocationUpdate);
  }

  void _handleFriendLocationUpdate(List<Map<String, dynamic>> dataList) async {
    for (final Map<String, dynamic> data in dataList) {
      if (_isDisposed) return;

      final String userId = data['user_id'] as String;
      if (!_allowedUserIds.contains(userId)) continue;

      try {
        await _processFriendLocation(userId, data);
      } catch (e) {
        if (kDebugMode) {
          print('Error processing friend location for user $userId: $e');
        }
      }
    }
  }

  Future<void> _processFriendLocation(String userId, Map<String, dynamic> data) async {
    final double lat = (data['latitude'] as num).toDouble();
    final double lng = (data['longitude'] as num).toDouble();

    final Map<String, dynamic>? profile = await _getUserProfile(userId);
    final String name = profile?['full_name'] ?? 'User';
    final BitmapDescriptor markerIcon = await _getUserMarkerIcon(profile?['avatar_url']);

    _animateMarker(userId, LatLng(lat, lng), markerIcon, name);
  }

  Future<void> _animateMarker(
      String userId,
      LatLng newPosition,
      BitmapDescriptor icon,
      String title,
      ) async {
    if (_isDisposed) return;

    final Marker? oldMarker = _markers[userId];
    if (oldMarker == null) {
      _addNewMarker(userId, newPosition, icon, title);
      return;
    }

    await _animateMarkerMovement(userId, oldMarker.position, newPosition, icon, title);
  }

  void _addNewMarker(
      String userId,
      LatLng position,
      BitmapDescriptor icon,
      String title,
      ) {
    if (!mounted) return;

    setState(() {
      _markers[userId] = Marker(
        markerId: MarkerId(userId),
        position: position,
        icon: icon,
        infoWindow: InfoWindow(title: title),
      );
    });
    _fitBounds();
  }

  Future<void> _animateMarkerMovement(
      String userId,
      LatLng oldPosition,
      LatLng newPosition,
      BitmapDescriptor icon,
      String title,
      ) async {
    const int steps = 20;
    const Duration totalDuration = Duration(milliseconds: 300);
    final Duration stepDuration = totalDuration ~/ steps;

    for (int i = 1; i <= steps; i++) {
      if (_isDisposed) return;

      final double lat = oldPosition.latitude +
          (newPosition.latitude - oldPosition.latitude) * i / steps;
      final double lng = oldPosition.longitude +
          (newPosition.longitude - oldPosition.longitude) * i / steps;

      _updateMarkerPosition(userId, LatLng(lat, lng), icon, title);
      await Future.delayed(stepDuration);
    }
    _fitBounds();
  }

  void _updateMarkerPosition(
      String userId,
      LatLng position,
      BitmapDescriptor icon,
      String title,
      ) {
    if (!mounted) return;

    setState(() {
      _markers[userId] = Marker(
        markerId: MarkerId(userId),
        position: position,
        icon: icon,
        infoWindow: InfoWindow(title: title),
      );
    });
  }

  Future<void> _startLocationUpdates() async {
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _isDisposed) return;

    try {
      await _updateInitialLocation(userId);
      _startLocationStream(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location updates: $e');
      }
    }
  }

  Future<void> _updateInitialLocation(String userId) async {
    final Position position = await Geolocator.getCurrentPosition();
    final LatLng latLng = LatLng(position.latitude, position.longitude);

    await Supabase.instance.client.from('user_locations').upsert({
      'user_id': userId,
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    },onConflict: ("user_id"));
  }

  void _startLocationStream(String userId) {
    Geolocator.getPositionStream().listen((Position position) async {
      if (_isDisposed) return;

      final LatLng newLatLng = LatLng(position.latitude, position.longitude);
      try {
        await Supabase.instance.client.from('user_locations').upsert({
          'user_id': userId,
          'latitude': newLatLng.latitude,
          'longitude': newLatLng.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        },onConflict: ("user_id"));
      } catch (e) {
        if (kDebugMode) {
          print('Error updating location stream: $e');
        }
      }
    });
  }

  void _fitBounds() {
    if (_markers.isEmpty || _mapController == null || _isDisposed) return;

    final List<LatLng> positions = _markers.values.map((Marker m) => m.position).toList();
    final LatLngBounds bounds = _calculateBounds(positions);

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final LatLng pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _onBeginJourneyPressed() {
    final JourneyProvider provider = Provider.of<JourneyProvider>(context, listen: false);
    final bool hasActiveJourney = provider.isTracking;

    debugPrint("A journey Already Running: $hasActiveJourney");

    if (hasActiveJourney) {
      _navigateToActiveJourney(provider);
    } else {
      _navigateToAddJourney();
    }
  }

  void _navigateToActiveJourney(JourneyProvider provider) {
    provider.loadActiveJourney();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyViewers(
          markers: provider.markers,
          polylines: provider.polylines,
          journeyId: provider.currentJourneyId,
          travelMode: provider.travelMode,
          fromLocation: provider.fromLocation!,
          toLocation: provider.toLocation!,
          userLocation: provider.userLocation!,
          instructions: provider.instructions,
        ),
      ),
    );
  }

  void _navigateToAddJourney() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddJourney()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildGoogleMap(),
          _buildTopLeftSettingsButton(),
          _buildTopCenterDropdown(),
          _buildTopRightMailButton(),
          _buildBottomRightActionButtons(),
          _buildDraggableBottomSheet(lastName),
        ],
      ),
    );
  }



  Widget _buildGoogleMap() {

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center, zoom: 14),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      style: MapsThemeManager.getMapStyle(context),
      markers: _currentLocationMarker != null
          ? {..._markers.values, _currentLocationMarker!}
          : _markers.values.toSet(),
      zoomControlsEnabled: false,
      myLocationEnabled: true,
    );
  }

  Widget _buildTopLeftSettingsButton() {
    return Positioned(
      top: 40,
      left: 20,
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.settings, size: 30, color: Colors.black87),
            onPressed: _onSettingsPressed,
          ),
          _buildNotificationDot(),
        ],
      ),
    );
  }

  Widget _buildNotificationDot() {
    return const Positioned(
      top: 8,
      right: 8,
      child: CircleAvatar(
        radius: 5,
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _onSettingsPressed() async {
    // final String serviceKey = await GetServiceKey().getServiceKey();
    // if (kDebugMode) {
    //   print('Service Key: $serviceKey');
    // }



      Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingPage(user: widget.user!)));


    //await NotificationService().sendPushNotification(OauthHelper.currentUser()!.id, title: "Notification Send Success", body: "Hey there! This is a test notification.");


  }

  Widget _buildTopCenterDropdown() {
    return Positioned(
      top: 45,
      left: 70,
      right: 70,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow:  [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Locate>(
            dropdownColor: AppColors.getCardColor(context),
            value: _selectedLocation,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: _locations.map((loc) {
              return DropdownMenuItem<Locate>(
                value: loc,
                child: Text(loc.locationName,style: TextStyle(
                  color: AppColors.textPrimaryColor(context),
                ),),
              );
            }).toList(),
            onChanged: (Locate? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLocation = newValue;
                  _center = LatLng(_selectedLocation.lat, _selectedLocation.lng);


                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopRightMailButton() {
    return Positioned(
      top: 40,
      right: 20,
      child: IconButton(
        icon: const Icon(Icons.mail_outline, size: 30, color: Colors.black87),
        onPressed: () {

        },
      ),
    );
  }

  Widget _buildBottomRightActionButtons() {
    return Positioned(
      bottom: 270,
      right: 20,
      child: Column(
        children: [
          _buildCheckInButton(),
          const SizedBox(height: 12),
          _buildSOSButton(),
        ],
      ),
    );
  }

  Widget _buildCheckInButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        elevation: 3,
      ),
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('Check in'),
      onPressed: () {
        // TODO: Implement check-in functionality
      },
    );
  }

  Widget _buildSOSButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        elevation: 3,
      ),
      icon: const Icon(Icons.sos_outlined, color: Colors.red),
      label: const Text('SOS', style: TextStyle(color: Colors.red)),
      onPressed: () {
        // TODO: Implement SOS functionality
      },
    );
  }

  Widget _buildDraggableBottomSheet(String lastName) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.5,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration:  BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              if(!isProfileComplete)
              _buildAccountSetupCard()??const SizedBox(),
              const SizedBox(height: 20),
              buildUserInfoTile(lastName,context),
              const SizedBox(height: 20),
              _buildMenuOptions(),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildAccountSetupCard() {
    final provider=Provider.of<DatabaseHelperProvider>(context);
    final profileData=provider.userInfo;
    final avatarLink=profileData?["avatar_url"];
    final phoneNo=profileData?["phone"];
    final isAvatarPresent=(avatarLink!=null && avatarLink.toString().isNotEmpty) ? true:false;
    final isPhonePresent=(phoneNo!=null && phoneNo.toString().isNotEmpty) ? true:false;


    if(!isAvatarPresent && !isPhonePresent) {
      isProfileComplete=true;
      return null;
    }



    return Card(
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
           if(!isAvatarPresent && !isPhonePresent)
            Text(
              '0/2 complete',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            if(isAvatarPresent && !isPhonePresent || !isAvatarPresent && isPhonePresent)
              Text(
                '1/2 complete',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            if(isAvatarPresent && isPhonePresent)
              Text(
                '2/2 complete',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            const SizedBox(height: 12),
            // Progress Bar
            buildProgressIndicator(context),
            const SizedBox(height: 8),
            buildProgressItem(context,() async {


              //Update
              setState(() {


                  isProfileComplete=true;

                });


            }),
          ],
        ),
      ),
    );
  }







  Widget _buildMenuOptions() {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.people,
          title: 'Companion Circle',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CompanionsScreen()),
            );
          },
        ),
        _buildMenuTile(
          icon: Icons.location_on,
          title: 'Places',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlacesScreen()),
            );
          },
        ),
        _buildMenuTile(
          icon: Icons.assistant_navigation,
          title: 'Begin Journey',
          iconSize: 30,
          onTap: _onBeginJourneyPressed,
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    double iconSize = 24,
  }) {
    return ListTile(
      leading: Icon(icon, color:AppColors.getIconColor(context), size: iconSize),
      title: Text(title),
      onTap: onTap,
    );
  }
}