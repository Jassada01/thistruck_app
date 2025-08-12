import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'dart:typed_data';
import '../models/announcement_model.dart';
import '../provider/font_size_provider.dart';

class ImageViewerWidget extends StatefulWidget {
  final List<AnnouncementAttachment> images;
  final int initialIndex;
  final FontSizeProvider fontProvider;

  const ImageViewerWidget({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.fontProvider,
  });

  @override
  State<ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: GoogleFonts.notoSansThai(
            fontSize: widget.fontProvider.getScaledFontSize(16.0),
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt, color: Colors.white),
            onPressed: () => _downloadImage(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main image viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Reset zoom when changing page
              _transformationController.value = Matrix4.identity();
            },
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      image.fullUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ?? 1)
                                    : null,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'กำลังโหลดรูปภาพ...',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: widget.fontProvider.getScaledFontSize(14.0),
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'ไม่สามารถโหลดรูปภาพได้',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: widget.fontProvider.getScaledFontSize(16.0),
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                image.fileName,
                                style: GoogleFonts.notoSansThai(
                                  fontSize: widget.fontProvider.getScaledFontSize(12.0),
                                  color: Colors.white54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Bottom overlay with image info
          if (widget.images.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, 40, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.images[_currentIndex].fileName,
                      style: GoogleFonts.notoSansThai(
                        fontSize: widget.fontProvider.getScaledFontSize(14.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatFileSize(widget.images[_currentIndex].fileSize),
                      style: GoogleFonts.notoSansThai(
                        fontSize: widget.fontProvider.getScaledFontSize(12.0),
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Thumbnail navigation
                    _buildThumbnailNavigation(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailNavigation() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final image = widget.images[index];
          final isSelected = index == _currentIndex;
          
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white38,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  image.fullUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 24,
                      ),
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

  Future<void> _downloadImage() async {
    try {
      final currentImage = widget.images[_currentIndex];
      
      // แสดงข้อความกำลังดาวน์โหลด
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'กำลังบันทึกรูปภาพ ${currentImage.fileName}...',
                  style: GoogleFonts.notoSansThai(
                    fontSize: widget.fontProvider.getScaledFontSize(14.0),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue[600],
            duration: Duration(seconds: 5),
          ),
        );
      }

      // ดาวน์โหลดรูปภาพเป็น bytes
      final dio = Dio();
      final response = await dio.get(
        currentImage.fullUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      
      final Uint8List imageBytes = Uint8List.fromList(response.data);
      
      // บันทึกรูปภาพไปยัง camera roll/gallery
      await Gal.putImageBytes(imageBytes, name: currentImage.fileName);

      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'บันทึกรูปภาพสำเร็จ: ${currentImage.fileName}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: widget.fontProvider.getScaledFontSize(14.0),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาด: ${e.toString()}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: widget.fontProvider.getScaledFontSize(14.0),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}