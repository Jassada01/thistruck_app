<?php
// ======================================================
// Integration code สำหรับ mainFunction.php
// เพิ่มส่วนนี้ในไฟล์ mainFunction.php ที่มีอยู่แล้ว
// ======================================================

// Include notification functions
require_once 'notification_backend_functions.php';

// Add these cases to your existing switch statement in mainFunction.php

// ======================================================
// Function 20: Create Notification
// ======================================================
case '20':
    header('Content-Type: application/json; charset=utf-8');
    
    $mobile_user_id = isset($_POST['mobile_user_id']) ? intval($_POST['mobile_user_id']) : 0;
    $title = isset($_POST['title']) ? trim($_POST['title']) : '';
    $message = isset($_POST['message']) ? trim($_POST['message']) : '';
    $data = isset($_POST['data']) ? $_POST['data'] : null;
    $notification_type = isset($_POST['notification_type']) ? trim($_POST['notification_type']) : 'general';
    $priority = isset($_POST['priority']) ? trim($_POST['priority']) : 'normal';
    
    // Validate required fields
    if ($mobile_user_id <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Mobile User ID is required'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    if (empty($title) || empty($message)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Title และ Message จำเป็นต้องระบุ'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Validate user exists
    if (!validateMobileUser($mobile_user_id)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'ไม่พบผู้ใช้ที่ระบุ'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Parse data if it's JSON string
    if ($data && is_string($data)) {
        $decodedData = json_decode($data, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            $data = $decodedData;
        }
    }
    
    $result = createNotification($mobile_user_id, $title, $message, $data, $notification_type, $priority);
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    break;

// ======================================================
// Function 21: Get Notifications
// ======================================================
case '21':
    header('Content-Type: application/json; charset=utf-8');
    
    $mobile_user_id = isset($_POST['mobile_user_id']) ? intval($_POST['mobile_user_id']) : 0;
    $page = isset($_POST['page']) ? max(1, intval($_POST['page'])) : 1;
    $limit = isset($_POST['limit']) ? max(1, min(100, intval($_POST['limit']))) : 20;
    $unread_only = isset($_POST['unread_only']) && $_POST['unread_only'] == '1';
    
    // Validate required fields
    if ($mobile_user_id <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Mobile User ID is required'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Validate user exists
    if (!validateMobileUser($mobile_user_id)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'ไม่พบผู้ใช้ที่ระบุ'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $result = getNotifications($mobile_user_id, $page, $limit, $unread_only);
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    break;

// ======================================================
// Function 22: Mark Notification as Read
// ======================================================
case '22':
    header('Content-Type: application/json; charset=utf-8');
    
    $notification_id = isset($_POST['notification_id']) ? intval($_POST['notification_id']) : 0;
    $device_id = isset($_POST['device_id']) ? trim($_POST['device_id']) : '';
    
    // Validate required fields
    if ($notification_id <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Notification ID is required'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    if (empty($device_id)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Device ID is required'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $result = markNotificationAsRead($notification_id, $device_id);
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    break;

// ======================================================
// Function 23: Get Unread Notification Count
// ======================================================
case '23':
    header('Content-Type: application/json; charset=utf-8');
    
    $mobile_user_id = isset($_POST['mobile_user_id']) ? intval($_POST['mobile_user_id']) : 0;
    
    // Validate required fields
    if ($mobile_user_id <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Mobile User ID is required'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Validate user exists
    if (!validateMobileUser($mobile_user_id)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'ไม่พบผู้ใช้ที่ระบุ'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $result = getUnreadNotificationCount($mobile_user_id);
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    break;

// ======================================================
// Function 24: Get Notification Statistics (Bonus)
// ======================================================
case '24':
    header('Content-Type: application/json; charset=utf-8');
    
    $mobile_user_id = isset($_POST['mobile_user_id']) ? intval($_POST['mobile_user_id']) : 0;
    
    // Validate required fields
    if ($mobile_user_id <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Mobile User ID is required'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Validate user exists
    if (!validateMobileUser($mobile_user_id)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'ไม่พบผู้ใช้ที่ระบุ'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $result = getNotificationStats($mobile_user_id);
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    break;

// ======================================================
// Function 25: Mark All Notifications as Read (Bonus)
// ======================================================
case '25':
    header('Content-Type: application/json; charset=utf-8');
    
    $mobile_user_id = isset($_POST['mobile_user_id']) ? intval($_POST['mobile_user_id']) : 0;
    $device_id = isset($_POST['device_id']) ? trim($_POST['device_id']) : '';
    
    // Validate required fields
    if ($mobile_user_id <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Mobile User ID is required'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    if (empty($device_id)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Device ID is required'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Validate user exists
    if (!validateMobileUser($mobile_user_id)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'ไม่พบผู้ใช้ที่ระบุ'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $result = markAllNotificationsAsRead($mobile_user_id, $device_id);
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    break;

?>

<!-- 
======================================================
การใช้งาน API Endpoints
======================================================

1. Create Notification (Function 20)
POST: http://yourserver.com/path/to/mainFunction.php
Parameters:
- f=20
- mobile_user_id=5
- title=งานใหม่ได้รับมอบหมาย
- message=คุณได้รับงานขนส่งใหม่ จาก กรุงเทพฯ ไป เชียงใหม่
- data={"job_id": 12345, "route": "กรุงเทพฯ - เชียงใหม่"}
- notification_type=job
- priority=high

2. Get Notifications (Function 21)
POST: http://yourserver.com/path/to/mainFunction.php
Parameters:
- f=21
- mobile_user_id=5
- page=1 (optional)
- limit=20 (optional)
- unread_only=0 (optional, 1 for unread only)

3. Mark as Read (Function 22)
POST: http://yourserver.com/path/to/mainFunction.php
Parameters:
- f=22
- notification_id=123
- device_id=820AEAE2-CF83-434E-9E33-7DCA0A66DF05

4. Get Unread Count (Function 23)
POST: http://yourserver.com/path/to/mainFunction.php
Parameters:
- f=23
- mobile_user_id=5

5. Get Statistics (Function 24)
POST: http://yourserver.com/path/to/mainFunction.php
Parameters:
- f=24
- mobile_user_id=5

6. Mark All as Read (Function 25)
POST: http://yourserver.com/path/to/mainFunction.php
Parameters:
- f=25
- mobile_user_id=5
- device_id=820AEAE2-CF83-434E-9E33-7DCA0A66DF05

======================================================
Response Format
======================================================

Success Response:
{
    "status": "success",
    "data": [...],
    "pagination": {
        "current_page": 1,
        "total_pages": 5,
        "total_items": 100,
        "unread_count": 15
    }
}

Error Response:
{
    "status": "error",
    "message": "Error description"
}

-->