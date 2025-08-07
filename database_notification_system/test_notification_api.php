<?php
// ======================================================
// Test Script สำหรับทดสอบ Notification API
// ======================================================

// Include notification functions
require_once 'notification_backend_functions.php';

echo "<h1>🧪 Test Notification API Functions</h1>";
echo "<hr>";

// Test mobile user ID (แก้ไขตามข้อมูลจริงในฐานข้อมูล)
$test_mobile_user_id = 5;
$test_device_id = "TEST-DEVICE-ID-123";

echo "<h2>📋 Test Data</h2>";
echo "Mobile User ID: $test_mobile_user_id<br>";
echo "Device ID: $test_device_id<br>";
echo "<hr>";

// ======================================================
// Test 1: Validate Mobile User
// ======================================================
echo "<h2>🔍 Test 1: Validate Mobile User</h2>";
$userExists = validateMobileUser($test_mobile_user_id);
echo "User exists: " . ($userExists ? "✅ Yes" : "❌ No") . "<br>";
echo "<hr>";

if (!$userExists) {
    echo "<p style='color: red;'>⚠️ Warning: Test mobile user ID $test_mobile_user_id does not exist. Please update the test_mobile_user_id variable with a valid ID from your mobile_users table.</p>";
    echo "<hr>";
}

// ======================================================
// Test 2: Create Test Notifications
// ======================================================
echo "<h2>📝 Test 2: Create Test Notifications</h2>";

$testNotifications = [
    [
        'title' => 'งานใหม่ได้รับมอบหมาย',
        'message' => 'คุณได้รับงานขนส่งใหม่ จาก กรุงเทพฯ ไป เชียงใหม่',
        'data' => ['job_id' => 12345, 'route' => 'กรุงเทพฯ - เชียงใหม่', 'pickup_date' => '2025-08-03'],
        'type' => 'job',
        'priority' => 'high'
    ],
    [
        'title' => 'แจ้งเตือนระบบ',
        'message' => 'ระบบจะปิดปรับปรุงในวันที่ 5 สิงหาคม 2568 เวลา 02:00-04:00 น.',
        'data' => ['maintenance_start' => '2025-08-05 02:00:00', 'maintenance_end' => '2025-08-05 04:00:00'],
        'type' => 'system',
        'priority' => 'normal'
    ],
    [
        'title' => 'เตือนความปลอดภัย',
        'message' => 'โปรดตรวจสอบความพร้อมของรถก่อนออกเดินทาง',
        'data' => ['safety_checklist' => ['เบรก', 'ไฟหน้า', 'ยาง', 'น้ำมันเครื่อง']],
        'type' => 'alert',
        'priority' => 'urgent'
    ]
];

$createdNotificationIds = [];

foreach ($testNotifications as $index => $notification) {
    echo "Creating notification " . ($index + 1) . ": {$notification['title']}<br>";
    
    $result = createNotification(
        $test_mobile_user_id,
        $notification['title'],
        $notification['message'],
        $notification['data'],
        $notification['type'],
        $notification['priority']
    );
    
    if ($result['status'] === 'success') {
        echo "✅ Created successfully (ID: {$result['notification_id']})<br>";
        $createdNotificationIds[] = $result['notification_id'];
    } else {
        echo "❌ Failed: {$result['message']}<br>";
    }
}
echo "<hr>";

// ======================================================
// Test 3: Get Notifications (All)
// ======================================================
echo "<h2>📋 Test 3: Get All Notifications</h2>";
$result = getNotifications($test_mobile_user_id, 1, 10, false);

if ($result['status'] === 'success') {
    echo "✅ Successfully retrieved notifications<br>";
    echo "Total items: {$result['pagination']['total_items']}<br>";
    echo "Unread count: {$result['pagination']['unread_count']}<br>";
    echo "Number of notifications returned: " . count($result['data']) . "<br>";
    
    echo "<h3>📝 Notification List:</h3>";
    foreach ($result['data'] as $notification) {
        echo "<div style='border: 1px solid #ccc; padding: 10px; margin: 5px 0;'>";
        echo "<strong>ID:</strong> {$notification['id']}<br>";
        echo "<strong>Title:</strong> {$notification['title']}<br>";
        echo "<strong>Type:</strong> {$notification['notification_type']}<br>";
        echo "<strong>Priority:</strong> {$notification['priority']}<br>";
        echo "<strong>Status:</strong> {$notification['status']}<br>";
        echo "<strong>Read:</strong> " . ($notification['is_read'] ? 'Yes' : 'No') . "<br>";
        echo "<strong>Created:</strong> {$notification['created_at']}<br>";
        echo "</div>";
    }
} else {
    echo "❌ Failed: {$result['message']}<br>";
}
echo "<hr>";

// ======================================================
// Test 4: Get Unread Notifications Only
// ======================================================
echo "<h2>📋 Test 4: Get Unread Notifications Only</h2>";
$result = getNotifications($test_mobile_user_id, 1, 10, true);

if ($result['status'] === 'success') {
    echo "✅ Successfully retrieved unread notifications<br>";
    echo "Number of unread notifications: " . count($result['data']) . "<br>";
} else {
    echo "❌ Failed: {$result['message']}<br>";
}
echo "<hr>";

// ======================================================
// Test 5: Get Unread Count
// ======================================================
echo "<h2>🔢 Test 5: Get Unread Count</h2>";
$result = getUnreadNotificationCount($test_mobile_user_id);

if ($result['status'] === 'success') {
    echo "✅ Unread count: {$result['unread_count']}<br>";
} else {
    echo "❌ Failed: {$result['message']}<br>";
}
echo "<hr>";

// ======================================================
// Test 6: Mark Notification as Read
// ======================================================
echo "<h2>✅ Test 6: Mark Notification as Read</h2>";
if (!empty($createdNotificationIds)) {
    $testNotificationId = $createdNotificationIds[0];
    echo "Marking notification ID $testNotificationId as read...<br>";
    
    $result = markNotificationAsRead($testNotificationId, $test_device_id);
    
    if ($result['status'] === 'success') {
        echo "✅ Successfully marked as read: {$result['message']}<br>";
    } else {
        echo "❌ Failed: {$result['message']}<br>";
    }
} else {
    echo "⚠️ No test notifications available to mark as read<br>";
}
echo "<hr>";

// ======================================================
// Test 7: Get Notification Statistics
// ======================================================
echo "<h2>📊 Test 7: Get Notification Statistics</h2>";
$result = getNotificationStats($test_mobile_user_id);

if ($result['status'] === 'success') {
    echo "✅ Successfully retrieved statistics<br>";
    $stats = $result['stats'];
    echo "<ul>";
    echo "<li>Total notifications: {$stats['total_notifications']}</li>";
    echo "<li>Unread count: {$stats['unread_count']}</li>";
    echo "<li>Job notifications: {$stats['job_notifications']}</li>";
    echo "<li>Alert notifications: {$stats['alert_notifications']}</li>";
    echo "<li>System notifications: {$stats['system_notifications']}</li>";
    echo "<li>Urgent notifications: {$stats['urgent_notifications']}</li>";
    echo "</ul>";
} else {
    echo "❌ Failed: {$result['message']}<br>";
}
echo "<hr>";

// ======================================================
// Test 8: Mark All Notifications as Read
// ======================================================
echo "<h2>✅ Test 8: Mark All Notifications as Read</h2>";
$result = markAllNotificationsAsRead($test_mobile_user_id, $test_device_id);

if ($result['status'] === 'success') {
    echo "✅ Successfully marked all as read<br>";
    echo "Updated count: {$result['updated_count']}<br>";
    echo "Message: {$result['message']}<br>";
} else {
    echo "❌ Failed: {$result['message']}<br>";
}
echo "<hr>";

// ======================================================
// Test 9: Verify All Read
// ======================================================
echo "<h2>🔍 Test 9: Verify All Notifications are Read</h2>";
$result = getUnreadNotificationCount($test_mobile_user_id);

if ($result['status'] === 'success') {
    $unreadCount = $result['unread_count'];
    if ($unreadCount == 0) {
        echo "✅ Success: All notifications are now read (unread count: $unreadCount)<br>";
    } else {
        echo "⚠️ Warning: There are still $unreadCount unread notifications<br>";
    }
} else {
    echo "❌ Failed to verify: {$result['message']}<br>";
}
echo "<hr>";

// ======================================================
// Test Summary
// ======================================================
echo "<h2>📋 Test Summary</h2>";
echo "<p>✅ Test completed! Check the results above to ensure all functions are working properly.</p>";
echo "<p>🔧 If you see any errors, please check:</p>";
echo "<ul>";
echo "<li>Database connection settings in notification_backend_functions.php</li>";
echo "<li>Make sure the mobile_users table has a user with ID $test_mobile_user_id</li>";
echo "<li>Verify that the mobile_notifications and mobile_notification_sends tables exist</li>";
echo "<li>Check that all table schemas match the expected structure</li>";
echo "</ul>";

echo "<h3>🚀 Next Steps:</h3>";
echo "<ol>";
echo "<li>If tests pass, copy the integration code to your mainFunction.php</li>";
echo "<li>Test the API endpoints using Postman or your Flutter app</li>";
echo "<li>Update the database password in the notification_backend_functions.php file</li>";
echo "<li>Deploy to your server and test with real FCM notifications</li>";
echo "</ol>";

?>

<style>
body {
    font-family: Arial, sans-serif;
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    line-height: 1.6;
}

h1, h2 {
    color: #333;
}

hr {
    border: none;
    border-top: 2px solid #eee;
    margin: 20px 0;
}

div {
    background-color: #f9f9f9;
}

ul, ol {
    padding-left: 20px;
}

p {
    margin: 10px 0;
}
</style>