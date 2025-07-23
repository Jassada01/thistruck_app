import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _logNotificationDetails('📱 Background Message', message);
}

// Helper function for detailed notification logging
void _logNotificationDetails(String context, RemoteMessage message) {
  print('\n========== $context ==========');
  print('📨 Message ID: ${message.messageId}');
  print('🕐 Sent Time: ${message.sentTime}');
  print('🏷️ Collapse Key: ${message.collapseKey ?? 'N/A'}');
  print('🔔 Category: ${message.category ?? 'N/A'}');
  print('📊 Message Type: ${message.messageType ?? 'N/A'}');
  print('🎯 From: ${message.from ?? 'N/A'}');
  print('📧 TTL: ${message.ttl ?? 'N/A'}');
  
  // Notification details
  if (message.notification != null) {
    print('📢 NOTIFICATION:');
    print('  📰 Title: ${message.notification!.title}');
    print('  📝 Body: ${message.notification!.body}');
    print('  🖼️ Android Image: ${message.notification!.android?.imageUrl ?? 'N/A'}');
    print('  🔊 Android Sound: ${message.notification!.android?.sound ?? 'N/A'}');
    print('  🎨 Android Color: ${message.notification!.android?.color ?? 'N/A'}');
    print('  📱 Android Channel ID: ${message.notification!.android?.channelId ?? 'N/A'}');
    print('  🔔 Android Click Action: ${message.notification!.android?.clickAction ?? 'N/A'}');
    print('  🍎 iOS Sound: ${message.notification!.apple?.sound ?? 'N/A'}');
    print('  🏷️ iOS Badge: ${message.notification!.apple?.badge ?? 'N/A'}');
  } else {
    print('📢 NOTIFICATION: null (data-only message)');
  }
  
  // Data payload
  if (message.data.isNotEmpty) {
    print('📦 DATA PAYLOAD:');
    message.data.forEach((key, value) {
      print('  🔑 $key: $value');
    });
  } else {
    print('📦 DATA PAYLOAD: Empty');
  }
  
  print('============================================\n');
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

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permission granted');
    } else {
      print('Permission denied');
      return permissionStatus;
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get device token
    String? token = await _firebaseMessaging.getToken();
    print('Device Token: $token');

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
        print('\n========== 👆 Local Notification Tapped ==========');
        print('🆔 Notification ID: ${response.id}');
        print('🏷️ Action ID: ${response.actionId ?? 'N/A'}');
        print('📦 Payload: ${response.payload ?? 'No payload'}');
        print('📱 Input: ${response.input ?? 'N/A'}');
        print('🔔 Details: ${response.notificationResponseType.name}');
        print('================================================\n');
        
        
        
        onNotificationTapped?.call('👆 Notification tapped: ${response.payload ?? 'No payload'}');
      },
    );
  }

  // Setup message listeners
  void _setupMessageListeners() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logNotificationDetails('🔔 Foreground Message', message);
      showLocalNotification(message);
      onMessageReceived?.call('📱 ${message.notification?.title}: ${message.notification?.body}');
    });

    // Listen for message taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logNotificationDetails('👆 Message Tap (Background)', message);
      
      
      onMessageReceived?.call('👆 Clicked: ${message.notification?.title}');
    });
    
    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      print('🔄 FCM Token Refreshed: $token');
    });
  }

  // Handle initial message
  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _logNotificationDetails('🚀 App Opened from Terminated State', initialMessage);
      
      
      onMessageReceived?.call('🚀 App opened from: ${initialMessage.notification?.title}');
    }
  }

  // Show local notification (only when app is in foreground)
  Future<void> showLocalNotification(RemoteMessage message) async {
    // ตรวจสอบว่า notification นี้ซ้ำกับ system notification หรือไม่
    // โดยเช็คว่ามี notification payload หรือไม่
    if (message.notification == null) {
      print('📦 Data-only message, not showing local notification');
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
      
      final String payload = message.data.toString();
      
      print('🔔 Showing local notification: $title');
      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print('❌ Error showing notification: $e');
      print('📋 Stack trace: ${StackTrace.current}');
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
      print('✅ Android notification channel created successfully');
    } catch (e) {
      print('❌ Error creating notification channel: $e');
    }
  }

  // Get current notification settings for debugging
  Future<void> logNotificationSettings() async {
    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    print('\n========== 📱 Notification Settings ==========');
    print('🔔 Authorization Status: ${settings.authorizationStatus.name}');
    print('📢 Alert Setting: ${settings.alert.name}');
    print('📣 Announcement Setting: ${settings.announcement.name}');
    print('🏷️ Badge Setting: ${settings.badge.name}');
    print('🔒 Car Play Setting: ${settings.carPlay.name}');
    print('🚨 Critical Alert Setting: ${settings.criticalAlert.name}');
    print('🔐 Lock Screen Setting: ${settings.lockScreen.name}');
    print('📲 Notification Center Setting: ${settings.notificationCenter.name}');
    print('🔊 Sound Setting: ${settings.sound.name}');
    print('⏰ Timed Sensitive Setting: ${settings.timeSensitive.name}');
    print('=============================================\n');
  }

  // Debug method to show all recent notifications
  Future<void> logPendingNotifications() async {
    List<PendingNotificationRequest> pendingNotifications = 
        await _localNotifications.pendingNotificationRequests();
    print('\n========== 📋 Pending Notifications ==========');
    print('📊 Count: ${pendingNotifications.length}');
    for (var notification in pendingNotifications) {
      print('🆔 ID: ${notification.id}');
      print('📰 Title: ${notification.title}');
      print('📝 Body: ${notification.body}');
      print('📦 Payload: ${notification.payload}');
      print('---');
    }
    print('=============================================\n');
  }

  // Comprehensive diagnostic method
  Future<void> runNotificationDiagnostic() async {
    print('\n========== 🔍 NOTIFICATION DIAGNOSTIC ==========');
    
    // Check FCM settings
    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    print('🔔 FCM Authorization: ${settings.authorizationStatus.name}');
    print('📢 Alert Setting: ${settings.alert.name}');
    print('🔊 Sound Setting: ${settings.sound.name}');
    print('🏷️ Badge Setting: ${settings.badge.name}');
    
    // Check device token
    String? token = await getDeviceToken();
    print('🔑 Device Token: ${token != null ? 'Available (${token.length} chars)' : 'NULL'}');
    
    // Test local notification
    print('🧪 Testing local notification...');
    try {
      await _localNotifications.show(
        999999, // Test ID
        'Test Notification',
        'This is a diagnostic test notification',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Test channel',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      print('✅ Local notification test successful');
    } catch (e) {
      print('❌ Local notification test failed: $e');
    }
    
    // Check Android notification channels
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        print('✅ Android plugin available');
      } else {
        print('❌ Android plugin not available');
      }
    } catch (e) {
      print('❌ Error checking Android plugin: $e');
    }
    
    print('===============================================\n');
  }

}