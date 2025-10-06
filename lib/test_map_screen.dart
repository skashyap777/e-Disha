import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TestMapScreen extends StatefulWidget {
  const TestMapScreen({super.key});

  @override
  State<TestMapScreen> createState() => _TestMapScreenState();
}

class _TestMapScreenState extends State<TestMapScreen> {
  GoogleMapController? _mapController;
  String _status = 'Initializing...';
  Position? _currentPosition;

  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090); // Delhi

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _status = 'Checking location services...';
      });

      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = 'Location services are disabled';
        });
        return;
      }

      setState(() {
        _status = 'Checking location permissions...';
      });

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _status = 'Location permissions denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _status = 'Location permissions permanently denied';
        });
        return;
      }

      setState(() {
        _status = 'Getting current location...';
      });

      // Get current position
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        setState(() {
          _currentPosition = position;
          _status = 'Location found: ${position.latitude}, ${position.longitude}';
        });
      } catch (e) {
        setState(() {
          _status = 'Using default location (Delhi). Error: $e';
        });
      }

      setState(() {
        _status = 'Map ready!';
      });

    } catch (e) {
      setState(() {
        _status = 'Error initializing map: $e';
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _status = 'Map controller created successfully!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : _defaultLocation,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _currentPosition != null
                  ? {
                      Marker(
                        markerId: const MarkerId('current_location'),
                        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        infoWindow: const InfoWindow(title: 'Your Location'),
                      ),
                    }
                  : {
                      const Marker(
                        markerId: MarkerId('default_location'),
                        position: _defaultLocation,
                        infoWindow: InfoWindow(title: 'Default Location (Delhi)'),
                      ),
                    },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Debug Info:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text('Current Position: ${_currentPosition?.toString() ?? 'Not available'}'),
                Text('Map Controller: ${_mapController != null ? 'Created' : 'Not created'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
