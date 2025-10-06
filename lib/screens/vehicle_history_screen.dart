import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edisha/services/device_service.dart';
import 'package:edisha/widgets/custom_vehicle_icons.dart';

/// Modern Vehicle History Screen - e-Disha 2025
/// Functionality from rapid_yatra, completely new timeline-based UI design
class VehicleHistoryScreen extends StatefulWidget {
  const VehicleHistoryScreen({super.key});

  @override
  State<VehicleHistoryScreen> createState() => _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState extends State<VehicleHistoryScreen>
    with SingleTickerProviderStateMixin {
  final DeviceService _deviceService = DeviceService();
  List<DeviceOwnerData> _vehicles = [];
  List<DeviceOwnerData> _filteredVehicles = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
    _loadVehicles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final vehicles = await _deviceService.getOwnerList();

      setState(() {
        _vehicles = vehicles;
        _filteredVehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredVehicles = _vehicles.where((vehicle) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final regNo = vehicle.vehicleRegNo.toLowerCase();
          final deviceId = vehicle.device.id.toLowerCase();
          final owner = vehicle.ownerName?.toLowerCase() ?? '';
          
          if (!regNo.contains(query) &&
              !deviceId.contains(query) &&
              !owner.contains(query)) {
            return false;
          }
        }

        // Status filter (placeholder logic - adjust based on your data)
        if (_filterStatus != 'all') {
          // You can add actual status logic here
          // For now, treating all as active
          return true;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with gradient
          _buildModernAppBar(theme),

          // Search and Filter Section
          SliverToBoxAdapter(
            child: _buildSearchAndFilter(theme)
                .animate()
                .slideY(begin: -0.5, duration: 400.ms, curve: Curves.easeOut)
                .fadeIn(),
          ),

          // Stats Section
          if (!_isLoading && _errorMessage == null)
            SliverToBoxAdapter(
              child: _buildStatsSection(theme)
                  .animate()
                  .slideY(begin: 0.5, duration: 400.ms, curve: Curves.easeOut)
                  .fadeIn(),
            ),

          // Content
          _isLoading
              ? SliverFillRemaining(
                  child: _buildLoadingView(theme),
                )
              : _errorMessage != null
                  ? SliverFillRemaining(
                      child: _buildErrorView(theme),
                    )
                  : _filteredVehicles.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyView(theme),
                        )
                      : _buildVehiclesList(theme),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF3B82F6),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3B82F6),
                const Color(0xFF2563EB),
              ],
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
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle History',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Track your fleet movements',
                              style: TextStyle(
                                color: Colors.white70,
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
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          onPressed: _loadVehicles,
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

  Widget _buildSearchAndFilter(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search vehicles...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          Row(
            children: [
              _buildFilterChip('All', 'all', theme),
              const SizedBox(width: 8),
              _buildFilterChip('Active', 'active', theme),
              const SizedBox(width: 8),
              _buildFilterChip('Inactive', 'inactive', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterStatus = value;
            _applyFilters();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            '${_vehicles.length}',
            Icons.directions_car_rounded,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem(
            'Tracked',
            '${_filteredVehicles.length}',
            Icons.gps_fixed_rounded,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem(
            'Today',
            '${_filteredVehicles.length}',
            Icons.today_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
            'Loading vehicles...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch your data',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF64748B),
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
              'Failed to Load Vehicles',
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
              onPressed: _loadVehicles,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
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
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Vehicles Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search filters'
                : 'No vehicles are registered in the system',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesList(ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final vehicle = _filteredVehicles[index];
            return _buildVehicleCard(vehicle, index, theme)
                .animate()
                .slideX(
                  begin: 0.2,
                  delay: (index * 50).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn();
          },
          childCount: _filteredVehicles.length,
        ),
      ),
    );
  }

  Widget _buildVehicleCard(DeviceOwnerData vehicle, int index, ThemeData theme) {
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
          onTap: () => _navigateToRouteHistory(vehicle),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Vehicle Icon with gradient background
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
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
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Vehicle Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.vehicleRegNo.isNotEmpty
                            ? vehicle.vehicleRegNo
                            : 'Vehicle ${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: ${vehicle.device.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          if (vehicle.ownerName != null &&
                              vehicle.ownerName!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vehicle.ownerName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRouteHistory(DeviceOwnerData vehicle) {
    Navigator.pushNamed(
      context,
      '/vehicle-route-history',
      arguments: vehicle,
    );
  }
}
