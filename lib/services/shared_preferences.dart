// lib/services/shared_pref_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static const String isNewKey = 'isNew';
  static const String hasSeenGuidelinesKey = 'hasSeenGuidelines';

  static Future<void> setIsNew(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isNewKey, value);
  }

  static Future<bool> getIsNew() async {
    final prefs = await SharedPreferences.getInstance();
    // Always return a bool, default to true if not set
    return prefs.getBool(isNewKey) ?? true;
  }

  static Future<void> setHasSeenGuidelines(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasSeenGuidelinesKey, value);
  }

  static Future<bool> getHasSeenGuidelines() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hasSeenGuidelinesKey) ?? false;
  }

  // Reset guidelines flag for testing
  static Future<void> resetGuidelines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(hasSeenGuidelinesKey);
  }
}
