import 'package:shared_preferences/shared_preferences.dart';

/// A service for managing user settings and preferences.
///
/// TODO: In the future, sync settings with backend APIs for multi-device support.
class SettingsService {
  /// Checks if the user has accepted the terms.
  Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('acceptedTerms') ?? false;
  }

  /// Sets the user's acceptance of terms.
  Future<void> setAcceptedTerms(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', value);
  }
}
