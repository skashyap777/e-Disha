import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gps_tracking_service.dart';
import '../services/settings_service.dart';
import '../widgets/custom_vehicle_icons.dart';

class LiveTrackingScreen extends StatefulWidget {
  final bool openHistoryDialog;
  
  const LiveTrackingScreen({super.key, this.openHistoryDialog = false});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  final GPSTrackingService _gpsService = GPSTrackingService();
  final SettingsService _settingsService = SettingsService();

  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isTracking = false;
  String? _errorMessage;
  List<GPSLocationData> _gpsLocations = [];
  BitmapDescriptor? _customMarkerIcon;
  bool _isTrackingUserLocation =
      false; // Flag to prevent auto-centering on vehicle
  bool _isMapReady = false; // Flag to prevent map recreation

  // Vehicle selection for tracking
  String? _selectedVehicleId;
  List<GPSLocationData> _availableVehicles = [];

  // Current bounds for map centering
  LatLngBounds? _currentBounds;

  // History playback settings
  bool _isHistoryMode = false;
  List<GPSLocationData> _historyData = [];
  int _currentHistoryIndex = 0;
  Timer? _historyPlaybackTimer;
  bool _isPlayingHistory = false;
  DateTime? _historyStartDate;
  DateTime? _historyEndDate;
  String? _historyVehicleId;

  // Update interval settings
  Duration _updateInterval = const Duration(seconds: 5);
  final List<Duration> _availableIntervals = [
    const Duration(seconds: 5),
    const Duration(seconds: 10),
    const Duration(seconds: 30),
    const Duration(minutes: 1),
    const Duration(minutes: 5),
    const Duration(minutes: 10),
  ];

  // Vehicle selection settings
  VehicleType _selectedVehicleType = VehicleType.yellowCar;

  // Default location (Delhi, India)
  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeMap();
    
    // Open history dialog if requested, but only after vehicles are loaded
    if (widget.openHistoryDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Load initial GPS data first, then show history dialog
          _loadInitialGPSData().then((_) {
            if (mounted) {
              _showHistoryPlaybackDialog();
            }
          }).catchError((error) {
            if (mounted) {
              // Even if loading fails, still try to show the dialog
              // as there might be cached data or the user might want to retry
              _showHistoryPlaybackDialog();
            }
          });
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      final vehicleTypeString = await _settingsService.getVehicleType();
      final updateIntervalSeconds = await _settingsService.getUpdateInterval();

      setState(() {
        _selectedVehicleType = VehicleType.values.firstWhere(
          (type) => type.toString().split('.').last == vehicleTypeString,
          orElse: () => VehicleType.yellowCar,
        );
        _updateInterval = Duration(seconds: updateIntervalSeconds);
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // Use default values if loading fails
    }
  }

  @override
  void dispose() {
    _gpsService.stopRealTimeTracking();
    _historyPlaybackTimer?.cancel();
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      debugPrint('🚀 Starting map initialization...');

      if (!mounted) {
        debugPrint('⚠️ Widget disposed before map initialization');
        return;
      }

      // Load marker icon first (lightweight)
      _customMarkerIcon = await _loadCustomMarkerIcon();

      if (!mounted) return;

      // Get current location (can be slow and may fail)
      await _getCurrentLocation();

      if (!mounted) return;

      // Load initial GPS data
      await _loadInitialGPSData();

      if (!mounted) return;

      debugPrint('✅ Map initialization completed');

      // Don't auto-start tracking - let user manually start tracking
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error initializing map: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<BitmapDescriptor> _loadCustomMarkerIcon() async {
    try {
      const String assetPath = 'lib/providers/gps-navigation.png';
      
      // Try to load from assets first
      try {
        final ImageConfiguration config = const ImageConfiguration();
        final ImageStream stream =
            AssetImage(assetPath).resolve(config);

        final Completer<BitmapDescriptor> completer = Completer();

        stream.addListener(ImageStreamListener(
          (ImageInfo image, bool _) async {
            try {
              final ui.Image markerImage = image.image;
              const int width = 90;
              const int height = 90;

              final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
              final Canvas canvas = Canvas(pictureRecorder);

              // Draw the image scaled to the desired size
              canvas.drawImageRect(
                markerImage,
                Rect.fromLTWH(0, 0, markerImage.width.toDouble(),
                    markerImage.height.toDouble()),
                Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
                Paint()..filterQuality = FilterQuality.high,
              );

              final ui.Picture picture = pictureRecorder.endRecording();
              final ui.Image img = await picture.toImage(width, height);
              final ByteData? byteData =
                  await img.toByteData(format: ui.ImageByteFormat.png);

              if (byteData != null) {
                final Uint8List uint8List = byteData.buffer.asUint8List();
                final BitmapDescriptor bitmap =
                    await BitmapDescriptor.fromBytes(uint8List);
                _customMarkerIcon = bitmap;
                debugPrint('✅ Custom GPS navigation icon loaded successfully from assets');
                if (!completer.isCompleted) {
                  completer.complete(bitmap);
                }
              } else {
                throw Exception('Failed to convert image to bytes');
              }
            } catch (e) {
              debugPrint('Error processing image: $e');
              if (!completer.isCompleted) {
                completer.complete(BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
              }
            }
          },
          onError: (Object error, StackTrace? stackTrace) {
            debugPrint('Error loading image from assets: $error');
            if (!completer.isCompleted) {
              completer.complete(BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
            }
          },
        ));

        return completer.future;
      } catch (e) {
        debugPrint('Asset loading failed, falling back to colored default marker: $e');
        // Fallback to green colored marker
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      }
    } catch (e) {
      debugPrint('Failed to load custom marker icon: $e');
      // Final fallback to basic default marker
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      debugPrint('🔍 Checking location services...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        throw Exception('Location services are disabled');
      }

      debugPrint('🔐 Checking location permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('🔐 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions denied by user');
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions permanently denied');
        throw Exception('Location permissions are permanently denied');
      }

      debugPrint('📍 Getting current position...');

      // Add timeout to prevent hanging
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏰ Location request timed out');
          throw Exception('Location request timed out');
        },
      );

      debugPrint(
          '✅ Got current position: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      // Don't rethrow - let the app continue without current location
    }
  }

  Future<void> _loadInitialGPSData() async {
    try {
      debugPrint('🌐 Fetching initial GPS data...');
      final locations = await _gpsService.fetchGPSData().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏰ GPS data fetch timed out');
          throw Exception('GPS data fetch timed out');
        },
      );

      if (!mounted) return;

      debugPrint(
          '✅ GPS data fetch completed, got ${locations.length} locations');
      
      // Store available vehicles for dropdown
      _availableVehicles = locations;
      
      // Initialize with 'all' to show all vehicles by default
      if (_selectedVehicleId == null) {
        _selectedVehicleId = 'all';
      }
      
      await _updateMarkersFromGPSData(locations);

      if (mounted) {
        setState(() {
          _gpsLocations = locations;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load GPS data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load GPS data: $e';
        });
      }
    }
  }

  Future<void> _updateMarkersFromGPSData(
      List<GPSLocationData> locations) async {
    debugPrint('🗺️ Updating markers from ${locations.length} GPS locations');
    final Set<Marker> newMarkers = {};

    // Add current location marker if available
    if (_currentPosition != null) {
      debugPrint(
          '📍 Adding current position marker at ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
        ),
      );
    }

    // Filter locations based on selected vehicle (if any)
    final locationsToShow =
        _selectedVehicleId == null || _selectedVehicleId == 'all'
            ? locations // Show all vehicles
            : locations
                .where((loc) => loc.vehicleId == _selectedVehicleId)
                .toList();

    debugPrint(
        '🚗 Creating markers for ${locationsToShow.length} vehicles to show');

    // Process GPS tracking markers with proximity grouping to prevent overlapping
    final List<Future<Marker>> markerFutures = [];
    final List<LatLng> markerPositions = []; // Collect positions for bounds calculation
    
    if (_selectedVehicleId == null || _selectedVehicleId == 'all') {
      // When showing all vehicles, show each at exact location with same icon
      for (final location in locationsToShow) {
        final markerPosition = LatLng(location.latitude, location.longitude);
        markerPositions.add(markerPosition);
        debugPrint(
            '🚗 Adding GPS vehicle marker: ${location.vehicleId} (${location.id}) at exact position ${location.latitude}, ${location.longitude}');
        markerFutures.add(_createVehicleMarker(location));
      }
    } else {
      // When tracking single vehicle, group by proximity to avoid overlap
      final groupedLocations = _groupLocationsByProximity(locationsToShow);

      // Create markers with offset for overlapping locations
      for (final group in groupedLocations) {
        for (int i = 0; i < group.length; i++) {
          final location = group[i];
          final offset = _calculateOffsetForGroupIndex(i, group.length);
          final markerPosition = LatLng(location.latitude + offset.latitude, location.longitude + offset.longitude);
          markerPositions.add(markerPosition);
          debugPrint(
              '🚗 Adding GPS vehicle marker: ${location.vehicleId} (${location.id}) at ${location.latitude}, ${location.longitude} with offset $offset -> final position $markerPosition');

          // Only pass offset if it's not zero
          if (offset.latitude == 0 && offset.longitude == 0) {
            markerFutures.add(_createVehicleMarker(location));
          } else {
            markerFutures.add(_createVehicleMarkerWithOffset(location, offset));
          }
        }
      }
    }
    
    // Calculate bounds based on final marker positions
    LatLngBounds? bounds;
    if (markerPositions.isNotEmpty) {
      double minLat = markerPositions.first.latitude;
      double maxLat = markerPositions.first.latitude;
      double minLng = markerPositions.first.longitude;
      double maxLng = markerPositions.first.longitude;

      for (final pos in markerPositions) {
        if (pos.latitude < minLat) minLat = pos.latitude;
        if (pos.latitude > maxLat) maxLat = pos.latitude;
        if (pos.longitude < minLng) minLng = pos.longitude;
        if (pos.longitude > maxLng) maxLng = pos.longitude;
      }

      // Add appropriate padding based on the geographic spread
      double padding = 0.001; // Default small padding
      final latSpread = maxLat - minLat;
      final lngSpread = maxLng - minLng;
      final maxSpread = math.max(latSpread, lngSpread);

      // Use dynamic padding based on the spread of markers
      if (maxSpread > 10) {
        padding = 0.5; // Large spread across states/countries
      } else if (maxSpread > 1) {
        padding = 0.1; // Medium spread across cities
      } else if (maxSpread > 0.01) {
        padding = 0.01; // Small spread within a city
      }

      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      _currentBounds = bounds; // Store for map centering
      debugPrint('🎯 Calculated bounds from marker positions: SW($minLat, $minLng) NE($maxLat, $maxLng) with padding $padding');
    } else {
      _currentBounds = null;
    }

    // Wait for all markers to be created in parallel
    if (markerFutures.isNotEmpty) {
      try {
        final markers = await Future.wait(markerFutures);
        newMarkers.addAll(markers);
      } catch (e) {
        debugPrint('Error creating vehicle markers: $e');
        // Fallback to simple markers
        for (final location in locations) {
          newMarkers.add(
            Marker(
              markerId: MarkerId(location.id),
              position: LatLng(location.latitude, location.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: location.vehicleId ?? 'Vehicle ${location.id}',
                snippet:
                    '${location.address ?? 'Unknown location'}\nSpeed: ${location.speed?.toStringAsFixed(1) ?? 'N/A'} km/h',
              ),
            ),
          );
        }
      }
    }

    debugPrint('🎯 Total markers created: ${newMarkers.length}');

    // Update markers only once after all are created
    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });

      // Only auto-center on GPS locations if user isn't tracking their own location
      if (!_isTrackingUserLocation) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_isTrackingUserLocation) {
            _centerMapOnGPSLocations();
          }
        });
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _toggleTracking() {
    if (_isTracking) {
      debugPrint('⏹️ Stopping GPS tracking...');
      _gpsService.stopRealTimeTracking();
      setState(() {
        _isTracking = false;
      });
      debugPrint(
          '✅ Tracking status set to INACTIVE (_isTracking: $_isTracking)');
    } else {
      _startTracking();
    }
  }

  void _startTracking() {
    debugPrint('🚀 Starting GPS tracking...');
    _gpsService.startRealTimeTracking(
      onLocationUpdate: (locations) {
        debugPrint(
            '📡 Received ${locations.length} GPS locations in real-time update');
        _updateMarkersFromGPSData(locations);
        setState(() {
          _gpsLocations = locations;
          _errorMessage = null;
        });
      },
      onError: (error) {
        debugPrint('❌ GPS tracking error: $error');
        setState(() {
          _errorMessage = error;
        });
      },
      interval: _updateInterval,
    );
    setState(() {
      _isTracking = true;
    });
    debugPrint(
        '✅ Tracking status set to ACTIVE (_isTracking: $_isTracking, service.isTracking: ${_gpsService.isTracking})');
  }

  void _onMapCreated(GoogleMapController controller) {
    if (_mapController != null) {
      debugPrint('⚠️ Map controller already exists, disposing old one');
      _mapController?.dispose();
    }
    _mapController = controller;
    _isMapReady = true;
    _centerMapOnGPSLocations();
  }

  // Robust camera control method with retry mechanism
  Future<void> _centerMapOnLocation(
      LatLng location, double zoom, String description) async {
    if (_mapController == null || !_isMapReady) {
      debugPrint('⚠️ Map not ready, cannot center on $description');
      return;
    }

    debugPrint(
        '🎯 Centering map on $description at ${location.latitude}, ${location.longitude}');

    // Reduced retries and optimized delays
    const maxRetries = 2;
    const delays = [200, 500]; // milliseconds

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (!mounted || _mapController == null || !_isMapReady) {
          debugPrint('⚠️ Widget disposed or map not ready during animation');
          return;
        }

        await Future.delayed(Duration(milliseconds: delays[attempt]));

        if (!mounted || _mapController == null) return;

        // Try animateCamera first
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, zoom),
        ).timeout(const Duration(seconds: 3));
        debugPrint('✅ Successfully animated camera to $description');
        return;
      } catch (e) {
        if (!e.toString().contains('channel-error') && attempt == maxRetries - 1) {
          debugPrint('⚠️ Camera animation failed for $description: $e');
        }
        
        // Try moveCamera as fallback only on last attempt
        if (attempt == maxRetries - 1) {
          try {
            if (mounted && _mapController != null) {
              await _mapController!.moveCamera(
                CameraUpdate.newLatLngZoom(location, zoom),
              ).timeout(const Duration(seconds: 2));
              debugPrint('✅ Successfully moved camera to $description');
              return;
            }
          } catch (moveError) {
            // Silently fail - don't spam logs
          }
        }
      }
    }
  }

  Future<void> _centerMapOnGPSLocations() async {
    if (_mapController == null) return;

    LatLng targetLocation = _defaultLocation;
    double zoom = 15.0;

    // Priority: Selected vehicle > GPS locations > Current position > Default location
    if (_gpsLocations.isNotEmpty) {
      // If a specific vehicle is selected, center on that vehicle
      if (_selectedVehicleId != null && _selectedVehicleId != 'all') {
        final selectedVehicle = _gpsLocations.firstWhere(
          (location) => location.vehicleId == _selectedVehicleId,
          orElse: () => _gpsLocations.first,
        );
        targetLocation =
            LatLng(selectedVehicle.latitude, selectedVehicle.longitude);
        debugPrint(
            '🎯 Centering map on SELECTED vehicle: ${selectedVehicle.vehicleId} at ${targetLocation.latitude}, ${targetLocation.longitude}');
        zoom = 16.0; // Zoom closer for selected vehicle
        await _centerMapOnLocation(
          targetLocation, zoom, 'selected vehicle ${selectedVehicle.vehicleId}');
      } else {
        // Show all vehicles - use dedicated method
        await _fitAllVehicles();
      }
    } else if (_currentPosition != null) {
      targetLocation =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      await _centerMapOnLocation(targetLocation, zoom, 'current position');
    } else {
      await _centerMapOnLocation(targetLocation, zoom, 'default location');
    }
  }

  /// Fit all vehicles in the map view
  Future<void> _fitAllVehicles() async {
    debugPrint('🗺️ _fitAllVehicles called');
    debugPrint('🗺️ Map controller: ${_mapController != null ? "EXISTS" : "NULL"}');
    debugPrint('🗺️ GPS locations count: ${_gpsLocations.length}');
    
    if (_mapController == null || !_isMapReady) {
      debugPrint('❌ Cannot fit vehicles: Map not ready');
      return;
    }
    
    // Reduced wait time
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted || _mapController == null) {
      debugPrint('❌ Map controller became null during wait');
      return;
    }
    
    if (_gpsLocations.isEmpty) {
      debugPrint('❌ Cannot fit vehicles: No GPS locations available');
      return;
    }
    
    if (_gpsLocations.length == 1) {
      debugPrint('⚠️ Only 1 vehicle - centering on it instead of fitting bounds');
      final vehicle = _gpsLocations.first;
      await _centerMapOnLocation(
        LatLng(vehicle.latitude, vehicle.longitude),
        16.0,
        'single vehicle ${vehicle.vehicleId}',
      );
      return;
    }

    debugPrint('🗺️ Fitting map to show all ${_gpsLocations.length} vehicles');

    // Calculate bounds from all vehicle locations
    double minLat = _gpsLocations.first.latitude;
    double maxLat = _gpsLocations.first.latitude;
    double minLng = _gpsLocations.first.longitude;
    double maxLng = _gpsLocations.first.longitude;

    for (final location in _gpsLocations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    // Add dynamic padding based on spread
    final latSpread = maxLat - minLat;
    final lngSpread = maxLng - minLng;
    final maxSpread = math.max(latSpread, lngSpread);

    double padding;
    if (maxSpread > 10) {
      padding = 0.5; // Large spread
    } else if (maxSpread > 1) {
      padding = 0.1; // Medium spread
    } else if (maxSpread > 0.01) {
      padding = 0.01; // Small spread
    } else {
      padding = 0.005; // Very small spread (vehicles close together)
    }

    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    debugPrint('🎯 Calculated bounds: SW($minLat, $minLng) NE($maxLat, $maxLng)');
    debugPrint('🎯 Padding applied: $padding degrees');

    try {
      // Use moveCamera for immediate effect, then animate
      await _mapController!.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, 80.0), // 80px padding from edges
      );
      debugPrint('✅ Successfully fit all vehicles in view');
    } catch (e) {
      debugPrint('⚠️ Error fitting bounds: $e');
      // Fallback: center on middle of all vehicles with appropriate zoom
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final centerLocation = LatLng(centerLat, centerLng);
      
      // Calculate appropriate zoom level based on spread
      double zoom;
      if (maxSpread > 5) {
        zoom = 6.0;
      } else if (maxSpread > 1) {
        zoom = 10.0;
      } else if (maxSpread > 0.1) {
        zoom = 12.0;
      } else {
        zoom = 14.0;
      }
      
      await _centerMapOnLocation(centerLocation, zoom, 'all vehicles center (fallback)');
    }
  }

  // Add a method to explicitly center on selected vehicle when user chooses
  Future<void> _centerMapOnSelectedVehicle() async {
    debugPrint('🎯 _centerMapOnSelectedVehicle called');
    debugPrint('🎯 Selected vehicle ID: $_selectedVehicleId');
    debugPrint('🎯 GPS locations count: ${_gpsLocations.length}');
    
    if (_mapController == null || _gpsLocations.isEmpty) {
      debugPrint('❌ Cannot center: map controller or GPS locations missing');
      return;
    }

    if (_selectedVehicleId != null && _selectedVehicleId != 'all') {
      debugPrint('🚗 Centering on single vehicle: $_selectedVehicleId');
      final selectedVehicle = _gpsLocations.firstWhere(
        (v) => v.vehicleId == _selectedVehicleId,
        orElse: () => _gpsLocations.first,
      );
      await _centerMapOnLocation(
          LatLng(selectedVehicle.latitude, selectedVehicle.longitude),
          16.0,
          'selected vehicle ${selectedVehicle.vehicleId}');
    } else {
      // Show all vehicles with appropriate zoom
      debugPrint('🗺️ Showing ALL vehicles - calling _fitAllVehicles()');
      await _fitAllVehicles();
    }
  }

  // Track user's current location
  Future<void> _trackMyLocation() async {
    try {
      debugPrint('📍 Getting current location for tracking...');

      // No loading feedback popup - silent operation

      await _getCurrentLocation();

      if (_currentPosition != null && _mapController != null) {
        final currentLatLng =
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

        // Set flag to prevent auto-centering on vehicle
        setState(() {
          _isTrackingUserLocation = true;
        });

        // Immediately update state to show we have user location
        if (mounted) {
          setState(() {
            _currentPosition = Position(
              latitude: currentLatLng.latitude,
              longitude: currentLatLng.longitude,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: 0.0,
              headingAccuracy: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
            );
          });
        }

        // Update markers first to include current location
        await _updateMarkersFromGPSData(_gpsLocations);

        // Then center on user location with retry mechanism
        await _centerMapOnLocation(currentLatLng, 16.0, 'user location');

        // As a last resort, if camera fails, at least the marker should be visible
        debugPrint(
            '✅ User location marker added at ${currentLatLng.latitude}, ${currentLatLng.longitude}');
        debugPrint('🎯 Total markers now: ${_markers.length}');

        // Silent success - no popup notification
      }
    } catch (e) {
      debugPrint('❌ Error tracking location: $e');
      // Silent error handling - no popup, just debug log
    }
  }

  Future<Marker> _createVehicleMarker(GPSLocationData location) async {
    return _createVehicleMarkerWithOffset(location, const LatLng(0, 0));
  }

  Future<Marker> _createVehicleMarkerWithOffset(GPSLocationData location, LatLng offset) async {
    debugPrint('🎨 Creating marker for ${location.vehicleId} (${location.id})');
    
    final vehicleState =
        CustomVehicleIcons.getStateFromPacketType(location.packetType);
    debugPrint('🔍 Vehicle state: $vehicleState');
    
    final effectiveVehicleType = await _getVehicleIcon(location.vehicleId ?? '');
    final customIcon = await CustomVehicleIcons.createVehicleIcon(
        effectiveVehicleType, vehicleState);
    debugPrint('🖼️ Custom icon created: ${customIcon != null}');
    
    final formattedTimestamp = _formatTimestamp(location.timestamp);
    debugPrint(
        '🕒 Timestamp for ${location.vehicleId}: ${location.timestamp} (formatted: $formattedTimestamp)');
    
    final infoWindowSnippet =
        'Speed: ${location.speed?.toStringAsFixed(1) ?? 'N/A'} km/h | Last Update: $formattedTimestamp';
    
    debugPrint('📍 InfoWindow for ${location.vehicleId}: $infoWindowSnippet');
    
    // Apply offset correctly by adding to original coordinates
    final LatLng position;
    if (offset.latitude != 0 || offset.longitude != 0) {
      position = LatLng(
        location.latitude + offset.latitude,
        location.longitude + offset.longitude,
      );
      debugPrint(
          '📍 Applied offset: Original(${location.latitude}, ${location.longitude}) + Offset(${offset.latitude}, ${offset.longitude}) = Final(${position.latitude}, ${position.longitude})');
    } else {
      position = LatLng(location.latitude, location.longitude);
      debugPrint(
          '📍 No offset applied: Final position: ${position.latitude}, ${position.longitude}');
    }
    
    // Dual icon system: Only rotate when tracking single vehicle, keep straight for "show all"
    final double rotation;
    if (_selectedVehicleId == null || _selectedVehicleId == 'all') {
      // When showing all vehicles, keep icons pointing north (no rotation)
      rotation = 0.0;
      debugPrint(
          '🧭 No rotation applied for ${location.vehicleId} (showing all vehicles)');
    } else {
      // When tracking single vehicle, apply directional rotation
      rotation = location.heading ?? 0.0;
      debugPrint(
          '🧭 Applied rotation ${rotation}° for ${location.vehicleId} (single vehicle tracking)');
    }
    
    final marker = Marker(
      markerId: MarkerId(location.id),
      position: position,
      icon: customIcon,
      infoWindow: InfoWindow(
        title: location.vehicleId ?? 'Vehicle ${location.id}',
        snippet: infoWindowSnippet,
        onTap: () {
          debugPrint('🖱️ InfoWindow tapped for ${location.vehicleId}');
          debugPrint('📅 Timestamp: $formattedTimestamp');
        },
      ),
      rotation: rotation,
      onTap: () {
        debugPrint(
            '🚗 Marker tapped for ${location.vehicleId} at ${location.latitude}, ${location.longitude}');
        debugPrint('📅 Timestamp: $formattedTimestamp');
      },
    );
    
    debugPrint('✅ Marker created successfully for ${location.vehicleId}');
    return marker;
  }

  String _getIntervalText(Duration interval) {
    if (interval.inSeconds < 60) {
      return '${interval.inSeconds} seconds';
    } else if (interval.inMinutes < 60) {
      return '${interval.inMinutes} minute${interval.inMinutes == 1 ? '' : 's'}';
    } else {
      return '${interval.inHours} hour${interval.inHours == 1 ? '' : 's'}';
    }
  }

  void _showVehicleSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.directions_car,
                  color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text('Select Vehicle Type'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: VehicleType.values.map((type) {
              return RadioListTile<VehicleType>(
                title: Text(_getVehicleTypeName(type)),
                value: type,
                groupValue: _selectedVehicleType,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (VehicleType? value) {
                  if (value != null) {
                    if (_selectedVehicleId != null && _selectedVehicleId != 'all') {
                      // Save for specific vehicle
                      _setVehicleIcon(_selectedVehicleId!, value);
                    } else {
                      // Save globally
                      setState(() {
                        _selectedVehicleType = value;
                      });
                      _saveVehicleTypeToSettings(value);
                    }
                    Navigator.of(context).pop();
                    _updateMarkersWithNewVehicleType();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showUpdateIntervalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.timer,
                  color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text('Update Interval'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableIntervals.map((interval) {
              return RadioListTile<Duration>(
                title: Text(_formatDuration(interval)),
                value: interval,
                groupValue: _updateInterval,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (Duration? value) {
                  if (value != null) {
                    setState(() {
                      _updateInterval = value;
                    });
                    Navigator.of(context).pop();
                    _saveUpdateIntervalToSettings(value);
                    _restartTrackingWithNewInterval();
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _getVehicleTypeName(VehicleType type) {
    switch (type) {
      case VehicleType.yellowCar:
        return 'Yellow Car';
      case VehicleType.blueCar:
        return 'Blue Car';
      case VehicleType.brownTruck:
        return 'Brown Truck';
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.bus:
        return 'Bus';
    }
  }

  Future<void> _saveVehicleTypeToSettings(VehicleType type) async {
    await _settingsService.setVehicleType(type.toString().split('.').last);
  }

  Future<void> _updateMarkersWithNewVehicleType() async {
    if (_gpsLocations.isNotEmpty) {
      debugPrint(
          '🔄 Updating markers with new vehicle type: $_selectedVehicleType');
      _updateMarkersFromGPSData(_gpsLocations);

      // Show confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Vehicle type changed to ${_getVehicleTypeName(_selectedVehicleType)}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 160, left: 16, right: 16),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} seconds';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    }
  }

  Future<void> _saveUpdateIntervalToSettings(Duration interval) async {
    await _settingsService.setUpdateInterval(interval.inSeconds);
  }

  Future<void> _restartTrackingWithNewInterval() async {
    if (_isTracking) {
      debugPrint(
          '🔄 Restarting tracking with new interval: ${_getIntervalText(_updateInterval)}');
      _gpsService.stopRealTimeTracking();
      setState(() {
        _isTracking = false;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      _startTracking();
      // No popup notification - silent update
    } else {
      // Update interval for next tracking session - silent
      debugPrint(
          '🔄 Update interval set to: ${_getIntervalText(_updateInterval)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Tracking',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _showHistoryPlaybackDialog(),
            tooltip: 'History Playback',
          ),
          IconButton(
            icon: const Icon(Icons.directions_car, color: Colors.white),
            onPressed: _showVehicleSelectionDialog,
            tooltip: 'Vehicle Type',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showUpdateIntervalDialog,
            tooltip: 'Update Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialGPSData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Vehicle Selection Dropdown at the top
          if (_availableVehicles.isNotEmpty) _buildVehicleSelectionBar(theme),
          // Map takes the remaining space
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget(theme)
                : _errorMessage != null
                    ? _buildErrorWidget(theme)
                    : Stack(
                        children: [
                          _buildSafeMapWidget(theme),
                          // Track My Location button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: FloatingActionButton.small(
                              heroTag: "track_my_location",
                              onPressed: _trackMyLocation,
                              backgroundColor: Colors.white,
                              foregroundColor: theme.colorScheme.primary,
                              elevation: 6,
                              child: const Icon(
                                Icons.my_location,
                                size: 20,
                              ),
                            ),
                          ),
                          // Show All Vehicles button
                          if (_gpsLocations.length > 1)
                            Positioned(
                              top: 72,
                              right: 16,
                              child: FloatingActionButton.small(
                                heroTag: "show_all_vehicles",
                                onPressed: _fitAllVehicles,
                                backgroundColor: Colors.white,
                                foregroundColor: theme.colorScheme.secondary,
                                elevation: 6,
                                tooltip: 'Show All Vehicles',
                                child: const Icon(
                                  Icons.zoom_out_map,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
      bottomSheet: _isHistoryMode ? _buildHistoryBottomSheet(theme) : _buildBottomSheet(theme),
    );
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading GPS tracking data...',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Map',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              _initializeMap();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeMapWidget(ThemeData theme) {
    // Use RepaintBoundary to isolate map rendering from parent rebuilds
    // This prevents the map from being recreated on every widget tree rebuild
    return RepaintBoundary(
      child: _buildMapWidget(theme),
    );
  }

  Widget _buildMapWidget(ThemeData theme) {
    try {
      return GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          try {
            debugPrint('🗺️ Google Map created successfully');
            _onMapCreated(controller);
          } catch (e) {
            debugPrint('❌ Error in map created callback: $e');
          }
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : _gpsLocations.isNotEmpty
                  ? LatLng(_gpsLocations.first.latitude,
                      _gpsLocations.first.longitude)
                  : _defaultLocation,
          zoom: 15.0,
        ),
        markers: _markers,
        // Enable location features now that we have proper error handling
        myLocationEnabled: true,
        myLocationButtonEnabled: false, // We have our custom button
        mapType: MapType.normal,
        compassEnabled: true,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        tiltGesturesEnabled: true,
        zoomGesturesEnabled: true,
        zoomControlsEnabled: false,
        // Add error handling for gestures
        onTap: (LatLng position) {
          debugPrint(
              '👆 Map tapped at: ${position.latitude}, ${position.longitude}');
        },
      );
    } catch (e) {
      debugPrint('❌ Error creating Google Map widget: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Map Failed to Load',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $e',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeMap();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  void _showHistoryPlaybackDialog() {
    // Ensure we have vehicle data before showing the dialog
    if (_availableVehicles.isEmpty) {
      // Load vehicle data first if not available
      _loadInitialGPSData().then((_) {
        if (mounted && _availableVehicles.isNotEmpty) {
          // Now show the dialog with updated vehicle data
          _showHistoryPlaybackDialogWithVehicles();
        } else if (mounted) {
          // Show error if still no vehicles
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No vehicles available for history playback'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading vehicles: $error'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } else {
      // Show dialog immediately if vehicles are already loaded
      _showHistoryPlaybackDialogWithVehicles();
    }
  }

  void _showHistoryPlaybackDialogWithVehicles() {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 1));
    DateTime endDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 59);
    String? selectedVehicle = _availableVehicles.isNotEmpty
        ? _availableVehicles.first.vehicleId
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.history, color: Color(0xFFFFD700), size: 24),
                  SizedBox(width: 12),
                  Text('History Playback'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Selection
                    const Text(
                      'Select Vehicle:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedVehicle,
                          isExpanded: true,
                          items: _availableVehicles.map((vehicle) {
                            return DropdownMenuItem<String>(
                              value: vehicle.vehicleId,
                              child: Text(
                                vehicle.vehicleId ?? 'Unknown Vehicle',
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedVehicle = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Date
                    const Text(
                      'Start Date:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${startDate.day}/${startDate.month}/${startDate.year}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Start Time
                    const Text(
                      'Start Time:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (picked != null) {
                          setState(() {
                            startTime = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Date
                    const Text(
                      'End Date:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${endDate.day}/${endDate.month}/${endDate.year}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // End Time
                    const Text(
                      'End Time:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (picked != null) {
                          setState(() {
                            endTime = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedVehicle != null
                      ? () {
                          Navigator.of(context).pop();
                          _loadHistoryData(
                            startDate: DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute),
                            endDate: DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute),
                            vehicleId: selectedVehicle!,
                          );
                        }
                      : null,
                  child: const Text('Load History'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadHistoryData({
    required DateTime startDate,
    required DateTime endDate,
    required String vehicleId,
  }) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Format dates for API (YYYY-MM-DD format)
      final startDateStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      debugPrint('🔄 Loading history data for vehicle: $vehicleId');
      debugPrint('📅 Date range: $startDateStr to $endDateStr');

      final historyData = await _gpsService.fetchGPSHistoryData(
        startDateTime: startDateStr,
        endDateTime: endDateStr,
        vehicleRegistrationNumber: vehicleId,
      );

      if (historyData.isNotEmpty) {
        setState(() {
          _isHistoryMode = true;
          _historyData = historyData;
          _currentHistoryIndex = 0;
          _historyStartDate = startDate;
          _historyEndDate = endDate;
          _historyVehicleId = vehicleId;
          _isLoading = false;

          // Stop live tracking when entering history mode
          if (_isTracking) {
            _gpsService.stopRealTimeTracking();
            _isTracking = false;
          }
        });

        // Show initial history point
        await _showHistoryPoint(_currentHistoryIndex);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Loaded ${historyData.length} history points for $vehicleId'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No history data found for the selected period';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'No history data found for $vehicleId in the selected period'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load history data: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  Future<void> _showHistoryPoint(int index) async {
    if (_historyData.isEmpty || index < 0 || index >= _historyData.length) {
      debugPrint('❌ Cannot show history point: index=$index, dataLength=${_historyData.length}');
      return;
    }

    debugPrint('📍 Showing history point $index of ${_historyData.length}');
    final historyPoint = _historyData[index];
    debugPrint('🚗 History point: ${historyPoint.vehicleId} at (${historyPoint.latitude}, ${historyPoint.longitude})');
    debugPrint('🕒 Timestamp: ${historyPoint.timestamp}');
    
    final Set<Marker> newMarkers = {};

    // Add current location marker if available
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
        ),
      );
      debugPrint('📍 Added current location marker');
    }

    // Create marker for history point
    debugPrint('🎨 Creating history marker...');
    final historyMarker = await _createVehicleMarker(historyPoint);
    newMarkers.add(historyMarker);
    debugPrint('✅ History marker created, total markers: ${newMarkers.length}');

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _currentHistoryIndex = index;
      });
      debugPrint('✅ State updated with new markers');
    }

    // Center map on history point
    debugPrint('🎯 Centering map on history point...');
    await _centerMapOnLocation(
        LatLng(historyPoint.latitude, historyPoint.longitude),
        16.0,
        'history point ${index + 1}');
    debugPrint('✅ History point $index displayed successfully');
  }

  void _startHistoryPlayback() {
    if (_historyData.isEmpty) {
      debugPrint('❌ Cannot start playback: No history data');
      return;
    }

    debugPrint('▶️ Starting history playback with ${_historyData.length} points');
    debugPrint('📍 Current index: $_currentHistoryIndex');
    
    _historyPlaybackTimer?.cancel();
    _historyPlaybackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      debugPrint('⏱️ Playback timer tick - current index: $_currentHistoryIndex');
      
      if (_currentHistoryIndex < _historyData.length - 1) {
        debugPrint('➡️ Moving to next point: ${_currentHistoryIndex + 1}');
        _showHistoryPoint(_currentHistoryIndex + 1);
      } else {
        debugPrint('🏁 Playback reached end');
        _stopHistoryPlayback();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('History playback completed'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    });

    setState(() {
      _isPlayingHistory = true;
    });
    debugPrint('✅ Playback started, timer active: ${_historyPlaybackTimer?.isActive}');
  }

  void _stopHistoryPlayback() {
    _historyPlaybackTimer?.cancel();
    setState(() {
      _isPlayingHistory = false;
    });
  }

  void _exitHistoryMode() {
    _stopHistoryPlayback();
    setState(() {
      _isHistoryMode = false;
      _historyData.clear();
      _currentHistoryIndex = 0;
      _historyStartDate = null;
      _historyEndDate = null;
      _historyVehicleId = null;
    });

    // Reload live data
    _loadInitialGPSData();
  }

  Widget _buildVehicleSelectionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.car_rental,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Select Vehicle to Track:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedVehicleId ?? 'all',
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down,
                    color: theme.colorScheme.primary),
                style: theme.textTheme.bodyMedium,
                items: [
                  DropdownMenuItem<String>(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.all_inclusive,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Show All Vehicles (${_availableVehicles.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._availableVehicles.map((vehicle) {
                    return DropdownMenuItem<String>(
                      value: vehicle.vehicleId ?? 'unknown_${vehicle.id}',
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  vehicle.vehicleId ?? 'Unknown Vehicle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'Speed: ${vehicle.speed?.toStringAsFixed(0) ?? '0'} km/h • ${vehicle.packetType ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) async {
                  debugPrint('🔽 Dropdown changed to: $newValue');
                  
                  setState(() {
                    _selectedVehicleId = newValue;
                  });

                  // Update markers to show only selected vehicle
                  await _updateMarkersFromGPSData(_gpsLocations);
                  debugPrint('✅ Markers updated');

                  // Center map on selected vehicle AFTER markers are updated
                  await Future.delayed(const Duration(milliseconds: 300));
                  debugPrint('🎯 Calling _centerMapOnSelectedVehicle()');
                  await _centerMapOnSelectedVehicle();

                  // Show feedback
                  if (newValue != null && newValue != 'all') {
                    final selectedVehicle = _availableVehicles.firstWhere(
                      (v) => (v.vehicleId ?? 'unknown_${v.id}') == newValue,
                      orElse: () => _availableVehicles.first,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Now tracking: ${selectedVehicle.vehicleId}'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.fixed,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Now showing all ${_availableVehicles.length} vehicles'),
                          backgroundColor: Colors.blue,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.fixed,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(ThemeData theme) {
    // Debug: Log current tracking state
    debugPrint(
        '🔍 Bottom sheet rebuild - _isTracking: $_isTracking, GPS service isTracking: ${_gpsService.isTracking}');

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with tracking status and vehicle button
          Flexible(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - GPS icon and tracking info
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.gps_fixed,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Update interval text in small green
                          Text(
                            'Updates every ${_getIntervalText(_updateInterval)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.lightGreenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Live Tracking title
                          Text(
                            'Live Tracking',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          // Vehicle selection info
                          Text(
                            _selectedVehicleId == null || _selectedVehicleId == 'all'
                                ? '${_gpsLocations.length} vehicle${_gpsLocations.length == 1 ? '' : 's'} visible'
                                : 'Tracking: $_selectedVehicleId',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right side - Large Track Vehicle Button
                if (_gpsLocations.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isTrackingUserLocation = false;
                      });
                      _centerMapOnGPSLocations();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.track_changes,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                  'Tracking ${_gpsLocations.first.vehicleId ?? 'vehicle'}'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: theme.colorScheme.primary,
                          margin: const EdgeInsets.only(
                              bottom: 220, left: 16, right: 16),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.25),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.gps_fixed, size: 18),
                    label: const Text(
                      'Track Vehicle',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          // Vehicle information row with status
          if (_gpsLocations.isNotEmpty)
            Flexible(
              flex: 1,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_gpsLocations.first.vehicleId ?? 'Vehicle'} • ${_gpsLocations.first.speed?.toStringAsFixed(1) ?? '0.0'} km/h',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status indicator aligned with vehicle info
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isTracking ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isTracking ? 'ACTIVE' : 'INACTIVE',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // Control buttons row
          Flexible(
            flex: 1,
            child: Row(
              children: [
                // Start/Stop tracking button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _toggleTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking
                            ? Colors.red.withOpacity(0.9)
                            : Colors.green.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      icon: Icon(
                        _isTracking ? Icons.stop : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(
                        _isTracking ? 'Stop Tracking' : 'Start Tracking',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryBottomSheet(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 180,
        minHeight: 140,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Header row with history mode status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, size: 24, color: Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  Text(
                    'History Playback',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _exitHistoryMode,
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Exit History Mode',
              ),
            ],
          ),
          const SizedBox(height: 4),

          // History info
          if (_historyData.isNotEmpty) ...[
            Text(
              'Vehicle: $_historyVehicleId • ${_historyData.length} points',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Point ${_currentHistoryIndex + 1} of ${_historyData.length} • ${_formatTimestamp(_historyData[_currentHistoryIndex].timestamp)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Playback controls
            Row(
              children: [
                // Previous button
                IconButton(
                  onPressed: _currentHistoryIndex > 0
                      ? () {
                          _showHistoryPoint(_currentHistoryIndex - 1);
                        }
                      : null,
                  icon: const Icon(Icons.skip_previous, size: 20),
                  tooltip: 'Previous Point',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),

                // Play/Pause button
                IconButton(
                  onPressed: () {
                    if (_isPlayingHistory) {
                      _stopHistoryPlayback();
                    } else {
                      _startHistoryPlayback();
                    }
                  },
                  icon: Icon(
                    _isPlayingHistory ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  tooltip: _isPlayingHistory ? 'Pause' : 'Play',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),

                // Next button
                IconButton(
                  onPressed: _currentHistoryIndex < _historyData.length - 1
                      ? () {
                          _showHistoryPoint(_currentHistoryIndex + 1);
                        }
                      : null,
                  icon: const Icon(Icons.skip_next, size: 20),
                  tooltip: 'Next Point',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(width: 12),

                // Progress indicator
                Expanded(
                  child: LinearProgressIndicator(
                    value: _historyData.isNotEmpty
                        ? (_currentHistoryIndex + 1) / _historyData.length
                        : 0,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                ),
              ],
            ),
          ],
          ],  // Close children list
        ),
      ),
    );
  }

  /// Group locations that are within close proximity to avoid overlapping markers
  List<List<GPSLocationData>> _groupLocationsByProximity(
      List<GPSLocationData> locations) {
    final groups = <List<GPSLocationData>>[];
    const double proximityThreshold = 0.001; // ~100 meters

    for (final location in locations) {
      bool addedToGroup = false;

      for (final group in groups) {
        final firstInGroup = group.first;
        final distance = _calculateDistance(location.latitude,
            location.longitude, firstInGroup.latitude, firstInGroup.longitude);

        if (distance < proximityThreshold) {
          group.add(location);
          addedToGroup = true;
          break;
        }
      }

      if (!addedToGroup) {
        groups.add([location]);
      }
    }

    debugPrint(
        '📍 Grouped ${locations.length} locations into ${groups.length} proximity groups');
    return groups;
  }

  /// Calculate distance between two coordinates in degrees
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat2 - lat1).abs();
    final dLon = (lon2 - lon1).abs();
    return dLat + dLon; // Simple approximation for grouping
  }

  /// Calculate offset for markers in the same group to avoid overlap
  LatLng _calculateOffsetForGroupIndex(int index, int groupSize) {
    if (groupSize == 1) return const LatLng(0, 0);

    // Spread markers in a small circle around the original position
    const double radius = 0.0005; // ~50 meters
    final angle = (index * 2 * 3.14159) / groupSize;

    final offsetLat = radius * math.sin(angle);
    final offsetLng = radius * math.cos(angle);

    return LatLng(offsetLat, offsetLng);
  }

  /// Calculate LatLngBounds that encompass all vehicle locations
  LatLngBounds? _getBoundsForVehicles(List<GPSLocationData> vehicles) {
    if (vehicles.isEmpty) return null;

    double minLat = vehicles.first.latitude;
    double maxLat = vehicles.first.latitude;
    double minLng = vehicles.first.longitude;
    double maxLng = vehicles.first.longitude;

    for (final vehicle in vehicles) {
      if (vehicle.latitude < minLat) minLat = vehicle.latitude;
      if (vehicle.latitude > maxLat) maxLat = vehicle.latitude;
      if (vehicle.longitude < minLng) minLng = vehicle.longitude;
      if (vehicle.longitude > maxLng) maxLng = vehicle.longitude;
    }

    // Add small padding to bounds
    const double padding = 0.001; // ~100 meters
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<VehicleType> _getVehicleIcon(String vehicleId) async {
    if (vehicleId.isEmpty) return _selectedVehicleType;
    final prefs = await SharedPreferences.getInstance();
    final iconString = prefs.getString('vehicle_icon_$vehicleId');
    if (iconString != null) {
      return VehicleType.values.firstWhere(
        (type) => type.toString().split('.').last == iconString,
        orElse: () => _selectedVehicleType,
      );
    }
    return _selectedVehicleType;
  }

  Future<void> _setVehicleIcon(String vehicleId, VehicleType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehicle_icon_$vehicleId', type.toString().split('.').last);
  }
}
