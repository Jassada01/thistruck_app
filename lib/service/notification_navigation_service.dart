import 'package:flutter/material.dart';
import 'dart:convert';

class NotificationNavigationService {
  static final NotificationNavigationService _instance = 
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// จัดการการนำทางจาก notification data - ไปหน้า notifications ทุกครั้ง
  static Future<void> handleNotificationNavigation(Map<String, dynamic> data) async {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) {
      print('⚠️ Navigator context is null, cannot navigate');
      return;
    }

    print('🧭 Navigating to notifications screen with data: $data');

    // ไปหน้า notifications ทุกครั้งไม่ว่า notification จะมี data อะไร
    await _navigateToNotificationsScreen(context, data);
  }

  /// นำทางไปหน้ารายละเอียดงาน
  static Future<void> _navigateToJobDetail(
    BuildContext context, 
    Map<String, dynamic> data
  ) async {
    final String? randomCode = data['randomCode'];

    print('🔍 Attempting navigation to jobDetail with randomCode: $randomCode');

    if (randomCode == null || randomCode.isEmpty) {
      print('⚠️ randomCode is required for jobDetail navigation');
      return;
    }

    try {
      // ส่งแค่ randomCode ก็พอ หน้า JobDetailScreen จะเรียก getJobOrderTripByRandomCode เองเพื่อดึงข้อมูล
      final args = {
        'randomCode': randomCode,
      };
      
      print('🚀 Navigating to /job-detail with randomCode: $randomCode');
      
      await Navigator.of(context).pushNamed(
        '/job-detail',
        arguments: args,
      );
      print('✅ Successfully navigated to job detail: $randomCode');
    } catch (e) {
      print('❌ Error navigating to job detail: $e');
      print('📋 Stack trace: ${StackTrace.current}');
    }
  }

  /// นำทางไปหน้า dashboard
  static Future<void> _navigateToDashboard(
    BuildContext context,
    Map<String, dynamic> data
  ) async {
    try {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
      print('✅ Successfully navigated to dashboard');
    } catch (e) {
      print('❌ Error navigating to dashboard: $e');
    }
  }

  /// นำทางไปหน้า notifications list
  static Future<void> _navigateToNotificationsScreen(
    BuildContext context,
    Map<String, dynamic> data
  ) async {
    try {
      await Navigator.of(context).pushNamed('/notifications');
      print('✅ Successfully navigated to notifications screen');
    } catch (e) {
      print('❌ Error navigating to notifications screen: $e');
    }
  }

  /// แปลง payload string เป็น Map
  static Map<String, dynamic> parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return {};
    }

    print('🔍 Parsing payload: $payload');

    try {
      // ลองแปลงจาก JSON string ปกติก่อน
      if (payload.startsWith('{') && payload.endsWith('}')) {
        return json.decode(payload) as Map<String, dynamic>;
      }
      
      // แปลงจาก toString() format ของ Dart Map
      // ตัวอย่าง: "{randomCode: sKBMapEIcB, page: jobDetail}"
      String cleanPayload = payload.trim();
      
      // ลบ { และ } ออก
      if (cleanPayload.startsWith('{') && cleanPayload.endsWith('}')) {
        cleanPayload = cleanPayload.substring(1, cleanPayload.length - 1);
      }
      
      final Map<String, dynamic> result = {};
      
      // แยกด้วย ", " เพื่อแยก key-value pairs
      final parts = cleanPayload.split(', ');
      
      for (final part in parts) {
        // แยก key และ value ด้วย ": "
        final colonIndex = part.indexOf(': ');
        if (colonIndex > 0) {
          final key = part.substring(0, colonIndex).trim();
          final value = part.substring(colonIndex + 2).trim();
          result[key] = value;
        }
      }
      
      print('✅ Parsed payload result: $result');
      return result;
    } catch (e) {
      print('❌ Error parsing payload: $e');
      
      // Fallback: ถ้า parse ไม่ได้ให้ลองแยกด้วย regex
      try {
        final Map<String, dynamic> fallbackResult = {};
        final regExp = RegExp(r'(\w+):\s*([^,}]+)');
        final matches = regExp.allMatches(payload);
        
        for (final match in matches) {
          final key = match.group(1)?.trim() ?? '';
          final value = match.group(2)?.trim() ?? '';
          if (key.isNotEmpty && value.isNotEmpty) {
            fallbackResult[key] = value;
          }
        }
        
        print('✅ Fallback parsed result: $fallbackResult');
        return fallbackResult;
      } catch (fallbackError) {
        print('❌ Fallback parsing also failed: $fallbackError');
        return {};
      }
    }
  }

  /// วิเคราะห์และจัดการ notification tap
  static Future<void> handleNotificationTap(String? payload) async {
    if (payload == null || payload.isEmpty) {
      print('⚠️ Empty notification payload');
      return;
    }

    print('📱 Processing notification tap with payload: $payload');
    
    final Map<String, dynamic> data = parsePayload(payload);
    if (data.isEmpty) {
      print('⚠️ Failed to parse notification payload');
      return;
    }

    await handleNotificationNavigation(data);
  }
}