import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../service/api_service.dart';
import '../../theme/app_theme.dart' as AppThemeConfig;
import '../../provider/font_size_provider.dart';
import 'widgets/expense_list_widget.dart';
import 'widgets/travel_plan_widget.dart';

class JobDetailScreen extends StatefulWidget {
  final String randomCode;

  const JobDetailScreen({
    Key? key,
    required this.randomCode,
  }) : super(key: key);

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _tripData;
  String _errorMessage = '';
  bool _isUpdatingContainer = false;
  bool _isUpdatingStatus = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJobDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 ===== DEBUG: JobDetailScreen _loadJobDetail =====');
      print('🔍 Random Code: ${widget.randomCode}');
      
      final result = await ApiService.getJobOrderTripByRandomCode(widget.randomCode);
      
      print('🔍 ===== DEBUG: API RESULT =====');
      print('🔍 API Success: ${result['success']}');
      print('🔍 API Message: ${result['message']}');
      print('🔍 Full API Result: $result');

      if (result['success']) {
        final tripData = result['trip_data'];
        
        print('🔍 ===== DEBUG: TRIP DATA STRUCTURE =====');
        print('🔍 Trip Data Type: ${tripData?.runtimeType}');
        print('🔍 Trip Data Keys: ${tripData?.keys?.toList()}');
        print('🔍 Full Trip Data: $tripData');
        
        if (tripData != null) {
          print('🔍 ===== DEBUG: TRIP DATA DETAILS =====');
          print('🔍 Trip ID: ${tripData['id']}');
          print('🔍 Trip Status: ${tripData['status']}');
          print('🔍 Customer Name: ${tripData['customer_name']}');
          print('🔍 Driver Name: ${tripData['driver_name']}');
          print('🔍 Container ID: ${tripData['containerID']}');
          print('🔍 Job Name: ${tripData['job_name']}');
          print('🔍 Job Start DateTime: ${tripData['jobStartDateTime']}');
          
          if (tripData['trip_locations'] != null) {
            print('🔍 Trip Locations Count: ${(tripData['trip_locations'] as List).length}');
            print('🔍 Trip Locations: ${tripData['trip_locations']}');
          }
          
          if (tripData['action_logs'] != null) {
            print('🔍 Action Logs Count: ${(tripData['action_logs'] as List).length}');
            print('🔍 Action Logs: ${tripData['action_logs']}');
          }
        }
        
        setState(() {
          _tripData = tripData;
          _isLoading = false;
        });
      } else {
        print('🔍 ===== DEBUG: API ERROR =====');
        print('🔍 Error Message: ${result['message']}');
        
        setState(() {
          _errorMessage = result['message'] ?? 'ไม่สามารถโหลดข้อมูลงานได้';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔍 ===== DEBUG: EXCEPTION =====');
      print('🔍 Exception Type: ${e.runtimeType}');
      print('🔍 Exception Message: $e');
      print('🔍 Stack Trace: ${StackTrace.current}');
      
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'ไม่ระบุเวลา';
    
    try {
      final date = DateTime.parse(dateTime);
      final months = ['มค.', 'กพ.', 'มีค.', 'เมย.', 'พค.', 'มิย.', 'กค.', 'สค.', 'กย.', 'ตค.', 'พย.', 'ธค.'];
      return '${date.day} ${months[date.month - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  String _formatWeight(String? weightStr) {
    if (weightStr == null || weightStr.isEmpty) return 'ไม่ระบุ';
    
    try {
      final weight = double.tryParse(weightStr) ?? 0.0;
      if (weight == 0.0) return '-';
      
      final formatter = NumberFormat('#,##0.##', 'en_US');
      return '${formatter.format(weight)} กก.';
    } catch (e) {
      return weightStr.isNotEmpty ? '$weightStr กก.' : 'ไม่ระบุ';
    }
  }


  Color _getStatusColor(String? status) {
    final colors = AppThemeConfig.AppColorScheme.light();
    if (status == null) return colors.textSecondary;

    final statusLower = status.toLowerCase();

    // 🔴 RED - Error/Cancel/Suspended states
    if (statusLower.contains('ยกเลิก') ||
        statusLower.contains('ระงับชั่วคราว') ||
        statusLower.contains('cancelled') ||
        statusLower.contains('cancel')) {
      return colors.error; // Red
    }
    
    // 🟠 ORANGE - Waiting/Pending states
    else if (statusLower.contains('รอเจ้าหน้าที่ยืนยัน') ||
             statusLower.contains('รอ') ||
             statusLower.contains('draft')) {
      return colors.warning; // Orange/Amber
    }
    
    // 🟢 GREEN - Completed/Success states
    else if (statusLower.contains('ดำเนินการเสร็จ') ||
             statusLower.contains('ออกจากสถานที่แล้ว') ||
             statusLower.contains('จบงาน') ||
             statusLower.contains('คนขับยืนยันจบงานแล้ว') ||
             statusLower.contains('เสร็จสิ้น') ||
             statusLower.contains('completed') ||
             statusLower.contains('complete')) {
      return colors.success; // Green
    }
    
    // 🔵 BLUE - In Progress/Active states
    else if (statusLower.contains('กำลังดำเนินการ') ||
             statusLower.contains('เริ่มดำเนินการ') ||
             statusLower.contains('in_progress') ||
             statusLower.contains('active')) {
      return Color(0xFF2196F3); // Blue
    }
    
    // 🟣 PURPLE - Arrived/Location-based states
    else if (statusLower.contains('เข้าสถานที่แล้ว')) {
      return Color(0xFF9C27B0); // Purple
    }
    
    // 🟡 YELLOW - Confirmation states
    else if (statusLower.contains('เจ้าหน้าที่ยืนยันแล้ว') ||
             statusLower.contains('คนขับยืนยันแล้ว') ||
             statusLower.contains('ยืนยันเริ่มงานแล้ว')) {
      return Color(0xFFFFC107); // Amber/Yellow
    }
    
    // 🟢 TEAL - Container/Cargo specific operations
    else if (statusLower.contains('รับตู้หนัก') ||
             statusLower.contains('รับตู้เปล่า') ||
             statusLower.contains('คืนตู้หนัก') ||
             statusLower.contains('คืนตู้เปล่า')) {
      return Color(0xFF009688); // Teal
    }
    
    // 🔵 INDIGO - Delivery/Pickup operations
    else if (statusLower.contains('ส่งสินค้า') ||
             statusLower.contains('รับสินค้า')) {
      return Color(0xFF3F51B5); // Indigo
    }
    
    // 🟫 BROWN - Other operations
    else if (statusLower.contains('อื่นๆ')) {
      return Color(0xFF8D6E63); // Brown
    }

    return colors.primary; // Default fallback
  }

  Map<String, dynamic>? _getCurrentActionLog() {
    if (_tripData == null || _tripData!['action_logs'] == null) return null;
    
    final actionLogs = _tripData!['action_logs'] as List;
    
    // หา action_log ที่มี complete_flag = null และ id น้อยสุด
    Map<String, dynamic>? currentLog;
    int? minId;
    
    for (var log in actionLogs) {
      if (log['complete_flag'] == null) {
        final logId = log['id'] as int;
        if (minId == null || logId < minId) {
          minId = logId;
          currentLog = log;
        }
      }
    }
    
    return currentLog;
  }

  String? _getCurrentStage() {
    final currentLog = _getCurrentActionLog();
    return currentLog?['stage'];
  }

  String? _getCurrentButtonName() {
    final currentLog = _getCurrentActionLog();
    if (currentLog == null) return null;
    
    final location = _getLocationByPlanOrder(currentLog['plan_order']);
    return _getButtonName(currentLog, location);
  }

  bool _canUpdateStatus() {
    final currentStage = _getCurrentStage();
    if (currentStage == null) return false;
    
    // ตรวจสอบสถานะของ trip_data ก่อน
    if (_tripData != null && _tripData!['status'] != null) {
      final tripStatusLower = _tripData!['status'].toString().toLowerCase();
      if (tripStatusLower.contains('ระงับชั่วคราว')) {
        return false;
      }
    }
    
    // ไม่สามารถอัพเดทได้ถ้าสถานะเป็น "รอเจ้าหน้าที่ยืนยัน" หรือ "รอตรวจเอกสาร"
    final stageLower = currentStage.toLowerCase();
    return !stageLower.contains('รอเจ้าหน้าที่ยืนยัน') && 
           !stageLower.contains('รอตรวจเอกสาร');
  }

  Future<void> _updateWorkStatus() async {
    if (_tripData == null) return;

    final currentStage = _getCurrentStage();
    final buttonName = _getCurrentButtonName();
    
    if (currentStage == null || buttonName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่พบข้อมูลสถานะปัจจุบัน',
            style: GoogleFonts.notoSansThai(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ดึงข้อมูลสถานที่สำหรับการแสดงใน dialog
    final currentAction = _getCurrentActionLog();
    final location = currentAction != null ? _getLocationByPlanOrder(currentAction['plan_order']) : null;
    final locationName = location?['location_name'] ?? '';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Consumer<FontSizeProvider>(
        builder: (context, fontProvider, child) {
          return AlertDialog(
            title: Text(
              'ยืนยันการดำเนินการ',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(16.0),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สถานะปัจจุบัน:',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(12.0),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusColor(currentStage).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    currentStage,
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(12.0),
                      color: _getStatusColor(currentStage),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (locationName.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    'สถานที่:',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(12.0),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            locationName,
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(12.0),
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16),
                Text(
                  'คุณต้องการดำเนินการ "$buttonName" หรือไม่?',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'ยกเลิก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(currentStage),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonName,
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      await _processCurrentAction();
    }
  }

  Future<void> _processCurrentAction() async {
    final currentLog = _getCurrentActionLog();
    if (currentLog == null) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      // เรียก Function 15 โดยส่ง trip_id และ job_id
      final response = await ApiService.updateWorkStatus(
        tripId: _tripData!['id'].toString(),
        jobId: _tripData!['job_id'].toString(),
        updateUser: 'Mobile App Driver', // ระบุว่าเป็นคนขับที่อัพเดท
      );

      if (response['success']) {
        // รีโหลดข้อมูลเพื่อดูสถานะใหม่
        await _loadJobDetail();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ดำเนินการเรียบร้อยแล้ว',
                style: GoogleFonts.notoSansThai(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'เกิดข้อผิดพลาดในการดำเนินการ',
                style: GoogleFonts.notoSansThai(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการเชื่อมต่อ',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isUpdatingStatus = false;
    });
  }



  Future<void> _updateContainerID() async {
    if (_tripData == null) return;

    final TextEditingController controller = TextEditingController(
      text: _tripData!['containerID']?.toString() ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => Consumer<FontSizeProvider>(
        builder: (context, fontProvider, child) {
          return AlertDialog(
            title: Text(
              'แก้ไขหมายเลขตู้',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(16.0),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Container ID',
                hintText: 'กรุณากรอกหมายเลขตู้',
                border: OutlineInputBorder(),
              ),
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(14.0),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ยกเลิก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text(
                  'บันทึก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      await _saveContainerID(result);
    }
  }

  Future<void> _saveContainerID(String newContainerID) async {
    setState(() {
      _isUpdatingContainer = true;
    });

    try {
      final response = await ApiService.updateContainerID(
        tripId: _tripData!['id'].toString(),
        containerID: newContainerID,
      );

      if (response['success']) {
        setState(() {
          _tripData!['containerID'] = newContainerID;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'อัพเดทหมายเลขตู้เรียบร้อยแล้ว',
                style: GoogleFonts.notoSansThai(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'เกิดข้อผิดพลาดในการอัพเดท',
                style: GoogleFonts.notoSansThai(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการเชื่อมต่อ',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isUpdatingContainer = false;
    });
  }

  Future<void> _updateSealNo() async {
    if (_tripData == null) return;

    final TextEditingController controller = TextEditingController(
      text: _tripData!['seal_no']?.toString() ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => Consumer<FontSizeProvider>(
        builder: (context, fontProvider, child) {
          return AlertDialog(
            title: Text(
              'แก้ไขหมายเลขซีล',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(16.0),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'หมายเลขซีล',
                hintText: 'กรุณากรอกหมายเลขซีล',
                border: OutlineInputBorder(),
              ),
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(14.0),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ยกเลิก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text(
                  'บันทึก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      await _saveSealAndWeight(sealNo: result);
    }
  }

  Future<void> _updateContainerWeight() async {
    if (_tripData == null) return;

    final TextEditingController controller = TextEditingController(
      text: _tripData!['containerWeight']?.toString().replaceAll('.00', '') ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => Consumer<FontSizeProvider>(
        builder: (context, fontProvider, child) {
          return AlertDialog(
            title: Text(
              'แก้ไขน้ำหนักตู้',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(16.0),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'น้ำหนักตู้ (กก.)',
                hintText: 'กรุณากรอกน้ำหนักตู้',
                border: OutlineInputBorder(),
                suffixText: 'กก.',
              ),
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(14.0),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ยกเลิก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text(
                  'บันทึก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      await _saveSealAndWeight(containerWeight: result);
    }
  }

  Future<void> _saveSealAndWeight({String? sealNo, String? containerWeight}) async {
    setState(() {
      _isUpdatingContainer = true;
    });

    try {
      final response = await ApiService.updateSealAndWeight(
        tripId: _tripData!['id'].toString(),
        sealNo: sealNo,
        containerWeight: containerWeight,
      );

      if (response['success']) {
        setState(() {
          if (sealNo != null) {
            _tripData!['seal_no'] = sealNo;
          }
          if (containerWeight != null) {
            _tripData!['containerWeight'] = containerWeight;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'อัพเดทข้อมูลเรียบร้อยแล้ว',
                style: GoogleFonts.notoSansThai(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'เกิดข้อผิดพลาดในการอัพเดท',
                style: GoogleFonts.notoSansThai(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการเชื่อมต่อ',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isUpdatingContainer = false;
    });
  }


  Widget _buildStatusUpdateButton() {
    if (!_canUpdateStatus()) return SizedBox.shrink();

    final currentStage = _getCurrentStage();
    final buttonName = _getCurrentButtonName();
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isUpdatingStatus ? null : _updateWorkStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isUpdatingStatus 
                    ? Colors.grey.withOpacity(0.5)
                    : _getStatusColor(currentStage),
                foregroundColor: Colors.white,
                elevation: _isUpdatingStatus ? 0 : 3,
                shadowColor: _getStatusColor(currentStage).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: _isUpdatingStatus
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.touch_app,
                      size: 20,
                    ),
              label: Text(
                _isUpdatingStatus 
                    ? 'กำลังดำเนินการ...'
                    : buttonName ?? 'อัพเดทสถานะ',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(14.0),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobInfo() {
    if (_tripData == null) return SizedBox.shrink();
    
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with job start time
              Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'ข้อมูลงาน',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(13.0),
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  if (_tripData!['jobStartDateTime'] != null)
                    Text(
                      _formatDateTime(_tripData!['jobStartDateTime']),
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(14.0),
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              // Compact grid layout
              Row(
                children: [
                  Expanded(child: _buildCompactInfoRow('คนขับ', _tripData!['driver_name'])),
                  SizedBox(width: 12),
                  Expanded(child: _buildCompactInfoRow('ทะเบียน', _tripData!['truck_licenseNo'])),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildEditableContainerRow()),
                  SizedBox(width: 12),
                  Expanded(child: _buildEditableSealRow()),
                ],
              ),
              SizedBox(height: 8),
              _buildEditableWeightRow(),
              // Additional job information
              SizedBox(height: 8),
              _buildAdditionalJobInfo(),
              // Job remark if exists
              if (_tripData!['job_remark'] != null && _tripData!['job_remark'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                _buildRemarkSection(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactInfoRow(String label, dynamic value) {
    final colors = AppThemeConfig.AppColorScheme.light();
    final displayValue = value?.toString() ?? 'ไม่ระบุ';
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(9.0),
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Tooltip(
              message: displayValue,
              child: Text(
                displayValue,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(11.0),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableContainerRow() {
    final colors = AppThemeConfig.AppColorScheme.light();
    final containerID = _tripData!['containerID']?.toString() ?? '';
    final displayValue = containerID.isNotEmpty ? containerID : 'ไม่ระบุ';
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Container ID',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(9.0),
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                if (_isUpdatingContainer)
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _updateContainerID,
                    child: Icon(
                      Icons.edit,
                      size: 12,
                      color: colors.primary.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2),
            Tooltip(
              message: displayValue,
              child: Text(
                displayValue,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(11.0),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableSealRow() {
    final colors = AppThemeConfig.AppColorScheme.light();
    final sealNo = _tripData!['seal_no']?.toString() ?? '';
    final displayValue = sealNo.isNotEmpty ? sealNo : 'ไม่ระบุ';
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'หมายเลขซีล',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(9.0),
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: _updateSealNo,
                  child: Icon(
                    Icons.edit,
                    size: 12,
                    color: colors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Tooltip(
              message: displayValue,
              child: Text(
                displayValue,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(11.0),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableWeightRow() {
    final colors = AppThemeConfig.AppColorScheme.light();
    final containerWeight = _tripData!['containerWeight']?.toString() ?? '';
    final displayValue = _formatWeight(containerWeight);
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'น้ำหนักตู้',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(9.0),
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: _updateContainerWeight,
                  child: Icon(
                    Icons.edit,
                    size: 12,
                    color: colors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Tooltip(
              message: displayValue,
              child: Text(
                displayValue,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(11.0),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRemarkSection() {
    final colors = AppThemeConfig.AppColorScheme.light();
    final remark = _tripData!['job_remark']?.toString() ?? '';
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.warning.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.note_alt_outlined, size: 12, color: colors.warning),
                  SizedBox(width: 4),
                  Text(
                    'หมายเหตุ',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(9.0),
                      color: colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                remark,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(10.0),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildAdditionalJobInfo() {
    List<Widget> additionalRows = [];
    
    // สร้างรายการข้อมูลเพิ่มเติมที่ต้องแสดง
    Map<String, String> additionalFields = {
      'customer_job_no': 'Job NO ของลูกค้า',
      'booking': 'Booking (บุ๊กกิ้ง)',
      'customer_po_no': 'PO No.',
      'bill_of_lading': 'B/L (ใบขน)',
      'customer_invoice_no': 'Invoice No.',
      'agent': 'Agent (เอเย่นต์)',
      'goods': 'ชื่อสินค้า',
      'quantity': 'QTY/No. of Package',
    };

    List<MapEntry<String, String>> fieldsWithData = [];
    
    // กรองเฉพาะข้อมูลที่มีค่า
    additionalFields.forEach((key, label) {
      var value = _tripData![key];
      if (value != null && value.toString().isNotEmpty && value.toString() != '0') {
        fieldsWithData.add(MapEntry(key, label));
      }
    });

    // จัดเรียงเป็น 2 คอลัมน์
    for (int i = 0; i < fieldsWithData.length; i += 2) {
      if (i + 1 < fieldsWithData.length) {
        // มี 2 ฟิลด์ในแถว
        additionalRows.add(
          Row(
            children: [
              Expanded(child: _buildCompactInfoRow(
                fieldsWithData[i].value, 
                _tripData![fieldsWithData[i].key]
              )),
              SizedBox(width: 12),
              Expanded(child: _buildCompactInfoRow(
                fieldsWithData[i + 1].value, 
                _tripData![fieldsWithData[i + 1].key]
              )),
            ],
          ),
        );
      } else {
        // มีเพียง 1 ฟิลด์ในแถว
        additionalRows.add(
          _buildCompactInfoRow(
            fieldsWithData[i].value, 
            _tripData![fieldsWithData[i].key]
          ),
        );
      }
    }

    return Column(children: additionalRows);
  }






  Map<String, dynamic>? _getLocationByPlanOrder(int? planOrder) {
    if (planOrder == null || _tripData == null || _tripData!['trip_locations'] == null) {
      return null;
    }
    
    final locations = _tripData!['trip_locations'] as List;
    
    for (var location in locations) {
      if (location['plan_order'] == planOrder) {
        return location;
      }
    }
    
    return null;
  }


  // สร้างชื่อปุ่มตาม minor_order
  String _getButtonName(Map<String, dynamic>? currentAction, Map<String, dynamic>? location) {
    if (currentAction == null) return 'อัพเดทสถานะ';
    
    final stepDesc = currentAction['step_desc'] ?? '';
    final locationName = location?['location_name'] ?? '';
    final minorOrder = currentAction['minor_order']?.toString() ?? '';
    final mainOrder = currentAction['main_order']?.toString() ?? '';
    
    if (mainOrder == "3") {
      switch (minorOrder) {
        case "1":
          return locationName.isNotEmpty ? 'ยืนยันถึง $locationName' : 'ยืนยันถึงที่หมาย';
        case "3":
          return locationName.isNotEmpty ? 'ยืนยันเริ่ม$stepDesc ที่ $locationName' : 'ยืนยันเริ่มดำเนินการ$stepDesc';
        case "7":
          return locationName.isNotEmpty ? 'ยืนยัน$stepDesc เสร็จ ที่ $locationName' : 'ยืนยัน$stepDesc เสร็จ';
        case "9":
          return locationName.isNotEmpty ? 'ยืนยันออกจาก $locationName' : 'ยืนยันออกจาก';
        default:
          return locationName.isNotEmpty ? 'ยืนยัน$stepDesc ที่ $locationName' : 'ยืนยัน$stepDesc';
      }
    }
    
    return 'อัพเดทสถานะ';
  }


  @override
  Widget build(BuildContext context) {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Consumer<FontSizeProvider>(
          builder: (context, fontProvider, child) {
            return Text(
              _tripData?['job_name'] ?? 'รายละเอียดงาน',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(16.0),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: colors.primary, size: 20),
              onPressed: _loadJobDetail,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern Compact Header Design
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  colors.primary.withOpacity(0.8),
                  colors.primary.withOpacity(0.6),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.3),
                  offset: Offset(0, 4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    // Top Row: Job Name with Status Badge
                    Row(
                      children: [
                        // Job Title Section
                        Expanded(
                          child: Consumer<FontSizeProvider>(
                            builder: (context, fontProvider, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Customer Name
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.business_center_rounded,
                                          size: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: _tripData == null 
                                          ? Container(
                                              constraints: BoxConstraints(maxWidth: 150),
                                              child: _buildSkeletonLine(width: 0.6, height: 14, isHeader: true),
                                            )
                                          : Builder(
                                              builder: (context) {
                                                final customerName = _tripData!['customer_name'] ?? 'ไม่ระบุลูกค้า';
                                                return Tooltip(
                                                  message: customerName,
                                                  child: Text(
                                                    customerName,
                                                    style: GoogleFonts.notoSansThai(
                                                      fontSize: fontProvider.getScaledFontSize(14.0),
                                                      color: Colors.white.withOpacity(0.85),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                );
                                              },
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Status Badge
                        if (_tripData?['status'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Consumer<FontSizeProvider>(
                              builder: (context, fontProvider, child) {
                                return Text(
                                  _tripData!['status'],
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: fontProvider.getScaledFontSize(12.0),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Bottom Row: Job/Trip Numbers with Date
                    Row(
                      children: [
                        // Left Side: Job & Trip Numbers
                        Expanded(
                          child: Row(
                            children: [
                              // Job Number
                              if (_tripData?['job_no'] != null) ...[
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Consumer<FontSizeProvider>(
                                      builder: (context, fontProvider, child) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.assignment_outlined,
                                              size: 14,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Job ${_tripData!['job_no']}',
                                                style: GoogleFonts.notoSansThai(
                                                  fontSize: fontProvider.getScaledFontSize(11.0),
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                              // Trip Number
                              if (_tripData?['trip_no'] != null || _tripData?['id'] != null) ...[
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Consumer<FontSizeProvider>(
                                      builder: (context, fontProvider, child) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.route_outlined,
                                              size: 14,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Trip ${_tripData?['tripNo'] ?? _tripData?['id']}',
                                                style: GoogleFonts.notoSansThai(
                                                  fontSize: fontProvider.getScaledFontSize(11.0),
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 12),
                        
                        // Right Side: Start Date/Time
                        if (_tripData?['jobStartDateTime'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Consumer<FontSizeProvider>(
                              builder: (context, fontProvider, child) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: Colors.orange.shade300,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _formatDateTime(_tripData!['jobStartDateTime']),
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: fontProvider.getScaledFontSize(11.0),
                                        color: Colors.orange.shade200,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoading()
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.error_outline_rounded, 
                                size: 48, 
                                color: colors.error
                              ),
                            ),
                            SizedBox(height: 20),
                            Consumer<FontSizeProvider>(
                              builder: (context, fontProvider, child) {
                                return Text(
                                  _errorMessage,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: fontProvider.getScaledFontSize(16.0),
                                    color: colors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadJobDetail,
                              icon: Icon(Icons.refresh_rounded, size: 20),
                              label: Consumer<FontSizeProvider>(
                                builder: (context, fontProvider, child) {
                                  return Text(
                                    'ลองใหม่',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: fontProvider.getScaledFontSize(14.0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: EdgeInsets.only(top: 8),
                        child: DefaultTabController(
                          length: 3,
                          child: NestedScrollView(
                            headerSliverBuilder: (context, innerBoxIsScrolled) {
                              return [
                                SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      _buildStatusUpdateButton(),
                                      _buildJobInfo(),
                                    ],
                                  ),
                                ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyTabBarDelegate(
                              child: Container(
                                color: Colors.grey[100],
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.grey.shade200, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        offset: Offset(0, 2),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Consumer<FontSizeProvider>(
                                    builder: (context, fontProvider, child) {
                                      return TabBar(
                                        controller: _tabController,
                                        indicatorSize: TabBarIndicatorSize.tab,
                                        dividerColor: Colors.transparent,
                                        indicator: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colors.primary,
                                              colors.primary.withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colors.primary.withOpacity(0.3),
                                              offset: Offset(0, 2),
                                              blurRadius: 6,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        labelColor: Colors.white,
                                        unselectedLabelColor: colors.textSecondary,
                                        labelStyle: GoogleFonts.notoSansThai(
                                          fontWeight: FontWeight.w700,
                                          fontSize: fontProvider.getScaledFontSize(11.0),
                                          letterSpacing: 0.5,
                                        ),
                                        unselectedLabelStyle: GoogleFonts.notoSansThai(
                                          fontWeight: FontWeight.w500,
                                          fontSize: fontProvider.getScaledFontSize(11.0),
                                        ),
                                        splashFactory: NoSplash.splashFactory,
                                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                                        tabs: [
                                          Tab(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.route, size: 16),
                                                  SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'แผนการเดินทาง',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Tab(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.attach_money, size: 16),
                                                  SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'ค่าใช้จ่าย',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Tab(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.receipt_long, size: 16),
                                                  SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'ที่อยู่ใบเสร็จ',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                              ];
                            },
                            body: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 1: แผนการเดินทาง
                                TravelPlanWidget(tripData: _tripData),
                                // Tab 2: ค่าใช้จ่าย
                                SingleChildScrollView(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: ExpenseListWidget(
                                    tripData: _tripData,
                                    onExpenseUpdated: () {
                                      setState(() {
                                        _calculateTotalExpenses();
                                      });
                                    },
                                  ),
                                ),
                                // Tab 3: ที่อยู่ออกใบเสร็จ
                                SingleChildScrollView(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: _buildInvoiceAddress(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }


  Widget _buildInvoiceAddress() {
    if (_tripData == null || _tripData!['trip_cost'] == null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'ไม่มีข้อมูลที่อยู่ออกใบเสร็จ',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final costData = _tripData!['trip_cost'] as Map<String, dynamic>;
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: colors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'ที่อยู่ออกใบเสร็จ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: fontProvider.getScaledFontSize(14.0),
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _copyAllAddresses(costData),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.content_copy,
                            size: 14,
                            color: colors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'คัดลอกทั้งหมด',
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(11.0),
                              color: colors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildAddressRow('ที่อยู่ 1', costData['insInvAdd1']),
              _buildAddressRow('ที่อยู่ 2', costData['insInvAdd2']),
              _buildAddressRow('ที่อยู่ 3', costData['insInvAdd3']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressRow(String label, dynamic value) {
    final colors = AppThemeConfig.AppColorScheme.light();
    final displayValue = value?.toString().isNotEmpty == true ? value.toString() : 'ไม่ระบุ';
    final hasValue = value?.toString().isNotEmpty == true;
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(11.0),
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasValue)
                    GestureDetector(
                      onTap: () => _copyToClipboard(displayValue, label),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy,
                              size: 12,
                              color: colors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'คัดลอก',
                              style: GoogleFonts.notoSansThai(
                                fontSize: fontProvider.getScaledFontSize(10.0),
                                color: colors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  displayValue,
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(12.0),
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'คัดลอก$labelแล้ว',
            style: GoogleFonts.notoSansThai(),
          ),
          backgroundColor: AppThemeConfig.AppColorScheme.light().success,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _copyAllAddresses(Map<String, dynamic> costData) async {
    List<String> addresses = [];
    
    if (costData['insInvAdd1']?.toString().isNotEmpty == true) {
      addresses.add('ที่อยู่ 1: ${costData['insInvAdd1']}');
    }
    if (costData['insInvAdd2']?.toString().isNotEmpty == true) {
      addresses.add('ที่อยู่ 2: ${costData['insInvAdd2']}');
    }
    if (costData['insInvAdd3']?.toString().isNotEmpty == true) {
      addresses.add('ที่อยู่ 3: ${costData['insInvAdd3']}');
    }
    
    if (addresses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่มีข้อมูลที่อยู่ใบเสร็จให้คัดลอก',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }
    
    final allAddressText = addresses.join('\n');
    await Clipboard.setData(ClipboardData(text: allAddressText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'คัดลอกที่อยู่ใบเสร็จทั้งหมดแล้ว (${addresses.length} รายการ)',
            style: GoogleFonts.notoSansThai(),
          ),
          backgroundColor: AppThemeConfig.AppColorScheme.light().success,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _calculateTotalExpenses() {
    if (_tripData?['trip_cost'] == null) return;

    final costData = _tripData!['trip_cost'] as Map<String, dynamic>;
    
    double total = 0.0;
    final costFields = [
      'overtime_fee',
      'port_charge',
      'yard_charge',
      'container_return',
      'container_cleaning_repair',
      'container_drop_lift',
      'expenses_1',
    ];

    for (String field in costFields) {
      final value = double.tryParse(costData[field]?.toString() ?? '0.00') ?? 0.0;
      total += value;
    }

    costData['total_expenses'] = total.toStringAsFixed(2);
  }

  Widget _buildSkeletonLoading() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Skeleton for status update button
            _buildSkeletonCard(height: 50, width: double.infinity),
            
            SizedBox(height: 16),
            
            // Skeleton for job info card
            _buildSkeletonCard(height: 220),
            
            SizedBox(height: 16),
            
            // Skeleton for tabs
            _buildSkeletonCard(height: 50),
            
            SizedBox(height: 16),
            
            // Skeleton for tab content
            Column(
              children: [
                _buildSkeletonCard(height: 120),
                SizedBox(height: 12),
                _buildSkeletonCard(height: 80),
                SizedBox(height: 12),
                _buildSkeletonCard(height: 100),
                SizedBox(height: 12),
                _buildSkeletonCard(height: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard({double? height, double? width}) {
    return Container(
      constraints: BoxConstraints(
        minHeight: height ?? 80,
        maxHeight: (height ?? 80) * 1.2,
      ),
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: _buildShimmerEffect(),
    );
  }

  Widget _buildShimmerEffect() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _buildSkeletonLine(width: 0.6),
          ),
          SizedBox(height: 4),
          Flexible(
            child: _buildSkeletonLine(width: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine({double width = 1.0, double height = 12, bool isHeader = false}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          height: height,
          width: isHeader ? null : MediaQuery.of(context).size.width * width,
          constraints: isHeader ? BoxConstraints(minWidth: 60, maxWidth: 180) : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * value, 0.0),
              end: Alignment(1.0 + 2.0 * value, 0.0),
              colors: isHeader 
                ? [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.3),
                  ]
                : [
                    Colors.grey.shade300,
                    Colors.grey.shade100,
                    Colors.grey.shade300,
                  ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
      onEnd: () {
        // เริ่มใหม่เพื่อให้เป็น continuous animation
        if (mounted && _isLoading) {
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted && _isLoading) {
              setState(() {});
            }
          });
        }
      },
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 70;

  @override
  double get minExtent => 70;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}