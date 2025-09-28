import 'dart:async';
import 'dart:convert';
import 'package:companion/Auth/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/geolocation.dart';
import 'package:geocoding/geocoding.dart';
import 'journey_viewers.dart';

class AddJourney extends StatefulWidget {
  const AddJourney({super.key});

  @override
  State<AddJourney> createState() => _AddJourneyState();
}

class _AddJourneyState extends State<AddJourney> {

  LatLng? fromLocation;
  LatLng? toLocation;
  LatLng? userLocation;
  late GoogleMapController mapController;
  static final String googleApiKey =dotenv.env['GOOGLE_Api_Key']!;
  BitmapDescriptor? drivingIcon;
  BitmapDescriptor? walkingIcon;
  BitmapDescriptor? bicyclingIcon;
  BitmapDescriptor? transitIcon;
  BitmapDescriptor? destinationIcon;


  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  // markers for map
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  String travelMode = 'driving'; // default mode
  List<String> travelModes = ['driving', 'walking', 'bicycling', 'transit'];
  String routeInfo = '';

  List<Map<String, dynamic>> _friends = [];
  bool isLoading = true;
  Timer? _debounce;

  Future<void> loadEnv() async {
    await dotenv.load(fileName: ".env");
  }

  @override
  void initState() {
    super.initState();
    loadEnv();
    _getUserLocation();
    _fetchFriends();

  }

  @override
  void dispose() {
    _debounce?.cancel();
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }


  Future<void> _loadCustomIcons() async {
    drivingIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)), 'assets/car.png');

    walkingIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)), 'assets/walking.png');

    bicyclingIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)), 'assets/bike.png');

    transitIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)), 'assets/transit.png');

    destinationIcon = await BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen);

    setState(() {});
  }


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

  /// Google Directions API route fetching
  Future<Map<String, dynamic>?> getRoute(
      LatLng from, LatLng to, String mode) async {
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?"
            "origin=${from.latitude},${from.longitude}&"
            "destination=${to.latitude},${to.longitude}&"
            "mode=$mode&key=$googleApiKey");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        return data['routes'][0];
      }
    }
    return null;
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return polyline;
  }

  void _updateMarkersAndPolyline() async {
    markers.removeWhere((m) => m.markerId.value != 'user_current');

    if (fromLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: fromLocation!,
        infoWindow: const InfoWindow(title: 'Pickup Address'),
      ));
    }

    if (toLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: toLocation!,
        infoWindow: const InfoWindow(title: 'Destination Address'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    polylines.clear();
    routeInfo = '';

    if (fromLocation != null && toLocation != null) {
      final route = await getRoute(fromLocation!, toLocation!, travelMode);
      if (route != null) {
        final points = decodePolyline(route['overview_polyline']['points']);
        polylines.add(Polyline(
          polylineId: const PolylineId('journey_line'),
          points: points,
          color: Colors.blue,
          width: 5,
        ));

        final legs = route['legs'][0];
        final distance = legs['distance']['text'];
        final duration = legs['duration']['text'];
        routeInfo = "Distance: $distance, Duration: $duration";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No route available for selected travel mode"),
          ),
        );
      }

      // Update travel modes dynamically
      await _updateTravelModes();
    }

    setState(() {});
  }

  Future<void> _updateTravelModes() async {
    if (fromLocation == null || toLocation == null) return;

    List<String> modes = ['driving', 'walking', 'bicycling', 'transit'];
    List<String> availableModes = [];

    for (var mode in modes) {
      final route = await getRoute(fromLocation!, toLocation!, mode);
      if (route != null) availableModes.add(mode);
    }

    if (availableModes.isNotEmpty) {
      setState(() {
        travelModes = availableModes;
        if (!availableModes.contains(travelMode)) {
          travelMode = availableModes.first;
        }
      });
    }
  }

  Future<List<String>> fetchGooglePlaceSuggestions(String input) async {
    if (input.isEmpty) return [];
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey&types=geocode&language=en");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final predictions = data['predictions'] as List;
      return predictions.map((p) => p['description'] as String).toList();
    }
    return [];
  }

  Future<List<String>> _getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    // Cancel any previous debounce
    _debounce?.cancel();

    final completer = Completer<List<String>>();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final url = Uri.parse(
            "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey&types=geocode&language=en");
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final predictions = data['predictions'] as List;
          completer.complete(
              predictions.map((p) => p['description'] as String).toList());
        } else {
          completer.complete([]);
        }
      } catch (e) {
        completer.complete([]);
      }
    });

    return completer.future;
  }

  Future<void> _onFromSelected(String selectedPlace) async {
    try {
      List<Location> locations = await locationFromAddress(selectedPlace);
      if (locations.isNotEmpty) {
        fromLocation =
            LatLng(locations.first.latitude, locations.first.longitude);

        fromController.text = selectedPlace;
        _updateMarkersAndPolyline();
        mapController.animateCamera(
            CameraUpdate.newLatLngZoom(fromLocation!, 15));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _onToSelected(String selectedPlace) async {
    try {
      List<Location> locations = await locationFromAddress(selectedPlace);
      if (locations.isNotEmpty) {
        toLocation = LatLng(locations.first.latitude, locations.first.longitude);
        toController.text = selectedPlace;
        _updateMarkersAndPolyline();
        mapController.animateCamera(
            CameraUpdate.newLatLngZoom(toLocation!, 15));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _addressInputField({
    required TextEditingController controller,
    required String hint,
    required void Function(String) onSuggestionSelected,
    bool useCurrentLocation = false,
  }) {
    return TypeAheadField<String>(
      controller: controller,
      suggestionsCallback: _getPlaceSuggestions,
      itemBuilder: (context, suggestion) => ListTile(
        leading: const Icon(Icons.location_on),
        title: Text(suggestion),
      ),
      onSelected: onSuggestionSelected,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller, // Use the controller provided by TypeAheadField
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: useCurrentLocation
                ? IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () async {
                if (userLocation != null) {
                  List<Placemark> placemarks =
                  await placemarkFromCoordinates(
                      userLocation!.latitude, userLocation!.longitude);
                  if (placemarks.isNotEmpty) {
                    final place = placemarks.first;
                    controller.text = '${place.name}, ${place.locality}';
                    if (hint == 'From') {
                      fromLocation = userLocation;
                    } else {
                      toLocation = userLocation;
                    }
                    _updateMarkersAndPolyline();
                  }
                }
              },
            )
                : const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  Widget _travelModeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: travelModes.map((mode) {
          final isSelected = travelMode == mode;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(mode.toUpperCase()),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  travelMode = mode;
                  _updateMarkersAndPolyline();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _fetchFriends() async {
    final currentUserId = OauthHelper.currentUser()!.id;
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('friends').select('''
      id,
      user_id_1,
      user_id_2,
      can_share_location,
      profiles!friends_user_id_2_fkey(id, username, full_name, avatar_url)
    ''').or('user_id_1.eq.$currentUserId,user_id_2.eq.$currentUserId');

      List<Map<String, dynamic>> friendsList = response.map<Map<String, dynamic>>((row) {
        Map<String, dynamic> friendProfile;
        if (row['user_id_1'] == currentUserId) {
          friendProfile = row['profiles'];
        } else {
          friendProfile = {
            'id': row['user_id_1'],
            'username': row['profiles']?['username'] ?? '',
            'full_name': row['profiles']?['full_name'] ?? '',
            'avatar_url': row['profiles']?['avatar_url'] ?? ''
          };
        }

        return {
          'id': row['id'],
          'user_id': friendProfile['id'],
          'username': friendProfile['username'],
          'full_name': friendProfile['full_name'],
          'avatar_url': friendProfile['avatar_url'],
          'can_share_location': row['can_share_location'],
        };
      }).toList();

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

  void _shareWithCompanion() {
    final Map<int, bool> selectedCompanions = {};
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Companions to Share',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _friends.isEmpty
                    ? const Center(child: Text('No friends found'))
                    : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    final isSelected = selectedCompanions[index] ?? false;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend['avatar_url'] != null
                            ? NetworkImage(friend['avatar_url'])
                            : null,
                        child: friend['avatar_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        friend['full_name'] ??
                            friend['username'] ??
                            'Unknown',
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setStateModal(() {
                            selectedCompanions[index] = value ?? false;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share_location_rounded),
                label: const Text('Share Location'),
                onPressed: () {
                  final sharedWith = selectedCompanions.entries
                      .where((e) => e.value)
                      .map((e) =>
                  _friends[e.key]['full_name'] ??
                      _friends[e.key]['username'])
                      .toList();

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Journey shared with: ${sharedWith.join(', ')}'),
                    ),
                  );
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => JourneyViewers(
                              markers: markers, polylines: polylines)));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            initialChildSize: 0.45,
            minChildSize: 0.1,
            maxChildSize: 0.8,
            builder: (context, scrollController) => Container(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.02),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                  const Text(
                    'Select Address',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _addressInputField(
                    controller: fromController,
                    hint: 'From',
                    onSuggestionSelected: _onFromSelected,
                    useCurrentLocation: true,
                  ),
                  const SizedBox(height: 12),
                  _addressInputField(
                    controller: toController,
                    hint: 'To',
                    onSuggestionSelected: _onToSelected,
                  ),
                  const SizedBox(height: 16),
                  _travelModeSelector(),
                  const SizedBox(height: 12),
                  if (routeInfo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        routeInfo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share_location_rounded),
                    label: const Text('Share with Companion'),
                    onPressed: _shareWithCompanion,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
