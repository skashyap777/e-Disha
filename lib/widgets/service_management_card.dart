import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edisha/generated/app_localizations.dart';
import 'package:edisha/services/device_service.dart';
import 'package:edisha/services/alert_api_service.dart';
import 'package:edisha/services/notification_api_service.dart';
import 'package:edisha/core/service_locator.dart';
import 'package:edisha/providers/language_provider.dart';
import 'package:edisha/providers/theme_provider.dart';

/// Enhanced Service Management Card with API integration
class ServiceManagementCard extends StatefulWidget {
  const ServiceManagementCard({super.key});

  @override
  State<ServiceManagementCard> createState() => _ServiceManagementCardState();
}

class _ServiceManagementCardState extends State<ServiceManagementCard> {
  int _activeDeviceCount = 0;
  int _totalNotifications = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceData();
  }

  Future<void> _loadServiceData() async {
    try {
      setState(() => _isLoading = true);

      // Check if GetIt services are registered
      if (!isEDishaServiceRegistered<DeviceService>()) {
        debugPrint('❌ DeviceService not registered in GetIt');
        setState(() {
          _activeDeviceCount = 0;
          _totalNotifications = 0;
          _isLoading = false;
        });
        return;
      }

      if (!isEDishaServiceRegistered<AlertApiService>()) {
        debugPrint('❌ AlertApiService not registered in GetIt');
        setState(() {
          _activeDeviceCount = 0;
          _totalNotifications = 0;
          _isLoading = false;
        });
        return;
      }

      // Load device count
      final deviceService = getEDishaService<DeviceService>();
      final devices = await deviceService.getOwnerList();
      
      // Load notification count
      NotificationApiService notificationService;
      if (isEDishaServiceRegistered<NotificationApiService>()) {
        notificationService = getEDishaService<NotificationApiService>();
      } else {
        notificationService = NotificationApiService();
      }
      
      final notificationsResponse = await notificationService.fetchNotifications();
      debugPrint('🔍 SERVICE MGMT: Notifications response: $notificationsResponse');
      final notificationCount = notificationsResponse['total'] as int? ?? 0;
      debugPrint('🔍 SERVICE MGMT: Notification count extracted: $notificationCount');
      
      setState(() {
        _activeDeviceCount = devices.length;
        _totalNotifications = notificationCount;
        _isLoading = false;
      });
      
      debugPrint('🔍 SERVICE MGMT: Final state - devices: $_activeDeviceCount, notifications: $_totalNotifications');
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading service data: $e');
      
      // Show a user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load service data: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadServiceData,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 20),
              _isLoading ? _buildLoadingState() : _buildServiceGrid(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.miscellaneous_services,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            AppLocalizations.of(context)?.serviceManagement ?? 'Service Management',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _loadServiceData,
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildServiceGrid(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid
        int crossAxisCount = 2;
        if (constraints.maxWidth > 800) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: _buildServiceItems(theme),
        );
      },
    );
  }

  List<Widget> _buildServiceItems(ThemeData theme) {
    final serviceItems = [
      {
        'title': AppLocalizations.of(context)?.routes ?? 'Routes',
        'subtitle': AppLocalizations.of(context)?.manageRoutes ?? 'Manage Routes',
        'icon': Icons.route,
        'color': Colors.blue,
        'onTap': () => _navigateToRoutes(),
      },
      {
        'title': AppLocalizations.of(context)?.devices ?? 'Devices',
        'subtitle': '$_activeDeviceCount ${AppLocalizations.of(context)?.activeCount ?? 'Active'}',
        'icon': Icons.devices,
        'color': Colors.green,
        'count': _activeDeviceCount,
        'onTap': () => _navigateToDevices(),
      },
      {
        'title': AppLocalizations.of(context)?.notifications ?? 'Notifications',
        'subtitle': '$_totalNotifications ${AppLocalizations.of(context)?.notificationsCount ?? 'Notifications'}',
        'icon': Icons.notifications,
        'color': Colors.orange,
        'count': _totalNotifications,
        'onTap': () => _navigateToNotifications(),
      },
      {
        'title': AppLocalizations.of(context)?.settings ?? 'Settings',
        'subtitle': AppLocalizations.of(context)?.appSettings ?? 'App Settings',
        'icon': Icons.settings,
        'color': Colors.purple,
        'onTap': () => _navigateToSettings(),
      },
    ];

    return serviceItems.map((item) => _buildServiceCard(item, theme)).toList();
  }

  Widget _buildServiceCard(Map<String, dynamic> item, ThemeData theme) {
    final color = item['color'] as Color;
    final count = item['count'] as int?;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: item['onTap'] as VoidCallback,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Stack(
                  children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 28,
                    ),
                  ),
                  if (count != null && count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item['subtitle'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRoutes() {
    Navigator.pushNamed(context, '/route-fixing');
  }

  void _navigateToDevices() {
    // Navigate to device management screen or show device list dialog
    _showDevicesDialog();
  }

  void _navigateToNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _navigateToSettings() {
    _showSettingsDialog();
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => DevicesDialog(
        activeDeviceCount: _activeDeviceCount,
        onRefresh: _loadServiceData,
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const AppSettingsDialog(),
    );
  }
}

/// Dialog to show device information
class DevicesDialog extends StatefulWidget {
  final int activeDeviceCount;
  final VoidCallback onRefresh;

  const DevicesDialog({
    super.key,
    required this.activeDeviceCount,
    required this.onRefresh,
  });

  @override
  State<DevicesDialog> createState() => _DevicesDialogState();
}

class _DevicesDialogState extends State<DevicesDialog> {
  List<DeviceOwnerData> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      setState(() => _isLoading = true);
      
      if (!isEDishaServiceRegistered<DeviceService>()) {
        debugPrint('❌ DeviceService not registered in GetIt (DevicesDialog)');
        setState(() {
          _devices = [];
          _isLoading = false;
        });
        return;
      }
      
      final deviceService = getEDishaService<DeviceService>();
      final devices = await deviceService.getOwnerList();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading devices in dialog: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.devices, color: Colors.green),
          const SizedBox(width: 12),
          const Text('Active Devices'),
          const Spacer(),
          IconButton(
            onPressed: () {
              _loadDevices();
              widget.onRefresh();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        child: const Icon(Icons.directions_car, color: Colors.green),
                      ),
                      title: Text(
                        device.vehicleRegNo.isNotEmpty ? device.vehicleRegNo : 'Unknown Vehicle',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Device ID: ${device.device.id.isNotEmpty ? device.device.id : 'N/A'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog for app settings
class AppSettingsDialog extends StatefulWidget {
  const AppSettingsDialog({super.key});

  @override
  State<AppSettingsDialog> createState() => _AppSettingsDialogState();
}

class _AppSettingsDialogState extends State<AppSettingsDialog> {
  bool _notifications = true;
  bool _locationTracking = true;
  bool _autoRefresh = true;
  double _refreshInterval = 30.0; // seconds
  double _mapZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from SharedPreferences or secure storage
    // For now, using default values
  }

  Future<void> _saveSettings() async {
    // Save settings to SharedPreferences or backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.settings, color: Colors.purple),
          const SizedBox(width: 12),
          Text(l10n?.settings ?? 'Settings'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language Settings Section
              _buildSettingSection(l10n?.language ?? 'Language', [
                _buildLanguageSetting(context),
              ]),
              
              // Appearance Settings Section
              _buildSettingSection(l10n?.appearance ?? 'Appearance', [
                _buildDarkModeSetting(context),
              ]),
              
              _buildSettingSection(l10n?.notifications ?? 'Notifications', [
                _buildSwitchSetting(
                  l10n?.pushNotifications ?? 'Push Notifications',
                  'Receive alerts and updates',
                  _notifications,
                  (value) => setState(() => _notifications = value),
                ),
              ]),
              
              _buildSettingSection(l10n?.tracking ?? 'Tracking', [
                _buildSwitchSetting(
                  l10n?.locationTracking ?? 'Location Tracking',
                  'Allow GPS location access',
                  _locationTracking,
                  (value) => setState(() => _locationTracking = value),
                ),
                _buildSwitchSetting(
                  l10n?.autoRefresh ?? 'Auto Refresh',
                  'Automatically refresh data',
                  _autoRefresh,
                  (value) => setState(() => _autoRefresh = value),
                ),
                _buildSliderSetting(
                  l10n?.refreshInterval ?? 'Refresh Interval',
                  '${_refreshInterval.round()}s',
                  _refreshInterval,
                  10.0,
                  120.0,
                  (value) => setState(() => _refreshInterval = value),
                ),
              ]),
              
              _buildSettingSection(l10n?.map ?? 'Map', [
                _buildSliderSetting(
                  l10n?.defaultZoomLevel ?? 'Default Zoom Level',
                  _mapZoom.toStringAsFixed(1),
                  _mapZoom,
                  10.0,
                  20.0,
                  (value) => setState(() => _mapZoom = value),
                ),
              ]),
              
              const SizedBox(height: 20),
              
              // App Info
              _buildSettingSection(l10n?.appInfo ?? 'App Info', [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n?.appTitle ?? 'e-Disha',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${l10n?.version ?? 'Version'} 1.0.0',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n?.company ?? 'Company'}: DARS Transtrade Pvt. Ltd.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _saveSettings();
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.purple,
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String value,
    double currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          trailing: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Slider(
          value: currentValue,
          min: min,
          max: max,
          divisions: ((max - min) / (max > 50 ? 10 : 1)).round(),
          onChanged: onChanged,
          activeColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildLanguageSetting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          title: Text(l10n?.language ?? 'Language', style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            languageProvider.currentLanguageDisplayName,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showLanguageDialog(context),
        );
      },
    );
  }

  Widget _buildDarkModeSetting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          title: Text(l10n?.darkMode ?? 'Dark Mode', style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(),
            activeColor: Colors.purple,
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.language, color: Colors.purple),
              const SizedBox(width: 12),
              Text(l10n?.selectLanguage ?? 'Select Language'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Text('🇺🇸', style: TextStyle(fontSize: 28)),
                      title: Text(
                        l10n?.english ?? 'English',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: languageProvider.isEnglish 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 24) 
                          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                      onTap: () {
                        languageProvider.changeLanguage('en');
                        Navigator.of(context).pop();
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    ListTile(
                      leading: const Text('🇮🇳', style: TextStyle(fontSize: 28)),
                      title: Text(
                        l10n?.hindi ?? 'हिंदी',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: languageProvider.isHindi 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 24) 
                          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                      onTap: () {
                        languageProvider.changeLanguage('hi');
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n?.cancel ?? 'Cancel',
                style: const TextStyle(color: Colors.purple),
              ),
            ),
          ],
        );
      },
    );
  }
}