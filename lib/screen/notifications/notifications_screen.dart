import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/notification_model.dart';
import '../../service/api_service.dart';
import '../../widgets/notification_item_widget.dart';
import '../../service/local_storage.dart';
import '../../service/badge_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  int? _mobileUserId;
  String? _deviceId;

  final ScrollController _allScrollController = ScrollController();
  final ScrollController _unreadScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _setupScrollControllers();
    
    // When user opens notifications screen, consider badge as "seen"
    // We'll update it properly after loading notifications
  }

  void _setupScrollControllers() {
    _allScrollController.addListener(() {
      if (_allScrollController.position.pixels >=
          _allScrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData && _tabController.index == 0) {
          _loadMoreNotifications();
        }
      }
    });

    _unreadScrollController.addListener(() {
      if (_unreadScrollController.position.pixels >=
          _unreadScrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData && _tabController.index == 1) {
          _loadMoreNotifications();
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    final userData = await LocalStorage.getProfile();
    
    
    if (userData != null) {
      // Use 'id' field as mobile_user_id (this is the mobile_users.id)
      _mobileUserId = userData['id'];
      
      // Get device ID first, then load notifications
      await _getDeviceId();
      
      _loadNotifications();
    } else {
      // Handle case where user is not logged in
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _getDeviceId() async {
    try {
      // Get device ID using ApiService
      final deviceId = await ApiService.getDeviceId();
      _deviceId = deviceId ?? 'unknown_device';
    } catch (e) {
      _deviceId = 'unknown_device';
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (_mobileUserId == null) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _isLoading = true;
        _allNotifications.clear();
        _unreadNotifications.clear();
      });
    }

    try {
      
      // Load all notifications
      final allResponse = await ApiService.getNotifications(
        mobileUserId: _mobileUserId!,
        page: _currentPage,
        limit: _pageSize,
        unreadOnly: false,
      );
      

      // Load unread notifications
      final unreadResponse = await ApiService.getNotifications(
        mobileUserId: _mobileUserId!,
        page: 1,
        limit: 100, // Load more unread notifications
        unreadOnly: true,
      );
      

      if (mounted) {
        setState(() {
          if (allResponse != null) {
            if (refresh) {
              _allNotifications = allResponse.notifications;
            } else {
              _allNotifications.addAll(allResponse.notifications);
            }
            
            // เรียงลำดับตามเวลาที่สร้าง (ใหม่ที่สุดก่อน)
            _allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            _hasMoreData = allResponse.notifications.length == _pageSize;
          }

          if (unreadResponse != null) {
            _unreadNotifications = unreadResponse.notifications;
            // เรียงลำดับการแจ้งเตือนที่ยังไม่อ่านตามเวลาที่สร้าง (ใหม่ที่สุดก่อน)
            _unreadNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
        );
      }
    }
    
    // Update badge count after loading notifications
    _updateBadgeCount();
  }

  /// Update app badge count with unread notifications
  Future<void> _updateBadgeCount() async {
    final unreadCount = _unreadNotifications.length;
    await BadgeService.setBadgeCountFromAPI(unreadCount);
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreData || _mobileUserId == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadNotifications();
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (_deviceId == null) return;

    try {
      final result = await ApiService.markNotificationAsRead(
        notificationId: notification.id,
        deviceId: _deviceId!,
      );

      if (result['success']) {
        setState(() {
          // Update the notification in all lists
          final updatedNotification = notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
            readDeviceId: _deviceId,
          );

          // Update in all notifications list
          final allIndex = _allNotifications.indexWhere((n) => n.id == notification.id);
          if (allIndex != -1) {
            _allNotifications[allIndex] = updatedNotification;
          }

          // Remove from unread notifications list
          _unreadNotifications.removeWhere((n) => n.id == notification.id);
        });
        
        // Update badge count after marking as read
        _updateBadgeCount();

      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'เกิดข้อผิดพลาด')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการทำเครื่องหมายอ่านแล้ว')),
        );
      }
    }
  }

  void _onNotificationTap(NotificationModel notification) {
    // If notification is unread, mark it as read first
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    // Handle navigation based on notification data
    if (notification.data != null) {
      final notificationData = notification.data!;
      

      // Check notification type and handle accordingly
      // ตรวจสอบจาก notification.notificationType (จาก DB) หรือ data.type (จาก JSON)
      bool isCancelNotification = notification.notificationType == 'cancel' ||
                                  notificationData['type'] == 'JobCancel' || 
                                  notificationData['type'] == 'cancel';
      
      if (isCancelNotification) {
        // Handle job cancellation notification
        if (mounted) {
          String jobTitle = '';
          
          // ดึงชื่องานจาก showData ก่อน
          if (notificationData['showData'] != null && 
              notificationData['showData']['ชื่องาน'] != null) {
            jobTitle = notificationData['showData']['ชื่องาน'];
          } else {
            // Fallback ถ้าไม่มีใน showData
            jobTitle = notificationData['job_title'] ?? 
                      notificationData['title'] ?? 
                      notification.title;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('งาน "$jobTitle" ถูกยกเลิก'),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'ปิด',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } else if (notificationData['type'] == 'JobDetail' && notificationData['randomCode'] != null) {
        
        // Navigate to job detail screen with randomCode
        Navigator.pushNamed(
          context, 
          '/job-detail', 
          arguments: {
            'randomCode': notificationData['randomCode'],
          }
        );
      } else {
        // For other types, show info in SnackBar
        if (mounted) {
          String message = 'คลิกการแจ้งเตือน';
          if (notificationData['type'] != null) {
            message += ' ประเภท: ${notificationData['type']}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } else {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('การแจ้งเตือนนี้ไม่มีข้อมูลเพิ่มเติม')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allScrollController.dispose();
    _unreadScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การแจ้งเตือน'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'ทั้งหมด',
              icon: Icon(Icons.notifications),
            ),
            Tab(
              text: 'ยังไม่อ่าน (${_unreadNotifications.length})',
              icon: Icon(Icons.notifications_active),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadNotifications(refresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // All notifications tab
                _buildNotificationsList(
                  notifications: _allNotifications,
                  scrollController: _allScrollController,
                  emptyMessage: 'ไม่มีการแจ้งเตือน',
                ),
                // Unread notifications tab
                _buildNotificationsList(
                  notifications: _unreadNotifications,
                  scrollController: _unreadScrollController,
                  emptyMessage: 'ไม่มีการแจ้งเตือนที่ยังไม่อ่าน',
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationsList({
    required List<NotificationModel> notifications,
    required ScrollController scrollController,
    required String emptyMessage,
  }) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            // Loading indicator at bottom
            return Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final notification = notifications[index];
          return NotificationItemWidget(
            notification: notification,
            onTap: () => _onNotificationTap(notification),
            onMarkAsRead: notification.isRead 
                ? null 
                : () => _markAsRead(notification),
          );
        },
      ),
    );
  }
}