import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../generated/app_localizations.dart';
import 'package:edisha/services/gps_tracking_service.dart';
import 'package:edisha/widgets/custom_vehicle_icons.dart';

/// Dedicated History Playback Screen - e-Disha 2025
/// Shows vehicle history route on Google Maps with polyline
class HistoryPlaybackScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String vehicleId;

  const HistoryPlaybackScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.vehicleId,
  });

  @override
  State<HistoryPlaybackScreen> createState() => _HistoryPlaybackScreenState();
}

class _HistoryPlaybackScreenState extends State<HistoryPlaybackScreen> {
  GoogleMapController? _mapController;
  final GPSTrackingService _gpsService = GPSTrackingService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<GPSLocationData> _historyData = [];
  List<LatLng> _traveledPath = []; // Points traveled so far
  
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _errorMessage;
  
  int _currentIndex = 0;
  Timer? _playbackTimer;
  double _playbackSpeed = 1.0; // 1x speed
  
  bool _showInfo = true;
  GPSLocationData? _currentLocation;
  BitmapDescriptor? _customVehicleIcon;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Format dates for API
      final startDateStr =
          '${widget.startDate.year}-${widget.startDate.month.toString().padLeft(2, '0')}-${widget.startDate.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${widget.endDate.year}-${widget.endDate.month.toString().padLeft(2, '0')}-${widget.endDate.day.toString().padLeft(2, '0')}';

      debugPrint('🔄 Loading history data for vehicle: ${widget.vehicleId}');
      debugPrint('📅 Date range: $startDateStr to $endDateStr');

      final historyData = await _gpsService.fetchGPSHistoryData(
        startDateTime: startDateStr,
        endDateTime: endDateStr,
        vehicleRegistrationNumber: widget.vehicleId,
      );

      if (historyData.isEmpty) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)?.noHistoryDataFound ?? 'No history data found for the selected period';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _historyData = historyData;
        _isLoading = false;
      });

      // Load custom vehicle icon
      await _loadCustomVehicleIcon();
      
      // Add ONLY start and end markers initially (no polyline)
      _addStartEndMarkers();
      
      // Center map on route
      if (_mapController != null) {
        _centerMapOnRoute();
      }

      debugPrint('✅ Loaded ${historyData.length} history points');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load history data: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('❌ Error loading history: $e');
    }
  }

  Future<void> _loadCustomVehicleIcon() async {
    try {
      // Get the first location's packet type to determine vehicle state
      final vehicleState = _historyData.isNotEmpty
          ? CustomVehicleIcons.getStateFromPacketType(_historyData.first.packetType)
          : VehicleState.moving;
      
      // Create custom vehicle icon
      _customVehicleIcon = await CustomVehicleIcons.createVehicleIcon(
        VehicleType.yellowCar, // Default to yellow car
        vehicleState,
      );
      debugPrint('✅ Custom vehicle icon loaded');
    } catch (e) {
      debugPrint('❌ Error loading custom vehicle icon: $e');
      _customVehicleIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  void _updatePolyline() {
    if (_traveledPath.length < 2) {
      setState(() {
        _polylines = {};
      });
      return;
    }

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('history_route'),
          points: _traveledPath,
          color: const Color(0xFF3B82F6), // e-Disha blue
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
    });
  }

  void _addStartEndMarkers() {
    if (_historyData.isEmpty) return;

    final startPoint = _historyData.first;
    final endPoint = _historyData.last;

    setState(() {
      _markers = {
        // Start marker (Green)
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(startPoint.latitude, startPoint.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '🚩 Start',
            snippet: _formatDateTime(startPoint.timestamp),
          ),
        ),
        // End marker (Red)
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(endPoint.latitude, endPoint.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🏁 End',
            snippet: _formatDateTime(endPoint.timestamp),
          ),
        ),
      };
    });
  }

  void _updateCurrentMarker() {
    if (_historyData.isEmpty || _currentIndex >= _historyData.length) return;

    final currentPoint = _historyData[_currentIndex];
    final currentPosition = LatLng(currentPoint.latitude, currentPoint.longitude);
    
    // Add current position to traveled path
    if (_traveledPath.isEmpty || _traveledPath.last != currentPosition) {
      _traveledPath.add(currentPosition);
    }
    
    setState(() {
      _currentLocation = currentPoint;
      
      // Remove old current marker and add new one with custom icon
      _markers.removeWhere((m) => m.markerId.value == 'current');
      
      // Calculate rotation based on heading
      final rotation = currentPoint.heading ?? 0.0;
      
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: currentPosition,
          icon: _customVehicleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          rotation: rotation,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    });
    
    // Update polyline with traveled path
    _updatePolyline();

    // Move camera to current position
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(currentPosition),
    );
  }

  Future<void> _centerMapOnRoute() async {
    if (_historyData.isEmpty || _mapController == null) return;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final point in _historyData) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
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
    if (!_isLoading && _historyData.isNotEmpty) {
      _centerMapOnRoute();
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_historyData.isEmpty) return;

    setState(() {
      _isPlaying = true;
      // Remove start and end markers when playback starts
      _markers.removeWhere((m) => m.markerId.value == 'start' || m.markerId.value == 'end');
      // Initialize traveled path with first point if starting from beginning
      if (_currentIndex == 0) {
        _traveledPath = [LatLng(_historyData[0].latitude, _historyData[0].longitude)];
      }
    });
    
    // Show initial position
    _updateCurrentMarker();

    // Calculate interval based on speed (faster speed = shorter interval)
    final intervalMs = (1000 / _playbackSpeed).round();

    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentIndex < _historyData.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _updateCurrentMarker();
      } else {
        // Reached end
        _pausePlayback();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.playbackCompleted ?? 'Playback completed'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _resetPlayback() {
    _pausePlayback();
    setState(() {
      _currentIndex = 0;
      _currentLocation = null;
      _traveledPath = []; // Clear traveled path
      _polylines = {}; // Clear polyline
    });
    // Remove current marker and restore start/end markers
    _markers.removeWhere((m) => m.markerId.value == 'current');
    _addStartEndMarkers();
    _centerMapOnRoute();
  }

  void _changeSpeed(double speed) {
    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      _pausePlayback();
    }
    setState(() => _playbackSpeed = speed);
    if (wasPlaying) {
      _startPlayback();
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatSpeed(double? speed) {
    if (speed == null) return 'N/A';
    return '${speed.toStringAsFixed(1)} km/h';
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
            myLocationEnabled: false,
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
          if (_isLoading) _buildLoadingOverlay(),

          // Error Overlay
          if (_errorMessage != null && !_isLoading) _buildErrorOverlay(),

          // Top App Bar
          if (!_isLoading && _errorMessage == null) _buildTopAppBar(),

          // Playback Controls (Bottom)
          if (!_isLoading && _errorMessage == null && _historyData.isNotEmpty)
            _buildPlaybackControls(),

          // Info Card
          if (_showInfo && !_isLoading && _errorMessage == null && _currentLocation != null)
            _buildInfoCard(),

          // Floating Action Buttons
          if (!_isLoading && _errorMessage == null) _buildFloatingButtons(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading history data...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.failedToLoadHistory ?? 'Failed to Load History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? (AppLocalizations.of(context)?.unexpectedError ?? 'An unexpected error occurred'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(AppLocalizations.of(context)?.goBack ?? 'Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64748B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadHistoryData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(AppLocalizations.of(context)?.tryAgain ?? 'Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                        AppLocalizations.of(context)?.historyPlaybackTitle ?? 'History Playback',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.vehicleId,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_historyData.length} points',
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
        ),
      ).animate().slideY(begin: -1, duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildPlaybackControls() {
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Bar
              Row(
                children: [
                  Text(
                    '${_currentIndex + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: _currentIndex.toDouble(),
                        min: 0,
                        max: (_historyData.length - 1).toDouble(),
                        activeColor: const Color(0xFF3B82F6),
                        inactiveColor: const Color(0xFFE2E8F0),
                        onChanged: (value) {
                          setState(() {
                            _currentIndex = value.round();
                          });
                          _updateCurrentMarker();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_historyData.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset Button
                  _buildControlButton(
                    icon: Icons.replay_rounded,
                    label: 'Reset',
                    onPressed: _resetPlayback,
                    color: const Color(0xFF64748B),
                  ),

                  // Play/Pause Button
                  _buildControlButton(
                    icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    label: _isPlaying ? 'Pause' : 'Play',
                    onPressed: _togglePlayback,
                    color: const Color(0xFF3B82F6),
                    isPrimary: true,
                  ),

                  // Speed Button
                  PopupMenuButton<double>(
                    child: _buildControlButton(
                      icon: Icons.speed_rounded,
                      label: '${_playbackSpeed}x',
                      onPressed: null,
                      color: const Color(0xFF8B5CF6),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 0.5, child: Text('0.5x Speed')),
                      const PopupMenuItem(value: 1.0, child: Text('1x Speed')),
                      const PopupMenuItem(value: 2.0, child: Text('2x Speed')),
                      const PopupMenuItem(value: 5.0, child: Text('5x Speed')),
                    ],
                    onSelected: _changeSpeed,
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          .animate()
          .slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut)
          .fadeIn(),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPrimary ? 24 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: isPrimary ? 24 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : color,
                fontSize: isPrimary ? 16 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Position',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => setState(() => _showInfo = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time_rounded,
                'Time',
                _formatDateTime(_currentLocation?.timestamp),
                const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.speed_rounded,
                'Speed',
                _formatSpeed(_currentLocation?.speed),
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.location_on_rounded,
                'Location',
                '${_currentLocation?.latitude.toStringAsFixed(6)}, ${_currentLocation?.longitude.toStringAsFixed(6)}',
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
      )
          .animate()
          .slideY(begin: -1, duration: 400.ms, curve: Curves.easeOut)
          .fadeIn(),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
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
      bottom: _showInfo ? 200 : 160,
      child: Column(
        children: [
          // Recenter Button
          FloatingActionButton(
            heroTag: 'recenter',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _centerMapOnRoute,
            child: const Icon(Icons.my_location_rounded, color: Color(0xFF3B82F6)),
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
}
