import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart' as AppThemeConfig;
import '../../../provider/font_size_provider.dart';
import '../../../widgets/map_modal.dart';
import '../../../service/api_service.dart';
import '../../../service/local_storage.dart';
import 'trip_timeline_widget.dart';

class TravelPlanWidget extends StatefulWidget {
  final Map<String, dynamic>? tripData;
  final VoidCallback? onStatusUpdated;

  const TravelPlanWidget({
    super.key,
    required this.tripData,
    this.onStatusUpdated,
  });

  @override
  State<TravelPlanWidget> createState() => _TravelPlanWidgetState();
}

class _TravelPlanWidgetState extends State<TravelPlanWidget> {
  
  // ตรวจสอบว่าสามารถ update สถานะได้หรือไม่ (ใช้ logic เดียวกับ job_detail_screen)
  bool _canUpdateStatus() {
    final currentStage = _getCurrentStage();
    if (currentStage == null) return false;

    // ตรวจสอบสถานะของ trip_data ก่อน
    if (widget.tripData != null && widget.tripData!['status'] != null) {
      final tripStatusLower = widget.tripData!['status'].toString().toLowerCase();
      if (tripStatusLower.contains('ระงับชั่วคราว')) {
        return false;
      }
    }

    // ไม่สามารถอัพเดทได้ถ้าสถานะเป็น "รอเจ้าหน้าที่ยืนยัน" หรือ "รอตรวจเอกสาร"
    final stageLower = currentStage.toLowerCase();
    return !stageLower.contains('รอเจ้าหน้าที่ยืนยัน') &&
        !stageLower.contains('รอตรวจเอกสาร');
  }

  // ดึงสถานะปัจจุบัน
  String? _getCurrentStage() {
    if (widget.tripData == null) return null;
    
    final logs = widget.tripData!['action_logs'] as List? ?? [];
    
    // หาข้อมูล action_log ที่มี complete_flag เป็น null (ยังไม่เสร็จ) และมี id น้อยที่สุด
    Map<String, dynamic>? currentLog;
    for (var log in logs) {
      if (log['complete_flag'] == null) {
        if (currentLog == null || log['id'] < currentLog['id']) {
          currentLog = log;
        }
      }
    }
    
    return currentLog?['stage'];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tripData == null) return SizedBox.shrink();
    
    final tripLocations = widget.tripData!['trip_locations'] as List? ?? [];
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // Timeline widget at the top
          TripTimelineWidget(
            tripLocations: tripLocations,
            tripId: widget.tripData!['id']?.toString() ?? '',
          ),
          // Existing integrated timeline below
          _buildIntegratedTimeline(),
        ],
      ),
    );
  }

  Widget _buildIntegratedTimeline() {
    if (widget.tripData == null) return SizedBox.shrink();
    
    final logs = widget.tripData!['action_logs'] as List? ?? [];
    final colors = AppThemeConfig.AppColorScheme.light();
    
    // Sort all logs by id first
    final sortedLogs = List<Map<String, dynamic>>.from(logs);
    sortedLogs.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));
    
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              SizedBox(height: 16),
              
              // Timeline Body - Show all logs in ID order
              ...sortedLogs.asMap().entries.map((entry) {
                final index = entry.key;
                final log = entry.value;
                final isLast = index == sortedLogs.length - 1;
                
                // Find the location for this log
                Map<String, dynamic>? logLocation;
                if (log['plan_order'] != null) {
                  logLocation = _getLocationByPlanOrder(log['plan_order']);
                }
                
                return _buildTimelineLogItem(
                  log, 
                  logLocation,
                  index + 1, 
                  isLast,
                  fontProvider,
                  colors,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineLogItem(
    Map<String, dynamic> log, 
    Map<String, dynamic>? location,
    int order, 
    bool isLast,
    FontSizeProvider fontProvider,
    dynamic colors,
  ) {
    final bool isCompleted = log['complete_flag'] == 1;
    final bool isActive = log['complete_flag'] == null;
    final bool canUpdate = _canUpdateStatus();
    
    // ตรวจสอบว่าเป็น step ที่ไม่ควรให้กดได้หรือไม่
    final int mainOrder = log['main_order'] ?? 0;
    final int minorOrder = log['minor_order'] ?? 0;
    final bool isRestrictedStep = (mainOrder == 7 && minorOrder == 3);
    
    // ถ้าเป็น restricted step ให้ปรับ canUpdate เป็น false
    final bool canUpdateThisStep = canUpdate && !isRestrictedStep;
    
    Color stepColor = colors.textSecondary;
    Color timelineColor = colors.divider;
    
    if (isCompleted) {
      stepColor = colors.success;
      timelineColor = colors.success;
    } else if (isActive && canUpdateThisStep) {
      stepColor = colors.primary;
      timelineColor = colors.primary;
    } else if (!canUpdateThisStep) {
      stepColor = colors.textSecondary.withOpacity(0.5);
      timelineColor = colors.divider.withOpacity(0.3);
    }
    
    // Create display text using the existing method
    String displayText = _getTimelineText(log, location);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Line & Node
        Column(
          children: [
            // Step Node - Clickable (if not restricted)
            GestureDetector(
              onTap: () => _onStepIconTapped(log, isCompleted, isActive),
              child: MouseRegion(
                cursor: !canUpdateThisStep ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: stepColor,
                    shape: BoxShape.circle,
                    boxShadow: !canUpdateThisStep ? [] : [
                      BoxShadow(
                        color: stepColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: 18)
                        : isActive && canUpdateThisStep
                            ? Icon(Icons.play_arrow, color: Colors.white, size: 18)
                            : !canUpdateThisStep
                                ? Icon(Icons.block, color: Colors.white.withOpacity(0.7), size: 16)
                                : Text(
                                    order.toString(),
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: fontProvider.getScaledFontSize(15.0),
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                  ),
                ),
              ),
            ),
            
            // Connecting Line
            if (!isLast)
              Container(
                width: 3,
                height: 80,
                decoration: BoxDecoration(
                  color: timelineColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
          ],
        ),
        
        SizedBox(width: 16),
        
        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 32),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: !canUpdateThisStep ? Colors.grey.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: stepColor.withOpacity(0.2)),
              boxShadow: !canUpdateThisStep ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: GoogleFonts.notoSansThai(
                          fontSize: fontProvider.getScaledFontSize(14.0),
                          fontWeight: FontWeight.bold,
                          color: !canUpdateThisStep ? colors.textSecondary : colors.textPrimary,
                        ),
                      ),
                    ),
                    if (location != null)
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => _showLocationModal(context, location),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.map_outlined, 
                              color: colors.success, 
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Stage and location info
                SizedBox(height: 8),
                Row(
                  children: [
                    if (log['stage'] != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stepColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log['stage'],
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(13.0),
                            color: stepColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    if (location != null && location['job_characteristic'] != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          location['job_characteristic'],
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(13.0),
                            color: colors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _getLocationByPlanOrder(int? planOrder) {
    if (planOrder == null || widget.tripData == null || widget.tripData!['trip_locations'] == null) {
      return null;
    }
    
    final locations = widget.tripData!['trip_locations'] as List;
    
    for (var location in locations) {
      if (location['plan_order'] == planOrder) {
        return location;
      }
    }
    
    return null;
  }

  String _getTimelineText(Map<String, dynamic> log, Map<String, dynamic>? location) {
    final stepDesc = log['step_desc'] ?? 'ไม่ระบุขั้นตอน';
    final locationName = location?['location_name'] ?? '';
    final minorOrder = log['minor_order']?.toString() ?? '';
    
    if (locationName.isNotEmpty) {
      switch (minorOrder) {
        case "1":
          return 'ถึงที่ $stepDesc ที่ $locationName';
        case "3":
          return 'เริ่ม $stepDesc';
        case "7":
          return 'เสร็จแล้ว $stepDesc';
        case "9":
          return 'ออกจากที่ $stepDesc';
        default:
          return '$stepDesc - $locationName';
      }
    } else {
      return stepDesc;
    }
  }

  void _showLocationModal(BuildContext context, Map<String, dynamic> location) {
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

  // Handle step icon tapped
  void _onStepIconTapped(Map<String, dynamic> log, bool isCompleted, bool isActive) {
    // ตรวจสอบว่าสามารถ update สถานะได้หรือไม่
    if (!_canUpdateStatus()) {
      // ไม่แสดงอะไร เมื่อไม่สามารถกดได้
      return;
    }
    
    // ตรวจสอบว่าเป็น restricted step หรือไม่
    final int mainOrder = log['main_order'] ?? 0;
    final int minorOrder = log['minor_order'] ?? 0;
    if (mainOrder == 7 && minorOrder == 3) {
      // ไม่แสดงอะไร เมื่อเป็น restricted step
      return;
    }
    
    // ถ้า step นี้ยังไม่เสร็จ ให้แสดง confirmation dialog
    if (!isCompleted) {
      _showStatusUpdateConfirmation(log, isActive);
    }
  }


  // Show confirmation dialog
  void _showStatusUpdateConfirmation(Map<String, dynamic> log, bool isActive) {
    final colors = AppThemeConfig.AppColorScheme.light();
    final stepDesc = log['step_desc'] ?? 'ไม่ระบุขั้นตอน';
    final progress = log['progress'] ?? '';

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
                  color: isActive ? colors.primary : colors.warning,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.play_arrow : Icons.pending,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ยืนยันการดำเนินการ',
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
                'คุณต้องการดำเนินการ:',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  stepDesc,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
              if (progress.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'สถานะที่จะเปลี่ยน: $progress',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateActionLogStatus(log);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ยืนยัน',
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

  // Update action log status via API
  Future<void> _updateActionLogStatus(Map<String, dynamic> log) async {
    // Show loading dialog
    _showLoadingDialog();

    try {
      // Get user info from local storage
      final userData = await LocalStorage.getProfile();
      final userName = userData?['user_name'] ?? 'Mobile User';

      // Call API
      final result = await ApiService.updateActionLogStatus(
        actionLogId: log['id'].toString(),
        updateUser: userName,
      );

      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        if (result['success']) {
          // Show success message
          _showResultMessage(
            title: 'สำเร็จ',
            message: result['message'] ?? 'อัพเดทสถานะเรียบร้อยแล้ว',
            isSuccess: true,
          );

          // Callback to parent to refresh data
          if (widget.onStatusUpdated != null) {
            widget.onStatusUpdated!();
          }
        } else {
          // Show error message
          _showResultMessage(
            title: 'เกิดข้อผิดพลาด',
            message: result['message'] ?? 'ไม่สามารถอัพเดทสถานะได้',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        _showResultMessage(
          title: 'เกิดข้อผิดพลาด',
          message: 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
          isSuccess: false,
        );
      }
    }
  }

  // Show loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'กำลังอัพเดทสถานะ...',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show result message
  void _showResultMessage({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
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
                  color: isSuccess ? colors.success : colors.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check : Icons.error,
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
                backgroundColor: isSuccess ? colors.success : colors.error,
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