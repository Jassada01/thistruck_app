import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/announcement_model.dart';
import '../provider/font_size_provider.dart';
import 'image_viewer_widget.dart';

class AnnouncementDetailDialog extends StatelessWidget {
  final AnnouncementModel announcement;
  final FontSizeProvider fontProvider;

  const AnnouncementDetailDialog({
    super.key,
    required this.announcement,
    required this.fontProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getPriorityColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPriorityIcon(),
                    color: _getPriorityColor(),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(16.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPriorityColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getPriorityColor().withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(),
                            size: 16,
                            color: _getPriorityColor(),
                          ),
                          SizedBox(width: 4),
                          Text(
                            announcement.priorityText,
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(12.0),
                              fontWeight: FontWeight.w600,
                              color: _getPriorityColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // รูปภาพประกอบ (ถ้ามี)
                    if (announcement.hasImages) ...[
                      _buildDetailImageGallery(context),
                      SizedBox(height: 16),
                    ],
                    
                    Text(
                      announcement.content,
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(14.0),
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                    
                    if (announcement.endDate != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 8),
                            Text(
                              'หมดอายุ: ${_formatDate(announcement.endDate!)}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: fontProvider.getScaledFontSize(12.0),
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _getPriorityColor(),
                    ),
                    child: Text(
                      'ปิด',
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(14.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailImageGallery(BuildContext context) {
    final images = announcement.imageAttachments;
    if (images.isEmpty) return SizedBox.shrink();
    
    if (images.length == 1) {
      final image = images.first;
      return SizedBox(
        height: 150,
        width: double.infinity,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
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
                      Icon(Icons.broken_image, color: Colors.grey[400], size: 48),
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
      );
    } else {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return Container(
              margin: EdgeInsets.only(right: 8),
              width: 100,
              child: ClipRRect(
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
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
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
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
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
            );
          },
        ),
      );
    }
  }

  Color _getPriorityColor() {
    switch (announcement.priority) {
      case 1:
        return Color(0xFF4CAF50);
      case 2:
        return Color(0xFF2196F3);
      case 3:
        return Color(0xFFFF9800);
      case 4:
        return Color(0xFFF44336);
      default:
        return Color(0xFF2196F3);
    }
  }

  IconData _getPriorityIcon() {
    switch (announcement.priority) {
      case 1:
        return Icons.info_outline;
      case 2:
        return Icons.notification_important_outlined;
      case 3:
        return Icons.warning_outlined;
      case 4:
        return Icons.priority_high;
      default:
        return Icons.notification_important_outlined;
    }
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}