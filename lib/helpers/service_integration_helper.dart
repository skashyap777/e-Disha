import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ServiceState { idle, loading, success, error }

class ServiceResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final bool requiresReauth;

  ServiceResult({
    required this.success,
    this.data,
    this.message,
    this.requiresReauth = false,
  });
}

class ServiceIntegrationHelper extends ChangeNotifier {
  final Map<String, ServiceState> _serviceStates = {};
  final Map<String, String?> _serviceErrors = {};

  ServiceState getServiceState(String serviceName) {
    return _serviceStates[serviceName] ?? ServiceState.idle;
  }

  String? getServiceError(String serviceName) {
    return _serviceErrors[serviceName];
  }

  bool isServiceLoading(String serviceName) {
    return _serviceStates[serviceName] == ServiceState.loading;
  }

  bool hasServiceError(String serviceName) {
    return _serviceStates[serviceName] == ServiceState.error;
  }

  void setServiceLoading(String serviceName) {
    _serviceStates[serviceName] = ServiceState.loading;
    _serviceErrors[serviceName] = null;
    notifyListeners();
  }

  void setServiceSuccess(String serviceName) {
    _serviceStates[serviceName] = ServiceState.success;
    _serviceErrors[serviceName] = null;
    notifyListeners();
  }

  void setServiceError(String serviceName, String error) {
    _serviceStates[serviceName] = ServiceState.error;
    _serviceErrors[serviceName] = error;
    notifyListeners();
  }

  void clearService(String serviceName) {
    _serviceStates[serviceName] = ServiceState.idle;
    _serviceErrors[serviceName] = null;
    notifyListeners();
  }

  /// Handle service calls with consistent error handling and state management
  Future<ServiceResult<T>> handleServiceCall<T>(
    String serviceName,
    Future<Map<String, dynamic>> Function() serviceCall,
    T Function(dynamic)? dataParser,
  ) async {
    try {
      setServiceLoading(serviceName);
      
      final result = await serviceCall();
      
      print('🔵 ServiceIntegrationHelper result keys: ${result.keys.toList()}');
      print('🔵 ServiceIntegrationHelper result["success"]: ${result['success']}');
      print('🔵 ServiceIntegrationHelper success check: ${result['success'] == true}');
      
      if (result['success'] == true) {
        print('✅ Success condition met, calling setServiceSuccess');
        setServiceSuccess(serviceName);
        
        T? parsedData;
        print('📑 dataParser null? ${dataParser == null}');
        print('📑 result["data"] null? ${result['data'] == null}');
        
        if (dataParser != null && result['data'] != null) {
          print('🚀 About to call dataParser...');
          try {
            parsedData = dataParser(result['data']);
            print('✅ dataParser completed successfully');
          } catch (e, stackTrace) {
            print('❌ ERROR in dataParser: $e');
            print('❌ Stack trace: $stackTrace');
            throw e; // Re-throw to be caught by outer catch
          }
        }
        
        print('🏁 Returning ServiceResult with success=true');
        return ServiceResult<T>(
          success: true,
          data: parsedData,
          message: result['message'],
        );
      } else {
        final error = result['message'] ?? 'Unknown error occurred';
        setServiceError(serviceName, error);
        
        return ServiceResult<T>(
          success: false,
          message: error,
          requiresReauth: result['requiresReauth'] ?? false,
        );
      }
    } catch (e) {
      final error = 'Network error: $e';
      setServiceError(serviceName, error);
      
      return ServiceResult<T>(
        success: false,
        message: error,
      );
    }
  }

  /// Show error dialog with consistent styling
  static void showErrorDialog(BuildContext context, String title, String message, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar with consistent styling
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error snackbar with consistent styling
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info snackbar with consistent styling
  static void showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show warning snackbar with consistent styling
  static void showWarningSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Create a loading widget with consistent styling
  static Widget buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Create an error widget with consistent styling
  static Widget buildErrorWidget(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Create an empty state widget with consistent styling
  static Widget buildEmptyStateWidget(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}