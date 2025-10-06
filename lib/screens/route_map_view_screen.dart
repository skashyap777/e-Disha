import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edisha/services/route_service.dart';
import 'package:edisha/services/device_service.dart';

/// Modern Route Map View Screen - e-Disha 2025
/// Displays a saved route on Google Maps with waypoints and polyline
class RouteMapViewScreen extends StatefulWidget {
  final DeviceOwnerData vehicle;
  final RouteData route;

  const RouteMapViewScreen({
    super.key,
    required this.vehicle,
    required this.route,
  });

  @override
  State<RouteMapViewScreen> createState() => _RouteMapViewScreenState();
}

class _RouteMapViewScreenState extends State<RouteMapViewScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _showInfo = true;

  final RouteService _routeService = RouteService();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Create markers for route points
      _markers = {};
      for (int i = 0; i < widget.route.routePoints.length; i++) {
        final point = widget.route.routePoints[i];
        if (point.length >= 2) {
          final marker = Marker(
            markerId: MarkerId('point_$i'),
            position:
                LatLng(point[1], point[0]), // [lng, lat] -> LatLng(lat, lng)
            icon: await _getMarkerIcon(i),
            infoWindow: InfoWindow(
              title: _getMarkerTitle(i),
              snippet:
                  'Lat: ${point[1].toStringAsFixed(6)}, Lng: ${point[0].toStringAsFixed(6)}',
            ),
          );
          _markers.add(marker);
        }
      }

      // Create polyline for the route
      if (widget.route.routePoints.length >= 2) {
        final polylinePoints = widget.route.routePoints
            .map((point) =>
                LatLng(point[1], point[0])) // [lng, lat] -> LatLng(lat, lng)
            .toList();

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route_path'),
            points: polylinePoints,
            color: const Color(0xFF3B82F6),
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
      }

      setState(() {
        _isLoading = false;
      });

      // Center map on the route
      if (_mapController != null && widget.route.routePoints.isNotEmpty) {
        await _centerMapOnRoute();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error initializing map: $e');
    }
  }

  Future<BitmapDescriptor> _getMarkerIcon(int index) async {
    if (index == 0) {
      return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen); // Start - Green
    } else if (index == widget.route.routePoints.length - 1) {
      return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed); // End - Red
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure); // Waypoints - Blue
    }
  }

  String _getMarkerTitle(int index) {
    if (index == 0) {
      return '🚩 Start Point';
    } else if (index == widget.route.routePoints.length - 1) {
      return '🏁 End Point';
    } else {
      return '📍 Waypoint $index';
    }
  }

  Future<void> _centerMapOnRoute() async {
    if (widget.route.routePoints.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final point in widget.route.routePoints) {
      if (point.length >= 2) {
        final lat = point[1];
        final lng = point[0];
        minLat = minLat < lat ? minLat : lat;
        maxLat = maxLat > lat ? maxLat : lat;
        minLng = minLng < lng ? minLng : lng;
        maxLng = maxLng > lng ? maxLng : lng;
      }
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 80);
    await _mapController!.animateCamera(cameraUpdate);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_isLoading) {
      _centerMapOnRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629), // India center
              zoom: 5.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Loading route...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top App Bar
          _buildTopAppBar(),

          // Route Info Card (Bottom)
          if (_showInfo) _buildRouteInfoCard(),

          // Floating Action Buttons
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF2563EB),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    children: [
                      Text(
                        widget.route.routeName ?? 'Route ${widget.route.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.vehicle.vehicleRegNo,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    onPressed: _editRoute,
                    tooltip: 'Edit Route',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.delete_rounded, color: Colors.white),
                    onPressed: _deleteRoute,
                    tooltip: 'Delete Route',
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().slideY(begin: -1, duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildRouteInfoCard() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Route Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF64748B)),
                      onPressed: () {
                        setState(() {
                          _showInfo = false;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle Info
                _buildInfoRow(
                  Icons.directions_car_rounded,
                  'Vehicle',
                  widget.vehicle.vehicleRegNo,
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 12),

                // Waypoints Count
                _buildInfoRow(
                  Icons.route_rounded,
                  'Waypoints',
                  '${widget.route.routePoints.length} points',
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),

                // Device ID
                _buildInfoRow(
                  Icons.devices_rounded,
                  'Device ID',
                  widget.vehicle.device.id,
                  const Color(0xFF8B5CF6),
                ),

                if (widget.route.createdAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today_rounded,
                    'Created',
                    _formatDate(widget.route.createdAt!),
                    const Color(0xFFF59E0B),
                  ),
                ],
              ],
            ),
          ),
        ),
      )
          .animate()
          .slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut)
          .fadeIn(),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      right: 16,
      bottom: _showInfo ? 250 : 100,
      child: Column(
        children: [
          // Recenter Button
          FloatingActionButton(
            heroTag: 'recenter',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _centerMapOnRoute,
            child: const Icon(Icons.my_location_rounded,
                color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 12),

          // Toggle Info Button
          FloatingActionButton(
            heroTag: 'toggle_info',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () {
              setState(() {
                _showInfo = !_showInfo;
              });
            },
            child: Icon(
              _showInfo ? Icons.visibility_off_rounded : Icons.info_rounded,
              color: const Color(0xFF3B82F6),
            ),
          ),
        ],
      )
          .animate()
          .slideX(begin: 1, duration: 400.ms, curve: Curves.easeOut)
          .fadeIn(),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route editing feature coming soon!'),
        backgroundColor: Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: Navigate to route editing screen
    // Navigator.pushNamed(
    //   context,
    //   '/route-fixing',
    //   arguments: {
    //     'vehicle': widget.vehicle,
    //     'route': widget.route,
    //   },
    // );
  }

  void _deleteRoute() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_rounded,
                    color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Route',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this route?',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.route.routeName ?? 'Route ${widget.route.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vehicle: ${widget.vehicle.vehicleRegNo}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${widget.route.routePoints.length} waypoints',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ This action cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _performDeleteRoute();
              },
              child: const Text(
                'Delete Route',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteRoute() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Text(
                    'Deleting route...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final success = await _routeService.deleteRoute(
        routeId: widget.route.id,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Route deleted successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          // Go back to route list
          Navigator.of(context).pop(true); // Return true to refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete route. Please try again.'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Network error: Failed to delete route'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
