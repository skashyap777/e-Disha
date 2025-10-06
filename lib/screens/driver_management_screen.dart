import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/driver_api_service.dart';
import '../services/device_service.dart';
import '../helpers/service_integration_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverData {
  final String? id;  // May be null for locally stored drivers
  final String? driverId;  // Real driver_id from API
  final String name;
  final String licenseNo;
  final String phoneNo;
  final String? deviceId;
  final String? vehicleRegNo;  // Vehicle registration number
  final String? photoUrl;
  final String status;
  final DateTime createdAt;
  final bool? isRealDriverId;  // Flag to indicate if driverId is from API

  DriverData({
    this.id,
    this.driverId,
    required this.name,
    required this.licenseNo,
    required this.phoneNo,
    this.deviceId,
    this.vehicleRegNo,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    this.isRealDriverId,
  });

  factory DriverData.fromJson(Map<String, dynamic> json) {
    return DriverData(
      id: json['id']?.toString(),
      driverId: json['driverId']?.toString() ?? json['driver_id']?.toString(),
      name: json['name']?.toString() ?? json['driverName']?.toString() ?? '',
      licenseNo: json['licence_no']?.toString() ?? json['license_no']?.toString() ?? json['driverLicense']?.toString() ?? 'N/A',
      phoneNo: json['phone_no']?.toString() ?? json['phone']?.toString() ?? json['driverPhone']?.toString() ?? 'N/A',
      deviceId: json['device_id']?.toString() ?? json['deviceId']?.toString(),
      vehicleRegNo: json['vehicle_reg_no']?.toString() ?? json['vehicleModel']?.toString(),
      photoUrl: json['photo']?.toString() ?? json['photo_url']?.toString() ?? json['driverPhoto']?.toString(),
      status: json['status']?.toString() ?? 'active',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['addedDate']?.toString() ?? json['date_joined']?.toString() ?? '') ?? DateTime.now(),
      isRealDriverId: json['isRealDriverId'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': name,
      'driverLicense': licenseNo,
      'driverPhone': phoneNo,
      'deviceId': deviceId,
      'vehicleModel': vehicleRegNo,
      'driverPhoto': photoUrl,
      'status': status,
      'addedDate': createdAt.toString(),
      'isRealDriverId': isRealDriverId,
    };
  }
}

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final DriverApiService _driverApiService = DriverApiService();
  final ServiceIntegrationHelper _serviceHelper = ServiceIntegrationHelper();
  
  List<DriverData> _drivers = [];
  List<DriverData> _filteredDrivers = [];
  String _searchQuery = '';

  static const String tagOwnerServiceName = 'tagOwners';

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void dispose() {
    _serviceHelper.dispose();
    super.dispose();
  }

  /// Load drivers from local storage and merge with API data
  Future<void> _loadLocalDrivers(List<DriverData> driversList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driversJson = prefs.getString('local_drivers');
      if (driversJson != null) {
        final List<dynamic> localDriversData = json.decode(driversJson);
        print('📋 Loading ${localDriversData.length} drivers from local storage');
        
        for (var localDriverData in localDriversData) {
          final localDriver = DriverData.fromJson(Map<String, dynamic>.from(localDriverData));
          
          // Avoid duplicates - check if driver already exists
          final exists = driversList.any((driver) =>
              driver.driverId == localDriver.driverId ||
              (driver.deviceId == localDriver.deviceId &&
                  driver.name == localDriver.name));
          
          if (!exists) {
            print('📋 Adding local driver: ${localDriver.name}');
            driversList.add(localDriver);
          } else {
            print('⚠️ Skipping duplicate driver: ${localDriver.name}');
          }
        }
      }
    } catch (e) {
      print('❌ Error loading local drivers: $e');
    }
  }

  /// Save drivers to local storage
  Future<void> _saveLocalDrivers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driversJson = json.encode(_drivers.map((d) => d.toJson()).toList());
      await prefs.setString('local_drivers', driversJson);
      print('💾 Saved ${_drivers.length} drivers to local storage');
    } catch (e) {
      print('❌ Error saving local drivers: $e');
    }
  }

  /// Save a newly added driver to local storage
  Future<void> _saveNewDriver(DriverData driver) async {
    _drivers.add(driver);
    await _saveLocalDrivers();
    setState(() {
      _drivers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _applyFilters();
    });
  }

  Future<void> _loadDrivers() async {
    print('\n\n🔄 _loadDrivers called');
    final result = await _serviceHelper.handleServiceCall<List<DriverData>>(
      tagOwnerServiceName,
      () {  
        print('🌐 Calling getTagOwnerList API...');
        return _driverApiService.getTagOwnerList();
      },
      (data) {
        print('\n\n🔵 Parser function called with data type: ${data.runtimeType}');
        try {
          print('========================================');
          print('🚨 DRIVER PARSING STARTED (Rapid Yatra Logic)');
          print('========================================');
          List<DriverData> driversList = [];
          
          // The API returns data in result['data'] which is already extracted by handleServiceCall
          // So 'data' here is the actual list or map, not wrapped
          print('📝 Response data type: ${data.runtimeType}');
          
          List<dynamic> tagOwnerList = [];
          
          // Handle different data types
          if (data is List) {
            // Direct list - this is what we're getting
            tagOwnerList = data as List<dynamic>;
            print('✅ Data is a direct List with ${tagOwnerList.length} items');
          } else if (data is Map) {
            // Wrapped in a map
            print('⚠️ Data is a Map, extracting list...');
            final dataMap = data as Map<String, dynamic>;
            if (dataMap.containsKey('data') && dataMap['data'] is List) {
              tagOwnerList = dataMap['data'] as List<dynamic>;
            } else if (dataMap.containsKey('items') && dataMap['items'] is List) {
              tagOwnerList = dataMap['items'] as List<dynamic>;
            } else {
              // The map itself might be the single item
              tagOwnerList = [dataMap];
            }
          } else {
            print('⚠️ Unexpected data type, trying to convert...');
            // Try to handle as a single item
            tagOwnerList = [data];
          }
          
          print('📋 Total tag owners to process: ${tagOwnerList.length}');
          
          // Log the first item structure for debugging
          if (tagOwnerList.isNotEmpty) {
            print('🔍 First item type: ${tagOwnerList.first.runtimeType}');
            if (tagOwnerList.first is Map) {
              final firstItem = tagOwnerList.first as Map;
              print('🔍 First item keys: ${firstItem.keys.toList()}');
              print('🔍 First item has "drivers" field: ${firstItem.containsKey("drivers")}');
              print('🔍 First item has "driver" field: ${firstItem.containsKey("driver")}');
            }
          }
          
          // Extract drivers from tag owner list using Rapid Yatra's comprehensive logic
          for (var item in tagOwnerList) {
            try {
              if (item is! Map<String, dynamic>) {
                item = Map<String, dynamic>.from(item as Map);
              }
              
              // Extract device information
              final device = item['device'];
              final deviceId = device?['id']?.toString();
              
              // Get vehicle registration number
              final vehicleRegNo = item['vehicle_reg_no'] ??
                  item['registration_number'] ??
                  item['reg_no'] ??
                  'Unknown Registration';
              
              // Check for driver information in multiple possible locations
              String? driverName;
              String? driverPhone;
              String? driverLicense;
              String? driverPhoto;
              String? driverId;
              
              // Priority 1: Check 'drivers' field (plural) - this is what the API uses!
              if (item['drivers'] != null) {
                print('📋 FOUND DRIVERS FIELD: ${item['drivers']}');
                final drivers = item['drivers'];
                
                if (drivers is List && drivers.isNotEmpty) {
                  final driver = drivers.first;
                  driverName = driver['name'] ?? driver['driver_name'];
                  driverPhone = driver['phone'] ?? driver['phone_no'] ?? driver['mobile'];
                  driverLicense = driver['license'] ?? driver['licence_no'] ?? driver['license_no'];
                  driverPhoto = driver['photo'] ?? driver['driver_photo'] ?? driver['photo_url'];
                  driverId = driver['id']?.toString() ?? driver['driver_id']?.toString();
                  print('📋 EXTRACTED FROM DRIVERS LIST: name=$driverName, phone=$driverPhone, id=$driverId');
                } else if (drivers is Map) {
                  driverName = drivers['name'] ?? drivers['driver_name'];
                  driverPhone = drivers['phone'] ?? drivers['phone_no'] ?? drivers['mobile'];
                  driverLicense = drivers['license'] ?? drivers['licence_no'] ?? drivers['license_no'];
                  driverPhoto = drivers['photo'] ?? drivers['driver_photo'] ?? drivers['photo_url'];
                  driverId = drivers['id']?.toString() ?? drivers['driver_id']?.toString();
                  print('📋 EXTRACTED FROM DRIVERS OBJECT: name=$driverName, phone=$driverPhone, id=$driverId');
                }
              }
              // Priority 2: Check 'driver' field (singular)
              else if (item['driver'] != null) {
                final driver = item['driver'];
                driverName = driver['name'] ?? driver['driver_name'];
                driverPhone = driver['phone'] ?? driver['phone_no'] ?? driver['mobile'];
                driverLicense = driver['license'] ?? driver['licence_no'] ?? driver['license_no'];
                driverPhoto = driver['photo'] ?? driver['driver_photo'] ?? driver['photo_url'];
                driverId = driver['id']?.toString() ?? driver['driver_id']?.toString();
                print('📋 EXTRACTED FROM DRIVER FIELD: name=$driverName, phone=$driverPhone, id=$driverId');
              }
              // Priority 3: Check direct fields
              else if (item['driver_name'] != null || item['name'] != null) {
                driverName = item['driver_name'] ?? item['name'];
                driverPhone = item['driver_phone'] ?? item['phone_no'] ?? item['mobile'];
                driverLicense = item['driver_license'] ?? item['licence_no'];
                driverPhoto = item['driver_photo'] ?? item['photo'] ?? item['photo_url'];
                driverId = item['driver_id']?.toString() ?? item['id']?.toString();
                print('📋 EXTRACTED FROM DIRECT FIELDS: name=$driverName, phone=$driverPhone, id=$driverId');
              }
              
              // Only add to drivers list if we have driver information
              if (driverName != null && driverName.isNotEmpty) {
                final hasRealDriverId = driverId != null && !driverId.contains('_');
                print('📋 Adding driver: $driverName (driverId: $driverId, isReal: $hasRealDriverId)');
                
                driversList.add(DriverData(
                  id: driverId,
                  driverId: driverId,
                  name: driverName,
                  licenseNo: driverLicense ?? 'N/A',
                  phoneNo: driverPhone ?? 'N/A',
                  deviceId: deviceId,
                  vehicleRegNo: vehicleRegNo,
                  photoUrl: driverPhoto,
                  status: 'active',
                  createdAt: DateTime.now(),
                  isRealDriverId: hasRealDriverId,
                ));
              }
            } catch (e) {
              print('❌ Error extracting driver info from item: $e');
            }
          }
          
          print('========================================');
          print('📊 Total drivers extracted from API: ${driversList.length}');
          print('========================================');
          return driversList;
        } catch (e) {
          print('❌ ERROR parsing driver data: $e');
          return <DriverData>[];
        }
      },
    );

    print('🏁 handleServiceCall completed. Success: ${result.success}');
    if (result.data != null) {
      print('📊 Result data length: ${result.data!.length}');
    }

    if (result.success && result.data != null) {
      // Load local drivers and merge with API data
      final apiDrivers = result.data!;
      await _loadLocalDrivers(apiDrivers);
      
      setState(() {
        _drivers = apiDrivers;
        _applyFilters();
      });
    } else if (result.requiresReauth) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _applyFilters() {
    _filteredDrivers = _drivers.where((driver) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return driver.name.toLowerCase().contains(query) ||
            driver.licenseNo.toLowerCase().contains(query) ||
            driver.phoneNo.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Sort by creation date (newest first)
    _filteredDrivers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddDriverDialog(),
    ).then((result) {
      if (result == true) {
        _loadDrivers(); // Refresh the list
      }
    });
  }

  void _showDriverDetails(DriverData driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('License No: ${driver.licenseNo}'),
            const SizedBox(height: 8),
            Text('Phone: ${driver.phoneNo}'),
            const SizedBox(height: 8),
            Text('Status: ${driver.status.toUpperCase()}'),
            const SizedBox(height: 8),
            if (driver.deviceId != null) ...[
              Text('Device ID: ${driver.deviceId}'),
              const SizedBox(height: 8),
            ],
            Text('Added: ${driver.createdAt.toString().substring(0, 16)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (driver.status == 'active')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeDriver(driver);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
        ],
      ),
    );
  }

  Future<void> _removeDriver(DriverData driver) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to remove this driver?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${driver.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'License: ${driver.licenseNo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Mobile: ${driver.phoneNo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove Driver'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text('Removing ${driver.name}...')),
            ],
          ),
        ),
      );

      try {
        // Use driver_id if available, otherwise fall back to device_id
        final driverId = driver.driverId ?? driver.id;
        final deviceId = driver.deviceId;
        
        // Check if we have a real driver_id (not generated)
        final hasRealDriverId = driver.isRealDriverId == true &&
            driverId != null &&
            !driverId.contains('_');
        
        Map<String, dynamic> result;
        
        if (hasRealDriverId) {
          print('🔍 Attempting removal with real driver_id: $driverId');
          result = await _driverApiService.removeDriver(
            deviceId: deviceId,
            driverId: driverId,
          );
        } else {
          print('🔍 Attempting removal with device_id only: $deviceId');
          result = await _driverApiService.removeDriver(
            deviceId: deviceId,
            driverId: null,
          );
        }
        
        // If first attempt fails, try alternative approach
        if (!result['success'] && deviceId != null && driverId != null) {
          print('🔍 First attempt failed, trying alternative approach...');
          if (hasRealDriverId) {
            result = await _driverApiService.removeDriver(
              deviceId: deviceId,
              driverId: null,
            );
          } else {
            result = await _driverApiService.removeDriver(
              deviceId: deviceId,
              driverId: deviceId,
            );
          }
        }
        
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        if (mounted) {
          final errorMessage = result['message'] ?? 'Failed to remove driver';
          
          if (result['success']) {
            ServiceIntegrationHelper.showSuccessSnackbar(
              context,
              '${driver.name} removed successfully from server',
            );
          } else if (errorMessage.contains('does not exist') ||
              result['data']?['status_code'] == 404) {
            ServiceIntegrationHelper.showInfoSnackbar(
              context,
              '${driver.name} was not found on server (removing from local list)',
            );
          } else {
            ServiceIntegrationHelper.showWarningSnackbar(
              context,
              'Server error removing ${driver.name}, but removed from local list',
            );
          }
          
          // Always remove from local storage
          _drivers.removeWhere((d) =>
              d.driverId == driver.driverId ||
              (d.deviceId == driver.deviceId && d.name == driver.name));
          await _saveLocalDrivers();
          
          setState(() {
            _applyFilters();
          });
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        if (mounted) {
          ServiceIntegrationHelper.showErrorSnackbar(
            context,
            'Network error: Failed to remove ${driver.name}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrivers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search drivers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Drivers List
          Expanded(
            child: _serviceHelper.isServiceLoading(tagOwnerServiceName)
                ? ServiceIntegrationHelper.buildLoadingWidget('Loading drivers...')
                : _serviceHelper.hasServiceError(tagOwnerServiceName)
                    ? ServiceIntegrationHelper.buildErrorWidget(
                        _serviceHelper.getServiceError(tagOwnerServiceName) ?? 'Unknown error',
                        onRetry: _loadDrivers,
                      )
                    : _filteredDrivers.isEmpty
                        ? ServiceIntegrationHelper.buildEmptyStateWidget(
                            'No drivers found',
                            Icons.people_outline,
                          )
                        : ListView.builder(
                            itemCount: _filteredDrivers.length,
                            itemBuilder: (context, index) {
                              final driver = _filteredDrivers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    child: driver.photoUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.network(
                                              driver.photoUrl!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => 
                                                const Icon(Icons.person, color: Colors.blue),
                                            ),
                                          )
                                        : const Icon(Icons.person, color: Colors.blue),
                                  ),
                                  title: Text(
                                    driver.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('License: ${driver.licenseNo}'),
                                      const SizedBox(height: 2),
                                      Text('Phone: ${driver.phoneNo}'),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: driver.status == 'active' ? Colors.green : Colors.grey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      driver.status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _showDriverDetails(driver),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDriverDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Driver',
      ),
    );
  }
}

class AddDriverDialog extends StatefulWidget {
  const AddDriverDialog({super.key});

  @override
  State<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final DriverApiService _driverApiService = DriverApiService();
  final DeviceService _deviceService = DeviceService();
  final ServiceIntegrationHelper _serviceHelper = ServiceIntegrationHelper();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isLoadingDevices = true;
  List<DeviceOwnerData> _availableDevices = [];
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _loadAvailableDevices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _serviceHelper.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableDevices() async {
    try {
      final devices = await _deviceService.getOwnerList();
      setState(() {
        _availableDevices = devices;
        _isLoadingDevices = false;
        if (devices.isNotEmpty) {
          _selectedDeviceId = devices.first.device.id;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingDevices = false;
      });
      if (mounted) {
        ServiceIntegrationHelper.showErrorSnackbar(context, 'Failed to load devices: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    // Show bottom sheet to choose camera or gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Choose Photo Source',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                // Camera Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.blue,
                    ),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Use camera to capture photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                // Gallery Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.green,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Select from existing photos'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 10),
                // Cancel Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ServiceIntegrationHelper.showErrorSnackbar(
          context,
          'Failed to pick image: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ServiceIntegrationHelper.showErrorSnackbar(context, 'Please select a photo');
      return;
    }
    if (_selectedDeviceId == null) {
      ServiceIntegrationHelper.showErrorSnackbar(context, 'Please select a device');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _serviceHelper.handleServiceCall<bool>(
      'addDriver',
      () => _driverApiService.addDriver(
        deviceId: _selectedDeviceId!,
        photo: _selectedImage!,
        name: _nameController.text.trim(),
        licenceNo: _licenseController.text.trim(),
        phoneNo: _phoneController.text.trim(),
      ),
      (_) => true,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (result.success) {
      ServiceIntegrationHelper.showSuccessSnackbar(
        context,
        'Driver added successfully',
      );
      Navigator.of(context).pop(true); // Return success
    } else {
      ServiceIntegrationHelper.showErrorSnackbar(
        context,
        result.message ?? 'Failed to add driver',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Driver'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo Selection
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add photo',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Camera or Gallery',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter driver name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // License Field
                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'License Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter license number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Device Selector
                if (_isLoadingDevices)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_availableDevices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No devices found. Please add a device first.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDeviceId,
                        decoration: const InputDecoration(
                          labelText: 'Select Vehicle/Device',
                          prefixIcon: Icon(Icons.directions_car),
                          border: InputBorder.none,
                        ),
                        items: _availableDevices.map((device) {
                          final displayText = device.vehicleRegNo.isNotEmpty
                              ? '${device.vehicleRegNo} (${device.device.id})'
                              : 'Device ${device.device.id}';
                          return DropdownMenuItem<String>(
                            value: device.device.id,
                            child: Text(
                              displayText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDeviceId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a device';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Driver'),
        ),
      ],
    );
  }
}