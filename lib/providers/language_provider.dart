import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('en'); // Default to English
  
  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  bool get isHindi => _currentLocale.languageCode == 'hi';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  /// Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null) {
        _currentLocale = Locale(savedLanguage);
        notifyListeners();
        debugPrint('🌐 LANGUAGE: Loaded saved language: $savedLanguage');
      } else {
        debugPrint('🌐 LANGUAGE: No saved language, using default: en');
      }
    } catch (e) {
      debugPrint('❌ LANGUAGE: Error loading saved language: $e');
    }
  }
  
  /// Change language and save to SharedPreferences
  Future<void> changeLanguage(String languageCode) async {
    try {
      if (languageCode == _currentLocale.languageCode) {
        debugPrint('🌐 LANGUAGE: Language already set to $languageCode');
        return;
      }
      
      _currentLocale = Locale(languageCode);
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      notifyListeners();
      debugPrint('🌐 LANGUAGE: Changed language to $languageCode');
    } catch (e) {
      debugPrint('❌ LANGUAGE: Error changing language: $e');
    }
  }
  
  /// Toggle between English and Hindi
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLocale.languageCode == 'en' ? 'hi' : 'en';
    await changeLanguage(newLanguage);
  }
  
  /// Get language display name
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'हिंदी';
      case 'en':
      default:
        return 'English';
    }
  }
  
  /// Get current language display name
  String get currentLanguageDisplayName {
    return getLanguageDisplayName(_currentLocale.languageCode);
  }
  
  /// Get supported locales
  static List<Locale> get supportedLocales => [
    const Locale('en'),
    const Locale('hi'),
  ];
  
  /// Check if locale is supported
  static bool isLocaleSupported(Locale locale) {
    return supportedLocales.any((supportedLocale) => 
        supportedLocale.languageCode == locale.languageCode);
  }
}