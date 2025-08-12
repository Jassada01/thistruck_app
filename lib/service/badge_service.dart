import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeService {
  static const String _badgeCountKey = 'badge_count';
  
  /// Get current badge count from local storage
  static Future<int> getBadgeCountFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_badgeCountKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Set badge count from API (F=29) - This is the source of truth
  static Future<void> setBadgeCountFromAPI(int count) async {
    try {
      // Save to local storage first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_badgeCountKey, count);
      
      // Update app icon badge
      await _updateAppIconBadge(count);
    } catch (e) {
      // Silent error handling
    }
  }
  
  /// Increment badge count by 1 (for push notifications)
  static Future<void> incrementBadgeCountOnPush() async {
    try {
      final currentCount = await getBadgeCountFromStorage();
      final newCount = currentCount + 1;
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_badgeCountKey, newCount);
      
      // Update app icon badge
      await _updateAppIconBadge(newCount);
    } catch (e) {
      // Silent error handling
    }
  }
  
  /// Internal method to update app icon badge
  static Future<void> _updateAppIconBadge(int count) async {
    try {
      final isSupported = await AppBadgePlus.isSupported();
      
      if (isSupported) {
        if (count > 0) {
          await AppBadgePlus.updateBadge(count);
        } else {
          await AppBadgePlus.updateBadge(0);
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }
  
  /// Update badge count (keeping for backward compatibility)
  static Future<void> updateBadgeCount(int count) async {
    await setBadgeCountFromAPI(count);
  }
  
  /// Get current badge count from storage (alias for getBadgeCountFromStorage)
  static Future<int> getBadgeCount() async {
    return await getBadgeCountFromStorage();
  }
  
  /// Clear badge count (set to 0)
  static Future<void> clearBadge() async {
    await updateBadgeCount(0);
  }
  
  /// Increment badge count by 1
  static Future<void> incrementBadge() async {
    final currentCount = await getBadgeCount();
    await updateBadgeCount(currentCount + 1);
  }
  
  /// Decrement badge count by 1 (minimum 0)
  static Future<void> decrementBadge() async {
    final currentCount = await getBadgeCount();
    if (currentCount > 0) {
      await updateBadgeCount(currentCount - 1);
    }
  }
  
  /// Check if badge is supported on current platform
  static Future<bool> isBadgeSupported() async {
    try {
      return await AppBadgePlus.isSupported();
    } catch (e) {
      return false;
    }
  }
}