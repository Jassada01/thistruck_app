import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'notification_service.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.38/thistruck/function/mobile';
  //static const String baseUrl = 'https://thistruck.app/function/mobile';
  static const String endpoint = '$baseUrl/mainFunction.php';

  // Check network connectivity
  static Future<bool> checkConnectivity() async {
    try {
      final result = await http
          .get(
            Uri.parse('https://www.google.com'),
            headers: {'Connection': 'keep-alive'},
          )
          .timeout(Duration(seconds: 5));
      return result.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get device information
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
          'product': androidInfo.product,
          'device_id': androidInfo.id,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'device_id': iosInfo.identifierForVendor ?? 'unknown_ios_device',
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
      deviceData = {
        'platform': Platform.operatingSystem,
        'error': e.toString(),
        'device_id': 'unknown_device_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    return deviceData;
  }

  // Login with passcode and send device info + FCM token
  static Future<Map<String, dynamic>> loginWithPasscode(String passcode) async {
    try {
      // Get device information
      Map<String, dynamic> deviceInfo = await _getDeviceInfo();
      String deviceId = deviceInfo['device_id'] ?? 'unknown_device';
      String deviceName =
          '${deviceInfo['brand'] ?? 'Unknown'} ${deviceInfo['model'] ?? 'Device'}';

      // Get FCM token
      NotificationService notificationService = NotificationService();
      String? fcmToken = await notificationService.getDeviceToken();

      print('📱 Device Info: $deviceInfo');
      print('🔑 FCM Token: ${fcmToken?.substring(0, 20)}...');

      // Prepare request data
      Map<String, String> requestData = {
        'f': '5', // Function number for login
        'passcode': passcode,
        'device_id': deviceId,
        'device_name': deviceName,
        'device_info': jsonEncode(deviceInfo),
      };

      // Add FCM token if available
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestData['fcm_token'] = fcmToken;
        print('✅ FCM Token added to request');
      } else {
        print('⚠️ No FCM Token available');
      }

      print('📤 Sending login request...');

      // Send POST request
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      print('📥 ===== API RESPONSE DETAILS =====');
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Full response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            print('✅ Login successful');
            return {
              'success': true,
              'message': result['message'] ?? 'เข้าสู่ระบบสำเร็จ',
              'data': result['user_data'],
              'mobile_user_id': result['user_data']?['id'],
            };
          } else {
            print('❌ Login failed: ${result['message']}');

            // แสดง debug info ถ้ามี
            if (result['debug_info'] != null) {
              print('🔍 Debug Info:');
              print('   Error Type: ${result['debug_info']['error_type']}');
              print('   Error File: ${result['debug_info']['error_file']}');
              print('   Error Line: ${result['debug_info']['error_line']}');

              if (result['debug_info']['last_sql'] != null) {
                print('   Last SQL: ${result['debug_info']['last_sql']}');
                print('   Last Params: ${result['debug_info']['last_params']}');
              }

              if (result['debug_info']['post_data'] != null) {
                print('   POST Data: ${result['debug_info']['post_data']}');
              }
            }

            return {
              'success': false,
              'message': result['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ',
              'debug_info': result['debug_info'], // ส่ง debug info ต่อไปด้วย
            };
          }
        } catch (e) {
          print('💥 JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล',
          };
        }
      } else {
        print('💥 HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'เซิร์ฟเวอร์ไม่ตอบสนอง (${response.statusCode})',
        };
      }
    } catch (e) {
      print('💥 Network Error: $e');

      if (e.toString().contains('TimeoutException')) {
        return {'success': false, 'message': 'การเชื่อมต่อใช้เวลานานเกินไป'};
      } else if (e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        };
      } else {
        return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
      }
    }
  }

  // Update device info (Function 3)
  static Future<Map<String, dynamic>> updateDeviceInfo(int mobileUserId) async {
    try {
      // Get device information
      Map<String, dynamic> deviceInfo = await _getDeviceInfo();
      String deviceId = deviceInfo['device_id'] ?? 'unknown_device';
      String deviceName =
          '${deviceInfo['brand'] ?? 'Unknown'} ${deviceInfo['model'] ?? 'Device'}';

      // Get FCM token
      NotificationService notificationService = NotificationService();
      String? fcmToken = await notificationService.getDeviceToken();

      // Prepare request data
      Map<String, String> requestData = {
        'f': '3', // Function number for createOrUpdateDevice
        'mobile_user_id': mobileUserId.toString(),
        'device_id': deviceId,
        'device_name': deviceName,
        'device_info': jsonEncode(deviceInfo),
      };

      // Add FCM token if available
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestData['fcm_token'] = fcmToken;
      }

      print('📤 Updating device info...');

      // Send POST request
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      print('📥 Update response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            return {
              'success': true,
              'message': result['message'] ?? 'อัพเดทข้อมูลอุปกรณ์สำเร็จ',
            };
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'อัพเดทข้อมูลอุปกรณ์ไม่สำเร็จ',
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล',
          };
        }
      } else {
        return {'success': false, 'message': 'เซิร์ฟเวอร์ไม่ตอบสนอง'};
      }
    } catch (e) {
      print('💥 Update Device Error: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการอัพเดทข้อมูลอุปกรณ์',
      };
    }
  }

  // Reset passcode (Function 8)
  static Future<Map<String, dynamic>> resetPasscode(int mobileUserId) async {
    try {
      Map<String, String> requestData = {
        'f': '8', // Function number for resetPasscode
        'mobile_user_id': mobileUserId.toString(),
      };

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            return {
              'success': true,
              'message': result['message'] ?? 'รีเซ็ตรหัสผ่านสำเร็จ',
              'new_passcode': result['new_passcode'],
              'expire_date': result['expire_date'],
            };
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'รีเซ็ตรหัสผ่านไม่สำเร็จ',
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล',
          };
        }
      } else {
        return {'success': false, 'message': 'เซิร์ฟเวอร์ไม่ตอบสนอง'};
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการรีเซ็ตรหัสผ่าน'};
    }
  }

  // Get user devices (Function 7)
  static Future<Map<String, dynamic>> getUserDevices(int mobileUserId) async {
    try {
      Map<String, String> requestData = {
        'f': '7', // Function number for getUserDevices
        'mobile_user_id': mobileUserId.toString(),
      };

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            return {'success': true, 'devices': result['devices'] ?? []};
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'ไม่สามารถดึงข้อมูลอุปกรณ์ได้',
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล',
          };
        }
      } else {
        return {'success': false, 'message': 'เซิร์ฟเวอร์ไม่ตอบสนอง'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการดึงข้อมูลอุปกรณ์',
      };
    }
  }

  static Future<void> updateLastActive(
    int mobileUserId,
    String deviceId,
    String fcmToken,
  ) async {
    try {
      Map<String, String> requestData = {
        'f': '11', // Function number ใหม่สำหรับ update last active
        'mobile_user_id': mobileUserId.toString(),
        'device_id': deviceId,
        'fcm_token': fcmToken,
      };

      await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: requestData,
          )
          .timeout(Duration(seconds: 10));

      print(
        '📱 Last active updated for FCM token: ${fcmToken.substring(0, 20)}...',
      );
    } catch (e) {
      print('⚠️ Failed to update last active: $e');
    }
  }

  // Get Job Order Trips by Driver ID (Function 13)
  static Future<Map<String, dynamic>> getJobOrderTripsByDriverId(
    int driverId, {
    String? statusFilter,
    String? dateFrom,
    String? dateTo,
    int? limitRecords,
    int? offsetRecords,
  }) async {
    try {
      Map<String, String> requestData = {
        'f': '13', // Function number for getJobOrderTripsByDriverId
        'driver_id': driverId.toString(),
      };

      // เพิ่ม optional parameters
      if (statusFilter != null && statusFilter.isNotEmpty) {
        requestData['status_filter'] = statusFilter;
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        requestData['date_from'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        requestData['date_to'] = dateTo;
      }
      if (limitRecords != null) {
        requestData['limit_records'] = limitRecords.toString();
      }
      if (offsetRecords != null) {
        requestData['offset_records'] = offsetRecords.toString();
      }

      print('📤 ===== API REQUEST DETAILS =====');
      print('📤 Endpoint: $endpoint');
      print('📤 Driver ID: $driverId');
      print('📤 Full request data being sent:');
      requestData.forEach((key, value) {
        print('   $key: $value');
      });

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      print('📥 ===== API RESPONSE DETAILS =====');
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Full response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            return {
              'success': true,
              'total_trips': result['total_trips'] ?? 0,
              'date_range': result['date_range'] ?? {},
              'filters': result['filters'] ?? {},
              'trips': result['trips'] ?? [],
            };
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'ไม่สามารถดึงข้อมูลรายการงานได้',
            };
          }
        } catch (e) {
          print('💥 JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'เซิร์ฟเวอร์ไม่ตอบสนอง (${response.statusCode})',
        };
      }
    } catch (e) {
      print('💥 Network Error: $e');

      if (e.toString().contains('TimeoutException')) {
        return {'success': false, 'message': 'การเชื่อมต่อใช้เวลานานเกินไป'};
      } else if (e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        };
      } else {
        return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
      }
    }
  }

  // Get Job Order Trip by Random Code (Function 12)
  static Future<Map<String, dynamic>> getJobOrderTripByRandomCode(
    String randomCode,
  ) async {
    try {
      Map<String, String> requestData = {
        'f': '12', // Function number for getJobOrderTripByRandomCode
        'random_code': randomCode,
      };

      print('📤 Getting job order trip by random code: $randomCode');

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            return {
              'success': true,
              'trip_data': result['trip_data'] ?? {},
            };
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'ไม่พบข้อมูลรายการงาน',
            };
          }
        } catch (e) {
          print('💥 JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'เซิร์ฟเวอร์ไม่ตอบสนอง (${response.statusCode})',
        };
      }
    } catch (e) {
      print('💥 Network Error: $e');

      if (e.toString().contains('TimeoutException')) {
        return {'success': false, 'message': 'การเชื่อมต่อใช้เวลานานเกินไป'};
      } else if (e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        };
      } else {
        return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
      }
    }
  }

  // Update Container ID (Function 16)
  static Future<Map<String, dynamic>> updateContainerID({
    required String tripId,
    required String containerID,
  }) async {
    try {
      // Prepare request data
      Map<String, String> requestData = {
        'f': '16', // Function number for updateContainerID
        'trip_id': tripId,
        'container_id': containerID,
      };

      print('📤 Updating container ID for trip $tripId...');
      
      // Send POST request
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      print('📥 Container update response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        print('📋 Container update result: $result');
        
        if (result['status'] == 'success') {
          return {
            'success': true,
            'message': result['message'] ?? 'อัพเดทเรียบร้อยแล้ว',
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'เกิดข้อผิดพลาดในการอัพเดท',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server responded with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error updating container ID: $e');
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection timed out')) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        };
      } else {
        return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
      }
    }
  }

  // Update Seal Number and Container Weight (Function 17)
  static Future<Map<String, dynamic>> updateSealAndWeight({
    required String tripId,
    String? sealNo,
    String? containerWeight,
  }) async {
    try {
      // Prepare request data
      Map<String, String> requestData = {
        'f': '17', // Function number for updateSealAndWeight
        'trip_id': tripId,
      };

      // เพิ่มข้อมูลที่จะอัพเดท
      if (sealNo != null) {
        requestData['seal_no'] = sealNo;
      }
      if (containerWeight != null) {
        requestData['container_weight'] = containerWeight;
      }

      print('📤 Updating seal/weight for trip $tripId...');
      
      // Send POST request
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      print('📥 Seal/Weight update response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        print('📋 Seal/Weight update result: $result');
        
        if (result['status'] == 'success') {
          return {
            'success': true,
            'message': result['message'] ?? 'อัพเดทเรียบร้อยแล้ว',
            'seal_no': result['seal_no'],
            'container_weight': result['container_weight'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'เกิดข้อผิดพลาดในการอัพเดท',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server responded with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error updating seal/weight: $e');
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection timed out')) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        };
      } else {
        return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
      }
    }
  }

  // Update Trip Cost (Function 18)
  static Future<Map<String, dynamic>> updateTripCost({
    required String tripId,
    required Map<String, String> costData,
  }) async {
    try {
      // Prepare request data
      Map<String, String> requestData = {
        'f': '18', // Function number for updateTripCost
        'trip_id': tripId,
      };

      // เพิ่มข้อมูลค่าใช้จ่ายที่จะอัพเดท
      costData.forEach((key, value) {
        requestData[key] = value;
      });

      print('📤 Updating trip cost for trip $tripId...');
      print('📤 Cost data: $costData');
      
      // Send POST request
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      print('📥 Trip cost update response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        print('📋 Trip cost update result: $result');
        
        if (result['status'] == 'success') {
          return {
            'success': true,
            'message': result['message'] ?? 'อัพเดทค่าใช้จ่ายเรียบร้อยแล้ว',
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'เกิดข้อผิดพลาดในการอัพเดทค่าใช้จ่าย',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server responded with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error updating trip cost: $e');
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection timed out')) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        };
      } else {
        return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
      }
    }
  }

  // Update Work Status (Function 15)
  static Future<Map<String, dynamic>> updateWorkStatus({
    required String tripId,
    required String jobId, // เพิ่ม jobId
    String updateUser = 'Mobile App User', // ค่าเริ่มต้นสำหรับ update_user
  }) async {
    try {
      // Prepare request data ตามที่ฟังก์ชัน PHP ต้องการ
      Map<String, String> requestData = {
        'f': '15', // Function number for updateWorkStatus
        'MAIN_JOB_ID': jobId, // Job ID
        'MAIN_trip_id': tripId, // Trip ID
        'update_user': updateUser, // ผู้อัพเดท
      };

      print('📤 Updating work status for trip $tripId (job $jobId) by $updateUser...');
      
      // Send POST request
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(Duration(seconds: 30));

      print('📥 Work status update response status: ${response.statusCode}');
      print('📥 Work status update response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        print('📋 Response body: $responseBody');
        
        // ตรวจสอบประเภทของ response
        if (responseBody == "0 results") {
          // ไม่พบ action_log ที่ต้องอัพเดท
          return {
            'success': false,
            'message': 'ไม่พบขั้นตอนที่ต้องดำเนินการ',
          };
        } else if (responseBody.isNotEmpty && responseBody.contains(RegExp(r'^\d+$'))) {
          // ถ้าเป็นตัวเลข (error code)
          return {
            'success': false,
            'message': 'เกิดข้อผิดพลาดในฐานข้อมูล (Error: $responseBody)',
          };
        } else {
          // ลองแปลงเป็น JSON
          try {
            final Map<String, dynamic> result = jsonDecode(responseBody);
            print('📋 Work status update result: $result');
            
            // ถ้ามี id และ progress แสดงว่าสำเร็จ
            if (result.containsKey('id') && result.containsKey('progress')) {
              return {
                'success': true,
                'message': 'ดำเนินการเรียบร้อยแล้ว: ${result['progress']}',
              };
            } else if (result['status'] == 'success') {
              return {
                'success': true,
                'message': result['message'] ?? 'ดำเนินการเรียบร้อยแล้ว',
              };
            } else {
              return {
                'success': false,
                'message': result['message'] ?? 'เกิดข้อผิดพลาดในการดำเนินการ',
              };
            }
          } catch (jsonError) {
            // ถ้าไม่ใช่ JSON และไม่ใช่ error code ให้ถือว่าสำเร็จ
            print('📋 Non-JSON response: $responseBody');
            return {
              'success': true,
              'message': 'ดำเนินการเรียบร้อยแล้ว',
            };
          }
        }
      } else {
        return {
          'success': false,
          'message': 'Server responded with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error updating work status: $e');
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection timed out')) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        };
      } else {
        return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
      }
    }
  }
}
