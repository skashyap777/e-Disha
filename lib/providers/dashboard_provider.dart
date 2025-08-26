import 'package:flutter/foundation.dart';

/// Provider for managing dashboard data state.
///
/// TODO: In the future, connect this provider to backend API services for live data.
class DashboardProvider extends ChangeNotifier {
  Map<String, dynamic> _dashboardData = {};

  /// Updates the dashboard data and notifies listeners.
  void updateData(Map<String, dynamic> newData) {
    _dashboardData = newData;
    notifyListeners();
  }

  /// Returns the current dashboard data.
  Map<String, dynamic> get dashboardData => _dashboardData;
}
