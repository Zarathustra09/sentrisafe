// lib/services/shared_pref_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static const String isNewKey = 'isNew';

  static Future<void> setIsNew(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isNewKey, value);
  }

  static Future<bool> getIsNew() async {
    final prefs = await SharedPreferences.getInstance();
    // Always return a bool, default to true if not set
    return prefs.getBool(isNewKey) ?? true;
  }
}