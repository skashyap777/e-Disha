import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Global cache for marker icons in e-Disha to avoid recreating them on every map update
/// This significantly improves performance in LiveTrackingScreen and RouteFixingScreen
class EDishaMarkerIconCache {
  static final Map<String, BitmapDescriptor> _cache = {};
  static final Map<String, Completer<BitmapDescriptor>> _loadingCompleters = {};

  /// Get a cached marker icon or load it if not cached
  /// 
  /// Usage in e-Disha:
  /// ```dart
  /// // In LiveTrackingScreen
  /// final icon = await EDishaMarkerIconCache.getMarkerIcon(
  ///   'vehicle_${vehicleId}',
  ///   () => CustomVehicleIcons.createVehicleIcon(vehicleType, state),
  /// );
  /// 
  /// // In RouteFixingScreen  
  /// final routeIcon = await EDishaMarkerIconCache.getMarkerIcon(
  ///   'route_marker_${routeId}',
  ///   () => _loadRouteMarkerIcon(),
  /// );
  /// ```
  static Future<BitmapDescriptor> getMarkerIcon(
    String key,
    Future<BitmapDescriptor> Function() loader,
  ) async {
    // Return cached icon if available
    if (_cache.containsKey(key)) {
      debugPrint('📦 [e-Disha] Using cached marker icon: $key');
      return _cache[key]!;
    }

    // If already loading, wait for it
    if (_loadingCompleters.containsKey(key)) {
      debugPrint('⏳ [e-Disha] Waiting for marker icon to load: $key');
      return await _loadingCompleters[key]!.future;
    }

    // Start loading
    debugPrint('🔄 [e-Disha] Loading new marker icon: $key');
    final completer = Completer<BitmapDescriptor>();
    _loadingCompleters[key] = completer;

    try {
      final icon = await loader();
      _cache[key] = icon;
      completer.complete(icon);
      debugPrint('✅ [e-Disha] Marker icon cached: $key');
      return icon;
    } catch (e) {
      debugPrint('❌ [e-Disha] Failed to load marker icon: $key - $e');
      completer.completeError(e);
      rethrow;
    } finally {
      _loadingCompleters.remove(key);
    }
  }

  /// Preload commonly used icons for e-Disha
  static Future<void> preloadEDishaIcons() async {
    debugPrint('🔄 [e-Disha] Preloading common marker icons...');
    
    try {
      // Preload default marker
      await getMarkerIcon(
        'default_marker',
        () async => BitmapDescriptor.defaultMarker,
      );

      // Preload vehicle markers for different states
      await getMarkerIcon(
        'vehicle_active',
        () => _createColoredMarker(Colors.green, 'A'),
      );

      await getMarkerIcon(
        'vehicle_inactive',
        () => _createColoredMarker(Colors.grey, 'I'),
      );

      await getMarkerIcon(
        'vehicle_moving',
        () => _createColoredMarker(Colors.blue, 'M'),
      );

      // Preload route markers
      await getMarkerIcon(
        'route_start',
        () async => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      await getMarkerIcon(
        'route_end',
        () async => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      debugPrint('✅ [e-Disha] Common marker icons preloaded');
    } catch (e) {
      debugPrint('❌ [e-Disha] Failed to preload marker icons: $e');
    }
  }

  /// Create a colored marker with text overlay
  static Future<BitmapDescriptor> _createColoredMarker(Color color, String text) async {
    const int size = 120;
    
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Draw circle background
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 10,
      paint,
    );
    
    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 10,
      borderPaint,
    );
    
    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final Uint8List uint8List = byteData.buffer.asUint8List();
      return await BitmapDescriptor.fromBytes(uint8List);
    }
    
    return BitmapDescriptor.defaultMarker;
  }

  /// Load an icon from assets (e-Disha specific paths)
  static Future<BitmapDescriptor> loadEDishaAssetIcon(
    String assetPath,
    int width,
    int height,
  ) async {
    return await getMarkerIcon(
      'asset_${assetPath}_${width}x$height',
      () => _loadAssetIcon(assetPath, width, height),
    );
  }

  static Future<BitmapDescriptor> _loadAssetIcon(
    String assetPath,
    int width,
    int height,
  ) async {
    final ImageConfiguration config = const ImageConfiguration();
    final ImageStream stream = AssetImage(assetPath).resolve(config);

    final Completer<BitmapDescriptor> completer = Completer();

    stream.addListener(ImageStreamListener(
      (ImageInfo image, bool _) async {
        try {
          final ui.Image markerImage = image.image;

          final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
          final Canvas canvas = Canvas(pictureRecorder);

          canvas.drawImageRect(
            markerImage,
            Rect.fromLTWH(
              0,
              0,
              markerImage.width.toDouble(),
              markerImage.height.toDouble(),
            ),
            Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
            Paint()..filterQuality = FilterQuality.high,
          );

          final ui.Picture picture = pictureRecorder.endRecording();
          final ui.Image img = await picture.toImage(width, height);
          final ByteData? byteData =
              await img.toByteData(format: ui.ImageByteFormat.png);

          if (byteData != null) {
            final Uint8List uint8List = byteData.buffer.asUint8List();
            final BitmapDescriptor bitmap =
                await BitmapDescriptor.fromBytes(uint8List);
            completer.complete(bitmap);
          } else {
            throw Exception('Failed to convert image to bytes');
          }
        } catch (e) {
          completer.completeError(e);
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        completer.completeError(error);
      },
    ));

    return completer.future;
  }

  /// Clear a specific cached icon
  static void clearIcon(String key) {
    _cache.remove(key);
    debugPrint('🗑️ [e-Disha] Cleared cached marker icon: $key');
  }

  /// Clear all cached icons (useful when switching themes or vehicle types)
  static void clearAll() {
    _cache.clear();
    _loadingCompleters.clear();
    debugPrint('🗑️ [e-Disha] Cleared all cached marker icons');
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'project': 'e-Disha',
      'cached_icons': _cache.length,
      'loading_icons': _loadingCompleters.length,
      'cache_keys': _cache.keys.toList(),
      'memory_estimate_kb': _cache.length * 10, // Rough estimate
    };
  }

  /// Utility method to create vehicle marker with specific styling for e-Disha
  static Future<BitmapDescriptor> createEDishaVehicleMarker({
    required String vehicleId,
    required String vehicleType,
    required bool isActive,
    required bool isMoving,
  }) async {
    final key = 'edisha_vehicle_${vehicleId}_${vehicleType}_${isActive}_$isMoving';
    
    return await getMarkerIcon(key, () async {
      Color markerColor;
      String markerText;
      
      if (!isActive) {
        markerColor = Colors.grey;
        markerText = 'X';
      } else if (isMoving) {
        markerColor = Colors.green;
        markerText = '→';
      } else {
        markerColor = Colors.blue;
        markerText = '■';
      }
      
      return await _createColoredMarker(markerColor, markerText);
    });
  }
}