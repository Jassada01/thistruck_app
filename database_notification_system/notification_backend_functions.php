<?php
// ======================================================
// PHP Backend Functions สำหรับระบบการแจ้งเตือน
// ======================================================

// Database connection function
function getDbConnection() {
    $host = 'localhost';
    $username = 'root';
    $password = '}Ww]3v2CX<2mSH$7';  // แก้ไขตามของคุณ
    $database = 'mysystem';
    
    try {
        $pdo = new PDO("mysql:host=$host;dbname=$database;charset=utf8mb4", $username, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        return $pdo;
    } catch (PDOException $e) {
        error_log("Database connection failed: " . $e->getMessage());
        return null;
    }
}

// ======================================================
// Function 21: Get Notifications
// ======================================================
function getNotifications($mobile_user_id, $page = 1, $limit = 20, $unread_only = false) {
    $pdo = getDbConnection();
    if (!$pdo) {
        return [
            'status' => 'error',
            'message' => 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้'
        ];
    }
    
    try {
        // Validate input
        $mobile_user_id = intval($mobile_user_id);
        $page = max(1, intval($page));
        $limit = max(1, min(100, intval($limit))); // Max 100 items per page
        $offset = ($page - 1) * $limit;
        
        // Build query
        $whereClause = "WHERE mobile_user_id = :mobile_user_id";
        if ($unread_only) {
            $whereClause .= " AND is_read = 0";
        }
        
        // Get total count for pagination
        $countQuery = "SELECT COUNT(*) as total FROM mobile_notifications $whereClause";
        $countStmt = $pdo->prepare($countQuery);
        $countStmt->bindParam(':mobile_user_id', $mobile_user_id, PDO::PARAM_INT);
        $countStmt->execute();
        $totalItems = $countStmt->fetch()['total'];
        
        // Get unread count
        $unreadCountQuery = "SELECT COUNT(*) as unread_count FROM mobile_notifications 
                            WHERE mobile_user_id = :mobile_user_id AND is_read = 0";
        $unreadStmt = $pdo->prepare($unreadCountQuery);
        $unreadStmt->bindParam(':mobile_user_id', $mobile_user_id, PDO::PARAM_INT);
        $unreadStmt->execute();
        $unreadCount = $unreadStmt->fetch()['unread_count'];
        
        // Get notifications
        $query = "SELECT id, mobile_user_id, title, message, data, notification_type, 
                         priority, status, processed_at, is_read, read_at, read_device_id, 
                         created_at, updated_at
                  FROM mobile_notifications 
                  $whereClause
                  ORDER BY priority DESC, created_at DESC
                  LIMIT :limit OFFSET :offset";
        
        $stmt = $pdo->prepare($query);
        $stmt->bindParam(':mobile_user_id', $mobile_user_id, PDO::PARAM_INT);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();
        
        $notifications = $stmt->fetchAll();
        
        // Calculate pagination
        $totalPages = ceil($totalItems / $limit);
        
        return [
            'status' => 'success',
            'data' => $notifications,
            'pagination' => [
                'current_page' => $page,
                'total_pages' => $totalPages,
                'total_items' => intval($totalItems),
                'unread_count' => intval($unreadCount)
            ]
        ];
        
    } catch (PDOException $e) {
        error_log("Error getting notifications: " . $e->getMessage());
        return [
            'status' => 'error',
            'message' => 'เกิดข้อผิดพลาดในการดึงข้อมูลการแจ้งเตือน'
        ];
    }
}

// ======================================================
// Function 22: Mark Notification as Read
// ======================================================
function markNotificationAsRead($notification_id, $device_id) {
    $pdo = getDbConnection();
    if (!$pdo) {
        return [
            'status' => 'error',
            'message' => 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้'
        ];
    }
    
    try {
        // Validate input
        $notification_id = intval($notification_id);
        if (empty($device_id)) {
            return [
                'status' => 'error',
                'message' => 'Device ID is required'
            ];
        }
        
        // Check if notification exists and is not already read
        $checkQuery = "SELECT id, mobile_user_id, is_read FROM mobile_notifications WHERE id = :notification_id";
        $checkStmt = $pdo->prepare($checkQuery);
        $checkStmt->bindParam(':notification_id', $notification_id, PDO::PARAM_INT);
        $checkStmt->execute();
        
        $notification = $checkStmt->fetch();
        if (!$notification) {
            return [
                'status' => 'error',
                'message' => 'ไม่พบการแจ้งเตือนที่ระบุ'
            ];
        }
        
        if ($notification['is_read'] == 1) {
            return [
                'status' => 'success',
                'message' => 'การแจ้งเตือนนี้อ่านแล้ว'
            ];
        }
        
        // Update notification as read
        $updateQuery = "UPDATE mobile_notifications 
                       SET is_read = 1, read_at = NOW(), read_device_id = :device_id, updated_at = NOW()
                       WHERE id = :notification_id";
        
        $updateStmt = $pdo->prepare($updateQuery);
        $updateStmt->bindParam(':notification_id', $notification_id, PDO::PARAM_INT);
        $updateStmt->bindParam(':device_id', $device_id, PDO::PARAM_STR);
        $result = $updateStmt->execute();
        
        if ($result) {
            return [
                'status' => 'success',
                'message' => 'ทำเครื่องหมายอ่านแล้วสำเร็จ'
            ];
        } else {
            return [
                'status' => 'error',
                'message' => 'ไม่สามารถทำเครื่องหมายอ่านแล้วได้'
            ];
        }
        
    } catch (PDOException $e) {
        error_log("Error marking notification as read: " . $e->getMessage());
        return [
            'status' => 'error',
            'message' => 'เกิดข้อผิดพลาดในการทำเครื่องหมายอ่านแล้ว'
        ];
    }
}

// ======================================================
// Function 23: Get Unread Notification Count
// ======================================================
function getUnreadNotificationCount($mobile_user_id) {
    $pdo = getDbConnection();
    if (!$pdo) {
        return [
            'status' => 'error',
            'message' => 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้'
        ];
    }
    
    try {
        // Validate input
        $mobile_user_id = intval($mobile_user_id);
        
        // Get unread count
        $query = "SELECT COUNT(*) as unread_count FROM mobile_notifications 
                  WHERE mobile_user_id = :mobile_user_id AND is_read = 0";
        
        $stmt = $pdo->prepare($query);
        $stmt->bindParam(':mobile_user_id', $mobile_user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        $result = $stmt->fetch();
        $unreadCount = $result['unread_count'];
        
        return [
            'status' => 'success',
            'unread_count' => intval($unreadCount)
        ];
        
    } catch (PDOException $e) {
        error_log("Error getting unread count: " . $e->getMessage());
        return [
            'status' => 'error',
            'message' => 'เกิดข้อผิดพลาดในการนับการแจ้งเตือนที่ยังไม่อ่าน'
        ];
    }
}

// ======================================================
// Function 20: Create Notification (Bonus)
// ======================================================
function createNotification($mobile_user_id, $title, $message, $data = null, $notification_type = 'general', $priority = 'normal') {
    $pdo = getDbConnection();
    if (!$pdo) {
        return [
            'status' => 'error',
            'message' => 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้'
        ];
    }
    
    try {
        // Validate input
        $mobile_user_id = intval($mobile_user_id);
        if (empty($title) || empty($message)) {
            return [
                'status' => 'error',
                'message' => 'Title และ Message จำเป็นต้องระบุ'
            ];
        }
        
        // Validate priority
        $validPriorities = ['low', 'normal', 'high', 'urgent'];
        if (!in_array($priority, $validPriorities)) {
            $priority = 'normal';
        }
        
        // Validate notification type
        $validTypes = ['general', 'job', 'alert', 'system'];
        if (!in_array($notification_type, $validTypes)) {
            $notification_type = 'general';
        }
        
        // Prepare data as JSON
        $dataJson = null;
        if ($data !== null) {
            if (is_array($data)) {
                $dataJson = json_encode($data, JSON_UNESCAPED_UNICODE);
            } else {
                $dataJson = $data;
            }
        }
        
        // Insert notification
        $query = "INSERT INTO mobile_notifications 
                  (mobile_user_id, title, message, data, notification_type, priority, status, created_at) 
                  VALUES (:mobile_user_id, :title, :message, :data, :notification_type, :priority, 'pending', NOW())";
        
        $stmt = $pdo->prepare($query);
        $stmt->bindParam(':mobile_user_id', $mobile_user_id, PDO::PARAM_INT);
        $stmt->bindParam(':title', $title, PDO::PARAM_STR);
        $stmt->bindParam(':message', $message, PDO::PARAM_STR);
        $stmt->bindParam(':data', $dataJson, PDO::PARAM_STR);
        $stmt->bindParam(':notification_type', $notification_type, PDO::PARAM_STR);
        $stmt->bindParam(':priority', $priority, PDO::PARAM_STR);
        
        $result = $stmt->execute();
        $notificationId = $pdo->lastInsertId();
        
        if ($result) {
            return [
                'status' => 'success',
                'notification_id' => intval($notificationId),
                'message' => 'สร้างการแจ้งเตือนสำเร็จ'
            ];
        } else {
            return [
                'status' => 'error',
                'message' => 'ไม่สามารถสร้างการแจ้งเตือนได้'
            ];
        }
        
    } catch (PDOException $e) {
        error_log("Error creating notification: " . $e->getMessage());
        return [
            'status' => 'error',
            'message' => 'เกิดข้อผิดพลาดในการสร้างการแจ้งเตือน'
        ];
    }
}

// ======================================================
// Helper Functions
// ======================================================

// Function to validate mobile_user_id exists
function validateMobileUser($mobile_user_id) {
    $pdo = getDbConnection();
    if (!$pdo) return false;
    
    try {
        $query = "SELECT id FROM mobile_users WHERE id = :mobile_user_id AND is_active = 1";
        $stmt = $pdo->prepare($query);
        $stmt->bindParam(':mobile_user_id', $mobile_user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetch() !== false;
    } catch (PDOException $e) {
        error_log("Error validating mobile user: " . $e->getMessage());
        return false;
    }
}

// Function to get notification statistics
function getNotificationStats($mobile_user_id) {
    $pdo = getDbConnection();
    if (!$pdo) {
        return [
            'status' => 'error',
            'message' => 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้'
        ];
    }
    
    try {
        $mobile_user_id = intval($mobile_user_id);
        
        $query = "SELECT 
                    COUNT(*) as total_notifications,
                    SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_count,
                    SUM(CASE WHEN notification_type = 'job' THEN 1 ELSE 0 END) as job_notifications,
                    SUM(CASE WHEN notification_type = 'alert' THEN 1 ELSE 0 END) as alert_notifications,
                    SUM(CASE WHEN notification_type = 'system' THEN 1 ELSE 0 END) as system_notifications,
                    SUM(CASE WHEN priority = 'urgent' THEN 1 ELSE 0 END) as urgent_notifications
                  FROM mobile_notifications 
                  WHERE mobile_user_id = :mobile_user_id";
        
        $stmt = $pdo->prepare($query);
        $stmt->bindParam(':mobile_user_id', $mobile_user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        $stats = $stmt->fetch();
        
        return [
            'status' => 'success',
            'stats' => [
                'total_notifications' => intval($stats['total_notifications']),
                'unread_count' => intval($stats['unread_count']),
                'job_notifications' => intval($stats['job_notifications']),
                'alert_notifications' => intval($stats['alert_notifications']),
                'system_notifications' => intval($stats['system_notifications']),
                'urgent_notifications' => intval($stats['urgent_notifications'])
            ]
        ];
        
    } catch (PDOException $e) {
        error_log("Error getting notification stats: " . $e->getMessage());
        return [
            'status' => 'error',
            'message' => 'เกิดข้อผิดพลาดในการดึงสถิติการแจ้งเตือน'
        ];
    }
}

// Function to mark all notifications as read
function markAllNotificationsAsRead($mobile_user_id, $device_id) {
    $pdo = getDbConnection();
    if (!$pdo) {
        return [
            'status' => 'error',
            'message' => 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้'
        ];
    }
    
    try {
        $mobile_user_id = intval($mobile_user_id);
        
        $query = "UPDATE mobile_notifications 
                  SET is_read = 1, read_at = NOW(), read_device_id = :device_id, updated_at = NOW()
                  WHERE mobile_user_id = :mobile_user_id AND is_read = 0";
        
        $stmt = $pdo->prepare($query);
        $stmt->bindParam(':mobile_user_id', $mobile_user_id, PDO::PARAM_INT);
        $stmt->bindParam(':device_id', $device_id, PDO::PARAM_STR);
        $result = $stmt->execute();
        
        $updatedCount = $stmt->rowCount();
        
        if ($result) {
            return [
                'status' => 'success',
                'updated_count' => $updatedCount,
                'message' => "ทำเครื่องหมายอ่านแล้ว $updatedCount รายการ"
            ];
        } else {
            return [
                'status' => 'error',
                'message' => 'ไม่สามารถทำเครื่องหมายอ่านแล้วได้'
            ];
        }
        
    } catch (PDOException $e) {
        error_log("Error marking all notifications as read: " . $e->getMessage());
        return [
            'status' => 'error',
            'message' => 'เกิดข้อผิดพลาดในการทำเครื่องหมายอ่านแล้วทั้งหมด'
        ];
    }
}

?>