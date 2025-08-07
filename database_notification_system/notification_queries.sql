-- ======================================================
-- SQL Queries สำหรับระบบการแจ้งเตือน Mobile Notification
-- ======================================================

-- ======================================================
-- 1. QUERIES สำหรับการสร้างและส่งการแจ้งเตือน
-- ======================================================

-- 1.1 สร้างการแจ้งเตือนใหม่
INSERT INTO mobile_notifications (mobile_user_id, title, message, data, notification_type, priority) 
VALUES (?, ?, ?, ?, ?, ?);

-- 1.2 ดึงรายการ devices ทั้งหมดของ user สำหรับส่งการแจ้งเตือน
SELECT id, device_id, fcm_token, device_name, is_active 
FROM mobile_user_devices 
WHERE mobile_user_id = ? AND is_active = 1;

-- 1.3 บันทึกประวัติการส่งการแจ้งเตือนไปยัง device
INSERT INTO mobile_notification_sends (notification_id, device_id, fcm_token, send_status) 
VALUES (?, ?, ?, 'pending');

-- 1.4 อัพเดทสถานะการส่งเมื่อส่งสำเร็จ
UPDATE mobile_notification_sends 
SET send_status = 'sent', 
    send_result = ?, 
    sent_at = NOW() 
WHERE id = ?;

-- 1.5 อัพเดทสถานะการส่งเมื่อส่งไม่สำเร็จ
UPDATE mobile_notification_sends 
SET send_status = 'failed', 
    error_message = ?, 
    retry_count = retry_count + 1 
WHERE id = ?;

-- ======================================================
-- 2. QUERIES สำหรับการอ่านการแจ้งเตือน
-- ======================================================

-- 2.1 ดึงการแจ้งเตือนที่ยังไม่อ่านของ user
SELECT id, title, message, data, notification_type, priority, created_at 
FROM mobile_notifications 
WHERE mobile_user_id = ? AND is_read = 0 
ORDER BY priority DESC, created_at DESC;

-- 2.2 ดึงการแจ้งเตือนทั้งหมดของ user (มีการแบ่งหน้า)
SELECT id, title, message, data, notification_type, priority, is_read, created_at 
FROM mobile_notifications 
WHERE mobile_user_id = ? 
ORDER BY created_at DESC 
LIMIT ? OFFSET ?;

-- 2.3 นับจำนวนการแจ้งเตือนที่ยังไม่อ่าน
SELECT COUNT(*) as unread_count 
FROM mobile_notifications 
WHERE mobile_user_id = ? AND is_read = 0;

-- 2.4 ทำเครื่องหมายการแจ้งเตือนว่าอ่านแล้ว
UPDATE mobile_notifications 
SET is_read = 1, 
    read_at = NOW(), 
    read_device_id = ? 
WHERE id = ? AND mobile_user_id = ?;

-- ======================================================
-- 3. QUERIES สำหรับการติดตามสถานะการส่ง
-- ======================================================

-- 3.1 ดูสถานะการส่งของการแจ้งเตือนเฉพาะ
SELECT 
    n.title,
    n.message,
    d.device_name,
    s.send_status,
    s.sent_at,
    s.delivered_at,
    s.error_message,
    s.retry_count
FROM mobile_notifications n
JOIN mobile_notification_sends s ON n.id = s.notification_id
JOIN mobile_user_devices d ON s.device_id = d.id
WHERE n.id = ?;

-- 3.2 ดูการแจ้งเตือนที่ส่งไม่สำเร็จ
SELECT 
    n.id,
    n.title,
    n.mobile_user_id,
    s.device_id,
    d.device_name,
    s.error_message,
    s.retry_count,
    s.created_at
FROM mobile_notifications n
JOIN mobile_notification_sends s ON n.id = s.notification_id
JOIN mobile_user_devices d ON s.device_id = d.id
WHERE s.send_status = 'failed' AND s.retry_count < 3
ORDER BY s.created_at ASC;

-- 3.3 ดูสถิติการส่งการแจ้งเตือนรายวัน
SELECT 
    DATE(created_at) as send_date,
    send_status,
    COUNT(*) as count
FROM mobile_notification_sends 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(created_at), send_status
ORDER BY send_date DESC;

-- ======================================================
-- 4. QUERIES สำหรับการจัดการ FCM Token
-- ======================================================

-- 4.1 อัพเดท FCM Token เมื่อ device เปลี่ยน token
UPDATE mobile_user_devices 
SET fcm_token = ?, updated_at = NOW() 
WHERE device_id = ? AND mobile_user_id = ?;

-- 4.2 ดึง FCM Tokens ทั้งหมดของ user สำหรับส่งการแจ้งเตือน
SELECT fcm_token 
FROM mobile_user_devices 
WHERE mobile_user_id = ? AND is_active = 1;

-- 4.3 ปิดการใช้งาน device ที่มี FCM Token ไม่ถูกต้อง
UPDATE mobile_user_devices 
SET is_active = 0 
WHERE fcm_token = ?;

-- ======================================================
-- 5. QUERIES สำหรับรายงานและสถิติ
-- ======================================================

-- 5.1 สถิติการแจ้งเตือนตามประเภท
SELECT 
    notification_type,
    COUNT(*) as total_notifications,
    SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as read_count,
    SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_count
FROM mobile_notifications 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY notification_type;

-- 5.2 User ที่มีการแจ้งเตือนค้างอ่านมากที่สุด
SELECT 
    mu.id as user_id,
    mu.user_type,
    mu.driver_id,
    COUNT(*) as unread_notifications
FROM mobile_notifications mn
JOIN mobile_users mu ON mn.mobile_user_id = mu.id
WHERE mn.is_read = 0
GROUP BY mu.id, mu.user_type, mu.driver_id
ORDER BY unread_notifications DESC
LIMIT 10;

-- 5.3 อัตราสำเร็จในการส่งการแจ้งเตือน
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_sends,
    SUM(CASE WHEN send_status = 'delivered' THEN 1 ELSE 0 END) as delivered_count,
    SUM(CASE WHEN send_status = 'failed' THEN 1 ELSE 0 END) as failed_count,
    ROUND((SUM(CASE WHEN send_status = 'delivered' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) as success_rate
FROM mobile_notification_sends 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- ======================================================
-- 6. QUERIES สำหรับการบำรุงรักษา
-- ======================================================

-- 6.1 ลบการแจ้งเตือนเก่าที่อ่านแล้ว (เก่ากว่า 90 วัน)
DELETE FROM mobile_notifications 
WHERE is_read = 1 AND created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);

-- 6.2 ลบประวัติการส่งที่เก่ามาก (เก่ากว่า 180 วัน)
DELETE FROM mobile_notification_sends 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 180 DAY);

-- 6.3 อัพเดท retry count สำหรับการส่งที่ล้มเหลว
UPDATE mobile_notification_sends 
SET retry_count = retry_count + 1 
WHERE send_status = 'failed' AND retry_count < 3;

-- ======================================================
-- 7. STORED PROCEDURES (ตัวอย่าง)
-- ======================================================

DELIMITER //

-- 7.1 Procedure สำหรับส่งการแจ้งเตือนไปยัง user
CREATE PROCEDURE SendNotificationToUser(
    IN p_mobile_user_id INT,
    IN p_title VARCHAR(255),
    IN p_message TEXT,
    IN p_data JSON,
    IN p_notification_type VARCHAR(50),
    IN p_priority ENUM('low','normal','high','urgent')
)
BEGIN
    DECLARE notification_id INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE device_id INT;
    DECLARE fcm_token TEXT;
    
    -- Cursor สำหรับดึง devices ของ user
    DECLARE device_cursor CURSOR FOR 
        SELECT id, fcm_token FROM mobile_user_devices 
        WHERE mobile_user_id = p_mobile_user_id AND is_active = 1;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- สร้างการแจ้งเตือน
    INSERT INTO mobile_notifications (mobile_user_id, title, message, data, notification_type, priority) 
    VALUES (p_mobile_user_id, p_title, p_message, p_data, p_notification_type, p_priority);
    
    SET notification_id = LAST_INSERT_ID();
    
    -- ส่งไปยังทุก device ของ user
    OPEN device_cursor;
    
    device_loop: LOOP
        FETCH device_cursor INTO device_id, fcm_token;
        IF done THEN
            LEAVE device_loop;
        END IF;
        
        INSERT INTO mobile_notification_sends (notification_id, device_id, fcm_token, send_status) 
        VALUES (notification_id, device_id, fcm_token, 'pending');
        
    END LOOP;
    
    CLOSE device_cursor;
    
    SELECT notification_id as created_notification_id;
    
END //

DELIMITER ;