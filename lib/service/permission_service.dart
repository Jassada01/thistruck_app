import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart' as app_theme;

class PermissionService {
  
  /// Check if permissions are available (always return true since image_picker handles permissions)
  static Future<bool> checkPermissions() async {
    // With image_picker, permissions are requested automatically when needed
    print('✅ Using image_picker - permissions will be requested when needed');
    return true;
  }
  
  /// Force request permissions - simplified version
  static Future<bool> forceRequestPermissions(BuildContext context) async {
    print('✅ Using image_picker - permissions will be requested automatically');
    // image_picker will handle permission requests automatically
    return true;
  }
  
  /// Show permission dialog when trying to upload
  static Future<bool> requestPermissionForUpload(BuildContext context) async {
    final colors = app_theme.AppColorScheme.light();
    
    bool? shouldProceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'อัพโหลดรูปโปรไฟล์',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เลือกวิธีการอัพโหลดรูปโปรไฟล์:',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 16),
              
              Row(
                children: [
                  Icon(Icons.camera_alt, color: colors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ถ่ายรูปใหม่',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.photo_library, color: colors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'เลือกจากคลังรูปภาพ',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'แอปจะขอสิทธิ์การเข้าถึงกล้องและคลังรูปภาพเมื่อจำเป็น',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ดำเนินการ',
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
    
    return shouldProceed ?? false;
  }
}