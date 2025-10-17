import 'dart:async';

import 'package:companion/Auth/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Services/geolocation.dart';
import '../Services/notification_service.dart';
import '../core/utils/constant.dart';
import '../widgets/custom_snackbar.dart';
import 'journey_viewers.dart';

class JourneyViewersListScreen extends StatefulWidget {
  const JourneyViewersListScreen({super.key});

  @override
  State<JourneyViewersListScreen> createState() => _JourneyViewersListScreenState();
}

class _JourneyViewersListScreenState extends State<JourneyViewersListScreen> {
  final supabase = Supabase.instance.client;

  // State variables
  List<Map<String, dynamic>> _ongoingJourneys = [];
  List<Map<String, dynamic>> _filteredJourneys = [];
  bool isLoading = true;
  String _searchQuery = '';
  bool _isMounted = false;
  String? _updatingViewerId;


  // Stream subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _rideViewerStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _journeyStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _profilesStreamSubscription;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeStreams();
    _fetchOngoingJourneys();
  }

  @override
  void dispose() {
    _isMounted = false;
    _rideViewerStreamSubscription?.cancel();
    _journeyStreamSubscription?.cancel();
    _profilesStreamSubscription?.cancel();
    super.dispose();
  }

  // ============================
  // STREAM MANAGEMENT
  // ============================

  /// Initialize all real-time streams for live updates
  void _initializeStreams() {
    final currentUserId = OauthHelper.currentUser()!.id;

    //  Watch for changes in ride_viewer table
    _rideViewerStreamSubscription = supabase.from('ride_viewer').stream(primaryKey: ['id'])
        .eq('viewer_id', currentUserId)
        .order('created_at', ascending: true)
        .listen((List<Map<String, dynamic>> viewerUpdates){
         //  Return the Whole Table on listen

         debugPrint('Ride viewer stream update: ${viewerUpdates.length} records');
        _handleRideViewerUpdates(viewerUpdates);
      },
      onError: (error) {
        debugPrint('Ride viewer stream error: $error');
      },
    );

    //  Watch for journey from User_journey Table updates (currloc, status changes)
    _journeyStreamSubscription = supabase.from('user_journey').stream(primaryKey: ['id']).eq('status', 'ongoing')
        .order('updated_at', ascending: true)
        .listen((List<Map<String, dynamic>> journeyUpdates) {
        debugPrint('Journey stream update: ${journeyUpdates.length} records');
        _handleJourneyUpdates(journeyUpdates);
      },
      onError: (error) {
        debugPrint('Journey stream error: $error');
      },
    );

    //  Watch for profile updates (name, avatar changes)
    _profilesStreamSubscription = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> profileUpdates) {
        debugPrint('Profile stream update: ${profileUpdates.length} records');
        _handleProfileUpdates(profileUpdates);
      },
      onError: (error) {
        debugPrint('Profile stream error: $error');
      },
    );
  }






  /// Handle ride_viewer table updates (permission changes, new shares, removals)
  /// Here ViewerUpdates Contain whole Ride_viewer Table Data
  void _handleRideViewerUpdates(List<Map<String, dynamic>> viewerUpdates) async {
    //Removing Duplicate Journeys and adding old journeys to Ongoing Journey
    final currentJourneyIds = _ongoingJourneys.map((j) => j['journey_id'].toString()).toSet();



    for (final viewerRow in viewerUpdates) {

      final journeyId = viewerRow['journey_id'].toString(); //Ride_viewer Table JourneyID
      final viewerId = viewerRow['id'].toString(); // Ride_viewer Table ViewerID
      final disallowed = viewerRow['disallowed'] == true; // Ride_viewer Table allow status


      // Check if new journey id  is a new journey
      if (!currentJourneyIds.contains(journeyId)) {
        if (!disallowed) {
          debugPrint('New journey shared: $journeyId');
          await _addJourneyToViewerList(viewerRow);

        }
      }


      // Update existing journey permissions
      else {
        // find the index of the existing journey
        final existingIndex = _ongoingJourneys.indexWhere((j) => j['journey_id'].toString() == journeyId,);

        if (existingIndex != -1) {
          if (disallowed) {
            // Remove from list if disallowed
            _safeSetState(() {
               _ongoingJourneys.removeAt(existingIndex);
              _applySearchFilter(_searchQuery);
            });
            debugPrint('Journey removed due to disallowed: $journeyId');
          } else {
            // Update existing record
            _safeSetState(() {
              _ongoingJourneys[existingIndex]['disallowed'] = false;
              _ongoingJourneys[existingIndex]['viewer_id'] = viewerId;
              _applySearchFilter(_searchQuery);
            });
            debugPrint('Journey permissions updated: $journeyId');
          }
        }
      }
    }

    // Clean up any journeys that are no longer in viewer list
    _cleanupRemovedJourneys(viewerUpdates);
  }

  /// Handle journey location and status updates
  /// Here journeyUpdates user_journey table data
  void _handleJourneyUpdates(List<Map<String, dynamic>> journeyUpdates) {

    for (final journeyUpdate in journeyUpdates) {
      final journeyId = journeyUpdate['id'].toString();
      final existingIndex = _ongoingJourneys.indexWhere((j) => j['journey_id'].toString() == journeyId,);

      if (existingIndex != -1) {
        _safeSetState(() {
          // Update journey data with new information
          _ongoingJourneys[existingIndex] = {
            ..._ongoingJourneys[existingIndex],
            'current_lat': journeyUpdate['current_lat'],
            'current_lng': journeyUpdate['current_lng'],
            'status': journeyUpdate['status'],
            'reached_dest': journeyUpdate['reached_dest'],
            'updated_at': journeyUpdate['updated_at']?.toString() ?? '',
          };
          _applySearchFilter(_searchQuery);
        });
        debugPrint('Journey location updated: $journeyId');
      }
    }
  }

  /// Handle profile updates (name, avatar changes)
  void _handleProfileUpdates(List<Map<String, dynamic>> profileUpdates) {
    for (final profileUpdate in profileUpdates) {
      final userId = profileUpdate['id'].toString();

      // Update all journeys for this user
      for (int i = 0; i < _ongoingJourneys.length; i++) {
        if (_ongoingJourneys[i]['user_id'].toString() == userId) {
          _safeSetState(() {
            _ongoingJourneys[i] = {
              ..._ongoingJourneys[i],
              'username': profileUpdate['username'],
              'full_name': profileUpdate['full_name'],
              'avatar_url': profileUpdate['avatar_url'],
            };
          });
        }
      }
      _applySearchFilter(_searchQuery);
    }
  }

  // ============================
  // DATA MANAGEMENT
  // ============================

  /// Add a new journey to the viewer list Actual UI LIST
  Future<void> _addJourneyToViewerList(Map<String, dynamic> viewerRow) async {
    final journeyId = viewerRow['journey_id'];

    try {
      final journeyResponse = await supabase.from('user_journey')
          .select('*')
          .eq('id', journeyId)
          .eq('status', 'ongoing')
          .eq('reached_dest', false)
          .maybeSingle();

      if (journeyResponse != null && journeyResponse.isNotEmpty) {

        // Connecting with Profile Table
        final profileResponse = await supabase
            .from('profiles')
            .select('id, username, full_name, avatar_url')
            .eq('id', journeyResponse['user_id'])
            .maybeSingle();


        // adding the cross product of Journey_table and profile table
        final newJourney = {
          'journey_id': journeyResponse['id'],
          'user_id': journeyResponse['user_id'],
          'pickup_lat': journeyResponse['pickup_lat'] as double?,
          'pickup_lng': journeyResponse['pickup_lng'] as double?,
          'current_lat': journeyResponse['current_lat'] as double?,
          'current_lng': journeyResponse['current_lng'] as double?,
          'destination_lat': journeyResponse['destination_lat'] as double?,
          'destination_lng': journeyResponse['destination_lng'] as double?,
          'status': journeyResponse['status'] ?? 'ongoing',
          'reached_dest': journeyResponse['reached_dest'] ?? false,
          'updated_at': journeyResponse['updated_at']?.toString() ?? '',
          'username': profileResponse?['username'] ?? 'Unknown',
          'full_name': profileResponse?['full_name'] ?? 'Unknown User',
          'avatar_url': profileResponse?['avatar_url'],
          'viewer_id': viewerRow['id'],
          'disallowed': viewerRow['disallowed'] ?? false,
          'travel_mode': journeyResponse['travelMode'] ?? 'driving'
        };

        _safeSetState(() {
          _ongoingJourneys.add(newJourney);
          _applySearchFilter(_searchQuery);
        });

        // Show notification for new journey share
        if (_isMounted) {
          if(!mounted)return;




          CustomSnackbar.show(
            context: context,
            label: "${newJourney['full_name']} shared a journey with you!",
            title: "Journey Shared",
            color: Color(0xE04CAF50),
            svgColor: Color(0xE0178327),
            actionLabel: "Tap to View",
            onAction: (){
              //On Click the Journey which shared will be visible to the user
              debugPrint("Tapped on newJourney");
              _viewJourney(newJourney);
            }
          );

        }
      }
    } catch (e) {
      debugPrint('Error adding journey to list: $e');
    }
  }

  /// Clean up journeys that are no longer in viewer list
  void _cleanupRemovedJourneys(List<Map<String, dynamic>> currentViewerRows) {
    final currentViewerJourneyIds = currentViewerRows.map((row) => row['journey_id'].toString()).toSet();

    final journeysToRemove = _ongoingJourneys.where((journey) => !currentViewerJourneyIds.contains(journey['journey_id'].toString())).toList();

    if (journeysToRemove.isNotEmpty) {
      _safeSetState(() {
        _ongoingJourneys.removeWhere((journey) =>
        !currentViewerJourneyIds.contains(journey['journey_id'].toString()),
        );
        _applySearchFilter(_searchQuery);
      });
      debugPrint('Removed ${journeysToRemove.length} journeys no longer shared');
    }
  }

  /// Fetch ongoing journeys where current user is a viewer (initial load)
  Future<void> _fetchOngoingJourneys() async {
    final currentUserId = OauthHelper.currentUser()!.id;
    debugPrint('Current User ID: $currentUserId');

    _safeSetState(() {
      isLoading = true;
    });

    try {
      // Get all ride_viewer records for current user
      final viewerResponse = await supabase
          .from('ride_viewer')
          .select('id, journey_id, disallowed')
          .eq('viewer_id', currentUserId)
          .eq('disallowed', false).order("created_at", ascending: true);


      debugPrint("Found ${viewerResponse.length} viewer records");

      List<Map<String, dynamic>> journeysList = [];

      for (var viewerRow in viewerResponse) {
        final journeyId = viewerRow['journey_id'];
        debugPrint("Processing journey: $journeyId");

        try {
          // Get journey details separately
          final journeyResponse = await supabase
              .from('user_journey')
              .select('*')
              .eq('id', journeyId)
              .eq('status', 'ongoing')
              .eq('reached_dest', false)
              .maybeSingle();

          if (journeyResponse != null && journeyResponse.isNotEmpty) {
            debugPrint("Found valid ongoing journey: ${journeyResponse['id']}");

            // Get profile details
            final profileResponse = await supabase
                .from('profiles')
                .select('id, username, full_name, avatar_url')
                .eq('id', journeyResponse['user_id'])
                .maybeSingle();

            if (profileResponse != null && profileResponse.isNotEmpty) {
              journeysList.add({
                'journey_id': journeyResponse['id'],
                'user_id': journeyResponse['user_id'],
                'pickup_lat': journeyResponse['pickup_lat'] as double?,
                'pickup_lng': journeyResponse['pickup_lng'] as double?,
                'current_lat': journeyResponse['current_lat'] as double?,
                'current_lng': journeyResponse['current_lng'] as double?,
                'destination_lat': journeyResponse['destination_lat'] as double?,
                'destination_lng': journeyResponse['destination_lng'] as double?,
                'status': journeyResponse['status'] ?? 'ongoing',
                'reached_dest': journeyResponse['reached_dest'] ?? false,
                'updated_at': journeyResponse['updated_at']?.toString() ?? '',
                'username': profileResponse['username'] ?? 'Unknown',
                'full_name': profileResponse['full_name'] ?? 'Unknown User',
                'avatar_url': profileResponse['avatar_url'],
                'viewer_id': viewerRow['id'],
                'disallowed': viewerRow['disallowed'] ?? false,
                "travel_mode": journeyResponse['travelMode'] ?? 'driving'
              });
            } else {
              debugPrint("Profile not found for user: ${journeyResponse['user_id']}");
              // Fallback for missing profile
              journeysList.add({
                'journey_id': journeyResponse['id'],
                'user_id': journeyResponse['user_id'],
                'pickup_lat': journeyResponse['pickup_lat'] as double?,
                'pickup_lng': journeyResponse['pickup_lng'] as double?,
                'current_lat': journeyResponse['current_lat'] as double?,
                'current_lng': journeyResponse['current_lng'] as double?,
                'destination_lat': journeyResponse['destination_lat'] as double?,
                'destination_lng': journeyResponse['destination_lng'] as double?,
                'status': journeyResponse['status'] ?? 'ongoing',
                'reached_dest': journeyResponse['reached_dest'] ?? false,
                'updated_at': journeyResponse['updated_at']?.toString() ?? '',
                'username': 'unknown',
                'full_name': 'Unknown User',
                'avatar_url': null,
                'viewer_id': viewerRow['id'],
                'disallowed': viewerRow['disallowed'] ?? false,
                "travel_mode": journeyResponse['travelMode'] ?? 'driving'
              });
            }
          } else {
            debugPrint("Journey not found or not ongoing: $journeyId");
            // Clean up invalid ride_viewer records
            await _cleanupInvalidViewerRecord(viewerRow['id']);
          }
        } catch (e) {
          debugPrint("Error processing journey $journeyId: $e");
        }
      }

      _safeSetState(() {
        _ongoingJourneys = journeysList;
        _filteredJourneys = journeysList;
        isLoading = false;
      });

      debugPrint("Successfully loaded ${journeysList.length} valid journeys");

    } catch (e) {
      debugPrint('Error fetching ongoing journeys: $e');
      _safeSetState(() {
        isLoading = false;
      });
    }
  }

  /// Clean up invalid viewer records
  Future<void> _cleanupInvalidViewerRecord(String viewerId) async {
    try {
      await supabase
          .from('ride_viewer')
          .delete()
          .eq('id', viewerId);
      debugPrint("Cleaned up invalid viewer record: $viewerId");
    } catch (e) {
      debugPrint("Error cleaning up viewer record: $e");
    }
  }

  // ============================
  // JOURNEY MANAGEMENT
  // ============================

  /// Toggle journey viewing permission
  Future<void> _toggleJourneyViewing(String viewerRowId, bool disallowed) async {
    _safeSetState(() {
      _updatingViewerId = viewerRowId;
    });

    try {
      await supabase
          .from('ride_viewer')
          .update({'disallowed': disallowed})
          .eq('id', viewerRowId);


      _safeSetState(() {
        _updatingViewerId = null;
      });

      if (_isMounted ) {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              disallowed
                  ? 'Journey viewing disabled'
                  : 'Journey viewing enabled',
            ),
            backgroundColor: disallowed ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      _safeSetState(() {
        _updatingViewerId = null;
      });
      debugPrint('Error updating journey viewing: $e');

      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update viewing settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to journey map view
  Future<void> _viewJourney(Map<String, dynamic> journey) async {


    final markers=await _createMarkersForJourney(journey);

    final polylines=await _createPolyLineForJourney(journey);








    if (!_isMounted) return;
    if(!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyViewers(
          markers: markers,
          polylines:polylines,
          journeyId: journey['journey_id'],
          travelMode: journey['travel_mode'],
          fromLocation: LatLng(
            journey['pickup_lat'] ?? 0.0,
            journey['pickup_lng'] ?? 0.0,
          ),
          toLocation: LatLng(
            journey['destination_lat'] ?? 0.0,
            journey['destination_lng'] ?? 0.0,
          ),
          userLocation: LatLng(
            journey['current_lat'] ?? journey['pickup_lat'] ?? 0.0,
            journey['current_lng'] ?? journey['pickup_lng'] ?? 0.0,
          ),
          instructions: [],
          isViewer: true,
        ),
      ),
    );
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













  /// Create map markers for a journey
  Future<Set<Marker>> _createMarkersForJourney(Map<String, dynamic> journey) async {
    final markers = <Marker>{};

    final pickupLat = journey['pickup_lat'] as double?;
    final pickupLng = journey['pickup_lng'] as double?;
    final destLat = journey['destination_lat'] as double?;
    final destLng = journey['destination_lng'] as double?;
    final pickupIcon=await pickup();
    final destination=await destinationIcon();

    if (pickupLat != null && pickupLng != null) {
      markers.add(
        Marker(
          markerId: MarkerId('pickup_${journey['journey_id']}'),
          position: LatLng(pickupLat, pickupLng),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: pickupIcon,
        ),
      );
    }

    if (destLat != null && destLng != null) {
      markers.add(
        Marker(
          markerId: MarkerId('destination_${journey['journey_id']}'),
          position: LatLng(destLat, destLng),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: destination,
        ),
      );
    }



    return markers;
  }





  /// Create map polyline for a journey
  Future<Set<Polyline>> _createPolyLineForJourney(Map<String, dynamic> journey) async {
    final polylines = <Polyline>{};
    polylines.clear();

    final pickupLat = journey['pickup_lat'] as double?;
    final pickupLng = journey['pickup_lng'] as double?;
    final destLat = journey['destination_lat'] as double?;
    final destLng = journey['destination_lng'] as double?;
    final travelMode=journey['travel_mode'];

    print("Travel Mode $travelMode");


    final fromLocation = pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : null;
    final toLocation= destLat != null && destLng != null ? LatLng(destLat, destLng) : null;


    if (fromLocation != null && toLocation != null) {
      final route = await LocationHelper().getRoute(fromLocation, toLocation, travelMode);
      print("Route: $route");

      if (route != null) {
        final points = LocationHelper().decodePolyline(route['overview_polyline']['points']);
        print("Decoded Points: $points");


        polylines.add(Polyline(
          polylineId: const PolylineId('journey_line'),
          points: points,
          color: Colors.blue,
          width: 5,
        ));


        final legs = route['legs'][0];
        final distance = legs['distance']['text'];
        final duration = legs['duration']['text'];
        var routeInfo = "Distance: $distance, Duration: $duration";
      } else {

        if(mounted) {
          CustomSnackbar.show(context: context, label: "No route available for selected travel mode");
        }


      }
    }
    return polylines;
  }











  // ============================
  // UI HELPERS
  // ============================

  void _safeSetState(VoidCallback fn) {
    if (_isMounted && mounted) {
      setState(fn);
    }
  }

  void _applySearchFilter(String query) {
    _safeSetState(() {
      _searchQuery = query;
      _filteredJourneys = _ongoingJourneys.where((journey) {
        final name = journey['full_name']?.toString().toLowerCase() ?? '';
        final username = journey['username']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || username.contains(searchLower);
      }).toList();
    });
  }

  String _getJourneyStatus(Map<String, dynamic> journey) {
    if (journey['reached_dest'] == true) {
      return 'Completed';
    }

    final status = journey['status']?.toString() ?? 'ongoing';
    switch (status) {
      case 'ongoing':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(String? updatedAt) {
    if (updatedAt == null || updatedAt.isEmpty) return 'Unknown';

    try {
      final updatedTime = DateTime.parse(updatedAt);
      final now = DateTime.now();
      final difference = now.difference(updatedTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  // ============================
  // UI BUILDING
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon:  Icon(Icons.arrow_back, color: AppColors.getAppBarColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title:  Text(
          'Companions Journeys',
          style: TextStyle(
            color: AppColors.textPrimaryColor(context),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:  Icon(Icons.refresh, color: AppColors.getAppBarColor(context)),
            onPressed: _fetchOngoingJourneys,
          ),
          // Real-time indicator
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.circle,
                  color: Colors.green,
                  size: 12,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Info Card
          if (_ongoingJourneys.isNotEmpty) _buildInfoCard(),

          // Journeys List
          Expanded(
            child: _buildJourneysList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search journeys...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: _applySearchFilter,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are watching ${_ongoingJourneys.length} ongoing journey${_ongoingJourneys.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneysList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredJourneys.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchOngoingJourneys,
        child: _buildEmptyState(),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOngoingJourneys,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredJourneys.length,
        separatorBuilder: (context, index) => const Divider(height: 16),
        itemBuilder: (context, index) => _buildJourneyItem(_filteredJourneys[index]),
      ),
    );
  }

  Widget _buildJourneyItem(Map<String, dynamic> journey) {
    final status = _getJourneyStatus(journey);
    final statusColor = _getStatusColor(status);
    final isUpdating = _updatingViewerId == journey['viewer_id'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Opacity(
        opacity: isUpdating ? 0.6 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _buildUserAvatar(journey, isUpdating),
          title: Text(
            journey['full_name']?.toString() ??
                journey['username']?.toString() ??
                'Unknown User',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: _buildJourneySubtitle(journey, status, statusColor),
          trailing: _buildTrailingActions(journey, isUpdating),
          onTap: () {
            if (journey['disallowed'] == false && !isUpdating) {
              _viewJourney(journey);
            }
          },
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> journey, bool isUpdating) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: journey['avatar_url'] != null
              ? NetworkImage(journey['avatar_url'].toString())
              : null,
          child: journey['avatar_url'] == null
              ? const Icon(Icons.person, size: 24)
              : null,
        ),
        if (isUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildJourneySubtitle(
      Map<String, dynamic> journey,
      String status,
      Color statusColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            // Last Updated
            Text(
              'Updated: ${_formatTimeAgo(journey['updated_at'])}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Live Tracking Indicator
        if (journey['current_lat'] != null && journey['current_lng'] != null)
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Live tracking active',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTrailingActions(Map<String, dynamic> journey, bool isUpdating) {
    if (isUpdating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Watch Journey'),
            trailing: Switch(
              value: journey['disallowed'] == false,
              onChanged: (bool value) {
                _toggleJourneyViewing(journey['viewer_id'], !value);
                Navigator.pop(context);
              },
            ),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.map),
              SizedBox(width: 8),
              Text('View on Map'),
            ],
          ),
        ),
        if (journey['disallowed'] == true)
          const PopupMenuItem<String>(
            value: 'enable',
            child: Row(
              children: [
                Icon(Icons.visibility, color: Colors.green),
                SizedBox(width: 8),
                Text('Enable Watching'),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            _viewJourney(journey);
            break;
          case 'enable':
            _toggleJourneyViewing(journey['viewer_id'], false);
            break;
        }
      },
    );
  }

  Widget _buildEmptyState() {
    final hasPermissionsButNoActive = _ongoingJourneys.isEmpty && _searchQuery.isEmpty;

    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasPermissionsButNoActive ? 'No Journeys to Watch' : 'No Journeys Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "You are not currently watching any ongoing journeys. "
                    "Ask your friends to share their journey with you",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 20),

          ],
        ),
      ],
    );
  }
}