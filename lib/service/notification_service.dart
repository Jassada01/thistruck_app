import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/material.dart';
import 'notification_navigation_service.dart';
import 'badge_service.dart';
import 'dart:convert';

// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // Increment badge count by 1 when push notification arrives
  await BadgeService.incrementBadgeCountOnPush();
}



class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  Function(String)? onMessageReceived;
  Function(String)? onNotificationTapped;
  

  // Initialize notifications
  Future<String> initializeNotifications({
    Function(String)? onMessage,
    Function(String)? onTap,
  }) async {
    onMessageReceived = onMessage;
    onNotificationTapped = onTap;

    // Create notification channel first (Android)
    await createNotificationChannel();

    // Request permission (simple version that works)
    NotificationSettings settings = await _firebaseMessaging.requestPermission();

    String permissionStatus = settings.authorizationStatus.name;

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return permissionStatus;
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get device token
    await _firebaseMessaging.getToken();

    // Setup message listeners
    _setupMessageListeners();

    // Handle initial message (when app is opened from terminated state)
    await _handleInitialMessage();

    return permissionStatus;
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        NotificationNavigationService.handleNotificationTap(response.payload);
        
        onNotificationTapped?.call('Notification tapped');
      },
    );
  }

  // Setup message listeners
  void _setupMessageListeners() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(message);
      onMessageReceived?.call('📱 ${message.notification?.title}: ${message.notification?.body}');
      
      // Increment badge count by 1 when push notification arrives
      BadgeService.incrementBadgeCountOnPush();
    });

    // Listen for message taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
      onMessageReceived?.call('👆 Clicked: ${message.notification?.title}');
    });
    
    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      // Token refreshed
    });
  }

  // Handle initial message
  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
      onMessageReceived?.call('🚀 App opened from: ${initialMessage.notification?.title}');
    }
  }

  // Show local notification (only when app is in foreground)
  Future<void> showLocalNotification(RemoteMessage message) async {
    // Check if this is a data-only message
    if (message.notification == null) {
      return;
    }
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      // เพิ่ม tag เพื่อไม่ให้ซ้ำ
      tag: 'fcm_notification',
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      // ใช้ messageId เป็น notificationId เพื่อป้องกันการซ้ำ
      final int notificationId = message.messageId.hashCode;
      final String title = message.notification?.title ?? 'Notification';
      final String body = message.notification?.body ?? 'You have a new message';
      
      final String payload = json.encode(message.data);
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      // Silent error handling
    }
  }

  // Get device token
  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Refresh token
  Future<String?> refreshToken() async {
    await _firebaseMessaging.deleteToken();
    return await _firebaseMessaging.getToken();
  }

  // Send test local notification
  Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      0,
      'Test Notification',
      'This is a test local notification',
      platformChannelSpecifics,
    );
  }

  // Create notification channel
  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );
    
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      // Silent error handling
    }
  }


  // Handle notification tap from FCM message
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      // Handle navigation
      NotificationNavigationService.handleNotificationNavigation(message.data);
    }
  }

}