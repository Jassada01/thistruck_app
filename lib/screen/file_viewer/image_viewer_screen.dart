import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../provider/font_size_provider.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              fileName,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSizeProvider.getScaledFontSize(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareImage(context),
              ),
            ],
          ),
          body: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained * 0.5,
              maxScale: PhotoViewComputedScale.covered * 2.0,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              errorBuilder: (context, error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่สามารถโหลดรูปภาพได้',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeProvider.getScaledFontSize(16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: fontSizeProvider.getScaledFontSize(14),
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

  void _shareImage(BuildContext context) {
    // TODO: Implement image sharing functionality if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ฟีเจอร์แชร์จะพัฒนาในอนาคต'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}