import 'dart:async';
import 'package:companion/models/instruction.dart';
import 'package:companion/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Providers/journey_provider.dart';
import '../Services/background_journey_service.dart';
import '../Services/geolocation.dart';
import '../core/utils/azure_tts_controller.dart';
import '../core/utils/walking_controller.dart';

class JourneyViewers extends StatefulWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String? journeyId;
  final dynamic travelMode;
  final LatLng? fromLocation;
  final LatLng? toLocation;
  final LatLng? userLocation;
  final List<Instruction> instructions;
  final bool isViewer;

  const JourneyViewers({
    super.key,
    required this.markers,
    required this.polylines,
    this.journeyId,
    required this.travelMode,
    required this.fromLocation,
    required this.toLocation,
    required this.userLocation,
    required this.instructions,
    this.isViewer = false,
  });

  @override
  State<JourneyViewers> createState() => _JourneyViewersState();
}

class _JourneyViewersState extends State<JourneyViewers> {
  late GoogleMapController mapController;
  late final WalkingMarkerController walkingController;
  late final AzureTTSController ttsController;

  // For Instructions Speak
  int _currentInstructionIndex = 0;
  DateTime _lastInstructionTime = DateTime.now();
  final Set<int> _spokenInstructions = {};
  final double _instructionTriggerDistance = 50.0;

  Set<Marker> markers = {};
  List<Map<String, dynamic>> watchers = [];
  bool isLoading = true;

  bool _isViewerMode = false;
  Timer? _viewerPresenceTimer;
  String? _currentViewerId;
  late List<Map<String, dynamic>> _activeWatchers = [];
  RealtimeChannel? _viewersChannel;
  RealtimeChannel? _journeyChannel;

  // Markers
  Marker? _carMarker;
  BitmapDescriptor? _carIcon;

  // Journey Status
  StreamSubscription<Position>? _positionStream;
  bool _journeyFinished = false;
  LatLng? _lastPosition;
  bool _soundEnabled = true;
  bool _trackingStarted = false;

  // Viewer real-time tracking
  Timer? _viewerLocationUpdateTimer;
  LatLng? _currentCompanionLocation;
  bool _isJourneyCompleted = false;

  @override
  void initState() {
    super.initState();
    markers = widget.markers;
    walkingController = WalkingMarkerController();

    if (!widget.isViewer) {
      ttsController = AzureTTSController();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint("Instruction Loaded: ${widget.instructions}");
      final journeyProvider = context.read<JourneyProvider>();
      await _initializeServices();
      _checkIfViewerMode();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _trackingStarted = false;
    if (widget.travelMode == "walking") {
      walkingController.stop();
    }
    if (!widget.isViewer) {
      ttsController.dispose();
    }
    _stopViewerPresence();
    _stopViewerLocationUpdates();
    _journeyChannel?.unsubscribe();
    super.dispose();
  }

  // Check if it is viewer or owner
  Future<void> _checkIfViewerMode() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // If journeyId is provided and user is not the journey owner, it's viewer mode
    if (widget.journeyId != null) {
      try {
        final journeyResponse = await Supabase.instance.client
            .from('user_journey')
            .select('user_id, status')
            .eq('id', widget.journeyId!)
            .single();

        final isOwner = journeyResponse['user_id'] == user.id;
        setState(() {
          _isViewerMode = !isOwner;
          _currentViewerId = user.id;
        });

        if (_isViewerMode) {
          debugPrint("👀 Viewer mode activated for journey: ${widget.journeyId}");
          await _startViewerPresence();
          await _setupJourneyRealtimeUpdates();
          await _startViewerLocationUpdates();
        } else {
          debugPrint("👤 Owner mode for journey: ${widget.journeyId}");
        }
      } catch (e) {
        debugPrint("Error checking viewer mode: $e");
      }
    }
  }

  // Setup real-time updates for journey location and status
  Future<void> _setupJourneyRealtimeUpdates() async {
    if (widget.journeyId == null) return;

    try {
      _journeyChannel = Supabase.instance.client.channel('journey_${widget.journeyId}')
          .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'user_journey',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: widget.journeyId!,
        ),
        callback: (payload) {
          _handleJourneyUpdate(payload);
        },
      ).subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint("🔔 Real-time journey subscription started");
        } else if (status == RealtimeSubscribeStatus.timedOut) {
          debugPrint("❌ Journey real-time subscription timed out");
        } else if (error != null) {
          debugPrint("❌ Journey real-time subscription error: $error");
        }
      });
    } catch (e) {
      debugPrint("Error setting up journey realtime: $e");
    }
  }

  void _handleJourneyUpdate(PostgresChangePayload payload) {
    debugPrint("Journey update received: ${payload.newRecord}");

    final newRecord = payload.newRecord;
    // Update companion location
    if (newRecord['current_lat'] != null && newRecord['current_lng'] != null) {
      final newLocation = LatLng(
        (newRecord['current_lat'] as num).toDouble(),
        (newRecord['current_lng'] as num).toDouble(),
      );
      _updateCompanionLocation(newLocation);
    }

    // Check if journey is completed
    if (newRecord['status'] == 'completed' && !_isJourneyCompleted) {
      _handleJourneyCompletion();
    }
    }

  // Update companion location for viewers
  void _updateCompanionLocation(LatLng newLocation) {
    if (!mounted) return;

    setState(() {
      _currentCompanionLocation = newLocation;
    });

    debugPrint("📍 Companion location updated: $newLocation");

    // Update marker based on travel mode
    if (widget.travelMode == "driving") {
      _updateCarPositionForViewer(newLocation);
    } else if (widget.travelMode == "walking") {
      _updateWalkingMarkerForViewer(newLocation);
    }

    // Move camera to follow companion
    mapController.animateCamera(CameraUpdate.newLatLng(newLocation));
  }

  void _updateCarPositionForViewer(LatLng newPos) {
    double bearing = _lastPosition != null
        ? LocationHelper().getBearing(_lastPosition!, newPos)
        : 0.0;

    final newCarMarker = Marker(
      markerId: const MarkerId("companion_car"),
      position: newPos,
      rotation: bearing,
      icon: _carIcon ?? BitmapDescriptor.defaultMarker,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndexInt: 2,
      infoWindow: const InfoWindow(title: "Companion Location"),
    );

    if (mounted) {
      setState(() {
        markers.removeWhere((m) => m.markerId.value == "companion_car");
        markers.add(newCarMarker);
        _carMarker = newCarMarker;
        _lastPosition = newPos;
      });
    }
  }

  void _updateWalkingMarkerForViewer(LatLng newPos) {
    final walkingMarker = Marker(
      markerId: const MarkerId("companion_walking"),
      position: newPos,
      icon: walkingController.walkingFrames.isNotEmpty
          ? walkingController.walkingFrames[0]
          : BitmapDescriptor.defaultMarker,
      anchor: const Offset(0.5, 1.0),
      infoWindow: const InfoWindow(title: "Companion Location"),
    );

    if (mounted) {
      setState(() {
        markers.removeWhere((m) => m.markerId.value == "companion_walking");
        markers.add(walkingMarker);
        _lastPosition = newPos;
      });
    }
  }

  // Start periodic location updates for viewer
  Future<void> _startViewerLocationUpdates() async {
    if (!_isViewerMode || widget.journeyId == null) return;

    // Initial fetch of companion location
    await _fetchCurrentCompanionLocation();

    // Set up periodic updates every 5 seconds
    _viewerLocationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCurrentCompanionLocation();
    });
  }

  Future<void> _fetchCurrentCompanionLocation() async {
    if (widget.journeyId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('user_journey')
          .select('current_lat, current_lng, status')
          .eq('id', widget.journeyId!)
          .single();

      if (response != null && response['current_lat'] != null && response['current_lng'] != null) {
        final location = LatLng(
          (response['current_lat'] as num).toDouble(),
          (response['current_lng'] as num).toDouble(),
        );

        if (_currentCompanionLocation == null ||
            _currentCompanionLocation != location) {
          _updateCompanionLocation(location);
        }

        // Check if journey is completed
        if (response['status'] == 'completed' && !_isJourneyCompleted) {
          _handleJourneyCompletion();
        }
      }
    } catch (e) {
      debugPrint("Error fetching companion location: $e");
    }
  }

  void _handleJourneyCompletion() {
    if (!mounted) return;

    setState(() {
      _isJourneyCompleted = true;
    });

    _showJourneyCompletionDialog();
  }

  void _showJourneyCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.green),
            SizedBox(width: 8),
            Text("Journey Completed"),
          ],
        ),
        content: const Text("The companion has successfully reached their destination!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToHomePage();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _navigateToHomePage() {
    // Navigate to home page and remove all routes
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _stopViewerLocationUpdates() {
    _viewerLocationUpdateTimer?.cancel();
  }

  // Rest of the existing methods remain the same...
  Future<void> _startViewerPresence() async {
    if (!_isViewerMode || _currentViewerId == null || widget.journeyId == null) {
      return;
    }

    try {
      await Supabase.instance.client
          .from('active_viewers')
          .upsert({
        'journey_id': widget.journeyId!,
        'viewer_id': _currentViewerId!,
        'is_active': true,
        'last_seen': DateTime.now().toIso8601String(),
      });

      _setupViewersRealtime();

      _viewerPresenceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateViewerPresence();
      });

      debugPrint("✅ Viewer presence tracking started");
    } catch (e) {
      debugPrint("Error starting viewer presence: $e");
    }
  }

  void _setupViewersRealtime() {
    if (widget.journeyId == null) return;

    try {
      _viewersChannel?.unsubscribe();

      _viewersChannel = Supabase.instance.client.channel('viewers_${widget.journeyId}')
          .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'active_viewers',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'journey_id',
          value: widget.journeyId!,
        ),
        callback: (payload) {
          _handleViewersUpdate(payload);
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'ride_viewer',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'journey_id',
          value: widget.journeyId!,
        ),
        callback: (payload) {
          _fetchViewers();
        },
      ).subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint("🔔 Real-time viewers subscription started");
        } else if (status == RealtimeSubscribeStatus.timedOut) {
          debugPrint("❌ Real-time subscription timed out");
        } else if (error != null) {
          debugPrint("❌ Real-time subscription error: $error");
        }
      });
    } catch (e) {
      debugPrint("Error setting up realtime: $e");
    }
  }

  void _handleViewersUpdate(PostgresChangePayload payload) {
    _fetchActiveWatchers();
  }

  Future<void> _updateViewerPresence() async {
    if (!_isViewerMode || _currentViewerId == null || widget.journeyId == null) {
      return;
    }

    try {
      await Supabase.instance.client
          .from('active_viewers')
          .upsert({
        'journey_id': widget.journeyId!,
        'viewer_id': _currentViewerId!,
        'last_seen': DateTime.now().toIso8601String(),
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('journey_id', widget.journeyId!)
          .eq('viewer_id', _currentViewerId!);
    } catch (e) {
      debugPrint("Error updating viewer presence: $e");
    }
  }

  Future<void> _fetchActiveWatchers() async {
    if (widget.journeyId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('active_viewers')
          .select('''
          viewer_id, 
          last_seen,
          is_active,
          profiles:viewer_id(id, full_name, avatar_url)
        ''')
          .eq('journey_id', widget.journeyId!)
          .eq('is_active', true)
          .gt(
        'last_seen',
        DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
      );

      List<Map<String, dynamic>> activeWatchersList = [];
      for (var row in response) {
        final profile = row['profiles'];
        if (profile != null && row['is_active'] == true) {
          activeWatchersList.add({
            'id': profile['id'],
            'full_name': profile['full_name'],
            'avatar_url': profile['avatar_url'],
            'last_seen': row['last_seen'],
            'is_online': _isViewerOnline(row['last_seen']),
          });
        }
      }

      if (mounted) {
        setState(() {
          _activeWatchers = activeWatchersList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching active watchers: $e");
    }
  }

  bool _isViewerOnline(String lastSeen) {
    try {
      final lastSeenTime = DateTime.parse(lastSeen);
      final now = DateTime.now();
      return now.difference(lastSeenTime).inMinutes < 2;
    } catch (e) {
      return false;
    }
  }

  Future<void> _stopViewerPresence() async {
    _viewerPresenceTimer?.cancel();

    if (_currentViewerId != null && widget.journeyId != null) {
      try {
        await Supabase.instance.client
            .from('active_viewers')
            .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('journey_id', widget.journeyId!)
            .eq('viewer_id', _currentViewerId!);
      } catch (e) {
        debugPrint("Error stopping viewer presence: $e");
      }
    }

    try {
      await _viewersChannel?.unsubscribe();
    } catch (e) {
      debugPrint("Error unsubscribing from channel: $e");
    }
  }

  Future<void> _fetchViewers() async {
    try {
      final journeyProvider = context.read<JourneyProvider>();
      final journeyId = journeyProvider.currentJourneyId ?? widget.journeyId;

      if (journeyId == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final response = await Supabase.instance.client
          .from('ride_viewer')
          .select('viewer_id, disallowed, profiles(id, full_name, avatar_url)')
          .eq('journey_id', journeyId)
          .eq('disallowed', false);

      List<Map<String, dynamic>> viewersList = [];
      for (var row in response) {
        final profile = row['profiles'];
        if (profile != null) {
          viewersList.add({
            'id': profile['id'],
            'full_name': profile['full_name'],
            'avatar_url': profile['avatar_url'],
          });
        }
      }

      if (mounted) {
        setState(() {
          watchers = viewersList;
          isLoading = false;
        });
      }

      if (_isViewerMode) {
        await _fetchActiveWatchers();
      }
    } catch (e) {
      debugPrint("Error fetching journey viewers: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _initializeServices() async {
    if (!widget.isViewer) {
      await _checkExistingJourney();
      await _fetchViewers();
    }
    await _initializeTracking();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkExistingJourney() async {
    final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);
    if (journeyProvider.isTracking) {
      _startForegroundTracking();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _initializeTracking() async {
    if (widget.travelMode == "driving") {
      await _loadCarIcon();
    } else if (widget.travelMode == "walking") {
      await walkingController.loadFrames();
    }

    setState(() {
      isLoading = false;
    });

    if (!widget.isViewer) {
      if (!mounted) return;
      final journeyProvider = context.read<JourneyProvider>();
      if (journeyProvider.isTracking) {
        _startForegroundTracking();
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  // Only Start If no active Journey and Isn't a viewer
  Future<void> _startNewJourney() async {
    final journeyProvider = context.read<JourneyProvider>();

    try {
      setState(() => isLoading = true);

      if (widget.journeyId == null || widget.journeyId!.isEmpty) {
        await journeyProvider.startNewJourney(
          pickupLat: widget.fromLocation!.latitude,
          pickupLng: widget.fromLocation!.longitude,
          destinationLat: widget.toLocation!.latitude,
          destinationLng: widget.toLocation!.longitude,
        );

        if (!mounted) return;
        final provider = Provider.of<JourneyProvider>(context, listen: false);
        await provider.saveActiveJourney(
          instructions: widget.instructions,
          markers: markers,
          polylines: widget.polylines,
          journeyId: provider.currentJourneyId!,
          pickup: widget.fromLocation!,
          destination: widget.toLocation!,
          currentLocation: widget.userLocation!,
          travelMode: widget.travelMode,
        );
      } else {
        await BackgroundJourneyService.startJourneyTracking(
          journeyId: widget.journeyId!,
          destLat: widget.toLocation!.latitude,
          destLng: widget.toLocation!.longitude,
        );
      }

      _startForegroundTracking();
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        label: "Journey started! Tracking in background...",
      );
    } catch (e) {
      setState(() => isLoading = false);
      CustomSnackbar.show(
        context: context,
        label: "Failed to start journey: $e",
      );
    }
  }

  Future<void> _stopCurrentJourney() async {
    final journeyProvider = context.read<JourneyProvider>();
    await Provider.of<JourneyProvider>(context, listen: false).clearActiveJourney();
    try {
      setState(() => isLoading = true);
      await journeyProvider.stopCurrentJourney();

      _positionStream?.cancel();
      _trackingStarted = false;
      if (widget.travelMode == "walking") {
        walkingController.stop();
      }

      setState(() {
        isLoading = false;
        _journeyFinished = true;
      });
      if (!mounted) return;
      CustomSnackbar.show(context: context, label: "Journey stopped");
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        label: "Failed to stop journey: $e",
      );
    }
  }

  // Track Journey
  void _startForegroundTracking() {
    _startLiveTracking();
    setState(() => isLoading = false);
  }

  // Only if travelMode==driving
  Future<void> _loadCarIcon() async {
    try {
      _carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(devicePixelRatio: 2.5),
        "assets/images/car.png",
        width: 40,
        height: 50
      );
      debugPrint("Car icon loaded successfully");
    } catch (e) {
      debugPrint(" Error loading car icon: $e");
      _carIcon = BitmapDescriptor.defaultMarker;
    }
  }

  // Only the Owner Location Can be _StartTracking
  Future<void> _startLiveTracking() async {
    if (!mounted) return;

    if (_trackingStarted) {
      debugPrint("🔄 Tracking already started, skipping...");
      return;
    }
    _trackingStarted = true;

    try {
      Position? initialPosition = await LocationHelper().determinePosition(context);

      if (initialPosition == null) {
        setState(() => isLoading = false);
        _trackingStarted = false;
        return;
      }

      LatLng initialLatLng = LatLng(
        initialPosition.latitude,
        initialPosition.longitude,
      );

      _lastPosition = initialLatLng;
      _updateJourneyPosition(initialLatLng);

      if (widget.travelMode == "driving") {
        debugPrint("🚗 Starting driving tracking at $initialLatLng");

        if (_carIcon == null) {
          await _loadCarIcon();
        }

        _updateCarPosition(initialLatLng);
      } else if (widget.travelMode == "walking") {
        walkingController.startAnimation(
          onMarkerUpdated: (marker) {
            if (mounted) {
              setState(() {
                markers.removeWhere((m) => m.markerId.value == "walking_marker");
                markers.add(marker);
              });
            }
          },
        );
        walkingController.updatePosition(initialLatLng);
      }

      if (_soundEnabled && widget.instructions.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        ttsController.speak(widget.instructions.first.text);
        _currentInstructionIndex = 1;
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        LatLng newPos = LatLng(position.latitude, position.longitude);
        _updatePosition(newPos);
        _checkIfArrived(newPos);
        _checkForNextInstruction(newPos);
      });

      debugPrint("✅ Live tracking started successfully");

    } catch (e) {
      _trackingStarted = false;
      debugPrint("❌ Error starting live tracking: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _updatePosition(LatLng newPos) {
    if (_lastPosition == null) {
      _lastPosition = newPos;
      return;
    }

    debugPrint("📍 Position update: $newPos");

    if (widget.travelMode == "driving") {
      _updateCarPosition(newPos);
    } else if (widget.travelMode == "walking") {
      walkingController.updatePosition(newPos);
      mapController.animateCamera(CameraUpdate.newLatLng(newPos));
    }

    _lastPosition = newPos;
    _updateJourneyPosition(newPos);
  }

  Future<void> _updateJourneyPosition(LatLng position) async {
    if (widget.journeyId == null) return;

    try {
      await Supabase.instance.client
          .from('user_journey')
          .update({
        'current_lat': position.latitude,
        'current_lng': position.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.journeyId!);
    } catch (e) {
      debugPrint("Error updating journey position: $e");
    }
  }

  void _updateCarPosition(LatLng newPos) {
    double bearing = _lastPosition != null
        ? LocationHelper().getBearing(_lastPosition!, newPos)
        : 0.0;

    final newCarMarker = Marker(
      markerId: const MarkerId("car"),
      position: newPos,
      rotation: bearing,
      icon: _carIcon ?? BitmapDescriptor.defaultMarker,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndexInt: 2,
    );

    if (mounted) {
      setState(() {
        markers.removeWhere((m) => m.markerId.value == "car");
        markers.add(newCarMarker);
        _carMarker = newCarMarker;
      });
    }

    mapController.animateCamera(CameraUpdate.newLatLng(newPos));
  }

  // Only in owner Journey Create
  void _checkForNextInstruction(LatLng currentPos) {
    if (!_soundEnabled || widget.instructions.isEmpty) return;

    if (_currentInstructionIndex >= widget.instructions.length) {
      return;
    }

    final currentInstruction = widget.instructions[_currentInstructionIndex];

    final distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      currentInstruction.lat,
      currentInstruction.lng,
    );

    bool shouldSpeak = _shouldSpeakInstruction(
      distance,
      currentInstruction,
      _currentInstructionIndex,
    );

    if (shouldSpeak) {
      _speakInstruction(currentInstruction, _currentInstructionIndex);
      _moveToNextInstruction();
    }

    _checkForMissedInstructions(currentPos);
  }

  bool _shouldSpeakInstruction(
      double distance,
      Instruction instruction,
      int index,
      ) {
    if (_spokenInstructions.contains(index)) {
      return false;
    }

    if (ttsController.isPlaying || ttsController.isLoading) {
      return false;
    }

    final timeSinceLast = DateTime.now().difference(_lastInstructionTime).inSeconds;
    if (timeSinceLast < 4) {
      return false;
    }

    double triggerDistance = _instructionTriggerDistance;

    if (_isImportantInstruction(instruction.text)) {
      triggerDistance = 100.0;
    }

    return distance <= triggerDistance;
  }

  bool _isImportantInstruction(String text) {
    final importantKeywords = [
      'turn', 'exit', 'keep', 'merge', 'ramp', 'roundabout',
      'fork', 'arrive', 'destination', 'left', 'right',
    ];

    final lowerText = text.toLowerCase();
    return importantKeywords.any((keyword) => lowerText.contains(keyword));
  }

  void _speakInstruction(Instruction instruction, int index) async {
    try {
      debugPrint("🗣️ Speaking instruction $index: ${instruction.text}");
      await ttsController.speak(instruction.text);
      _spokenInstructions.add(index);
      _lastInstructionTime = DateTime.now();
    } catch (e) {
      debugPrint("❌ Failed to speak instruction $index: $e");
      _spokenInstructions.remove(index);
    }
  }

  void _moveToNextInstruction() {
    if (_currentInstructionIndex < widget.instructions.length - 1) {
      _currentInstructionIndex++;
    }
  }

  void _checkForMissedInstructions(LatLng currentPos) {
    for (int i = _currentInstructionIndex; i < widget.instructions.length; i++) {
      if (_spokenInstructions.contains(i)) continue;

      final instruction = widget.instructions[i];
      final distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        instruction.lat,
        instruction.lng,
      );

      if (distance <= 20.0) {
        _speakInstruction(instruction, i);
        _currentInstructionIndex = i + 1;
        break;
      }
    }
  }

  // Both Viewer Can Call
  Future<void> _checkIfArrived(LatLng currentPos) async {
    if (widget.toLocation == null || _journeyFinished) return;

    double distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      widget.toLocation!.latitude,
      widget.toLocation!.longitude,
    );

    if (distance <= 20) {
      _journeyFinished = true;
      _positionStream?.cancel();
      _trackingStarted = false;

      if (widget.travelMode == "walking") {
        walkingController.stopAnimation();
      }

      final journeyProvider = context.read<JourneyProvider>();
      journeyProvider.completeJourney();
      await Provider.of<JourneyProvider>(context, listen: false).clearActiveJourney();

      _showArrivalDialog();
    }
  }

  // Only for owner
  void _showArrivalDialog() async {
    if (_soundEnabled) {
      ttsController.speak("You have arrived at your destination!");
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Arrived Your Destination"),
        content: const Text("You have successfully reached your destination!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fixAtDestination();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // For both viewer
  void _fixAtDestination() {
    if (widget.toLocation == null) return;

    setState(() {
      if (widget.travelMode == "driving") {
        markers.removeWhere((m) => m.markerId.value == "car");
        markers.add(
          Marker(
            markerId: const MarkerId("car"),
            position: widget.toLocation!,
            icon: _carIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: "Arrived Destination"),
          ),
        );
      } else if (widget.travelMode == "walking") {
        markers.removeWhere((m) => m.markerId.value == "walking_marker");
        markers.add(
          Marker(
            markerId: const MarkerId("walking_marker"),
            position: widget.toLocation!,
            icon: walkingController.walkingFrames.isNotEmpty
                ? walkingController.walkingFrames[0]
                : BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 1.0),
            infoWindow: const InfoWindow(title: "Arrived Destination"),
          ),
        );
      }
    });

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(widget.toLocation!, 16),
    );
  }

  void _toggleSound() {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    if (!_soundEnabled) ttsController.stop();
  }

  void _moveCameraToFitMarkers() {
    if (markers.isEmpty) return;
    if (markers.length == 1) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(markers.first.position, 14),
      );
      return;
    }

    double? minLat, maxLat, minLng, maxLng;
    for (var marker in markers) {
      minLat ??= marker.position.latitude;
      maxLat ??= marker.position.latitude;
      minLng ??= marker.position.longitude;
      maxLng ??= marker.position.longitude;

      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  @override
  Widget build(BuildContext context) {
    final journeyProvider = context.watch<JourneyProvider>();
    final bool isViewer = widget.isViewer;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.fromLocation ?? const LatLng(0, 0),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _moveCameraToFitMarkers();
              });
            },
            markers: markers,
            polylines: widget.polylines,
            myLocationEnabled: isViewer,
            myLocationButtonEnabled: isViewer,
            zoomControlsEnabled: true,
          ),

          // Debug Info Panel
          Positioned(
            top: 120,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isViewer ? '👀 Viewer Mode' : '👤 Owner Mode',
                    style: TextStyle(
                      color: isViewer ? Colors.green : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '📍 Companion Position:',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    _currentCompanionLocation != null
                        ? 'Lat: ${_currentCompanionLocation!.latitude.toStringAsFixed(6)}\nLng: ${_currentCompanionLocation!.longitude.toStringAsFixed(6)}'
                        : 'Not set',
                    style: TextStyle(color: Colors.yellow, fontSize: 10),
                  ),
                  if (!isViewer) ...[
                    Text(
                      'Markers: ${markers.length}',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      'Instructions: $_currentInstructionIndex/${widget.instructions.length}',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                  if (isViewer)
                    Text(
                      'Active Watchers: ${_activeWatchers.length}',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  if (_isJourneyCompleted)
                    Text(
                      '✅ Journey Completed',
                      style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),

          // Journey Control Button (Owner only)
          if (!isViewer) ..._buildOwnerControls(journeyProvider),

          // Single Draggable Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
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
                  // Mode Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isViewer ? Icons.visibility : Icons.person,
                        color: isViewer ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isViewer ? 'Viewer Mode' : 'Owner Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isViewer ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Content based on mode
                  if (!isViewer) ..._buildOwnerContent(journeyProvider),
                  if (isViewer) ..._buildViewerContent(),

                  const SizedBox(height: 16),

                  // Watchers List
                  if (_activeWatchers.isNotEmpty) ..._buildActiveWatchersList(),
                  if (_activeWatchers.isEmpty && !_isViewerMode) ..._buildWatchersList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOwnerControls(JourneyProvider journeyProvider) {
    return [
      // Journey Control Button
      Positioned(
        top: 80,
        left: 16,
        child: GestureDetector(
          onTap: journeyProvider.isTracking ? _stopCurrentJourney : _startNewJourney,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  journeyProvider.isTracking ? Icons.stop_circle : Icons.play_arrow,
                  color: journeyProvider.isTracking ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  journeyProvider.isTracking ? 'Stop Journey' : 'Start Journey',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: journeyProvider.isTracking ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Sound Toggle Button
      Positioned(
        top: 80,
        right: 16,
        child: FloatingActionButton(
          onPressed: _toggleSound,
          backgroundColor: _soundEnabled ? Colors.blue : Colors.grey,
          mini: true,
          child: Icon(
            _soundEnabled ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
          ),
        ),
      ),

      // Start/Stop Journey FAB
      if (!journeyProvider.isTracking && !_journeyFinished)
        Positioned(
          bottom: 120,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _startNewJourney,
            backgroundColor: Colors.green,
            icon: const Icon(Icons.directions_walk),
            label: const Text('Start Journey'),
          ),
        ),

      if (journeyProvider.isTracking)
        Positioned(
          bottom: 120,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _stopCurrentJourney,
            backgroundColor: Colors.red,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Journey'),
          ),
        ),
    ];
  }

  List<Widget> _buildOwnerContent(JourneyProvider journeyProvider) {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                journeyProvider.isTracking ? '🚀 Journey Active' : '⏸️ Journey Not Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: journeyProvider.isTracking ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                journeyProvider.isTracking
                    ? 'Your journey is being tracked in background'
                    : 'Start your journey to begin tracking',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (journeyProvider.isTracking) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildViewerContent() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👀 Watching Journey',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are currently watching this journey in real-time',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${_activeWatchers.length} people watching',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
              ),
              if (_currentCompanionLocation != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Companion is moving',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildActiveWatchersList() {
    return [
      const Text(
        '👥 Currently Watching',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      ..._activeWatchers.map((watcher) {
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: watcher['avatar_url'] != null
                    ? NetworkImage(watcher['avatar_url'])
                    : null,
                child: watcher['avatar_url'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              if (watcher['is_online'] == true)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(watcher['full_name'] ?? 'Unknown'),
          subtitle: Text(
            watcher['is_online'] == true ? 'Online now' : 'Recently active',
            style: TextStyle(
              color: watcher['is_online'] == true ? Colors.green : Colors.grey,
            ),
          ),
          trailing: const Icon(Icons.remove_red_eye, color: Colors.blue),
        );
      }),
    ];
  }

  List<Widget> _buildWatchersList() {
    if (watchers.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
            child: Text(
              'No one is watching your journey yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    return [
      const Text(
        'Currently Watching',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      ...watchers.map((watcher) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: watcher['avatar_url'] != null
                ? NetworkImage(watcher['avatar_url'])
                : null,
            child: watcher['avatar_url'] == null ? const Icon(Icons.person) : null,
          ),
          title: Text(watcher['full_name'] ?? 'Unknown'),
          subtitle: const Text('Watching your journey'),
          trailing: const Icon(Icons.remove_red_eye, color: Colors.blue),
        );
      }),
    ];
  }
}