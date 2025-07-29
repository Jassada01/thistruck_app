import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../provider/font_size_provider.dart';
import '../../file_viewer/image_viewer_screen.dart';
import '../../file_viewer/pdf_viewer_screen.dart';

class AttachedFilesWidget extends StatelessWidget {
  final String serverName;
  final List<dynamic> attachedFiles;

  const AttachedFilesWidget({
    super.key,
    required this.serverName,
    required this.attachedFiles,
  });

  @override
  Widget build(BuildContext context) {
    if (attachedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Icons.attach_file,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ไฟล์แนบ (${attachedFiles.length} ไฟล์)',
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: attachedFiles.map<Widget>((file) {
                    return _buildFileItem(context, file, fontSizeProvider);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileItem(BuildContext context, dynamic file, FontSizeProvider fontSizeProvider) {
    final fileName = file['originalFileName'] ?? 'Unknown File';
    final fileType = file['file_type'] ?? '';
    final documentType = file['document_type'] ?? '';
    final description = file['description'] ?? '';
    final isImage = file['isImage'] == 1;
    final createdAt = file['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _openFile(context, file),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getFileTypeColor(fileType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileTypeIcon(fileType, isImage),
                color: _getFileTypeColor(fileType),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: fontSizeProvider.getScaledFontSize(14),
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (documentType.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        documentType,
                        style: TextStyle(
                          fontSize: fontSizeProvider.getScaledFontSize(11),
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: fontSizeProvider.getScaledFontSize(12),
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'อัปโหลดเมื่อ: ${_formatDateTime(createdAt)}',
                      style: TextStyle(
                        fontSize: fontSizeProvider.getScaledFontSize(11),
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _getActionIcon(file),
          ],
        ),
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType, bool isImage) {
    if (isImage) return Icons.image;
    
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('word') || fileType.contains('msword')) return Icons.description;
    if (fileType.contains('excel') || fileType.contains('spreadsheet')) return Icons.table_chart;
    if (fileType.contains('powerpoint') || fileType.contains('presentation')) return Icons.slideshow;
    if (fileType.contains('text')) return Icons.text_snippet;
    
    return Icons.insert_drive_file;
  }

  Color _getFileTypeColor(String fileType) {
    if (fileType.contains('image')) return Colors.green;
    if (fileType.contains('pdf')) return Colors.red;
    if (fileType.contains('word') || fileType.contains('msword')) return Colors.blue;
    if (fileType.contains('excel') || fileType.contains('spreadsheet')) return Colors.green;
    if (fileType.contains('powerpoint') || fileType.contains('presentation')) return Colors.orange;
    if (fileType.contains('text')) return Colors.grey;
    
    return Colors.blue;
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  void _openFile(BuildContext context, dynamic file) async {
    final filePath = file['file_path'] ?? '';
    final fileName = file['originalFileName'] ?? 'Unknown File';
    final fileType = file['file_type'] ?? '';
    final isImage = file['isImage'] == 1;

    if (filePath.isEmpty) {
      if (context.mounted) {
        _showErrorDialog(context, 'ไม่พบไฟล์ที่ต้องการเปิด');
      }
      return;
    }

    String fullUrl = serverName;
    if (!fullUrl.endsWith('/')) {
      fullUrl += '/';
    }
    fullUrl += filePath;

    try {
      // Check if it's an image file
      if (isImage || _isImageFile(fileType)) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageViewerScreen(
                imageUrl: fullUrl,
                fileName: fileName,
              ),
            ),
          );
        }
        return;
      }

      // Check if it's a PDF file
      if (_isPDFFile(fileType)) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(
                pdfUrl: fullUrl,
                fileName: fileName,
              ),
            ),
          );
        }
        return;
      }

      // For other file types, use external application
      final Uri url = Uri.parse(fullUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showErrorDialog(context, 'ไม่สามารถเปิดไฟล์ได้');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'เกิดข้อผิดพลาดในการเปิดไฟล์: $e');
      }
    }
  }

  bool _isImageFile(String fileType) {
    return fileType.toLowerCase().contains('image') ||
           fileType.toLowerCase().contains('jpeg') ||
           fileType.toLowerCase().contains('jpg') ||
           fileType.toLowerCase().contains('png') ||
           fileType.toLowerCase().contains('gif') ||
           fileType.toLowerCase().contains('webp');
  }

  bool _isPDFFile(String fileType) {
    return fileType.toLowerCase().contains('pdf');
  }

  Widget _getActionIcon(dynamic file) {
    final fileType = file['file_type'] ?? '';
    final isImage = file['isImage'] == 1;

    if (isImage || _isImageFile(fileType)) {
      return Icon(
        Icons.visibility,
        color: Colors.blue[600],
        size: 16,
      );
    }

    if (_isPDFFile(fileType)) {
      return Icon(
        Icons.picture_as_pdf,
        color: Colors.red[600],
        size: 16,
      );
    }

    return Icon(
      Icons.open_in_new,
      color: Colors.grey[400],
      size: 16,
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ข้อผิดพลาด'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }
}