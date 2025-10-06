import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum VehicleType {
  yellowCar,
  blueCar,
  brownTruck,
  bike,
  bus,
}

enum VehicleState {
  moving,
  stopped,
  idle,
  offline,
}

class CustomVehicleIcons {
  static final Map<String, BitmapDescriptor> _cachedIcons = {};

  // Get vehicle state from packet type
  static VehicleState getStateFromPacketType(String? packetType) {
    if (packetType == null) return VehicleState.offline;

    switch (packetType.toLowerCase()) {
      case 'moving':
      case 'drive':
      case 'driving':
        return VehicleState.moving;
      case 'stopped':
      case 'stop':
        return VehicleState.stopped;
      case 'idle':
      case 'idling':
        return VehicleState.idle;
      case 'offline':
      case 'disconnected':
        return VehicleState.offline;
      default:
        return VehicleState.moving;
    }
  }

  // Create vehicle icon based on type and state
  static Future<BitmapDescriptor> createVehicleIcon(
    VehicleType type,
    VehicleState state, {
    double size = 80.0,
  }) async {
    final cacheKey = '${type.name}_${state.name}_$size';
    debugPrint('🏁 Creating vehicle icon: $cacheKey');

    if (_cachedIcons.containsKey(cacheKey)) {
      debugPrint('💾 Using cached icon for: $cacheKey');
      return _cachedIcons[cacheKey]!;
    }

    try {
      final icon = await _generateVehicleIcon(type, state, size);
      _cachedIcons[cacheKey] = icon;
      debugPrint('✅ Successfully created and cached icon: $cacheKey');
      return icon;
    } catch (e) {
      debugPrint('❌ Error creating vehicle icon: $e');
      // Return ultimate fallback
      const fallback = BitmapDescriptor.defaultMarker;
      _cachedIcons[cacheKey] = fallback; // Cache the fallback too
      return fallback;
    }
  }

  static Future<BitmapDescriptor> _generateVehicleIcon(
    VehicleType type,
    VehicleState state,
    double size,
  ) async {
    try {
      // Try to load PNG asset first
      final pngIcon = await _loadPngAsset(type, state, size);
      return pngIcon;
    } catch (e) {
      debugPrint('⚠️ Error loading PNG asset: $e');
      debugPrint('🔄 Falling back to colored marker');
      try {
        return _getFallbackMarker(type, state);
      } catch (fallbackError) {
        debugPrint('❌ Fallback marker also failed: $fallbackError');
        // Ultimate fallback to default marker
        return BitmapDescriptor.defaultMarker;
      }
    }
  }

  static Future<BitmapDescriptor> _loadPngAsset(
    VehicleType type,
    VehicleState state,
    double size,
  ) async {
    try {
      final assetPath = _getAssetPath(type);
      debugPrint('🖼️ Loading vehicle icon from: $assetPath');

      // Load the asset as bytes
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: size.toInt(),
        targetHeight: size.toInt(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Convert to bytes for BitmapDescriptor
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final Uint8List uint8List = byteData.buffer.asUint8List();
      final BitmapDescriptor bitmapDescriptor =
          BitmapDescriptor.fromBytes(uint8List);

      debugPrint('✅ Successfully loaded PNG asset for ${type.name}');
      return bitmapDescriptor;
    } catch (e) {
      debugPrint('❌ Failed to load PNG asset: $e');
      rethrow; // Re-throw to trigger fallback
    }
  }

  static String _getAssetPath(VehicleType type) {
    switch (type) {
      case VehicleType.yellowCar:
        return 'assets/images/yellow car.png';
      case VehicleType.blueCar:
        return 'assets/images/blur car.png';
      case VehicleType.brownTruck:
        return 'assets/images/brown truck.png';
      case VehicleType.bike:
        return 'assets/images/bike.png';
      case VehicleType.bus:
        return 'assets/images/bus.png';
    }
  }

  static BitmapDescriptor _getFallbackMarker(
      VehicleType type, VehicleState state) {
    double hue;

    // Choose hue based on vehicle type
    switch (type) {
      case VehicleType.yellowCar:
        hue = BitmapDescriptor.hueYellow;
        break;
      case VehicleType.blueCar:
        hue = BitmapDescriptor.hueBlue;
        break;
      case VehicleType.brownTruck:
        hue = BitmapDescriptor.hueOrange;
        break;
      case VehicleType.bike:
        hue = BitmapDescriptor.hueGreen;
        break;
      case VehicleType.bus:
        hue = BitmapDescriptor.hueViolet;
        break;
    }

    // Modify based on state
    switch (state) {
      case VehicleState.stopped:
        hue = BitmapDescriptor.hueRed;
        break;
      case VehicleState.offline:
        hue = 0.0; // Black/Grey equivalent
        break;
      case VehicleState.idle:
        hue = BitmapDescriptor.hueOrange;
        break;
      case VehicleState.moving:
      default:
        // Keep the vehicle type hue
        break;
    }

    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  static VehicleColors _getVehicleColors(VehicleType type, VehicleState state) {
    Color backgroundColor;
    Color iconColor;
    Color borderColor;

    // Base colors by vehicle type
    switch (type) {
      case VehicleType.yellowCar:
        backgroundColor = Colors.yellow.shade100;
        iconColor = Colors.orange.shade700;
        borderColor = Colors.orange.shade900;
        break;
      case VehicleType.blueCar:
        backgroundColor = Colors.blue.shade100;
        iconColor = Colors.blue.shade700;
        borderColor = Colors.blue.shade900;
        break;
      case VehicleType.brownTruck:
        backgroundColor = Colors.brown.shade100;
        iconColor = Colors.brown.shade700;
        borderColor = Colors.brown.shade900;
        break;
      case VehicleType.bike:
        backgroundColor = Colors.green.shade100;
        iconColor = Colors.green.shade700;
        borderColor = Colors.green.shade900;
        break;
      case VehicleType.bus:
        backgroundColor = Colors.purple.shade100;
        iconColor = Colors.purple.shade700;
        borderColor = Colors.purple.shade900;
        break;
    }

    // Modify colors based on state
    switch (state) {
      case VehicleState.moving:
        // Keep original colors
        break;
      case VehicleState.stopped:
        backgroundColor = Colors.red.shade100;
        iconColor = Colors.red.shade700;
        borderColor = Colors.red.shade900;
        break;
      case VehicleState.idle:
        backgroundColor = Colors.orange.shade100;
        iconColor = Colors.orange.shade700;
        borderColor = Colors.orange.shade900;
        break;
      case VehicleState.offline:
        backgroundColor = Colors.grey.shade300;
        iconColor = Colors.grey.shade600;
        borderColor = Colors.grey.shade800;
        break;
    }

    return VehicleColors(
      background: backgroundColor,
      icon: iconColor,
      border: borderColor,
    );
  }

  static void _drawVehicleShape(
      Canvas canvas, VehicleType type, double size, Paint paint) {
    final center = Offset(size / 2, size / 2);
    final iconSize = size * 0.4;

    switch (type) {
      case VehicleType.yellowCar:
      case VehicleType.blueCar:
        _drawCar(canvas, center, iconSize, paint);
        break;
      case VehicleType.brownTruck:
        _drawTruck(canvas, center, iconSize, paint);
        break;
      case VehicleType.bike:
        _drawBike(canvas, center, iconSize, paint);
        break;
      case VehicleType.bus:
        _drawBus(canvas, center, iconSize, paint);
        break;
    }
  }

  static void _drawCar(Canvas canvas, Offset center, double size, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size * 1.2, height: size * 0.8),
      Radius.circular(size * 0.1),
    );
    canvas.drawRRect(rect, paint);

    // Draw windows
    paint.color = paint.color.withOpacity(0.3);
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size * 0.8, height: size * 0.4),
      Radius.circular(size * 0.05),
    );
    canvas.drawRRect(windowRect, paint);
  }

  static void _drawTruck(
      Canvas canvas, Offset center, double size, Paint paint) {
    // Draw truck cab
    final cabRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - size * 0.3, center.dy),
        width: size * 0.6,
        height: size * 0.8,
      ),
      Radius.circular(size * 0.05),
    );
    canvas.drawRRect(cabRect, paint);

    // Draw truck bed
    final bedRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + size * 0.3, center.dy),
        width: size * 0.8,
        height: size * 0.6,
      ),
      Radius.circular(size * 0.03),
    );
    canvas.drawRRect(bedRect, paint);
  }

  static void _drawBike(
      Canvas canvas, Offset center, double size, Paint paint) {
    // Draw bike body (simplified)
    paint.strokeWidth = size * 0.1;
    paint.style = PaintingStyle.stroke;

    // Wheels
    canvas.drawCircle(
      Offset(center.dx - size * 0.3, center.dy + size * 0.1),
      size * 0.2,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + size * 0.3, center.dy + size * 0.1),
      size * 0.2,
      paint,
    );

    // Frame
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size * 0.8, height: size * 0.1),
      paint,
    );
  }

  static void _drawBus(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw bus body
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size * 1.4, height: size * 0.9),
      Radius.circular(size * 0.1),
    );
    canvas.drawRRect(rect, paint);

    // Draw windows
    paint.color = paint.color.withOpacity(0.3);
    for (int i = 0; i < 3; i++) {
      final windowRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
              center.dx - size * 0.4 + i * size * 0.4, center.dy - size * 0.1),
          width: size * 0.25,
          height: size * 0.3,
        ),
        Radius.circular(size * 0.03),
      );
      canvas.drawRRect(windowRect, paint);
    }
  }

  static void _drawStateIndicator(
      Canvas canvas, VehicleState state, double size, Paint paint) {
    final indicatorSize = size * 0.15;
    final position = Offset(size * 0.85, size * 0.15);

    Color indicatorColor;
    switch (state) {
      case VehicleState.moving:
        indicatorColor = Colors.green;
        break;
      case VehicleState.stopped:
        indicatorColor = Colors.red;
        break;
      case VehicleState.idle:
        indicatorColor = Colors.orange;
        break;
      case VehicleState.offline:
        indicatorColor = Colors.grey;
        break;
    }

    // Draw indicator background
    paint.color = Colors.white;
    canvas.drawCircle(position, indicatorSize + 2, paint);

    // Draw indicator
    paint.color = indicatorColor;
    canvas.drawCircle(position, indicatorSize, paint);
  }

  // Clear cached icons
  static void clearCache() {
    _cachedIcons.clear();
  }
}

class VehicleColors {
  final Color background;
  final Color icon;
  final Color border;

  const VehicleColors({
    required this.background,
    required this.icon,
    required this.border,
  });
}
