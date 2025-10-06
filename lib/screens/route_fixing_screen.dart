import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edisha/services/route_service.dart';
import 'package:edisha/services/gps_tracking_service.dart';
import 'package:edisha/services/device_service.dart';

/// Modern Route Fixing Screen - e-Disha 2025
/// Functionality from rapid_yatra, completely new UI design
class RouteFixingScreen extends StatefulWidget {
  final RouteData? existingRoute;
  final DeviceOwnerData? vehicle;

  const RouteFixingScreen({
    super.key,
    this.existingRoute,
    this.vehicle,
  });

  @override
  State<RouteFixingScreen> createState() => _RouteFixingScreenState();
}

class _RouteFixingScreenState extends State<RouteFixingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final RouteService _routeService = RouteService();
  final GPSTrackingService _gpsService = GPSTrackingService();
  final DeviceService _deviceService = DeviceService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  List<DeviceOwnerData> _availableDevices = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _selectedDeviceId;
  bool _showInstructions = true;

  late AnimationController _animationController;

  // Default location (New Delhi)
  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 RouteFixingScreen init');
    debugPrint('🚗 Passed vehicle: ${widget.vehicle?.vehicleRegNo ?? "NONE"}');
    debugPrint('📱 Passed device ID: ${widget.vehicle?.device.id ?? "NONE"}');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
    _initializeScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);
    try {
      await _loadAvailableDevices();
      if (widget.existingRoute != null) {
        _loadExistingRoute();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadExistingRoute() {
    final route = widget.existingRoute!;
    final vehicle = widget.vehicle;

    if (vehicle != null) {
      _selectedDeviceId = vehicle.device.id;
    }

    _routePoints = route.routePoints
        .map((point) => LatLng(point[1], point[0]))
        .toList();

    _markers.clear();
    for (int i = 0; i < _routePoints.length; i++) {
      final point = _routePoints[i];
      _markers.add(
        Marker(
          markerId: MarkerId('point_${i + 1}'),
          position: point,
          icon: _getMarkerIcon(i),
          infoWindow: InfoWindow(
            title: _getMarkerTitle(i),
            snippet: 'Tap to remove',
          ),
        ),
      );
    }

    if (_routePoints.length >= 2) {
      _updateRoutePath();
    }
    setState(() {});
  }

  BitmapDescriptor _getMarkerIcon(int index) {
    if (index == 0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (index == _routePoints.length - 1) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  String _getMarkerTitle(int index) {
    if (index == 0) return 'Start Point';
    if (index == _routePoints.length - 1) return 'End Point';
    return 'Waypoint ${index}';
  }

  Future<void> _loadAvailableDevices() async {
    try {
      final devices = await _deviceService.getOwnerList();
      setState(() {
        _availableDevices = devices;
        // Pre-select device if vehicle was passed
        if (widget.vehicle != null) {
          _selectedDeviceId = widget.vehicle!.device.id;
          debugPrint('🚗 Pre-selected device: $_selectedDeviceId');
        } else if (devices.isNotEmpty && _selectedDeviceId == null) {
          _selectedDeviceId = devices.first.device.id;
          debugPrint('🚗 Auto-selected first device: $_selectedDeviceId');
        }
      });
    } catch (e) {
      debugPrint('❌ Error loading devices: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _centerMapOnDefaultLocation();
  }

  void _centerMapOnDefaultLocation() {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_defaultLocation, 12.0),
    );
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      _routePoints.add(position);
      _markers.add(
        Marker(
          markerId: MarkerId('point_${_routePoints.length}'),
          position: position,
          icon: _getMarkerIcon(_routePoints.length - 1),
          infoWindow: InfoWindow(
            title: _getMarkerTitle(_routePoints.length - 1),
            snippet: 'Tap to remove',
          ),
        ),
      );
    });

    if (_routePoints.length >= 2) {
      await _updateRoutePath();
    }

    // Hide instructions after first point
    if (_showInstructions && _routePoints.length >= 1) {
      setState(() => _showInstructions = false);
    }
  }

  Future<void> _updateRoutePath() async {
    if (_routePoints.length < 2) return;

    try {
      final routePointsData = _routePoints
          .map((point) => [point.longitude, point.latitude])
          .toList();

      final routePathResponse = await _routeService.getRoutePath(
        points: routePointsData,
      );

      setState(() {
        _polylines.clear();

        if (routePathResponse?.coordinates != null &&
            routePathResponse!.coordinates!.isNotEmpty) {
          final routeCoordinates = routePathResponse.coordinates!
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();

          _polylines.add(
            Polyline(
              polylineId: const PolylineId('new_route'),
              points: routeCoordinates,
              color: const Color(0xFF3B82F6), // e-Disha blue
              width: 5,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        } else {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('new_route'),
              points: _routePoints,
              color: const Color(0xFFF59E0B), // Warning orange
              width: 4,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error updating route path: $e');
      setState(() {
        _polylines.clear();
        if (_routePoints.length > 1) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('new_route'),
              points: _routePoints,
              color: const Color(0xFFF59E0B),
              width: 4,
            ),
          );
        }
      });
    }
  }

  void _removePoint(int index) {
    setState(() {
      _routePoints.removeAt(index);
      _markers.clear();
      _polylines.clear();

      for (int i = 0; i < _routePoints.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('point_${i + 1}'),
            position: _routePoints[i],
            icon: _getMarkerIcon(i),
            infoWindow: InfoWindow(
              title: _getMarkerTitle(i),
              snippet: 'Tap to remove',
            ),
          ),
        );
      }
    });

    if (_routePoints.length >= 2) {
      _updateRoutePath();
    }
  }

  void _clearAllPoints() {
    setState(() {
      _routePoints.clear();
      _markers.clear();
      _polylines.clear();
      _showInstructions = true;
    });
  }

  Future<void> _saveRoute() async {
    if (_routePoints.isEmpty || _selectedDeviceId == null) {
      _showSnackbar(
        'Please add route points and select a vehicle',
        Colors.orange,
      );
      return;
    }

    debugPrint('📦 Saving route for device ID: $_selectedDeviceId');
    debugPrint('📍 Number of waypoints: ${_routePoints.length}');
    
    setState(() => _isSaving = true);

    try {
      final routePointsData = _routePoints
          .map((point) => [point.longitude, point.latitude])
          .toList();

      final routePathResponse = await _routeService.getRoutePath(
        points: routePointsData,
      );

      bool success = false;

      if (routePathResponse?.coordinates != null &&
          routePathResponse!.coordinates!.isNotEmpty) {
        success = await _routeService.saveRoute(
          deviceId: _selectedDeviceId!,
          routeCoordinates: routePathResponse.coordinates!,
          routePoints: routePointsData,
          id: widget.existingRoute?.id,
          routeName: widget.existingRoute?.routeName ??
              'Route ${DateTime.now().millisecondsSinceEpoch}',
          routeHash: routePathResponse.hash,
        );
      } else {
        final basicRoute =
            routePointsData.map((point) => '${point[0]},${point[1]}').join(';');
        success = await _routeService.saveRoute(
          deviceId: _selectedDeviceId!,
          route: basicRoute,
          routePoints: routePointsData,
          id: widget.existingRoute?.id,
          routeName: widget.existingRoute?.routeName ??
              'Route ${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (success) {
        _showSnackbar(
          widget.existingRoute != null
              ? '✅ Route updated successfully!'
              : '✅ Route saved successfully!',
          Colors.green,
        );
        Navigator.of(context).pop(true);
      } else {
        _showSnackbar('Failed to save route. Please try again.', Colors.red);
      }
    } catch (e) {
      _showSnackbar(
        'Error: ${e.toString().replaceAll('Exception: ', '')}',
        Colors.red,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 12.0,
            ),
            markers: _markers,
            polylines: _polylines,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            compassEnabled: true,
            zoomControlsEnabled: false,
            style: _darkMapStyle,
          ),

          // Top App Bar
          _buildModernAppBar(theme),

          // Vehicle Selector (Bottom Sheet Style)
          if (_availableDevices.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: _routePoints.isEmpty ? 24 : 180,
              child: _buildVehicleSelector(theme)
                  .animate()
                  .slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut)
                  .fadeIn(),
            ),

          // Instructions Banner
          if (_showInstructions)
            Positioned(
              left: 16,
              right: 16,
              top: 100,
              child: _buildInstructionsBanner(theme)
                  .animate()
                  .slideY(begin: -1, duration: 400.ms, curve: Curves.easeOut)
                  .fadeIn(),
            ),

          // Route Points Panel
          if (_routePoints.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildRoutePointsPanel(theme)
                  .animate()
                  .slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut),
            ),

          // Custom Location Button
          Positioned(
            right: 16,
            bottom: _routePoints.isEmpty ? 100 : 260,
            child: _buildLocationButton(theme),
          ),

          // Loading Overlay
          if (_isLoading || _isSaving) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF3B82F6).withOpacity(0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Back Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.existingRoute != null
                          ? 'Edit Route'
                          : 'Create New Route',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _routePoints.isEmpty
                          ? 'Tap map to add points'
                          : '${_routePoints.length} waypoint${_routePoints.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Clear Button
              if (_routePoints.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear All Points?'),
                          content: const Text(
                              'This will remove all waypoints from the route.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                _clearAllPoints();
                                Navigator.pop(ctx);
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(width: 8),

              // Save Button
              if (_routePoints.length >= 2)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_rounded, color: Colors.white),
                    onPressed: _isSaving ? null : _saveRoute,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Vehicle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8FAFC),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDeviceId,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded,
                    color: Color(0xFF3B82F6)),
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: _availableDevices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final device = entry.value;
                  final deviceId = device.device.id;
                  return DropdownMenuItem<String>(
                    value: deviceId,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            size: 18,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                device.vehicleRegNo.isNotEmpty
                                    ? device.vehicleRegNo
                                    : 'Vehicle ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'ID: $deviceId',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedDeviceId = newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Your Route',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap anywhere on the map to add waypoints. You need at least 2 points to create a route.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            onPressed: () => setState(() => _showInstructions = false),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePointsPanel(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Route Waypoints',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_routePoints.length} point${_routePoints.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Points List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _routePoints.length,
              itemBuilder: (context, index) {
                final point = _routePoints[index];
                final isStart = index == 0;
                final isEnd = index == _routePoints.length - 1;

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12, bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isStart
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : isEnd
                              ? [
                                  const Color(0xFFEF4444),
                                  const Color(0xFFDC2626)
                                ]
                              : [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF2563EB)
                                ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isStart
                                ? const Color(0xFF10B981)
                                : isEnd
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF3B82F6))
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isStart
                                  ? Icons.flag_rounded
                                  : isEnd
                                      ? Icons.location_on_rounded
                                      : Icons.circle,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _removePoint(index),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          _getMarkerTitle(index),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 8,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                      delay: (index * 50).ms,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeIn();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.my_location_rounded, color: Color(0xFF3B82F6)),
        onPressed: _centerMapOnDefaultLocation,
      ),
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 16),
              Text(
                _isSaving ? 'Saving route...' : 'Loading...',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#f5f5f5"}]
    }
  ]
  ''';
}
