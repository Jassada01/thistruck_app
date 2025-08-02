import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/image_picker_service.dart';
import '../service/firebase_storage_service.dart';
import '../service/api_service.dart';
import '../service/local_storage.dart';
import '../theme/app_theme.dart' as AppThemeConfig;

class ProfileImageUpload extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onImageUpdated;

  const ProfileImageUpload({
    super.key,
    required this.userProfile,
    this.onImageUpdated,
  });

  @override
  State<ProfileImageUpload> createState() => _ProfileImageUploadState();
}

class _ProfileImageUploadState extends State<ProfileImageUpload> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return GestureDetector(
      onTap: _isUploading ? null : _showImageUploadOptions,
      child: Stack(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 50,
            backgroundColor: colors.primary,
            backgroundImage: widget.userProfile?['profile_image'] != null && 
                            widget.userProfile!['profile_image'].toString().isNotEmpty
              ? NetworkImage(widget.userProfile!['profile_image'])
              : null,
            child: widget.userProfile?['profile_image'] == null || 
                   widget.userProfile!['profile_image'].toString().isEmpty
              ? Icon(Icons.person, size: 50, color: colors.onPrimary)
              : null,
            onBackgroundImageError: (exception, stackTrace) {
              // ถ้าโหลดรูปไม่สำเร็จ จะแสดง icon แทน
              print('Error loading profile image: $exception');
            },
          ),
          
          // Upload indicator or edit button
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'กำลังอัพโหลด...',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showImageUploadOptions() async {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    print('✅ Showing upload options - image_picker will handle permissions automatically');
    
    if (!mounted) return;
    
    showModalBottomSheet(
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
                    'รูปโปรไฟล์',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Options
                  Column(
                    children: [
                      // Upload new image
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.upload,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'อัพโหลดรูปใหม่',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'เลือกรูปจากกล้องหรือคลัง',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _handleImageUpload();
                        },
                      ),
                      
                      // View current image (if exists)
                      if (widget.userProfile?['profile_image'] != null && 
                          widget.userProfile!['profile_image'].toString().isNotEmpty)
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.visibility,
                              color: colors.success,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'ดูรูปปัจจุบัน',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'แสดงรูปโปรไฟล์ในขนาดเต็ม',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showFullImage();
                          },
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
  }

  Future<void> _handleImageUpload() async {
    try {
      print('🔄 Starting image upload process...');
      print('🔄 Step 1: About to call ImagePickerService.pickProfileImage');
      
      // Pick image
      final File? imageFile = await ImagePickerService.pickProfileImage(context);
      
      print('🔄 Step 2: ImagePickerService.pickProfileImage returned: $imageFile');
      
      if (imageFile == null) {
        print('❌ No image selected - stopping upload process');
        return;
      }
      
      print('✅ Image selected successfully');
      print('📁 Image file path: ${imageFile.path}');
      print('📏 Image file size: ${imageFile.lengthSync()} bytes');

      print('🔄 Step 3: Setting upload state to true');
      setState(() {
        _isUploading = true;
      });

      // Get driver ID
      final String? driverId = widget.userProfile?['driver_id']?.toString();
      
      print('🔄 Step 4: Getting driver ID from userProfile');
      print('👤 Driver ID from profile: $driverId');
      print('📋 Full userProfile: ${widget.userProfile}');
      
      if (driverId == null) {
        print('❌ Driver ID is null - cannot proceed with upload');
        _showErrorDialog('ไม่พบข้อมูลคนขับ', 'ไม่สามารถระบุคนขับได้');
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload to Firebase Storage
      print('🔄 Step 5: About to call FirebaseStorageService.uploadProfileImage');
      print('📤 Starting Firebase upload with params:');
      print('   - imageFile: ${imageFile.path}');
      print('   - driverId: $driverId');
      
      final uploadResult = await FirebaseStorageService.uploadProfileImage(
        imageFile: imageFile,
        driverId: driverId,
      );

      print('🔄 Step 6: FirebaseStorageService.uploadProfileImage completed');
      print('📤 Firebase upload result: $uploadResult');

      if (!uploadResult['success']) {
        print('❌ Firebase upload failed: ${uploadResult['message']}');
        _showErrorDialog('การอัพโหลดล้มเหลว', uploadResult['message']);
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Update database with new image URL
      final String imageUrl = uploadResult['downloadUrl'];
      print('🔗 Image URL from Firebase: $imageUrl');
      print('🌐 Calling API to update database...');
      
      final apiResult = await ApiService.updateProfileImage(
        driverId: driverId,
        imageUrl: imageUrl,
      );

      print('🌐 API result: $apiResult');

      if (apiResult['success']) {
        // Update local storage with new profile data
        if (apiResult['profile_data'] != null) {
          await LocalStorage.saveProfile(apiResult['profile_data']);
        }

        // Show success message
        _showSuccessDialog('สำเร็จ', apiResult['message']);
        
        // Notify parent widget
        if (widget.onImageUpdated != null) {
          widget.onImageUpdated!();
        }
      } else {
        _showErrorDialog('อัพเดทฐานข้อมูลล้มเหลว', apiResult['message']);
      }

    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาด', 'ไม่สามารถอัพโหลดรูปได้: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showFullImage() {
    final String? imageUrl = widget.userProfile?['profile_image'];
    
    if (imageUrl == null || imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                
                // Image
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 48, color: Colors.red),
                              SizedBox(height: 8),
                              Text(
                                'ไม่สามารถโหลดรูปได้',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
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
                  color: colors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.notoSansThai(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
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
                backgroundColor: colors.success,
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

  void _showErrorDialog(String title, String message) {
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