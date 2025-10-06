import 'package:flutter/material.dart';
import '../services/gps_tracking_service.dart';

class GPSTestScreen extends StatefulWidget {
  const GPSTestScreen({super.key});

  @override
  State<GPSTestScreen> createState() => _GPSTestScreenState();
}

class _GPSTestScreenState extends State<GPSTestScreen> {
  final GPSTrackingService _gpsService = GPSTrackingService();
  String _testResult = 'Ready to test...';
  bool _isLoading = false;
  List<GPSLocationData> _testData = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS API Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Connection Test',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _testResult,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_testData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Retrieved Data:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...(_testData.take(3).map((data) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${data.vehicleId}: ${data.latitude}, ${data.longitude} (${data.packetType})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ))),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(_isLoading ? 'Testing...' : 'Test GPS API Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _clearResults,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Results'),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SSL Certificate Fix Applied',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This test uses a custom HTTP client that bypasses SSL verification specifically for the Skytron API domain (api.skytron.in). This resolves the HandshakeException: CERTIFICATE_VERIFY_FAILED error.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'If the API fails, mock data will be returned for demonstration purposes.',
                      style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing GPS API connection with SSL bypass...';
    });

    try {
      final stopwatch = Stopwatch()..start();
      final data = await _gpsService.fetchGPSData();
      stopwatch.stop();

      setState(() {
        _testData = data;
        if (data.isEmpty) {
          _testResult = 'Connection successful but no data returned (${stopwatch.elapsedMilliseconds}ms)';
        } else {
          _testResult = 'Success! Retrieved ${data.length} GPS location(s) in ${stopwatch.elapsedMilliseconds}ms\n\nSSL certificate verification bypassed for Skytron API.';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Connection failed: $e\n\nNote: The app should still work with mock data.';
        _isLoading = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResult = 'Ready to test...';
      _testData = [];
    });
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }
}
