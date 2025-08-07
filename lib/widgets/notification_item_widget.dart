import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationItemWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationItemWidget({
    Key? key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 1 : 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with type badge and time
              Row(
                children: [
                  _buildTypeBadge(),
                  SizedBox(width: 8),
                  _buildPriorityIndicator(),
                  Spacer(),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (!notification.isRead) ...[
                    SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8),
              
              // Title
              Text(
                notification.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  color: notification.isRead ? Colors.grey[700] : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              
              // Message
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color: notification.isRead ? Colors.grey[600] : Colors.grey[800],
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Additional data if exists
              if (notification.data != null && notification.data!.isNotEmpty) ...[
                SizedBox(height: 8),
                _buildDataWidget(),
              ],
              
              // Action buttons
              if (!notification.isRead && onMarkAsRead != null) ...[
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onMarkAsRead,
                      icon: Icon(Icons.done, size: 16),
                      label: Text('ทำเครื่องหมายอ่านแล้ว'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String displayText = notification.notificationTypeText;

    switch (notification.notificationType) {
      case 'cancel':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel;
        displayText = 'ยกเลิกงาน';
        break;
      case 'job':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.work;
        break;
      case 'alert':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.warning;
        break;
      case 'system':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.settings;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.notifications;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    if (notification.priority == 'normal' || notification.priority == 'low') {
      return SizedBox.shrink();
    }

    Color color;
    IconData icon;

    switch (notification.priority) {
      case 'urgent':
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 'high':
        color = Colors.orange;
        icon = Icons.flag;
        break;
      default:
        return SizedBox.shrink();
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Widget _buildDataWidget() {
    final data = notification.data!;
    
    // Special handling for cancel notifications
    if (notification.notificationType == 'cancel') {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red[700], size: 16),
                SizedBox(width: 6),
                Text(
                  'รายละเอียดงานที่ยกเลิก',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ..._buildShowDataWidgets(data, isCancel: true),
          ],
        ),
      );
    }
    
    // Special handling for job notifications
    if (notification.isJobNotification) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work_outline, color: Colors.blue[700], size: 16),
                SizedBox(width: 6),
                Text(
                  'รายละเอียดงาน',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ..._buildShowDataWidgets(data),
          ],
        ),
      );
    }
    
    // Special handling for system notifications
    if (notification.isSystemNotification) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['maintenance_start'] != null && data['maintenance_end'] != null)
              Text(
                'ปิดปรับปรุง: ${_formatDateTime(data['maintenance_start'])} - ${_formatDateTime(data['maintenance_end'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
          ],
        ),
      );
    }
    
    // Generic data display
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        'ข้อมูลเพิ่มเติม: ${data.toString()}',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm', 'th').format(dateTime);
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy HH:mm', 'th').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  List<Widget> _buildShowDataWidgets(Map<String, dynamic> data, {bool isCancel = false}) {
    List<Widget> widgets = [];
    
    // Check if showData exists in the data
    if (data['showData'] != null && data['showData'] is Map) {
      final showData = data['showData'] as Map<String, dynamic>;
      
      // Build widgets for all key-value pairs in showData
      showData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          widgets.add(
            Container(
              margin: EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '$key:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isCancel ? Colors.red[600] : Colors.blue[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: key == 'ชื่องาน' ? FontWeight.w600 : FontWeight.normal,
                        color: isCancel ? Colors.red[800] : Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    } else {
      // Fallback to original hardcoded fields if showData doesn't exist
      if (data['job_id'] != null) {
        widgets.add(
          Text(
            'Job ID: ${data['job_id']}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue[800],
            ),
          ),
        );
      }
      if (data['route'] != null) {
        widgets.add(
          Text(
            'เส้นทาง: ${data['route']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
        );
      }
      if (data['pickup_date'] != null) {
        widgets.add(
          Text(
            'วันที่รับงาน: ${data['pickup_date']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
}