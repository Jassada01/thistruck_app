import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../service/local_storage.dart';
import '../../provider/font_size_provider.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isAccepted = false;
  bool _isLoading = false;

  // Colors (Blue/White theme)
  final Color _primaryColor = Color(0xFF2196F3);
  final Color _primaryVariant = Color(0xFF1976D2);
  final Color _backgroundColor = Color(0xFFFAFAFA);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = Color(0xFF1A1A1A);
  final Color _textSecondary = Color(0xFF6B7280);

  Future<void> _acceptTerms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await LocalStorage.setTermsAccepted(true);
      
      if (mounted) {
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการบันทึกข้อมูล',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTermsContent() {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'ข้อตกลงและเงื่อนไขการใช้งาน',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(24.0),
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 24),
              
              Text(
                'แอปพลิเคชัน "This Truck" สำหรับระบบจัดการรถขนส่ง',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Terms content
              _buildSection(
                '1. การเก็บรวบรวมข้อมูลส่วนบุคคล',
                'เราจะเก็บรวบรวมข้อมูลส่วนบุคคลของท่านเพื่อการให้บริการที่ดีที่สุด ดังนี้:\n\n'
                '• ข้อมูลส่วนตัว: ชื่อ-นามสกุล, เบอร์โทรศัพท์\n'
                '• ข้อมูลการใช้งาน: ประวัติการเข้าใช้งานระบบ\n'
                '• ข้อมูลอุปกรณ์: รุ่นโทรศัพท์, ระบบปฏิบัติการ, หมายเลขอุปกรณ์\n'
                '• ข้อมูลตำแหน่ง: เพื่อติดตามเส้นทางการขนส่ง (เฉพาะเมื่อเปิดแอป)',
                fontProvider,
              ),

              _buildSection(
                '2. วัตถุประสงค์ในการใช้ข้อมูล',
                'ข้อมูลที่เก็บรวบรวมจะนำไปใช้เพื่อ:\n\n'
                '• จัดการและติดตามงานขนส่ง\n'
                '• ส่งการแจ้งเตือนเกี่ยวกับงาน\n'
                '• ปรับปรุงคุณภาพการให้บริการ\n'
                '• รายงานสถิติการใช้งานระบบ\n'
                '• รักษาความปลอดภัยของระบบ',
                fontProvider,
              ),

              _buildSection(
                '3. การแจ้งเตือน (Push Notifications)',
                'แอปพลิเคชันจะขอสิทธิ์ส่งการแจ้งเตือนเพื่อ:\n\n'
                '• แจ้งงานใหม่ที่ได้รับมอบหมาย\n'
                '• แจ้งการเปลี่ยนแปลงสถานะงาน\n'
                '• แจ้งข้อมูลสำคัญจากระบบ\n\n'
                'ท่านสามารถปิดการแจ้งเตือนได้ในการตั้งค่าของอุปกรณ์',
                fontProvider,
              ),

              _buildSection(
                '4. ความปลอดภัยของข้อมูล',
                'เรามีมาตรการรักษาความปลอดภัยของข้อมูล:\n\n'
                '• เข้ารหัสข้อมูลในการส่งผ่าน (SSL/TLS)\n'
                '• จัดเก็บข้อมูลในเซิร์ฟเวอร์ที่ปลอดภัย\n'
                '• จำกัดการเข้าถึงข้อมูลเฉพาะผู้ที่มีสิทธิ์\n'
                '• สำรองข้อมูลเป็นประจำ',
                fontProvider,
              ),

              _buildSection(
                '5. สิทธิของผู้ใช้งาน',
                'ท่านมีสิทธิ์ในการ:\n\n'
                '• เข้าถึงและตรวจสอบข้อมูลส่วนตัว\n'
                '• ขอแก้ไขข้อมูลที่ไม่ถูกต้อง\n'
                '• ขอลบข้อมูลส่วนตัว\n'
                '• ถอนความยินยอมการใช้ข้อมูล\n'
                '• ร้องเรียนกรณีการใช้ข้อมูลผิดวัตถุประสงค์',
                fontProvider,
              ),

              _buildSection(
                '6. การติดต่อ',
                'หากมีข้อสงสัยเกี่ยวกับการใช้ข้อมูลส่วนบุคคล สามารถติดต่อได้ที่:\n\n'
                'บริษัท JSolutionsNext\n'
                'อีเมล: support@jsolutionsnext.com\n'
                'โทรศัพท์: 02-XXX-XXXX',
                fontProvider,
              ),

              SizedBox(height: 32),

              // Important note
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'การกด "ยอมรับ" ถือว่าท่านได้อ่านและยินยอมให้เราเก็บรวบรวมและใช้ข้อมูลของท่านตามเงื่อนไขที่ระบุไว้ข้างต้น',
                        style: GoogleFonts.notoSansThai(
                          fontSize: fontProvider.getScaledFontSize(14.0),
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, String content, FontSizeProvider fontProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(18.0),
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(14.0),
            color: _textSecondary,
            height: 1.6,
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: Consumer<FontSizeProvider>(
          builder: (context, fontProvider, child) {
            return Text(
              'ข้อตกลงการใช้งาน',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(18.0),
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            );
          },
        ),
        automaticallyImplyLeading: false, // ไม่แสดงปุ่มย้อนกลับ
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildTermsContent(),
          ),
          
          // Bottom action area
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkbox
                Consumer<FontSizeProvider>(
                  builder: (context, fontProvider, child) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _isAccepted = !_isAccepted;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _isAccepted ? _primaryColor : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color: _isAccepted ? _primaryColor : Colors.transparent,
                              ),
                              child: _isAccepted
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ข้าพเจ้าได้อ่านและเข้าใจข้อตกลงและเงื่อนไขการใช้งาน และยินยอมให้เก็บรวบรวมและใช้ข้อมูลส่วนบุคคลตามที่ระบุไว้',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(14.0),
                                  color: _textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 16),

                // Accept button
                Consumer<FontSizeProvider>(
                  builder: (context, fontProvider, child) {
                    return Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _isAccepted
                            ? LinearGradient(
                                colors: [_primaryColor, _primaryVariant],
                              )
                            : null,
                        color: _isAccepted ? null : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: _isAccepted
                            ? [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isAccepted && !_isLoading ? _acceptTerms : null,
                          borderRadius: BorderRadius.circular(26),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: _isAccepted
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'ยอมรับและเริ่มใช้งาน',
                                        style: GoogleFonts.notoSansThai(
                                          color: _isAccepted
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          fontSize: fontProvider.getScaledFontSize(16.0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}