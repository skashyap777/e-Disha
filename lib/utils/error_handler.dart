import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:io';

class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Handle specific network errors
    if (errorString.contains('connection timed out') || 
        errorString.contains('timeout')) {
      return 'Server is temporarily unavailable. Please try again in a few minutes.';
    }
    
    if (errorString.contains('connection refused') || 
        errorString.contains('network error') ||
        errorString.contains('socketexception')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    
    if (errorString.contains('502') || errorString.contains('503') || 
        errorString.contains('504') || errorString.contains('522')) {
      return 'Server maintenance in progress. Please try again later.';
    }
    
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Authentication failed. Please check your credentials.';
    }
    
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. Please contact support.';
    }
    
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Service not found. Please try again later.';
    }
    
    if (errorString.contains('no internet') || 
        errorString.contains('network unreachable')) {
      return 'No internet connection. Please check your network settings.';
    }
    
    if (error is String) {
      return error;
    } else if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection.';
    } else if (error is Exception) {
      return "An unexpected error occurred. Please try again later.";
    } else {
      return "An unknown error occurred. Please try again later.";
    }
  }

  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: context,
    );
  }

  static void showUserFriendlyError(BuildContext context, String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tap retry to try again',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show a network status indicator
  static void showNetworkStatus(BuildContext context, bool isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isConnected 
                  ? 'Connection restored'
                  : 'No internet connection',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: isConnected ? Colors.green.shade600 : Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isConnected ? 2 : 4),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Show server maintenance message
  static void showServerMaintenanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.cloud_off,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Server Unavailable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The e-Disha server is currently unavailable (Error 522). This could be due to maintenance or high traffic.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.green.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Try Demo Mode',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Continue with offline demo features while the server is unavailable.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Show demo mode information dialog
  static void showDemoModeDialog(BuildContext context, {VoidCallback? onEnable}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Demo Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demo mode allows you to explore e-Disha features without connecting to the live server.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Credentials:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('📱 Mobile: 7896517104', style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    const Text('🔑 Password: test1234', style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    const Text('🔐 OTP: 1234, 0000, or 9999', style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (onEnable != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onEnable();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enable Demo'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
