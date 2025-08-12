import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../service/api_service.dart';
import '../../service/local_storage.dart';
import '../../service/firebase_storage_service.dart';
import '../../provider/font_size_provider.dart';

class FuelRecordScreen extends StatefulWidget {
  @override
  _FuelRecordScreenState createState() => _FuelRecordScreenState();
}

class _FuelRecordScreenState extends State<FuelRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _amountFilledController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _odometerController = TextEditingController();
  
  String? _selectedFuelType = 'ดีเซล(B7)';
  DateTime _selectedDate = DateTime.now();
  List<XFile> _selectedImages = [];
  List<String> _uploadedImageUrls = []; // Store uploaded URLs
  List<bool> _imageUploadingStatus = []; // Track upload status for each image
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _trucks = [];
  int? _selectedTruckId;
  bool _isLoadingTrucks = false;
  
  List<String> _fuelTypes = [
    'ดีเซล(B7)',
    'ดีเซล(B10)', 
    'ดีเซล(B20)',
    'เบนซิน 91',
    'เบนซิน 95',
    'เบนซิน E20',
    'เบนซิน E85'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _dateController.text = _formatDateThai(_selectedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountFilledController.dispose();
    _totalCostController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profile = await LocalStorage.getProfile();
    setState(() {
      _userProfile = profile;
    });
    
    // Load trucks after profile is loaded
    if (profile != null && profile['driver_id'] != null) {
      await _loadTrucks(int.parse(profile['driver_id'].toString()));
    }
  }

  Future<void> _loadTrucks(int driverId) async {
    setState(() {
      _isLoadingTrucks = true;
    });

    try {
      final result = await ApiService.getTrucksByDriverId(driverId);
      
      if (result['success'] && result['trucks'] != null) {
        setState(() {
          _trucks = List<Map<String, dynamic>>.from(result['trucks']);
          // เลือกรถคันแรกเป็น default
          if (_trucks.isNotEmpty) {
            _selectedTruckId = _trucks.first['truck_id'];
          }
        });
      }
    } catch (e) {
      print('Error loading trucks: $e');
    } finally {
      setState(() {
        _isLoadingTrucks = false;
      });
    }
  }

  String _formatDateThai(DateTime date) {
    final monthNames = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year + 543}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDateThai(picked);
      });
    }
  }

  Future<void> _pickImages() async {
    if (_userProfile == null) {
      _showErrorDialog('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    
    if (images != null && images.isNotEmpty) {
      // Limit to 10 images maximum and check current count
      final currentImageCount = _selectedImages.length;
      final availableSlots = 10 - currentImageCount;
      final imagesToAdd = images.take(availableSlots).toList();
      
      if (imagesToAdd.isEmpty) {
        _showErrorDialog('สามารถเลือกรูปภาพได้สูงสุด 10 รูป');
        return;
      }
      
      // Add selected images and initialize upload status
      setState(() {
        _selectedImages.addAll(imagesToAdd);
        // Initialize upload status for new images (false = uploading, true = completed)
        for (int i = 0; i < imagesToAdd.length; i++) {
          _imageUploadingStatus.add(false);
          _uploadedImageUrls.add(''); // Placeholder for URL
        }
      });
      
      // Upload each image immediately
      for (int i = currentImageCount; i < _selectedImages.length; i++) {
        await _uploadImageImmediately(i);
      }
    }
  }

  Future<void> _uploadImageImmediately(int index) async {
    final image = _selectedImages[index];
    final File imageFile = File(image.path);
    
    try {
      // Upload to fuel_images folder
      final result = await FirebaseStorageService.uploadFuelImage(
        imageFile: imageFile,
        driverId: _userProfile!['driver_id'].toString(),
      );
      
      setState(() {
        if (result['success'] && result['downloadUrl'] != null) {
          _uploadedImageUrls[index] = result['downloadUrl'];
          _imageUploadingStatus[index] = true; // Upload completed
        } else {
          _imageUploadingStatus[index] = false; // Upload failed
        }
      });
      
    } catch (e) {
      print('Error uploading image $index: $e');
      setState(() {
        _imageUploadingStatus[index] = false; // Upload failed
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
      _uploadedImageUrls.removeAt(index);
      _imageUploadingStatus.removeAt(index);
    });
  }

  List<String> _getUploadedImageUrls() {
    // Return only successfully uploaded image URLs
    List<String> validUrls = [];
    for (int i = 0; i < _uploadedImageUrls.length; i++) {
      if (_imageUploadingStatus[i] && _uploadedImageUrls[i].isNotEmpty) {
        validUrls.add(_uploadedImageUrls[i]);
      }
    }
    return validUrls;
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userProfile == null) {
      _showErrorDialog('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get already uploaded image URLs
      List<String> imageUrls = _getUploadedImageUrls();
      
      // Check if any images are still uploading
      bool hasUploadingImages = false;
      for (int i = 0; i < _imageUploadingStatus.length; i++) {
        if (!_imageUploadingStatus[i] && _uploadedImageUrls[i].isEmpty) {
          hasUploadingImages = true;
          break;
        }
      }
      
      if (hasUploadingImages) {
        _showErrorDialog('กรุณารอให้การอัพโหลดรูปภาพเสร็จสิ้น');
        return;
      }

      // ตรวจสอบว่าเลือกรถแล้วหรือยัง
      if (_selectedTruckId == null) {
        _showErrorDialog('กรุณาเลือกรถที่ใช้เติมน้ำมัน');
        return;
      }

      // Prepare fuel record data
      final fuelRecordData = {
        'inputDate': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'fuelType': _selectedFuelType,
        'amountFilled': double.tryParse(_amountFilledController.text) ?? 0.0,
        'totalCost': double.tryParse(_totalCostController.text) ?? 0.0,
        'odometer': int.tryParse(_odometerController.text) ?? 0,
        'driver_id': _userProfile!['driver_id'],
        'truck_id': _selectedTruckId!,
        'driverName': _userProfile!['user_name'] ?? '',
      };

      // Save fuel record with images to database (all in one function)
      final result = await ApiService.saveFuelRecord(fuelRecordData, imageUrls);
      
      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(result['message'] ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล');
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text(
          'บันทึกสำเร็จ',
          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'ข้อมูลการเติมน้ำมันถูกบันทึกเรียบร้อยแล้ว',
          style: GoogleFonts.notoSansThai(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to dashboard
            },
            child: Text('ตกลง', style: GoogleFonts.notoSansThai()),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error, color: Colors.red, size: 48),
        title: Text(
          'เกิดข้อผิดพลาด',
          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.notoSansThai(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ตกลง', style: GoogleFonts.notoSansThai()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors;
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(
              'บันทึกค่าน้ำมัน',
              style: GoogleFonts.notoSansThai(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: fontProvider.getScaledFontSize(18.0),
              ),
            ),
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _isLoading 
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Section
                      if (_userProfile != null) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: _userProfile!['profile_image'] != null 
                                  ? NetworkImage(_userProfile!['profile_image'])
                                  : null,
                                child: _userProfile!['profile_image'] == null 
                                  ? Icon(Icons.person, color: Colors.white)
                                  : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userProfile!['user_name'] ?? 'ไม่ระบุชื่อ',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: fontProvider.getScaledFontSize(16.0),
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'คนขับรถ',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: fontProvider.getScaledFontSize(14.0),
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ],

                      // Form Fields
                      Text(
                        'ข้อมูลการเติมน้ำมัน',
                        style: GoogleFonts.notoSansThai(
                          fontSize: fontProvider.getScaledFontSize(18.0),
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Date and Fuel Type Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(fontProvider, colors),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildFuelTypeField(fontProvider, colors),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Truck Selection
                      _buildTruckSelectionField(fontProvider, colors),
                      SizedBox(height: 16),

                      // Amount and Total Cost Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildAmountField(fontProvider, colors),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildTotalCostField(fontProvider, colors),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Odometer Field
                      _buildOdometerField(fontProvider, colors),
                      SizedBox(height: 24),

                      // Image Upload Section
                      _buildImageUploadSection(fontProvider, colors),
                      SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'บันทึกข้อมูล',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(16.0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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

  Widget _buildDateField(FontSizeProvider fontProvider, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'วันที่',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          onTap: _selectDate,
          decoration: InputDecoration(
            hintText: 'เลือกวันที่',
            suffixIcon: Icon(Icons.calendar_today, color: colors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาเลือกวันที่';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFuelTypeField(FontSizeProvider fontProvider, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ประเภทน้ำมัน',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedFuelType,
          items: _fuelTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(
                type,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(14.0),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFuelType = value;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาเลือกประเภทน้ำมัน';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTruckSelectionField(FontSizeProvider fontProvider, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เลือกรถ',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        _isLoadingTrucks 
          ? Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: colors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : DropdownButtonFormField<int>(
              value: _selectedTruckId,
              items: _trucks.map((truck) {
                return DropdownMenuItem<int>(
                  value: truck['truck_id'],
                  child: Text(
                    truck['display_name'] ?? '${truck['truck_number']} - ${truck['province']}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTruckId = value;
                });
              },
              decoration: InputDecoration(
                hintText: _trucks.isEmpty ? 'ไม่พบรถในระบบ' : 'เลือกรถ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null) {
                  return 'กรุณาเลือกรถ';
                }
                return null;
              },
            ),
      ],
    );
  }

  Widget _buildAmountField(FontSizeProvider fontProvider, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'จำนวนที่เติม (ลิตร)',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _amountFilledController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            suffixText: 'ลิตร',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาระบุจำนวน';
            }
            if (double.tryParse(value) == null) {
              return 'กรุณาระบุตัวเลขที่ถูกต้อง';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTotalCostField(FontSizeProvider fontProvider, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ราคารวม (บาท)',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _totalCostController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            suffixText: 'บาท',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาระบุราคา';
            }
            if (double.tryParse(value) == null) {
              return 'กรุณาระบุตัวเลขที่ถูกต้อง';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOdometerField(FontSizeProvider fontProvider, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เลขไมล์ (กม.)',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _odometerController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            suffixText: 'กม.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาระบุเลขไมล์';
            }
            if (int.tryParse(value) == null) {
              return 'กรุณาระบุตัวเลขที่ถูกต้อง';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageUploadSection(FontSizeProvider fontProvider, dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รูปภาพประกอบ',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(16.0),
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'เพิ่มรูปใบเสร็จหรือรูปประกอบอื่นๆ (สูงสุด 10 รูป)',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(12.0),
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: 12),
        
        // Add Image Button - Beautiful Design with Dashed Border
        GestureDetector(
          onTap: _pickImages,
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: colors.primary.withValues(alpha: 0.3),
              strokeWidth: 2,
              borderRadius: 16,
            ),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.05),
                    colors.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: colors.primary.withValues(alpha: 0.1),
                  highlightColor: colors.primary.withValues(alpha: 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with gradient background
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary,
                              colors.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Primary Text
                      Text(
                        'เลือกรูปภาพ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: fontProvider.getScaledFontSize(16.0),
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Subtitle
                      Text(
                        'แตะเพื่อเพิ่มรูปใบเสร็จ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: fontProvider.getScaledFontSize(12.0),
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),

        // Selected Images Grid
        if (_selectedImages.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final isUploading = index < _imageUploadingStatus.length && 
                                 !_imageUploadingStatus[index] && 
                                 (index >= _uploadedImageUrls.length || _uploadedImageUrls[index].isEmpty);
              
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImages[index].path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Upload status overlay
                  if (isUploading) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black54,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'อัพโหลด...',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Success indicator
                  if (index < _imageUploadingStatus.length && _imageUploadingStatus[index]) ...[
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                  
                  // Remove button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashLength;
  final double gapLength;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.borderRadius = 0.0,
    this.dashLength = 4.0,
    this.gapLength = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, 
                    size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool shouldDraw = true;
      
      while (distance < pathMetric.length) {
        final double nextDistance = distance + (shouldDraw ? dashLength : gapLength);
        final Path segment = pathMetric.extractPath(
          distance, 
          nextDistance > pathMetric.length ? pathMetric.length : nextDistance
        );
        
        if (shouldDraw) {
          canvas.drawPath(segment, paint);
        }
        
        distance = nextDistance;
        shouldDraw = !shouldDraw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is DashedBorderPainter) {
      return color != oldDelegate.color ||
             strokeWidth != oldDelegate.strokeWidth ||
             borderRadius != oldDelegate.borderRadius ||
             dashLength != oldDelegate.dashLength ||
             gapLength != oldDelegate.gapLength;
    }
    return true;
  }
}