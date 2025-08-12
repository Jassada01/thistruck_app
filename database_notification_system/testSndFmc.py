import firebase_admin
from firebase_admin import credentials, messaging
import mysql.connector
import json
from datetime import datetime
import time

# --- 1. Database Configuration ---
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',  # แก้ไขตาม username ของคุณ
    'password': "}Ww]3v2CX<2mSH$7",  # แก้ไขตาม password ของคุณ
    'database': 'mysystem'
}

# --- 2. Database Functions ---
def get_db_connection():
    """เชื่อมต่อกับฐานข้อมูล MySQL"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except mysql.connector.Error as e:
        print(f"❌ Database connection error: {e}")
        return None

def get_pending_notifications():
    """ดึงการแจ้งเตือนที่มีสถานะ pending"""
    conn = get_db_connection()
    if not conn:
        return []
    
    try:
        cursor = conn.cursor(dictionary=True)
        query = """
        SELECT id, mobile_user_id, title, message, data, notification_type, priority 
        FROM mobile_notifications 
        WHERE status = 'pending' 
        ORDER BY priority DESC, created_at ASC
        """
        cursor.execute(query)
        notifications = cursor.fetchall()
        cursor.close()
        conn.close()
        return notifications
    except mysql.connector.Error as e:
        print(f"❌ Error fetching pending notifications: {e}")
        conn.close()
        return []

def update_notification_status(notification_id, status, processed_at=None):
    """อัปเดตสถานะของการแจ้งเตือน"""
    conn = get_db_connection()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        if processed_at:
            query = """
            UPDATE mobile_notifications 
            SET status = %s, processed_at = %s, updated_at = NOW() 
            WHERE id = %s
            """
            cursor.execute(query, (status, processed_at, notification_id))
        else:
            query = """
            UPDATE mobile_notifications 
            SET status = %s, updated_at = NOW() 
            WHERE id = %s
            """
            cursor.execute(query, (status, notification_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except mysql.connector.Error as e:
        print(f"❌ Error updating notification status: {e}")
        conn.close()
        return False

def get_user_devices(mobile_user_id):
    """ดึงข้อมูล devices ของ user"""
    conn = get_db_connection()
    if not conn:
        return []
    
    try:
        cursor = conn.cursor(dictionary=True)
        query = """
        SELECT id, device_id, fcm_token, device_name, is_active 
        FROM mobile_user_devices 
        WHERE mobile_user_id = %s AND is_active = 1
        """
        cursor.execute(query, (mobile_user_id,))
        devices = cursor.fetchall()
        cursor.close()
        conn.close()
        return devices
    except mysql.connector.Error as e:
        print(f"❌ Error fetching user devices: {e}")
        conn.close()
        return []

def create_notification_send_record(notification_id, device_id, fcm_token, status='pending'):
    """สร้างรายการส่งการแจ้งเตือน"""
    conn = get_db_connection()
    if not conn:
        return None
    
    try:
        cursor = conn.cursor()
        query = """
        INSERT INTO mobile_notification_sends 
        (notification_id, device_id, fcm_token, send_status, created_at) 
        VALUES (%s, %s, %s, %s, NOW())
        """
        cursor.execute(query, (notification_id, device_id, fcm_token, status))
        send_id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()
        return send_id
    except mysql.connector.Error as e:
        print(f"❌ Error creating notification send record: {e}")
        conn.close()
        return None

def update_send_status(send_id, status, result=None, error_message=None, retry_count=0):
    """อัปเดตสถานะการส่ง"""
    conn = get_db_connection()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        if status == 'sent' or status == 'delivered':
            query = """
            UPDATE mobile_notification_sends 
            SET send_status = %s, send_result = %s, sent_at = NOW(), updated_at = NOW()
            WHERE id = %s
            """
            cursor.execute(query, (status, json.dumps(result) if result else None, send_id))
        elif status == 'failed':
            query = """
            UPDATE mobile_notification_sends 
            SET send_status = %s, error_message = %s, retry_count = %s, updated_at = NOW()
            WHERE id = %s
            """
            cursor.execute(query, (status, error_message, retry_count, send_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except mysql.connector.Error as e:
        print(f"❌ Error updating send status: {e}")
        conn.close()
        return False

def update_engine_timestamp():
    """อัปเดต timestamp ของ mobile engine"""
    conn = get_db_connection()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        # Check if record exists
        cursor.execute("SELECT COUNT(*) FROM mobile_engine_timestamp")
        count = cursor.fetchone()[0]
        
        if count == 0:
            # Insert new record
            query = "INSERT INTO mobile_engine_timestamp (last_exec) VALUES (NOW())"
        else:
            # Update existing record
            query = "UPDATE mobile_engine_timestamp SET last_exec = NOW()"
        
        cursor.execute(query)
        conn.commit()
        cursor.close()
        conn.close()
        print("✅ Mobile engine timestamp updated successfully")
        return True
    except mysql.connector.Error as e:
        print(f"❌ Error updating engine timestamp: {e}")
        conn.close()
        return False

def check_engine_timestamp():
    """เช็คว่า engine รันไปแล้วหรือยัง (ภายใน 5 นาที)"""
    conn = get_db_connection()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        query = """
        SELECT last_exec, 
               TIMESTAMPDIFF(MINUTE, last_exec, NOW()) as minutes_diff 
        FROM mobile_engine_timestamp 
        LIMIT 1
        """
        cursor.execute(query)
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result and result[0]:  # มี record และมี last_exec
            minutes_diff = result[1]
            print(f"⏰ Last execution: {result[0]} ({minutes_diff} minutes ago)")
            
            if minutes_diff <= 5:
                print(f"🚫 Engine was executed {minutes_diff} minutes ago (within 5 minutes)")
                return True  # True = ไม่ควรรัน
            else:
                print(f"✅ Engine was executed {minutes_diff} minutes ago (more than 5 minutes)")
                return False  # False = ควรรัน
        else:
            print("ℹ️ No previous execution record found")
            return False  # ไม่มี record ให้รันได้
            
    except mysql.connector.Error as e:
        print(f"❌ Error checking engine timestamp: {e}")
        conn.close()
        return False

# --- 3. Firebase Functions ---
def initialize_firebase():
    """เริ่มต้นการเชื่อมต่อกับ Firebase Admin SDK"""
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate("/usr/myPi/keyfile.json")
            firebase_admin.initialize_app(cred)
            print("✅ Firebase App initialized successfully!")
            return True
        else:
            print("ℹ️ Firebase App already initialized.")
            return True
    except FileNotFoundError:
        print("❌ Error: 'keyfile.json' not found. Please check the file path.")
        return False
    except Exception as e:
        print(f"❌ Error initializing Firebase App: {e}")
        return False

def send_fcm_message(notification_data, fcm_token):
    """ส่งข้อความผ่าน FCM"""
    try:
        # Parse data field if it's a string
        data_dict = {}
        if notification_data.get('data'):
            if isinstance(notification_data['data'], str):
                data_dict = json.loads(notification_data['data'])
            else:
                data_dict = notification_data['data']
        
        # Convert all data values to strings (FCM requirement)
        data_strings = {k: str(v) for k, v in data_dict.items()}
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=notification_data['title'],
                body=notification_data['message']
            ),
            data=data_strings,
            token=fcm_token
        )
        
        response = messaging.send(message)
        return {'success': True, 'message_id': response}
    except Exception as e:
        return {'success': False, 'error': str(e)}

# --- 4. Main Processing Function ---
def process_pending_notifications():
    """ประมวลผลการแจ้งเตือนที่รอส่ง"""
    print("🔄 Starting notification processing...")
    
    # Initialize Firebase
    if not initialize_firebase():
        return
    
    # Get pending notifications
    notifications = get_pending_notifications()
    if not notifications:
        print("ℹ️ No pending notifications found.")
        return
    
    print(f"📋 Found {len(notifications)} pending notifications")
    
    for notification in notifications:
        notification_id = notification['id']
        mobile_user_id = notification['mobile_user_id']
        
        print(f"\n📤 Processing notification ID: {notification_id}")
        print(f"   Title: {notification['title']}")
        print(f"   User ID: {mobile_user_id}")
        
        # Update status to processing
        update_notification_status(notification_id, 'processing')
        
        # Get user devices
        devices = get_user_devices(mobile_user_id)
        if not devices:
            print(f"   ⚠️ No active devices found for user {mobile_user_id}")
            update_notification_status(notification_id, 'failed')
            continue
        
        print(f"   📱 Found {len(devices)} active devices")
        
        success_count = 0
        total_devices = len(devices)
        
        # Process each device
        for device in devices:
            device_id = device['id']
            fcm_token = device['fcm_token']
            device_name = device['device_name'] or 'Unknown Device'
            
            print(f"   🔹 Sending to {device_name} (ID: {device_id})")
            
            # Create send record
            send_id = create_notification_send_record(notification_id, device_id, fcm_token)
            if not send_id:
                print(f"   ❌ Failed to create send record for device {device_id}")
                continue
            
            # Send FCM message
            result = send_fcm_message(notification, fcm_token)
            
            if result['success']:
                print(f"   ✅ Successfully sent to {device_name}")
                update_send_status(send_id, 'sent', result)
                success_count += 1
            else:
                print(f"   ❌ Failed to send to {device_name}: {result['error']}")
                update_send_status(send_id, 'failed', error_message=result['error'])
        
        # Update notification final status
        if success_count > 0:
            update_notification_status(notification_id, 'processed', datetime.now())
            print(f"   ✅ Notification processed successfully ({success_count}/{total_devices} devices)")
        else:
            update_notification_status(notification_id, 'failed')
            print(f"   ❌ Notification failed - no devices received the message")
        
        # Small delay between notifications
        time.sleep(1)
    
    print("\n🎉 Notification processing completed!")

# --- 5. Legacy Functions (for backward compatibility) ---
def send_to_multiple_devices(tokens, title, body, data=None):
    """ส่งข้อความไปยังหลายอุปกรณ์พร้อมกัน (Legacy function)"""
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        tokens=tokens
    )
    
    try:
        response = messaging.send_multicast(message)
        print(f"🚀 Successfully sent to {response.success_count} devices")
        if response.failure_count > 0:
            print(f"❌ Failed to send to {response.failure_count} devices")
        return response
    except Exception as e:
        print(f"🔥 Error sending multicast message: {e}")
        return None

# --- 6. Main Execution ---
if __name__ == "__main__":
    print("🔄 Starting notification service...")
    
    # Check if engine was executed recently (within 5 minutes)
    if check_engine_timestamp():
        print("🛑 Engine already running or executed recently. Exiting...")
        exit()
    
    print("🚀 Starting notification service in infinite loop...")
    print("Press Ctrl+C to stop the service")
    
    try:
        while True:
            # Update engine timestamp first
            update_engine_timestamp()
            
            # Process notifications
            process_pending_notifications()
            
            # Sleep for 2 seconds before next iteration
            print("💤 Sleeping for 2 seconds...")
            time.sleep(2)
            
    except KeyboardInterrupt:
        print("\n🛑 Service stopped by user")
        print("✅ Script execution completed!")