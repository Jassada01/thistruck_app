import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorage {
  static const String _profileKey = 'user_profile';
  static const String _termsAcceptedKey = 'terms_accepted';
  
  // Get SharedPreferences instance
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Profile operations
  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await _prefs;
    final String? profileJson = prefs.getString(_profileKey);
    
    if (profileJson != null) {
      return jsonDecode(profileJson);
    }
    return null;
  }

  static Future<bool> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await _prefs;
    
    // Add timestamps
    final now = DateTime.now().toIso8601String();
    profile['created_at'] = profile['created_at'] ?? now;
    profile['updated_at'] = now;
    
    final String profileJson = jsonEncode(profile);
    return await prefs.setString(_profileKey, profileJson);
  }

  static Future<bool> updateProfile(Map<String, dynamic> updates) async {
    final currentProfile = await getProfile();
    if (currentProfile != null) {
      currentProfile.addAll(updates);
      return await saveProfile(currentProfile);
    }
    return false;
  }

  static Future<bool> deleteProfile() async {
    final prefs = await _prefs;
    return await prefs.remove(_profileKey);
  }

  // Check if profile exists
  static Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile != null;
  }

  // Get specific profile field
  static Future<String?> getProfileField(String field) async {
    final profile = await getProfile();
    return profile?[field];
  }

  // Terms acceptance operations
  static Future<bool> setTermsAccepted(bool accepted) async {
    final prefs = await _prefs;
    return await prefs.setBool(_termsAcceptedKey, accepted);
  }

  static Future<bool> isTermsAccepted() async {
    final prefs = await _prefs;
    return prefs.getBool(_termsAcceptedKey) ?? false;
  }

  // Clear all data
  static Future<bool> clearAll() async {
    final prefs = await _prefs;
    return await prefs.clear();
  }
}