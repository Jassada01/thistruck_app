import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import '../../provider/font_size_provider.dart';

class PDFViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              fileName,
              style: TextStyle(
                fontSize: fontSizeProvider.getScaledFontSize(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _sharePDF(context),
              ),
            ],
          ),
          body: SfPdfViewer.network(
            pdfUrl,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              _showErrorDialog(context, details.error, details.description);
            },
          ),
        );
      },
    );
  }

  void _sharePDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ฟีเจอร์แชร์จะพัฒนาในอนาคต'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ไม่สามารถเปิดไฟล์ PDF ได้'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('เกิดข้อผิดพลาดในการโหลดไฟล์ PDF'),
              const SizedBox(height: 8),
              Text(
                'รายละเอียด: $description',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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