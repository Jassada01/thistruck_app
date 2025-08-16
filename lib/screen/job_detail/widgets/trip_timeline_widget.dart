import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../provider/font_size_provider.dart';
import '../../../widgets/map_modal.dart';
import '../../../service/firebase_storage_service.dart';
import '../../../service/api_service.dart';
import '../../../service/local_storage.dart';

class TripTimelineWidget extends StatefulWidget {
  final List<dynamic> tripLocations;
  final String tripId;

  const TripTimelineWidget({
    super.key,
    required this.tripLocations,
    required this.tripId,
  });

  @override
  State<TripTimelineWidget> createState() => _TripTimelineWidgetState();
}

class _TripTimelineWidgetState extends State<TripTimelineWidget> {
  final ImagePicker _picker = ImagePicker();
  Map<String, List<Map<String, dynamic>>> _attachedFiles = {};
  Map<String, bool> _isLoadingImages = {};
  Map<String, bool> _isUploadingImages = {};

  @override
  void initState() {
    super.initState();
    _loadAllAttachedFiles();
  }

  Future<void> _loadAllAttachedFiles() async {
    for (var location in widget.tripLocations) {
      String planOrder = location['plan_order']?.toString() ?? '';
      if (planOrder.isNotEmpty) {
        await _loadAttachedFiles(planOrder);
      }
    }
  }

  Future<void> _loadAttachedFiles(String planOrder) async {
    setState(() {
      _isLoadingImages[planOrder] = true;
    });

    try {
      final result = await ApiService.getAttachedFiles(
        documentGroup: 'TRIP',
        documentGroupCode: widget.tripId,
        subDocId: planOrder,
      );

      if (result['success'] == true) {
        setState(() {
          _attachedFiles[planOrder] = List<Map<String, dynamic>>.from(result['files'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading attached files: $e');
    } finally {
      setState(() {
        _isLoadingImages[planOrder] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tripLocations.isEmpty) {
      return const Center(
        child: Text('ไม่พบข้อมูลแผนการเดินทาง'),
      );
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'แผนการเดินทาง',
                      style: TextStyle(
                        fontSize: fontSizeProvider.getScaledFontSize(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildTimelineItems(context, fontSizeProvider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTimelineItems(BuildContext context, FontSizeProvider fontSizeProvider) {
    return widget.tripLocations.map<Widget>((location) {
      return Flexible(
        flex: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildTimelineItem(context, location, fontSizeProvider),
        ),
      );
    }).toList();
  }

  Widget _buildTimelineItem(BuildContext context, dynamic location, FontSizeProvider fontSizeProvider) {
    final locationName = location['location_name'] ?? '';
    final locationCode = location['location_code'] ?? '';
    final jobCharacteristic = location['job_characteristic'] ?? '';
    final planOrder = location['plan_order']?.toString() ?? '';
    
    // Get color based on job characteristic
    Color iconColor = _getJobCharacteristicColor(jobCharacteristic);
    Color backgroundColor = iconColor.withValues(alpha: 0.1);
    
    // Get attached files for this step
    List<Map<String, dynamic>> stepFiles = _attachedFiles[planOrder] ?? [];
    bool isLoading = _isLoadingImages[planOrder] == true;
    bool isUploading = _isUploadingImages[planOrder] == true;
    
    return GestureDetector(
      onTap: () => _openLocationMap(context, location),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Job characteristic badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _getJobCharacteristicShort(jobCharacteristic),
              style: TextStyle(
                fontSize: fontSizeProvider.getScaledFontSize(11),
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          // Timeline dot with truck icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.local_shipping,
                  color: iconColor,
                  size: 14,
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: iconColor, width: 1),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: iconColor,
                      size: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Location info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Location code
              Text(
                locationCode,
                style: TextStyle(
                  fontSize: fontSizeProvider.getScaledFontSize(12),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Location name
              Text(
                locationName,
                style: TextStyle(
                  fontSize: fontSizeProvider.getScaledFontSize(10),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Upload button and images
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Upload button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isUploading ? null : () => _showImageUploadOptions(context, planOrder),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUploading ? Colors.grey[300] : iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUploading ? Colors.grey : iconColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUploading)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                            ),
                          )
                        else
                          Icon(
                            Icons.camera_alt,
                            size: 12,
                            color: iconColor,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          isUploading ? 'กำลังอัพโหลด...' : 'เพิ่มรูป',
                          style: TextStyle(
                            fontSize: fontSizeProvider.getScaledFontSize(9),
                            color: isUploading ? Colors.grey : iconColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Images display
              if (isLoading)
                Container(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  ),
                )
              else if (stepFiles.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: stepFiles.take(3).map((file) {
                          return GestureDetector(
                            onTap: () => _showImageDialog(context, file['file_path'] ?? ''),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.network(
                                  file['file_path'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 10,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // Show count if there are images
                      if (stepFiles.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          child: Text(
                            stepFiles.length > 3 ? '+${stepFiles.length - 3} รูป' : '${stepFiles.length} รูป',
                            style: TextStyle(
                              fontSize: fontSizeProvider.getScaledFontSize(7),
                              color: iconColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }


  Color _getJobCharacteristicColor(String jobCharacteristic) {
    final characteristic = jobCharacteristic.toLowerCase();
    
    if (characteristic.contains('pick up') || characteristic.contains('รับตู้')) {
      return Colors.blue;
    } else if (characteristic.contains('delivery') || characteristic.contains('ส่งสินค้า')) {
      return Colors.green;
    } else if (characteristic.contains('return') || characteristic.contains('คืนตู้')) {
      return Colors.orange;
    } else if (characteristic.contains('drop') || characteristic.contains('วางตู้')) {
      return Colors.purple;
    } else if (characteristic.contains('loading') || characteristic.contains('รับสินค้า')) {
      return Colors.teal;
    } else if (characteristic.contains('other') || characteristic.contains('อื่น')) {
      return Colors.brown;
    }
    
    return Colors.grey;
  }

  String _getJobCharacteristicShort(String jobCharacteristic) {
    final characteristic = jobCharacteristic.toLowerCase();
    
    if (characteristic.contains('pick up') || characteristic.contains('รับตู้')) {
      // แยกประเภทตู้
      if (characteristic.contains('ตู้หนัก')) {
        return 'รับตู้หนัก';
      } else if (characteristic.contains('ตู้เปล่า')) {
        return 'รับตู้เปล่า';
      }
      return 'รับตู้';
    } else if (characteristic.contains('delivery') || characteristic.contains('ส่งสินค้า')) {
      return 'ส่งสินค้า';
    } else if (characteristic.contains('return') || characteristic.contains('คืนตู้')) {
      // แยกประเภทตู้
      if (characteristic.contains('ตู้หนัก')) {
        return 'คืนตู้หนัก';
      } else if (characteristic.contains('ตู้เปล่า')) {
        return 'คืนตู้เปล่า';
      }
      return 'คืนตู้';
    } else if (characteristic.contains('drop') || characteristic.contains('วางตู้')) {
      return 'วางตู้';
    } else if (characteristic.contains('loading') || characteristic.contains('รับสินค้า')) {
      return 'รับสินค้า';
    } else if (characteristic.contains('other') || characteristic.contains('อื่น')) {
      return 'อื่นๆ';
    }
    
    return 'อื่นๆ';
  }

  void _showImageUploadOptions(BuildContext context, String planOrder) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เลือกแหล่งที่มาของรูปภาพ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'สามารถเลือกได้สูงสุด 3 รูปต่อครั้ง',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera option
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickSingleImage(ImageSource.camera, planOrder);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt, size: 32, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text('ถ่ายรูป', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('(1 รูป)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                  // Gallery multiple option
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickMultipleImages(planOrder);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.photo_library, size: 32, color: Colors.green),
                          const SizedBox(height: 8),
                          Text('คลังรูปภาพ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('(สูงสุด 3 รูป)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickSingleImage(ImageSource source, String planOrder) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadImages([File(pickedFile.path)], planOrder);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleImages(String planOrder) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        // Limit to maximum 3 images
        final List<XFile> limitedFiles = pickedFiles.take(3).toList();
        
        if (pickedFiles.length > 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เลือกได้สูงสุด 3 รูป จะอัพโหลด ${limitedFiles.length} รูปแรก'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // Convert XFile to File
        final List<File> imageFiles = limitedFiles.map((xFile) => File(xFile.path)).toList();
        await _uploadImages(imageFiles, planOrder);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImages(List<File> imageFiles, String planOrder) async {
    setState(() {
      _isUploadingImages[planOrder] = true;
    });

    try {
      // Get driver ID from local storage
      final profileData = await LocalStorage.getProfile();
      final driverId = profileData?['id']?.toString() ?? '';

      if (driverId.isEmpty) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      int successCount = 0;
      int failCount = 0;
      List<String> errorMessages = [];

      // Upload images one by one
      for (int i = 0; i < imageFiles.length; i++) {
        File imageFile = imageFiles[i];
        
        try {
          // Upload to Firebase Storage
          final uploadResult = await FirebaseStorageService.uploadTripImage(
            imageFile: imageFile,
            tripId: widget.tripId,
            planOrder: planOrder,
            driverId: driverId,
          );

          if (uploadResult['success'] == true) {
            // Save file info to database
            final saveResult = await ApiService.saveAttachedFile(
              documentGroup: 'TRIP',
              documentGroupCode: widget.tripId,
              originalFileName: uploadResult['fileName'],
              filePath: uploadResult['downloadUrl'],
              documentType: 'รูปภาพขั้นตอนการเดินทาง',
              fileType: 'image/jpeg',
              isImage: true,
              subDocId: planOrder,
              description: 'รูปภาพขั้นตอนการเดินทาง Step $planOrder (${i + 1}/${imageFiles.length})',
            );

            if (saveResult['success'] == true) {
              successCount++;
            } else {
              failCount++;
              errorMessages.add('รูปที่ ${i + 1}: บันทึกข้อมูลไฟล์ไม่สำเร็จ');
            }
          } else {
            failCount++;
            errorMessages.add('รูปที่ ${i + 1}: อัพโหลดไฟล์ไม่สำเร็จ');
          }
        } catch (e) {
          failCount++;
          errorMessages.add('รูปที่ ${i + 1}: $e');
        }
      }

      // Reload attached files for this step
      await _loadAttachedFiles(planOrder);
      
      // Show result message
      if (mounted) {
        if (successCount == imageFiles.length) {
          // All successful
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('อัพโหลดรูปภาพสำเร็จทั้งหมด ($successCount รูป)'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (successCount > 0) {
          // Partial success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('อัพโหลดสำเร็จ $successCount รูป ล้มเหลว $failCount รูป'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          // All failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('อัพโหลดล้มเหลวทั้งหมด'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingImages[planOrder] = false;
      });
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Image
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ไม่สามารถโหลดรูปภาพได้',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

  void _openLocationMap(BuildContext context, dynamic location) async {
    // Show modal with map information
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: false,
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            child: SingleChildScrollView(
              child: MapModalWidget(location: location),
            ),
          ),
        );
      },
    );
  }

}