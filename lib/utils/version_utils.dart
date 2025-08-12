import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

class VersionUtils {
  /// Compare version strings (e.g., "1.2.3" vs "1.2.4")
  /// Returns:
  /// - negative value if version1 < version2
  /// - zero if version1 == version2  
  /// - positive value if version1 > version2
  static int compareVersions(String version1, String version2) {
    List<int> v1Parts = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Parts = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    // Make both arrays same length by padding with zeros
    int maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    
    while (v1Parts.length < maxLength) {
      v1Parts.add(0);
    }
    while (v2Parts.length < maxLength) {
      v2Parts.add(0);
    }
    
    for (int i = 0; i < maxLength; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }
    
    return 0; // Versions are equal
  }
  
  /// Check if an update is needed
  /// Returns true if currentVersion < availableVersion
  static bool needsUpdate(String currentVersion, String availableVersion) {
    return compareVersions(currentVersion, availableVersion) < 0;
  }
  
  /// Get current app version
  static Future<String> getCurrentAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('Error getting app version: $e');
      return '1.0.0'; // Default version
    }
  }
  
  /// Get current platform (android/ios)
  static String getCurrentPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }
  
  /// Find version info for current platform from API response
  static Map<String, dynamic>? findVersionForCurrentPlatform(List<dynamic> versionData) {
    String currentPlatform = getCurrentPlatform();
    
    for (var version in versionData) {
      if (version['os']?.toLowerCase() == currentPlatform.toLowerCase()) {
        return Map<String, dynamic>.from(version);
      }
    }
    
    return null;
  }
}