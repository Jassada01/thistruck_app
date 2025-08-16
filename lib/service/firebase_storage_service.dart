import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Compress image to reduce file size to under 400KB
  static Future<File?> compressImage(File imageFile) async {
    try {
      print('🔧 Starting image compression...');
      print('📏 Original file size: ${imageFile.lengthSync()} bytes (${getFileSizeString(imageFile.lengthSync())})');
      
      const int maxSizeInBytes = 400 * 1024; // 400KB
      
      // If file is already under 400KB, return original
      if (imageFile.lengthSync() <= maxSizeInBytes) {
        print('✅ File already under 400KB, no compression needed');
        return imageFile;
      }
      
      // Get file info
      final String fileExtension = path.extension(imageFile.path).toLowerCase();
      final String directory = path.dirname(imageFile.path);
      final String baseName = path.basenameWithoutExtension(imageFile.path);
      final String compressedPath = '$directory/${baseName}_compressed$fileExtension';
      
      // Start with high quality and reduce until file size is under 400KB
      int quality = 85;
      Uint8List? compressedBytes;
      
      while (quality > 10) {
        print('🔧 Trying compression with quality: $quality%');
        
        compressedBytes = await FlutterImageCompress.compressWithFile(
          imageFile.absolute.path,
          quality: quality,
          format: fileExtension == '.png' ? CompressFormat.png : CompressFormat.jpeg,
        );
        
        if (compressedBytes != null) {
          print('📏 Compressed size: ${compressedBytes.length} bytes (${getFileSizeString(compressedBytes.length)})');
          
          if (compressedBytes.length <= maxSizeInBytes) {
            // Save compressed file
            final File compressedFile = File(compressedPath);
            await compressedFile.writeAsBytes(compressedBytes);
            
            print('✅ Compression successful! Final size: ${getFileSizeString(compressedBytes.length)}');
            return compressedFile;
          }
        }
        
        // Reduce quality and try again
        quality -= 15;
      }
      
      // If still too large, try reducing dimensions
      if (compressedBytes != null && compressedBytes.length > maxSizeInBytes) {
        print('🔧 File still too large, trying dimension reduction...');
        
        // Try different widths until file size is acceptable
        final List<int> widths = [1024, 800, 600, 400, 300];
        
        for (int width in widths) {
          print('🔧 Trying compression with width: ${width}px');
          
          compressedBytes = await FlutterImageCompress.compressWithFile(
            imageFile.absolute.path,
            quality: 75,
            minWidth: width,
            minHeight: (width * 0.75).round(), // Maintain aspect ratio
            format: CompressFormat.jpeg,
          );
          
          if (compressedBytes != null) {
            print('📏 Compressed size: ${compressedBytes.length} bytes (${getFileSizeString(compressedBytes.length)})');
            
            if (compressedBytes.length <= maxSizeInBytes) {
              final File compressedFile = File(compressedPath);
              await compressedFile.writeAsBytes(compressedBytes);
              
              print('✅ Compression with dimension reduction successful! Final size: ${getFileSizeString(compressedBytes.length)}');
              return compressedFile;
            }
          }
        }
      }
      
      print('❌ Could not compress image to under 400KB');
      return null;
      
    } catch (e) {
      print('❌ Error compressing image: $e');
      return null;
    }
  }

  /// Upload fuel record image to Firebase Storage
  static Future<Map<String, dynamic>> uploadFuelImage({
    required File imageFile,
    required String driverId,
  }) async {
    File? fileToUpload;
    
    try {
      print('🔥 FirebaseStorageService.uploadFuelImage ENTRY');
      print('📁 ImageFile: ${imageFile.path}');
      print('👤 DriverId: $driverId');
      print('📏 Original file size: ${imageFile.lengthSync()} bytes (${getFileSizeString(imageFile.lengthSync())})');
      print('📄 File exists: ${imageFile.existsSync()}');
      
      // Compress image before upload
      print('🔧 Compressing image...');
      final File? compressedFile = await compressImage(imageFile);
      
      if (compressedFile == null) {
        return {
          'success': false,
          'message': 'ไม่สามารถบีบอัดรูปภาพได้ กรุณาเลือกรูปภาพที่มีขนาดเล็กกว่า',
        };
      }
      
      // Use compressed file for upload
      fileToUpload = compressedFile;
      print('📏 Final file size for upload: ${fileToUpload.lengthSync()} bytes (${getFileSizeString(fileToUpload.lengthSync())})');
      print('📄 Compressed file exists: ${fileToUpload.existsSync()}');
      
      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileExtension = path.extension(fileToUpload.path);
      final String fileName = 'fuel_${driverId}_$timestamp$fileExtension';
      
      print('🔥 Generated filename: $fileName');
      print('🔥 File extension: $fileExtension');
      
      // Create reference to Firebase Storage
      final Reference storageRef = _storage
          .ref()
          .child('fuel_images')
          .child(fileName);

      print('🔥 Firebase Storage reference created');
      print('📤 Starting fuel image upload...');
      print('📁 File path: ${fileToUpload.path}');
      print('🏷️ Target filename: $fileName');

      // Upload compressed file
      print('🔥 About to create UploadTask');
      final UploadTask uploadTask = storageRef.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: {
            'driver_id': driverId,
            'uploaded_at': DateTime.now().toIso8601String(),
            'uploaded_by': 'mobile_app',
            'type': 'fuel_record',
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
        
        // Clean up compressed file if it's different from original
        if (fileToUpload.path != imageFile.path) {
          try {
            await fileToUpload.delete();
            print('🧹 Cleaned up compressed file');
          } catch (e) {
            print('⚠️ Could not delete compressed file: $e');
          }
        }
        
        return {
          'success': true,
          'downloadUrl': downloadUrl,
          'fileName': fileName,
          'filePath': 'fuel_images/$fileName',
          'fileSize': snapshot.totalBytes,
        };
      } else {
        print('❌ Upload failed with state: ${snapshot.state}');
        
        // Clean up compressed file if upload failed
        if (fileToUpload.path != imageFile.path) {
          try {
            await fileToUpload.delete();
            print('🧹 Cleaned up compressed file after failed upload');
          } catch (e) {
            print('⚠️ Could not delete compressed file: $e');
          }
        }
        
        return {
          'success': false,
          'message': 'การอัพโหลดไม่สำเร็จ',
        };
      }
    } catch (e) {
      print('❌ Error uploading fuel image: $e');
      
      // Clean up compressed file in case of error
      try {
        if (fileToUpload != null && fileToUpload.path != imageFile.path) {
          await fileToUpload.delete();
          print('🧹 Cleaned up compressed file after error');
        }
      } catch (cleanupError) {
        print('⚠️ Could not delete compressed file: $cleanupError');
      }
      
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

  /// Upload profile image to Firebase Storage
  static Future<Map<String, dynamic>> uploadProfileImage({
    required File imageFile,
    required String driverId,
  }) async {
    File? fileToUpload;
    
    try {
      print('🔥 FirebaseStorageService.uploadProfileImage ENTRY');
      print('📁 ImageFile: ${imageFile.path}');
      print('👤 DriverId: $driverId');
      print('📏 Original file size: ${imageFile.lengthSync()} bytes (${getFileSizeString(imageFile.lengthSync())})');
      print('📄 File exists: ${imageFile.existsSync()}');
      
      // Compress image before upload
      print('🔧 Compressing image...');
      final File? compressedFile = await compressImage(imageFile);
      
      if (compressedFile == null) {
        return {
          'success': false,
          'message': 'ไม่สามารถบีบอัดรูปภาพได้ กรุณาเลือกรูปภาพที่มีขนาดเล็กกว่า',
        };
      }
      
      // Use compressed file for upload
      fileToUpload = compressedFile;
      print('📏 Final file size for upload: ${fileToUpload.lengthSync()} bytes (${getFileSizeString(fileToUpload.lengthSync())})');
      print('📄 Compressed file exists: ${fileToUpload.existsSync()}');
      
      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileExtension = path.extension(fileToUpload.path);
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
      print('📁 File path: ${fileToUpload.path}');
      print('🏷️ Target filename: $fileName');

      // Upload compressed file
      print('🔥 About to create UploadTask');
      final UploadTask uploadTask = storageRef.putFile(
        fileToUpload,
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
        
        // Clean up compressed file if it's different from original
        if (fileToUpload.path != imageFile.path) {
          try {
            await fileToUpload.delete();
            print('🧹 Cleaned up compressed file');
          } catch (e) {
            print('⚠️ Could not delete compressed file: $e');
          }
        }
        
        return {
          'success': true,
          'downloadUrl': downloadUrl,
          'fileName': fileName,
          'filePath': 'profile_images/$fileName',
          'fileSize': snapshot.totalBytes,
        };
      } else {
        print('❌ Upload failed with state: ${snapshot.state}');
        
        // Clean up compressed file if upload failed
        if (fileToUpload.path != imageFile.path) {
          try {
            await fileToUpload.delete();
            print('🧹 Cleaned up compressed file after failed upload');
          } catch (e) {
            print('⚠️ Could not delete compressed file: $e');
          }
        }
        
        return {
          'success': false,
          'message': 'การอัพโหลดไม่สำเร็จ',
        };
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      
      // Clean up compressed file in case of error
      try {
        if (fileToUpload != null && fileToUpload.path != imageFile.path) {
          await fileToUpload.delete();
          print('🧹 Cleaned up compressed file after error');
        }
      } catch (cleanupError) {
        print('⚠️ Could not delete compressed file: $cleanupError');
      }
      
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

  /// Upload trip image to Firebase Storage
  static Future<Map<String, dynamic>> uploadTripImage({
    required File imageFile,
    required String tripId,
    required String planOrder,
    required String driverId,
  }) async {
    File? fileToUpload;
    
    try {
      print('🔥 FirebaseStorageService.uploadTripImage ENTRY');
      print('📁 ImageFile: ${imageFile.path}');
      print('🚛 TripId: $tripId');
      print('📋 PlanOrder: $planOrder');
      print('👤 DriverId: $driverId');
      print('📏 Original file size: ${imageFile.lengthSync()} bytes (${getFileSizeString(imageFile.lengthSync())})');
      print('📄 File exists: ${imageFile.existsSync()}');
      
      // Compress image before upload
      print('🔧 Compressing image...');
      final File? compressedFile = await compressImage(imageFile);
      
      if (compressedFile == null) {
        return {
          'success': false,
          'message': 'ไม่สามารถบีบอัดรูปภาพได้ กรุณาเลือกรูปภาพที่มีขนาดเล็กกว่า',
        };
      }
      
      // Use compressed file for upload
      fileToUpload = compressedFile;
      print('📏 Final file size for upload: ${fileToUpload.lengthSync()} bytes (${getFileSizeString(fileToUpload.lengthSync())})');
      print('📄 Compressed file exists: ${fileToUpload.existsSync()}');
      
      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileExtension = path.extension(fileToUpload.path);
      final String fileName = 'trip_${tripId}_step_${planOrder}_$timestamp$fileExtension';
      
      print('🔥 Generated filename: $fileName');
      print('🔥 File extension: $fileExtension');
      
      // Create folder path with date for organization
      final String dateFolder = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final String folderPath = 'trip_images/$dateFolder/trip_$tripId/step_$planOrder';
      
      // Create reference to Firebase Storage
      final Reference storageRef = _storage
          .ref()
          .child(folderPath)
          .child(fileName);

      print('🔥 Firebase Storage reference created');
      print('📤 Starting trip image upload...');
      print('📁 File path: ${fileToUpload.path}');
      print('📂 Storage folder: $folderPath');
      print('🏷️ Target filename: $fileName');

      // Upload compressed file
      print('🔥 About to create UploadTask');
      final UploadTask uploadTask = storageRef.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: {
            'trip_id': tripId,
            'plan_order': planOrder,
            'driver_id': driverId,
            'uploaded_at': DateTime.now().toIso8601String(),
            'uploaded_by': 'mobile_app',
            'type': 'trip_step_image',
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
        
        // Clean up compressed file if it's different from original
        if (fileToUpload.path != imageFile.path) {
          try {
            await fileToUpload.delete();
            print('🧹 Cleaned up compressed file');
          } catch (e) {
            print('⚠️ Could not delete compressed file: $e');
          }
        }
        
        return {
          'success': true,
          'downloadUrl': downloadUrl,
          'fileName': fileName,
          'filePath': '$folderPath/$fileName',
          'fullStoragePath': '$folderPath/$fileName',
          'fileSize': snapshot.totalBytes,
        };
      } else {
        print('❌ Upload failed with state: ${snapshot.state}');
        
        // Clean up compressed file if upload failed
        if (fileToUpload.path != imageFile.path) {
          try {
            await fileToUpload.delete();
            print('🧹 Cleaned up compressed file after failed upload');
          } catch (e) {
            print('⚠️ Could not delete compressed file: $e');
          }
        }
        
        return {
          'success': false,
          'message': 'การอัพโหลดไม่สำเร็จ',
        };
      }
    } catch (e) {
      print('❌ Error uploading trip image: $e');
      
      // Clean up compressed file in case of error
      try {
        if (fileToUpload != null && fileToUpload.path != imageFile.path) {
          await fileToUpload.delete();
          print('🧹 Cleaned up compressed file after error');
        }
      } catch (cleanupError) {
        print('⚠️ Could not delete compressed file: $cleanupError');
      }
      
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

  /// Upload multiple trip images
  static Future<Map<String, dynamic>> uploadMultipleTripImages({
    required List<File> imageFiles,
    required String tripId,
    required String planOrder,
    required String driverId,
  }) async {
    List<Map<String, dynamic>> uploadResults = [];
    List<String> successfulUrls = [];
    List<String> failedFiles = [];

    for (int i = 0; i < imageFiles.length; i++) {
      File imageFile = imageFiles[i];
      
      Map<String, dynamic> result = await uploadTripImage(
        imageFile: imageFile,
        tripId: tripId,
        planOrder: planOrder,
        driverId: driverId,
      );

      uploadResults.add(result);

      if (result['success'] == true) {
        successfulUrls.add(result['downloadUrl']);
      } else {
        failedFiles.add(path.basename(imageFile.path));
      }
    }

    return {
      'success': failedFiles.isEmpty,
      'uploadResults': uploadResults,
      'successfulUrls': successfulUrls,
      'failedFiles': failedFiles,
      'totalFiles': imageFiles.length,
      'successCount': successfulUrls.length,
      'failCount': failedFiles.length,
      'message': failedFiles.isEmpty 
          ? 'อัพโหลดทุกไฟล์สำเร็จ (${successfulUrls.length} ไฟล์)'
          : 'อัพโหลดสำเร็จ ${successfulUrls.length} ไฟล์ จาก ${imageFiles.length} ไฟล์',
    };
  }

  /// Delete trip image from Firebase Storage
  static Future<Map<String, dynamic>> deleteTripImage({
    required String filePath,
  }) async {
    try {
      // Create reference to the file
      final Reference storageRef = _storage.ref().child(filePath);

      print('🗑️ Deleting trip image: $filePath');

      // Delete the file
      await storageRef.delete();
      
      print('✅ Trip image deleted successfully');
      
      return {
        'success': true,
        'message': 'ลบรูปภาพเรียบร้อยแล้ว',
      };
    } catch (e) {
      print('❌ Error deleting trip image: $e');
      
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
}