import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart' as AppThemeConfig;
import '../../provider/font_size_provider.dart';

class JobCardItem extends StatelessWidget {
  final Map<String, dynamic> trip;

  const JobCardItem({
    Key? key, 
    required this.trip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return GestureDetector(
          onTap: () {
            if (trip['random_code'] != null) {
              Navigator.pushNamed(
                context,
                '/job-detail',
                arguments: {
                  'randomCode': trip['random_code'],
                  'jobNo': trip['job_no'] ?? 'ไม่ระบุ',
                  'tripNo': trip['tripNo'] ?? 'ไม่ระบุ',
                },
              );
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: Offset(0, 8),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status และข้อมูลพื้นฐาน
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(trip['status']),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(trip['status']).withValues(alpha: 0.3),
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          trip['status'] ?? 'ไม่ระบุ',
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(11.0),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Spacer(),
                      // Job & Trip Numbers (smaller)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'JOB: ',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(10.0),
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                trip['job_no'] ?? '-',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(10.0),
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TRIP: ',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(10.0),
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                trip['tripNo'] ?? '-',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(10.0),
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Job Name - Prominent (Bangchak style)
                  Text(
                    trip['job_name'] ?? 'ไม่ระบุชื่องาน',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(18.0),
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Container Number - if available
                  Builder(
                    builder: (context) {
                      String? containerId = _getContainerId(trip);
                      
                      if (containerId != null) {
                        return Column(
                          children: [
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inventory_2_rounded,
                                        size: 14,
                                        color: colors.success,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'เบอร์ตู้',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: fontProvider.getScaledFontSize(11.0),
                                          color: colors.success,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  containerId,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: fontProvider.getScaledFontSize(15.0),
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Basic Info - Bangchak Style
                  Column(
                    children: [
                      // Customer
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.business_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ลูกค้า',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: fontProvider.getScaledFontSize(12.0),
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  trip['customer_name'] ?? 'ไม่ระบุ',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: fontProvider.getScaledFontSize(14.0),
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Job Type & Start Date
                      Row(
                        children: [
                          // Job Type
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.work_rounded,
                                    size: 16,
                                    color: colors.warning,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ประเภทงาน',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: fontProvider.getScaledFontSize(11.0),
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        trip['job_type'] ?? 'ไม่ระบุ',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: fontProvider.getScaledFontSize(12.0),
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          // Start Date
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: colors.success,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'วันเวลาเริ่มงาน',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: fontProvider.getScaledFontSize(11.0),
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatDateTime(trip['jobStartDateTime']),
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: fontProvider.getScaledFontSize(12.0),
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Additional Job Information (แสดงเฉพาะเมื่อมีข้อมูล)
                  ..._buildAdditionalInfo(context, fontProvider, colors),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAdditionalInfo(BuildContext context, FontSizeProvider fontProvider, dynamic colors) {
    List<Widget> additionalWidgets = [];
    
    // Customer Job Info Section
    List<Widget> customerJobInfo = [];
    
    if (_hasValue(trip['customer_job_no'])) {
      customerJobInfo.add(_buildInfoItem(
        'เลขที่งานลูกค้า',
        trip['customer_job_no'],
        Icons.assignment_outlined,
        Color(0xFF2196F3), // Blue
        fontProvider,
      ));
    }
    
    if (_hasValue(trip['customer_po_no'])) {
      customerJobInfo.add(_buildInfoItem(
        'เลข PO',
        trip['customer_po_no'], 
        Icons.receipt_long_outlined,
        colors.warning,
        fontProvider,
      ));
    }
    
    if (_hasValue(trip['customer_invoice_no'])) {
      customerJobInfo.add(_buildInfoItem(
        'เลขที่ Invoice',
        trip['customer_invoice_no'],
        Icons.description_outlined,
        colors.success,
        fontProvider,
      ));
    }
    
    // Job Details Section
    List<Widget> jobDetails = [];
    
    if (_hasValue(trip['goods'])) {
      jobDetails.add(_buildInfoItem(
        'สินค้า',
        trip['goods'],
        Icons.inventory_2_outlined,
        colors.primary,
        fontProvider,
      ));
    }
    
    if (_hasValue(trip['booking'])) {
      jobDetails.add(_buildInfoItem(
        'Booking',
        trip['booking'],
        Icons.book_outlined,
        Color(0xFF795548), // Brown
        fontProvider,
      ));
    }
    
    if (_hasValue(trip['bill_of_lading'])) {
      jobDetails.add(_buildInfoItem(
        'Bill of Lading',
        trip['bill_of_lading'],
        Icons.article_outlined,
        Color(0xFF607D8B), // Blue Grey
        fontProvider,
      ));
    }
    
    if (_hasValue(trip['agent'])) {
      jobDetails.add(_buildInfoItem(
        'Agent',
        trip['agent'],
        Icons.person_outline,
        Color(0xFF9C27B0), // Purple
        fontProvider,
      ));
    }
    
    if (_hasValue(trip['quantity'])) {
      jobDetails.add(_buildInfoItem(
        'จำนวน',
        trip['quantity'],
        Icons.format_list_numbered_outlined,
        Color(0xFFFF5722), // Deep Orange
        fontProvider,
      ));
    }
    
    // เพิ่ม spacing และ sections เฉพาะเมื่อมีข้อมูล
    if (customerJobInfo.isNotEmpty || jobDetails.isNotEmpty) {
      additionalWidgets.add(SizedBox(height: 16));
      
      // Customer Job Information
      if (customerJobInfo.isNotEmpty) {
        additionalWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ข้อมูลงานลูกค้า',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(12.0),
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              ...customerJobInfo,
              if (jobDetails.isNotEmpty) SizedBox(height: 12),
            ],
          ),
        );
      }
      
      // Job Details Information  
      if (jobDetails.isNotEmpty) {
        additionalWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customerJobInfo.isEmpty) ...[
                Text(
                  'รายละเอียดงาน',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(12.0),
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
              ],
              ...jobDetails,
            ],
          ),
        );
      }
    }
    
    return additionalWidgets;
  }

  bool _hasValue(dynamic value) {
    return value != null && value.toString().trim().isNotEmpty && value.toString() != 'null';
  }

  Widget _buildInfoItem(String label, dynamic value, IconData icon, Color color, FontSizeProvider fontProvider) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(11.0),
                    color: AppThemeConfig.AppColorScheme.light().textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value.toString(),
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(13.0),
                    color: AppThemeConfig.AppColorScheme.light().textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _getContainerId(Map<String, dynamic> trip) {
    if (trip['container_id'] != null && trip['container_id'].toString().isNotEmpty) {
      return trip['container_id'].toString();
    } else if (trip['containerID'] != null && trip['containerID'].toString().isNotEmpty) {
      return trip['containerID'].toString();
    } else if (trip['CONTAINER_ID'] != null && trip['CONTAINER_ID'].toString().isNotEmpty) {
      return trip['CONTAINER_ID'].toString();
    } else if (trip['containerId'] != null && trip['containerId'].toString().isNotEmpty) {
      return trip['containerId'].toString();
    } else if (trip['containerid'] != null && trip['containerid'].toString().isNotEmpty) {
      return trip['containerid'].toString();
    } else if (trip['container'] != null && trip['container'].toString().isNotEmpty) {
      return trip['container'].toString();
    } else if (trip['cntr_no'] != null && trip['cntr_no'].toString().isNotEmpty) {
      return trip['cntr_no'].toString();
    } else if (trip['cntr_id'] != null && trip['cntr_id'].toString().isNotEmpty) {
      return trip['cntr_id'].toString();
    }
    return null;
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

}