import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

/// A widget that shows the current network connectivity status
class NetworkStatusIndicator extends StatefulWidget {
  final Widget child;
  final bool showOfflineMessage;

  const NetworkStatusIndicator({
    super.key,
    required this.child,
    this.showOfflineMessage = true,
  });

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  bool _isConnected = true;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _startConnectivityCheck();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (mounted && _isConnected != isConnected) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    } catch (e) {
      if (mounted && _isConnected != false) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isConnected && widget.showOfflineMessage)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              color: Colors.orange.shade600,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A simple connectivity checker utility
class ConnectivityChecker {
  static Future<bool> hasConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 10));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if a specific host is reachable
  static Future<bool> canReachHost(String host) async {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 10));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}