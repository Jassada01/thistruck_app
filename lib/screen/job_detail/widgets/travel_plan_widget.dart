import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart' as AppThemeConfig;
import '../../../provider/font_size_provider.dart';

class TravelPlanWidget extends StatelessWidget {
  final Map<String, dynamic>? tripData;

  const TravelPlanWidget({
    super.key,
    required this.tripData,
  });

  @override
  Widget build(BuildContext context) {
    if (tripData == null) return SizedBox.shrink();
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 20),
      child: _buildIntegratedTimeline(),
    );
  }

  Widget _buildIntegratedTimeline() {
    if (tripData == null) return SizedBox.shrink();
    
    final logs = tripData!['action_logs'] as List? ?? [];
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
              // Timeline Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary.withOpacity(0.1), colors.primary.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.primary.withOpacity(0.8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.timeline, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ผังลำดับการทำงาน',
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(18.0),
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${sortedLogs.length} ขั้นตอน • เรียงตาม ID',
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(13.0),
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
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
    
    Color stepColor = colors.textSecondary;
    Color timelineColor = colors.divider;
    
    if (isCompleted) {
      stepColor = colors.success;
      timelineColor = colors.success;
    } else if (isActive) {
      stepColor = colors.primary;
      timelineColor = colors.primary;
    }
    
    // Create display text using the existing method
    String displayText = _getTimelineText(log, location);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Line & Node
        Column(
          children: [
            // Step Node
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
                boxShadow: [
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
                    : isActive 
                        ? Icon(Icons.play_arrow, color: Colors.white, size: 18)
                        : Text(
                            order.toString(),
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(12.0),
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: stepColor.withOpacity(0.2)),
              boxShadow: [
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
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (location != null && location['map_url'] != null && location['map_url'].toString().isNotEmpty)
                      GestureDetector(
                        onTap: () => _openMap(location['map_url']),
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
                            fontSize: fontProvider.getScaledFontSize(10.0),
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
                            fontSize: fontProvider.getScaledFontSize(10.0),
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
    if (planOrder == null || tripData == null || tripData!['trip_locations'] == null) {
      return null;
    }
    
    final locations = tripData!['trip_locations'] as List;
    
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

  Future<void> _openMap(String? mapUrl) async {
    if (mapUrl == null || mapUrl.isEmpty) {
      print('⚠️ Map URL is empty or null');
      return;
    }
    
    try {
      print('🗺️ Opening map URL: $mapUrl');
      
      Uri? url;
      
      // ตรวจสอบประเภทของ URL และจัดการแต่ละประเภท
      if (mapUrl.startsWith('http://') || mapUrl.startsWith('https://')) {
        // URL ปกติ (Google Maps, etc.)
        url = Uri.parse(mapUrl);
      } else if (mapUrl.contains('lat') && mapUrl.contains('lng') || mapUrl.contains('latitude') && mapUrl.contains('longitude')) {
        // ถ้าเป็นพิกัด ให้เปิดด้วย Google Maps
        RegExp latRegex = RegExp(r'lat[itude]*[=:]?\s*([+-]?[0-9]*\.?[0-9]+)');
        RegExp lngRegex = RegExp(r'lng|lon[gitude]*[=:]?\s*([+-]?[0-9]*\.?[0-9]+)');
        
        Match? latMatch = latRegex.firstMatch(mapUrl);
        Match? lngMatch = lngRegex.firstMatch(mapUrl);
        
        if (latMatch != null && lngMatch != null) {
          final lat = latMatch.group(1);
          final lng = lngMatch.group(1);
          url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
        }
      } else if (RegExp(r'^[+-]?[0-9]*\.?[0-9]+,[+-]?[0-9]*\.?[0-9]+$').hasMatch(mapUrl.trim())) {
        // ถ้าเป็น format "lat,lng" เฉยๆ
        url = Uri.parse('https://www.google.com/maps?q=$mapUrl');
      }
      
      if (url != null && await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print('✅ Successfully opened map URL');
      } else {
        print('❌ Cannot launch URL: $mapUrl');
        // ถ้าเปิดไม่ได้ ให้ copy URL ไป clipboard แทน
        await Clipboard.setData(ClipboardData(text: mapUrl));
        print('📋 Copied map URL to clipboard instead');
      }
    } catch (e) {
      print('❌ Error opening map: $e');
      // ถ้าเกิดข้อผิดพลาด ให้ copy URL ไป clipboard แทน
      try {
        await Clipboard.setData(ClipboardData(text: mapUrl));
        print('📋 Copied map URL to clipboard due to error');
      } catch (clipboardError) {
        print('❌ Error copying to clipboard: $clipboardError');
      }
    }
  }
}