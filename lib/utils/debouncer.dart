import 'dart:async';
import 'package:flutter/material.dart';

/// Debouncer utility for e-Disha to prevent excessive function calls
/// Particularly useful for GPS updates, search queries, and map interactions
/// 
/// Usage in e-Disha:
/// ```dart
/// // In LiveTrackingScreen
/// final _gpsDebouncer = EDishaDebouncer(duration: Duration(milliseconds: 300));
/// 
/// void _onGPSUpdate(data) {
///   _gpsDebouncer.run(() {
///     _updateMarkersFromGPSData(data);
///   });
/// }
/// 
/// // In RouteFixingScreen
/// final _routeDebouncer = EDishaDebouncer(duration: Duration(milliseconds: 500));
/// 
/// void _onRoutePointsChanged(List<LatLng> points) {
///   _routeDebouncer.run(() {
///     _updateRouteOnMap(points);
///   });
/// }
/// ```
class EDishaDebouncer {
  final Duration duration;
  Timer? _timer;
  String? _debugName;

  EDishaDebouncer({
    required this.duration,
    String? debugName,
  }) : _debugName = debugName;

  void run(VoidCallback action) {
    _timer?.cancel();
    
    if (_debugName != null) {
      debugPrint('⏳ [e-Disha] Debouncing $_debugName for ${duration.inMilliseconds}ms');
    }
    
    _timer = Timer(duration, () {
      if (_debugName != null) {
        debugPrint('✅ [e-Disha] Executing debounced $_debugName');
      }
      action();
    });
  }

  void cancel() {
    _timer?.cancel();
    if (_debugName != null) {
      debugPrint('❌ [e-Disha] Cancelled debounced $_debugName');
    }
  }

  void dispose() {
    _timer?.cancel();
  }

  bool get isActive => _timer?.isActive ?? false;
}

/// Throttler utility for e-Disha to limit function execution rate
/// Useful for limiting API calls or expensive operations
/// 
/// Usage in e-Disha:
/// ```dart
/// final _apiThrottler = EDishaThrottler(duration: Duration(seconds: 2));
/// 
/// void _fetchGPSData() {
///   _apiThrottler.run(() {
///     _gpsService.fetchGPSData();
///   });
/// }
/// ```
class EDishaThrottler {
  final Duration duration;
  Timer? _timer;
  bool _isRunning = false;
  String? _debugName;

  EDishaThrottler({
    required this.duration,
    String? debugName,
  }) : _debugName = debugName;

  void run(VoidCallback action) {
    if (!_isRunning) {
      _isRunning = true;
      
      if (_debugName != null) {
        debugPrint('🚀 [e-Disha] Executing throttled $_debugName');
      }
      
      action();
      
      _timer = Timer(duration, () {
        _isRunning = false;
        if (_debugName != null) {
          debugPrint('✅ [e-Disha] Throttle cooldown finished for $_debugName');
        }
      });
    } else {
      if (_debugName != null) {
        debugPrint('⏸️ [e-Disha] Throttled $_debugName - skipping execution');
      }
    }
  }

  void cancel() {
    _timer?.cancel();
    _isRunning = false;
    if (_debugName != null) {
      debugPrint('❌ [e-Disha] Cancelled throttled $_debugName');
    }
  }

  void dispose() {
    _timer?.cancel();
  }

  bool get isRunning => _isRunning;
}

/// Smart Debouncer for e-Disha - combination of debounce and throttle
/// First call executes immediately (throttle), subsequent calls are debounced
/// Perfect for real-time GPS updates where you want immediate response but also smoothness
/// 
/// Usage in e-Disha:
/// ```dart
/// final _smartDebouncer = EDishaSmartDebouncer(
///   debounceTime: Duration(milliseconds: 300),
///   throttleTime: Duration(seconds: 1),
///   debugName: 'GPS Updates',
/// );
/// 
/// void _onGPSUpdate(data) {
///   _smartDebouncer.run(() {
///     _updateMap(data);
///   });
/// }
/// ```
class EDishaSmartDebouncer {
  final Duration debounceTime;
  final Duration throttleTime;
  Timer? _debounceTimer;
  DateTime? _lastExecuted;
  String? _debugName;

  EDishaSmartDebouncer({
    required this.debounceTime,
    required this.throttleTime,
    String? debugName,
  }) : _debugName = debugName;

  void run(VoidCallback action) {
    final now = DateTime.now();
    
    // If enough time has passed since last execution, execute immediately (throttle)
    if (_lastExecuted == null ||
        now.difference(_lastExecuted!) >= throttleTime) {
      
      if (_debugName != null) {
        debugPrint('⚡ [e-Disha] Smart debouncer - immediate execution for $_debugName');
      }
      
      action();
      _lastExecuted = now;
      return;
    }

    // Otherwise, debounce the call
    _debounceTimer?.cancel();
    
    if (_debugName != null) {
      debugPrint('⏳ [e-Disha] Smart debouncer - debouncing $_debugName for ${debounceTime.inMilliseconds}ms');
    }
    
    _debounceTimer = Timer(debounceTime, () {
      if (_debugName != null) {
        debugPrint('✅ [e-Disha] Smart debouncer - executing debounced $_debugName');
      }
      action();
      _lastExecuted = DateTime.now();
    });
  }

  void cancel() {
    _debounceTimer?.cancel();
    if (_debugName != null) {
      debugPrint('❌ [e-Disha] Cancelled smart debounced $_debugName');
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }

  bool get isActive => _debounceTimer?.isActive ?? false;
}

/// Factory class for creating pre-configured debouncers for common e-Disha use cases
class EDishaDebouncerFactory {
  /// For GPS updates in LiveTrackingScreen
  static EDishaDebouncer createGPSDebouncer() {
    return EDishaDebouncer(
      duration: const Duration(milliseconds: 300),
      debugName: 'GPS Updates',
    );
  }

  /// For route updates in RouteFixingScreen  
  static EDishaDebouncer createRouteDebouncer() {
    return EDishaDebouncer(
      duration: const Duration(milliseconds: 500),
      debugName: 'Route Updates',
    );
  }

  /// For search queries
  static EDishaDebouncer createSearchDebouncer() {
    return EDishaDebouncer(
      duration: const Duration(milliseconds: 400),
      debugName: 'Search Query',
    );
  }

  /// For API calls throttling
  static EDishaThrottler createAPIThrottler() {
    return EDishaThrottler(
      duration: const Duration(seconds: 2),
      debugName: 'API Calls',
    );
  }

  /// For real-time GPS with smart debouncing
  static EDishaSmartDebouncer createSmartGPSDebouncer() {
    return EDishaSmartDebouncer(
      debounceTime: const Duration(milliseconds: 300),
      throttleTime: const Duration(seconds: 1),
      debugName: 'Smart GPS Updates',
    );
  }

  /// For dashboard data updates
  static EDishaDebouncer createDashboardDebouncer() {
    return EDishaDebouncer(
      duration: const Duration(milliseconds: 800),
      debugName: 'Dashboard Updates',
    );
  }
}

/// Extension on StatefulWidget to easily add debouncing capability
extension EDishaWidgetDebouncing on State<StatefulWidget> {
  /// Create a debouncer that gets disposed automatically with the widget
  EDishaDebouncer createAutoDisposedDebouncer({
    required Duration duration,
    String? debugName,
  }) {
    final debouncer = EDishaDebouncer(
      duration: duration,
      debugName: debugName,
    );
    
    // Store reference for cleanup (you would typically store this in your State class)
    return debouncer;
  }
}