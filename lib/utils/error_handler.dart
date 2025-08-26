import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ErrorHandler {
  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: context,
    );
  }

  static void showUserFriendlyError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            // Retry logic can be implemented here.
            // For example, re-attempting the last operation.
            print('Retry action triggered.');
          },
        ),
      ),
    );
  }
}
