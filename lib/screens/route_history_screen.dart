import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edisha/services/route_service.dart';
import 'package:edisha/services/device_service.dart';

/// Modern Route History Screen - e-Disha 2025
/// Shows routes for a specific vehicle with modern card-based UI
class RouteHistoryScreen extends StatefulWidget {
  final DeviceOwnerData vehicle;

  const RouteHistoryScreen({super.key, required this.vehicle});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen>
    with SingleTickerProviderStateMixin {
  final RouteService _routeService = RouteService();
  List<RouteData> _routes = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
    _loadRoutes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('🔍 Loading routes for vehicle: ${widget.vehicle.vehicleRegNo}');
      debugPrint('🔍 Device ID: ${widget.vehicle.device.id}');

      final routes =
          await _routeService.getRoutes(deviceId: widget.vehicle.device.id);

      debugPrint('✅ Loaded ${routes.length} routes for device ${widget.vehicle.device.id}');
      if (routes.isEmpty) {
        debugPrint('⚠️ No routes found! Check if device ID matches saved routes.');
      } else {
        debugPrint('📊 Routes found:');
        for (var route in routes) {
          debugPrint('  - Route ${route.id}: ${route.routeName} (${route.routePoints.length} points)');
        }
      }

      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with vehicle info
          _buildModernAppBar(theme),

          // Vehicle Info Card
          SliverToBoxAdapter(
            child: _buildVehicleInfoCard(theme)
                .animate()
                .slideY(begin: -0.5, duration: 400.ms, curve: Curves.easeOut)
                .fadeIn(),
          ),

          // Content
          _isLoading
              ? SliverFillRemaining(child: _buildLoadingView(theme))
              : _errorMessage != null
                  ? SliverFillRemaining(child: _buildErrorView(theme))
                  : _routes.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyView(theme))
                      : _buildRoutesList(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/route-fixing',
            arguments: widget.vehicle,
          ).then((result) {
            // Refresh list if route was added
            if (result == true) {
              _loadRoutes();
            }
          });
        },
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add_road_rounded, color: Colors.white),
        label: const Text('Add Route', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildModernAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF3B82F6),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vehicle.vehicleRegNo.isNotEmpty
                                  ? widget.vehicle.vehicleRegNo
                                  : 'Vehicle Routes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Route History',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Refresh button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white),
                          onPressed: _loadRoutes,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicle.vehicleRegNo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device ID: ${widget.vehicle.device.id}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                if (widget.vehicle.ownerName != null &&
                    widget.vehicle.ownerName!.isNotEmpty)
                  Text(
                    'Owner: ${widget.vehicle.ownerName}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_routes.length} ${_routes.length == 1 ? 'Route' : 'Routes'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
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
            'Loading routes...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
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
            const Text(
              'Failed to Load Routes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRoutes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_outlined,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Routes Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No routes have been saved for this vehicle yet',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/route-fixing',
                arguments: widget.vehicle,
              ).then((result) {
                // Refresh list if route was added
                if (result == true) {
                  _loadRoutes();
                }
              });
            },
            icon: const Icon(Icons.add_road_rounded),
            label: const Text('Create First Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList(ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final route = _routes[index];
            return _buildRouteCard(route, index, theme)
                .animate()
                .slideX(
                  begin: 0.2,
                  delay: (index * 50).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn();
          },
          childCount: _routes.length,
        ),
      ),
    );
  }

  Widget _buildRouteCard(RouteData route, int index, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToRouteMap(route),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Route icon with gradient
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Route name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.routeName ?? 'Route ${route.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.pin_drop_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${route.routePoints.length} waypoints',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                if (route.createdAt != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Created: ${_formatDate(route.createdAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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

  void _navigateToRouteMap(RouteData route) {
    Navigator.pushNamed(
      context,
      '/route-map-view',
      arguments: {
        'vehicle': widget.vehicle,
        'route': route,
      },
    ).then((result) {
      // Refresh list if route was modified or deleted
      if (result == true) {
        _loadRoutes();
      }
    });
  }
}
