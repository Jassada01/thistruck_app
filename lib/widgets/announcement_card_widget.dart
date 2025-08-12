import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/announcement_model.dart';
import '../provider/font_size_provider.dart';
import 'image_viewer_widget.dart';

class AnnouncementCardWidget extends StatelessWidget {
  final AnnouncementModel announcement;
  final FontSizeProvider fontProvider;
  final VoidCallback? onTap;

  const AnnouncementCardWidget({
    super.key,
    required this.announcement,
    required this.fontProvider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getPriorityColor().withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: _getPriorityColor().withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getPriorityColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(),
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          announcement.priorityText,
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(12.0),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.campaign,
                    size: 20,
                    color: _getPriorityColor(),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(16.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 8),
                  
                  // รูปภาพประกอบ (ถ้ามี)
                  if (announcement.hasImages) ...[
                    SizedBox(height: 8),
                    _buildImageGallery(),
                    SizedBox(height: 8),
                  ],
                  
                  Text(
                    announcement.content,
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (announcement.endDate != null) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          'หมดอายุ: ${_formatDate(announcement.endDate!)}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(12.0),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (announcement.priority) {
      case 1: // ต่ำ
        return Color(0xFF4CAF50); // Green
      case 2: // ปานกลาง
        return Color(0xFF2196F3); // Blue
      case 3: // สูง
        return Color(0xFFFF9800); // Orange
      case 4: // ด่วนมาก
        return Color(0xFFF44336); // Red
      default:
        return Color(0xFF2196F3);
    }
  }

  IconData _getPriorityIcon() {
    switch (announcement.priority) {
      case 1: // ต่ำ
        return Icons.info_outline;
      case 2: // ปานกลาง
        return Icons.notification_important_outlined;
      case 3: // สูง
        return Icons.warning_outlined;
      case 4: // ด่วนมาก
        return Icons.priority_high;
      default:
        return Icons.notification_important_outlined;
    }
  }

  Widget _buildImageGallery() {
    final images = announcement.imageAttachments;
    if (images.isEmpty) return SizedBox.shrink();
    
    if (images.length == 1) {
      return _buildSingleImage(images.first);
    } else {
      return _buildMultipleImages(images);
    }
  }
  
  Widget _buildSingleImage(AnnouncementAttachment image) {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageViewerWidget(
                  images: announcement.imageAttachments,
                  initialIndex: 0,
                  fontProvider: fontProvider,
                ),
              ),
            );
          },
          child: Image.network(
            image.fullUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_getPriorityColor()),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'ไม่สามารถโหลดรูปภาพได้',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(12.0),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
          ),
        ),
      ),
    ),
    );
  }
  
  Widget _buildMultipleImages(List<AnnouncementAttachment> images) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length > 3 ? 3 : images.length,
        itemBuilder: (BuildContext context, int index) {
          final image = images[index];
          final isLast = index == 2 && images.length > 3;
          
          return Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            width: 80,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ImageViewerWidget(
                            images: announcement.imageAttachments,
                            initialIndex: index,
                            fontProvider: fontProvider,
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      image.fullUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_getPriorityColor()),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.broken_image, color: Colors.grey[400]),
                      );
                    },
                    ),
                  ),
                ),
                if (isLast)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${images.length - 3}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(14.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}