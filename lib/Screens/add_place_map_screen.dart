import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class AddPlaceMapScreen extends StatefulWidget {
  final String placeType;
  final bool isCustom;

  const AddPlaceMapScreen({
    super.key,
    required this.placeType,
    this.isCustom = false,
  });

  @override
  State<AddPlaceMapScreen> createState() => _AddPlaceMapScreenState();
}

class _AddPlaceMapScreenState extends State<AddPlaceMapScreen> {
  GoogleMapController? mapController;
  LatLng _selectedLocation = const LatLng(24.8949, 91.8687);
  String _address = "";
  double _radius = 300;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isCustom) {
      _nameController.text = widget.placeType;
    }
    _getAddressFromLatLng(_selectedLocation);
  }

  Future<void> _getAddressFromLatLng(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          final p = placemarks.first;
          _address = "${p.street}, ${p.locality}, ${p.country}";
        });
      }
    } catch (e) {
      setState(() {
        _address = "Unknown location";
      });
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _getAddressFromLatLng(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add ${widget.placeType}"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.bookmark, color: Colors.purple),
                hintText: "Place name",
                border: const UnderlineInputBorder(),
              ),
            ),
          ),

          // Address display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Google Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => mapController = controller,
                  onTap: _onMapTap,
                  markers: {
                    Marker(
                      markerId: const MarkerId("selected"),
                      position: _selectedLocation,
                      draggable: true,
                      onDragEnd: _onMapTap,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                    ),
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId("radius"),
                      center: _selectedLocation,
                      radius: _radius,
                      strokeWidth: 1,
                      strokeColor: Colors.purple,
                      fillColor: Colors.purple.withOpacity(0.2),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ],
            ),
          ),

          // Radius slider
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _radius,
                    min: 100,
                    max: 2000,
                    divisions: 20,
                    activeColor: Colors.purple,
                    onChanged: (value) {
                      setState(() {
                        _radius = value;
                      });
                    },
                  ),
                ),
                Text("${_radius.toInt()} m zone"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
