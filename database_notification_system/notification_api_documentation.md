# Mobile Notification System API Documentation

## ภาพรวมระบบ

ระบบการแจ้งเตือนสำหรับ ThistruckOn Mobile App ที่รองรับการส่งการแจ้งเตือนผ่าน Firebase Cloud Messaging (FCM) ไปยังอุปกรณ์ทั้งหมดของผู้ใช้

## Database Tables

### 1. mobile_notifications
ตารางหลักสำหรับเก็บข้อมูลการแจ้งเตือน

| Field | Type | Description |
|-------|------|-------------|
| id | int(11) | Primary Key |
| mobile_user_id | int(11) | Foreign Key to mobile_users.id |
| title | varchar(255) | หัวข้อการแจ้งเตือน |
| message | text | ข้อความการแจ้งเตือน |
| data | longtext (JSON) | ข้อมูลเพิ่มเติม |
| notification_type | varchar(50) | ประเภทการแจ้งเตือน (job, alert, system) |
| priority | enum | ระดับความสำคัญ (low, normal, high, urgent) |
| is_read | tinyint(1) | สถานะการอ่าน (0=ยังไม่อ่าน, 1=อ่านแล้ว) |
| read_at | datetime | เวลาที่อ่าน |
| read_device_id | varchar(255) | Device ID ที่อ่านการแจ้งเตือน |

### 2. mobile_notification_sends
ตารางสำหรับเก็บประวัติการส่งการแจ้งเตือนไปยังแต่ละอุปกรณ์

| Field | Type | Description |
|-------|------|-------------|
| id | int(11) | Primary Key |
| notification_id | int(11) | Foreign Key to mobile_notifications.id |
| device_id | int(11) | Foreign Key to mobile_user_devices.id |
| fcm_token | text | FCM Token ที่ใช้ส่ง |
| send_status | enum | สถานะการส่ง (pending, sent, failed, delivered) |
| send_result | longtext (JSON) | ผลการส่งจาก Firebase |
| error_message | text | ข้อความ error |
| retry_count | int(11) | จำนวนครั้งที่ retry |
| sent_at | datetime | เวลาที่ส่ง |
| delivered_at | datetime | เวลาที่ส่งถึง device |

## API Endpoints

### 1. สร้างการแจ้งเตือนใหม่

**POST** `/api/notifications/create`

**Parameters:**
```json
{
  "mobile_user_id": 5,
  "title": "งานใหม่ได้รับมอบหมาย",
  "message": "คุณได้รับงานขนส่งใหม่ จาก กรุงเทพฯ ไป เชียงใหม่",
  "data": {
    "job_id": 12345,
    "route": "กรุงเทพฯ - เชียงใหม่",
    "pickup_date": "2025-08-03"
  },
  "notification_type": "job",
  "priority": "high"
}
```

**Response:**
```json
{
  "success": true,
  "notification_id": 123,
  "message": "Notification created and queued for sending"
}
```

### 2. ดึงการแจ้งเตือนของผู้ใช้

**GET** `/api/notifications/user/{mobile_user_id}`

**Query Parameters:**
- `page` (optional): หมายเลขหน้า (default: 1)
- `limit` (optional): จำนวนต่อหน้า (default: 20)
- `unread_only` (optional): true เพื่อดูเฉพาะที่ยังไม่อ่าน

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "งานใหม่ได้รับมอบหมาย",
      "message": "คุณได้รับงานขนส่งใหม่ จาก กรุงเทพฯ ไป เชียงใหม่",
      "data": {
        "job_id": 12345,
        "route": "กรุงเทพฯ - เชียงใหม่"
      },
      "notification_type": "job",
      "priority": "high",
      "is_read": false,
      "created_at": "2025-08-02 16:00:00"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_items": 100,
    "unread_count": 15
  }
}
```

### 3. ทำเครื่องหมายว่าอ่านแล้ว

**PUT** `/api/notifications/{notification_id}/read`

**Parameters:**
```json
{
  "device_id": "820AEAE2-CF83-434E-9E33-7DCA0A66DF05"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

### 4. ดูสถานะการส่งการแจ้งเตือน

**GET** `/api/notifications/{notification_id}/status`

**Response:**
```json
{
  "success": true,
  "notification": {
    "id": 1,
    "title": "งานใหม่ได้รับมอบหมาย",
    "created_at": "2025-08-02 16:00:00"
  },
  "send_status": [
    {
      "device_name": "iPhone 16 Plus",
      "device_id": "820AEAE2-CF83-434E-9E33-7DCA0A66DF05",
      "send_status": "delivered",
      "sent_at": "2025-08-02 16:01:00",
      "delivered_at": "2025-08-02 16:01:15"
    },
    {
      "device_name": "google sdk_gphone64_arm64",
      "device_id": "BP22.250325.006",
      "send_status": "failed",
      "error_message": "Invalid FCM token",
      "retry_count": 2
    }
  ]
}
```

### 5. ส่งการแจ้งเตือนไปยังผู้ใช้ทั้งหมดในกลุ่ม

**POST** `/api/notifications/broadcast`

**Parameters:**
```json
{
  "user_type": "driver", // หรือ "user"
  "title": "แจ้งเตือนระบบ",
  "message": "ระบบจะปิดปรับปรุงในวันที่ 5 สิงหาคม 2568",
  "notification_type": "system",
  "priority": "normal"
}
```

### 6. ดูสถิติการแจ้งเตือน

**GET** `/api/notifications/statistics`

**Query Parameters:**
- `start_date`: วันที่เริ่มต้น (YYYY-MM-DD)
- `end_date`: วันที่สิ้นสุด (YYYY-MM-DD)

**Response:**
```json
{
  "success": true,
  "statistics": {
    "total_notifications": 1250,
    "total_sends": 3750,
    "success_rate": 95.2,
    "by_type": {
      "job": 800,
      "alert": 300,
      "system": 150
    },
    "by_status": {
      "delivered": 3570,
      "sent": 120,
      "failed": 60
    }
  }
}
```

## Implementation Guide

### Backend PHP Function (mainFunction.php)

เพิ่ม functions ใหม่สำหรับการจัดการการแจ้งเตือน:

- **Function 20**: สร้างการแจ้งเตือน
- **Function 21**: ดึงการแจ้งเตือนของผู้ใช้
- **Function 22**: ทำเครื่องหมายว่าอ่านแล้ว
- **Function 23**: อัพเดทสถานะการส่ง
- **Function 24**: ส่งการแจ้งเตือนแบบ broadcast

### Flutter Integration

1. **เพิ่ม Model Classes:**
```dart
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final String notificationType;
  final String priority;
  final bool isRead;
  final DateTime createdAt;
}

class NotificationSendStatus {
  final String deviceName;
  final String sendStatus;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String? errorMessage;
}
```

2. **เพิ่ม API Service Methods:**
```dart
Future<List<NotificationModel>> getNotifications({
  bool unreadOnly = false,
  int page = 1,
  int limit = 20
});

Future<bool> markAsRead(int notificationId, String deviceId);

Future<bool> createNotification(NotificationModel notification);
```

3. **อัพเดท FCM Handler:**
```dart
// ใน notification_service.dart
void handleForegroundMessage(RemoteMessage message) {
  // แสดงการแจ้งเตือนใน app
  // อัพเดทจำนวนการแจ้งเตือนที่ยังไม่อ่าน
}

void handleBackgroundMessage(RemoteMessage message) {
  // อัพเดทสถานะว่าได้รับการแจ้งเตือนแล้ว
}
```

## Security Considerations

1. **Authentication**: ตรวจสอบ mobile_user_id กับ session/token
2. **Authorization**: ผู้ใช้สามารถดูเฉพาะการแจ้งเตือนของตนเอง
3. **Rate Limiting**: จำกัดจำนวนการส่งการแจ้งเตือนต่อนาที
4. **Input Validation**: ตรวจสอบข้อมูลก่อนบันทึกลงฐานข้อมูล

## Performance Optimization

1. **Indexing**: สร้าง index สำหรับ field ที่ใช้ query บ่อย
2. **Pagination**: ใช้ LIMIT และ OFFSET สำหรับข้อมูลจำนวนมาก
3. **Caching**: Cache ข้อมูลการแจ้งเตือนที่ดึงบ่อย
4. **Background Jobs**: ใช้ queue สำหรับการส่งการแจ้งเตือนจำนวนมาก

## Error Handling

### Common Error Codes:
- `INVALID_FCM_TOKEN`: FCM Token ไม่ถูกต้อง
- `USER_NOT_FOUND`: ไม่พบผู้ใช้
- `NOTIFICATION_NOT_FOUND`: ไม่พบการแจ้งเตือน
- `DEVICE_INACTIVE`: อุปกรณ์ไม่ได้ใช้งาน
- `QUOTA_EXCEEDED`: เกินโควตาการส่ง

### Retry Logic:
- ลองส่งใหม่สูงสุด 3 ครั้ง
- เพิ่มระยะเวลาระหว่าง retry (exponential backoff)
- บันทึก error log สำหรับการ debug