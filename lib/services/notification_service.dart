import 'package:flutter/material.dart';

/// Service class for handling notifications and alerts in e-Disha app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Show success notification
  void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.green, Icons.check_circle);
  }

  /// Show error notification
  void showError(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.red, Icons.error);
  }

  /// Show warning notification
  void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.orange, Icons.warning);
  }

  /// Show info notification
  void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.blue, Icons.info);
  }

  /// Show vehicle alert notification
  void showVehicleAlert(
    BuildContext context,
    String vehicleId,
    String alertType,
  ) {
    final message = 'Vehicle $vehicleId: $alertType';
    _showSnackBar(context, message, Colors.red, Icons.directions_car);
  }

  /// Show emergency notification
  void showEmergencyAlert(BuildContext context, String message) {
    _showSnackBar(
      context,
      'EMERGENCY: $message',
      Colors.red.shade700,
      Icons.emergency,
      duration: const Duration(seconds: 10),
    );
  }

  /// Show tracking update notification
  void showTrackingUpdate(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.blue, Icons.location_on);
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.fixed, // Fixed behavior
        // Remove margin completely for fixed behavior
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show dialog notification
  void showCustomDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    String? cancelText,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(cancelText),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm?.call();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  /// Show emergency alert dialog
  void showEmergencyDialog(
    BuildContext context,
    String vehicleId,
    String alertDetails, {
    VoidCallback? onAcknowledge,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.red.shade50,
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'EMERGENCY ALERT',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle: $vehicleId'),
              const SizedBox(height: 8),
              Text('Alert: $alertDetails'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onAcknowledge?.call();
              },
              child: const Text('ACKNOWLEDGE'),
            ),
          ],
        );
      },
    );
  }

  // Backward compatibility methods for existing code
  static Future<void> showAlert(String title, String body) async {
    print('Notification: $title - $body');
  }

  static Future<void> showSuccessNotification(String message) async {
    print('Success: $message');
  }

  static Future<void> showErrorNotification(String message) async {
    print('Error: $message');
  }

  static Future<void> showInfoNotification(String message) async {
    print('Info: $message');
  }
}
