import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/announcement_model.dart';
import '../service/api_service.dart';
import '../provider/font_size_provider.dart';
import 'announcement_card_widget.dart';
import 'announcement_detail_dialog.dart';

class AnnouncementListWidget extends StatefulWidget {
  final FontSizeProvider fontProvider;

  const AnnouncementListWidget({
    super.key,
    required this.fontProvider,
  });

  @override
  State<AnnouncementListWidget> createState() => AnnouncementListWidgetState();
}

class AnnouncementListWidgetState extends State<AnnouncementListWidget> {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> refreshAnnouncements() async {
    await _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getActiveAnnouncementsForDrivers();
      
      if (mounted) {
        if (result['success'] == true) {
          final List<dynamic> announcementData = result['announcements'] ?? [];
          
          setState(() {
            _announcements = announcementData
                .map((data) => AnnouncementModel.fromJson(data))
                .where((announcement) => 
                    announcement.isCurrentlyActive && 
                    announcement.isForDrivers)
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'ไม่สามารถโหลดประกาศได้';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการโหลดประกาศ';
          _isLoading = false;
        });
      }
    }
  }

  void _showAnnouncementDetail(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AnnouncementDetailDialog(
        announcement: announcement,
        fontProvider: widget.fontProvider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
              SizedBox(height: 12),
              Text(
                'กำลังโหลดประกาศ...',
                style: GoogleFonts.notoSansThai(
                  fontSize: widget.fontProvider.getScaledFontSize(14.0),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: GoogleFonts.notoSansThai(
                  fontSize: widget.fontProvider.getScaledFontSize(14.0),
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAnnouncements,
                icon: Icon(Icons.refresh),
                label: Text(
                  'ลองใหม่',
                  style: GoogleFonts.notoSansThai(
                    fontSize: widget.fontProvider.getScaledFontSize(14.0),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 12),
              Text(
                'ไม่มีประกาศสำหรับคนขับในขณะนี้',
                style: GoogleFonts.notoSansThai(
                  fontSize: widget.fontProvider.getScaledFontSize(14.0),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Icon(
                Icons.campaign,
                color: Color(0xFF2196F3),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'ประกาศสำหรับคนขับ',
                style: GoogleFonts.notoSansThai(
                  fontSize: widget.fontProvider.getScaledFontSize(18.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_announcements.length}',
                  style: GoogleFonts.notoSansThai(
                    fontSize: widget.fontProvider.getScaledFontSize(12.0),
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: _announcements
                .map((announcement) => AnnouncementCardWidget(
                      announcement: announcement,
                      fontProvider: widget.fontProvider,
                      onTap: () => _showAnnouncementDetail(announcement),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}