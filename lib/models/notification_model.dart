import 'dart:convert';

class NotificationModel {
  final int id;
  final int mobileUserId;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final String notificationType;
  final String priority;
  final String status;
  final DateTime? processedAt;
  final bool isRead;
  final DateTime? readAt;
  final String? readDeviceId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationModel({
    required this.id,
    required this.mobileUserId,
    required this.title,
    required this.message,
    this.data,
    required this.notificationType,
    required this.priority,
    required this.status,
    this.processedAt,
    required this.isRead,
    this.readAt,
    this.readDeviceId,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        id: int.parse(json['id'].toString()),
        mobileUserId: int.parse(json['mobile_user_id'].toString()),
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        data: json['data'] != null 
            ? (json['data'] is String && json['data'].isNotEmpty
                ? (() {
                    try {
                      return jsonDecode(json['data']);
                    } catch (e) {
                      print('Error parsing notification data JSON: $e');
                      return null;
                    }
                  })()
                : json['data'])
            : null,
        notificationType: json['notification_type'] ?? 'general',
        priority: json['priority'] ?? 'normal',
        status: json['status'] ?? 'pending',
        processedAt: json['processed_at'] != null && json['processed_at'].toString().isNotEmpty
            ? DateTime.tryParse(json['processed_at']) 
            : null,
        isRead: json['is_read'] == 1 || json['is_read'] == '1' || json['is_read'] == true,
        readAt: json['read_at'] != null && json['read_at'].toString().isNotEmpty
            ? DateTime.tryParse(json['read_at']) 
            : null,
        readDeviceId: json['read_device_id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null && json['updated_at'].toString().isNotEmpty
            ? DateTime.tryParse(json['updated_at']) 
            : null,
      );
    } catch (e) {
      print('Error parsing NotificationModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile_user_id': mobileUserId,
      'title': title,
      'message': message,
      'data': data != null ? jsonEncode(data) : null,
      'notification_type': notificationType,
      'priority': priority,
      'status': status,
      'processed_at': processedAt?.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'read_at': readAt?.toIso8601String(),
      'read_device_id': readDeviceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isUrgent => priority == 'urgent';
  bool get isHigh => priority == 'high';
  bool get isJobNotification => notificationType == 'job';
  bool get isSystemNotification => notificationType == 'system';
  bool get isAlertNotification => notificationType == 'alert';
  
  String get priorityText {
    switch (priority) {
      case 'urgent':
        return 'ด่วนมาก';
      case 'high':
        return 'สำคัญ';
      case 'normal':
        return 'ปกติ';
      case 'low':
        return 'ไม่สำคัญ';
      default:
        return 'ปกติ';
    }
  }
  
  String get notificationTypeText {
    switch (notificationType) {
      case 'job':
        return 'งาน';
      case 'alert':
        return 'แจ้งเตือน';
      case 'system':
        return 'ระบบ';
      default:
        return 'ทั่วไป';
    }
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'รอส่ง';
      case 'processing':
        return 'กำลังส่ง';
      case 'processed':
        return 'ส่งแล้ว';
      case 'failed':
        return 'ส่งไม่สำเร็จ';
      default:
        return 'ไม่ทราบ';
    }
  }

  // Create a copy with updated fields
  NotificationModel copyWith({
    int? id,
    int? mobileUserId,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    String? notificationType,
    String? priority,
    String? status,
    DateTime? processedAt,
    bool? isRead,
    DateTime? readAt,
    String? readDeviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      mobileUserId: mobileUserId ?? this.mobileUserId,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      notificationType: notificationType ?? this.notificationType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      processedAt: processedAt ?? this.processedAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      readDeviceId: readDeviceId ?? this.readDeviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NotificationListResponse {
  final List<NotificationModel> notifications;
  final NotificationPagination pagination;

  NotificationListResponse({
    required this.notifications,
    required this.pagination,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      notifications: (json['data'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList(),
      pagination: NotificationPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class NotificationPagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int unreadCount;

  NotificationPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.unreadCount,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}