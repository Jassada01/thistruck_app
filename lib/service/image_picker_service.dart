import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart' as AppThemeConfig;

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();


  /// Show image source selection dialog (permissions should be checked before calling this)
  static Future<File?> pickProfileImage(BuildContext context) async {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    // Skip permission check since it's handled by the caller
    print('📷 Starting image picker...');
    print('📷 About to show modal bottom sheet');
    
    File? selectedImage;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'เลือกรูปโปรไฟล์',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    'เลือกแหล่งที่มาของรูปภาพ',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Options
                  Row(
                    children: [
                      // Camera option
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            print('📷 User tapped camera option');
                            print('📷 About to call _pickImageFromCamera');
                            final File? cameraImage = await _pickImageFromCamera(context);
                            print('📷 _pickImageFromCamera returned: $cameraImage');
                            selectedImage = cameraImage;
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'ถ่ายรูป',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ใช้กล้อง',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 16),
                      
                      // Gallery option
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            print('📷 User tapped gallery option');
                            print('📷 About to call _pickImageFromGallery');
                            final File? galleryImage = await _pickImageFromGallery(context);
                            print('📷 _pickImageFromGallery returned: $galleryImage');
                            selectedImage = galleryImage;
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.success.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'เลือกรูป',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.success,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'จากคลัง',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Cancel button
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    print('📷 Modal bottom sheet closed');
    print('📷 selectedImage final result: $selectedImage');
    return selectedImage;
  }

  /// Pick image from camera
  static Future<File?> _pickImageFromCamera(BuildContext context) async {
    try {
      print('📷 _pickImageFromCamera: Starting camera picker');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress to reduce file size
        maxWidth: 800,    // Limit max width
        maxHeight: 800,   // Limit max height
      );

      print('📷 _pickImageFromCamera: Camera picker returned: $image');

      if (image != null) {
        print('📷 _pickImageFromCamera: Image path: ${image.path}');
        final File imageFile = File(image.path);
        
        print('📷 _pickImageFromCamera: About to validate image');
        
        // Validate image file
        if (!_isValidImageFile(imageFile)) {
          print('📷 _pickImageFromCamera: Invalid image file format');
          _showErrorDialog(context, 'รูปแบบไฟล์ไม่ถูกต้อง', 'กรุณาเลือกไฟล์ภาพที่ถูกต้อง (JPG, PNG, GIF, WebP)');
          return null;
        }

        // Check file size (max 5MB)
        if (!_isFileSizeValid(imageFile)) {
          print('📷 _pickImageFromCamera: File too large');
          _showErrorDialog(context, 'ไฟล์ใหญ่เกินไป', 'ขนาดไฟล์ไม่ควรเกิน 5 MB');
          return null;
        }

        print('📷 _pickImageFromCamera: Image validation passed, returning file');
        return imageFile;
      } else {
        print('📷 _pickImageFromCamera: No image selected (cancelled)');
      }
    } catch (e) {
      print('📷 _pickImageFromCamera: Exception occurred: $e');
      _showErrorDialog(context, 'เกิดข้อผิดพลาด', 'ไม่สามารถเข้าถึงกล้องได้: $e');
    }
    
    return null;
  }

  /// Pick image from gallery
  static Future<File?> _pickImageFromGallery(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to reduce file size
        maxWidth: 800,    // Limit max width
        maxHeight: 800,   // Limit max height
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        // Validate image file
        if (!_isValidImageFile(imageFile)) {
          _showErrorDialog(context, 'รูปแบบไฟล์ไม่ถูกต้อง', 'กรุณาเลือกไฟล์ภาพที่ถูกต้อง (JPG, PNG, GIF, WebP)');
          return null;
        }

        // Check file size (max 5MB)
        if (!_isFileSizeValid(imageFile)) {
          _showErrorDialog(context, 'ไฟล์ใหญ่เกินไป', 'ขนาดไฟล์ไม่ควรเกิน 5 MB');
          return null;
        }

        return imageFile;
      }
    } catch (e) {
      _showErrorDialog(context, 'เกิดข้อผิดพลาด', 'ไม่สามารถเข้าถึงคลังรูปภาพได้: $e');
    }
    
    return null;
  }

  /// Validate image file format
  static bool _isValidImageFile(File file) {
    final String extension = file.path.toLowerCase();
    return extension.endsWith('.jpg') ||
           extension.endsWith('.jpeg') ||
           extension.endsWith('.png') ||
           extension.endsWith('.gif') ||
           extension.endsWith('.webp');
  }

  /// Check if file size is within limit (5MB)
  static bool _isFileSizeValid(File file) {
    final int fileSizeInBytes = file.lengthSync();
    final int maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    return fileSizeInBytes <= maxSizeInBytes;
  }

  /// Show error dialog
  static void _showErrorDialog(BuildContext context, String title, String message) {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ตกลง',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}