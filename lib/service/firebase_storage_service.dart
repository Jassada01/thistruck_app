import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile image to Firebase Storage
  static Future<Map<String, dynamic>> uploadProfileImage({
    required File imageFile,
    required String driverId,
  }) async {
    try {
      print('🔥 FirebaseStorageService.uploadProfileImage ENTRY');
      print('📁 ImageFile: ${imageFile.path}');
      print('👤 DriverId: $driverId');
      print('📏 File size: ${imageFile.lengthSync()} bytes');
      print('📄 File exists: ${imageFile.existsSync()}');
      
      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileExtension = path.extension(imageFile.path);
      final String fileName = 'profile_${driverId}_$timestamp$fileExtension';
      
      print('🔥 Generated filename: $fileName');
      print('🔥 File extension: $fileExtension');
      
      // Create reference to Firebase Storage
      final Reference storageRef = _storage
          .ref()
          .child('profile_images')
          .child(fileName);

      print('🔥 Firebase Storage reference created');
      print('📤 Starting profile image upload...');
      print('📁 File path: ${imageFile.path}');
      print('🏷️ Target filename: $fileName');

      // Upload file
      print('🔥 About to create UploadTask');
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: {
            'driver_id': driverId,
            'uploaded_at': DateTime.now().toIso8601String(),
            'uploaded_by': 'mobile_app',
          },
        ),
      );

      print('🔥 UploadTask created, waiting for completion...');
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      print('🔥 UploadTask completed with state: ${snapshot.state}');
      
      if (snapshot.state == TaskState.success) {
        // Get download URL
        final String downloadUrl = await storageRef.getDownloadURL();
        
        print('✅ Upload successful!');
        print('🔗 Download URL: $downloadUrl');
        
        return {
          'success': true,
          'downloadUrl': downloadUrl,
          'fileName': fileName,
          'filePath': 'profile_images/$fileName',
          'fileSize': snapshot.totalBytes,
        };
      } else {
        print('❌ Upload failed with state: ${snapshot.state}');
        return {
          'success': false,
          'message': 'การอัพโหลดไม่สำเร็จ',
        };
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      
      if (e.toString().contains('network-request-failed')) {
        return {
          'success': false,
          'message': 'ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
        };
      } else if (e.toString().contains('unauthorized')) {
        return {
          'success': false,
          'message': 'ไม่มีสิทธิ์ในการอัพโหลดไฟล์',
        };
      } else if (e.toString().contains('storage/object-not-found')) {
        return {
          'success': false,
          'message': 'ไม่พบโฟลเดอร์สำหรับจัดเก็บไฟล์',
        };
      } else {
        return {
          'success': false,
          'message': 'เกิดข้อผิดพลาดในการอัพโหลด: $e',
        };
      }
    }
  }

  /// Delete profile image from Firebase Storage
  static Future<Map<String, dynamic>> deleteProfileImage({
    required String fileName,
  }) async {
    try {
      // Create reference to the file
      final Reference storageRef = _storage
          .ref()
          .child('profile_images')
          .child(fileName);

      print('🗑️ Deleting profile image: $fileName');

      // Delete the file
      await storageRef.delete();
      
      print('✅ Profile image deleted successfully');
      
      return {
        'success': true,
        'message': 'ลบรูปโปรไฟล์เรียบร้อยแล้ว',
      };
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      
      if (e.toString().contains('storage/object-not-found')) {
        // File doesn't exist, consider it as success
        return {
          'success': true,
          'message': 'ไฟล์ไม่มีอยู่ในระบบแล้ว',
        };
      } else {
        return {
          'success': false,
          'message': 'เกิดข้อผิดพลาดในการลบไฟล์: $e',
        };
      }
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default to JPEG
    }
  }

  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Check if file is valid image format
  static bool isValidImageFile(File file) {
    final String extension = path.extension(file.path).toLowerCase();
    const List<String> validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return validExtensions.contains(extension);
  }

  /// Check if file size is within limit (default 5MB)
  static bool isFileSizeValid(File file, {int maxSizeInMB = 5}) {
    final int fileSizeInBytes = file.lengthSync();
    final int maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return fileSizeInBytes <= maxSizeInBytes;
  }
}