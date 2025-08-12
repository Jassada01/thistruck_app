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
              
              SizedBox(height: 16),
              
              Text(
                'แอปพลิเคชัน "This Truck" ระบบบริหารจัดการงานขนส่งตู้คอนเทนเนอร์',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),
              
              Text(
                'วันที่มีผลบังคับใช้: ${_getCurrentDate()}',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(14.0),
                  color: _textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Terms content
              _buildSection(
                '1. ข้อมูลทั่วไป',
                'This Truck เป็นแอปพลิเคชันที่พัฒนาโดย บริษัท เจโซลูชั่นส์เน็กซ์ จำกัด เพื่อใช้ในการบริหารจัดการงานขนส่งตู้คอนเทนเนอร์ โดยเฉพาะสำหรับคนขับรถ เจ้าหน้าที่ และผู้ควบคุมงานขนส่ง\n\n'
                'การใช้งานแอปพลิเคชันนี้ ถือว่าท่านยอมรับข้อตกลงและเงื่อนไขทั้งหมดที่ระบุไว้',
                fontProvider,
              ),

              _buildSection(
                '2. การเก็บรวบรวมข้อมูลส่วนบุคคล',
                'เราจะเก็บรวบรวมข้อมูลดังต่อไปนี้:\n\n'
                '2.1 ข้อมูลบัญชีผู้ใช้:\n'
                '• ชื่อ-นามสกุล, หมายเลขโทรศัพท์\n'
                '• รหัสผ่านแอป (Passcode) ที่ท่านตั้งไว้\n'
                '• รูปโปรไฟล์ (หากมีการอัปโหลด)\n\n'
                '2.2 ข้อมูลการทำงาน:\n'
                '• ข้อมูลรถที่รับผิดชอบ (ทะเบียน, ประเภทรถ)\n'
                '• รายการงานขนส่งที่ได้รับมอบหมาย\n'
                '• สถานะการทำงาน และรายงานผลงาน\n'
                '• ข้อมูลการเติมน้ำมันและค่าใช้จ่าย\n\n'
                '2.3 ข้อมูลตำแหน่ง: ข้อมูล GPS เมื่อจำเป็นสำหรับการปฏิบัติงาน\n\n'
                '2.4 ข้อมูลอุปกรณ์:\n'
                '• ข้อมูลโทรศัพท์มือถือ (ยี่ห้อ, รุ่น, OS)\n'
                '• Token สำหรับการส่งแจ้งเตือน',
                fontProvider,
              ),

              _buildSection(
                '3. วัตถุประสงค์การใช้ข้อมูล',
                'ข้อมูลที่เก็บรวบรวมจะใช้เพื่อ:\n\n'
                '3.1 การจัดการงาน:\n'
                '• มอบหมายงานขนส่งและติดตามความคืบหน้า\n'
                '• บันทึกและรายงานผลการทำงาน\n'
                '• จัดการข้อมูลรถและคนขับ\n\n'
                '3.2 การสื่อสาร:\n'
                '• ส่งแจ้งเตือนงานใหม่และการเปลี่ยนแปลง\n'
                '• ประชาสัมพันธ์ข้อมูลสำคัญจากบริษัท\n'
                '• ติดต่อสื่อสารในเรื่องงาน\n\n'
                '3.3 การปรับปรุงบริการ:\n'
                '• วิเคราะห์การใช้งานเพื่อพัฒนาระบบ\n'
                '• รายงานสถิติและข้อมูลเชิงวิเคราะห์\n'
                '• แก้ไขปัญหาและข้อบกพร่อง\n\n'
                '3.4 ความปลอดภัย:\n'
                '• ตรวจสอบตัวตนผู้ใช้งาน\n'
                '• ป้องกันการใช้งานโดยไม่ได้รับอนุญาต',
                fontProvider,
              ),


              _buildSection(
                '4. การแจ้งเตือน (Push Notifications)',
                '4.1 ประเภทการแจ้งเตือน:\n'
                '• งานใหม่ที่ได้รับมอบหมาย\n'
                '• การเปลี่ยนแปลงรายละเอียดงาน\n'
                '• การอนุมัติเอกสารและรายงาน\n'
                '• ข้อมูลสำคัญจากฝ่ายจัดการ\n'
                '• การแจ้งเตือนด้านความปลอดภัย\n\n'
                '4.2 การจัดการการแจ้งเตือน:\n'
                '• ท่านสามารถเปิด/ปิดการแจ้งเตือนได้\n'
                '• สามารถเลือกประเภทการแจ้งเตือนที่ต้องการ\n'
                '• การตั้งค่าแจ้งเตือนไม่ส่งผลต่อการทำงาน',
                fontProvider,
              ),

              _buildSection(
                '5. ความปลอดภัยและการเก็บรักษาข้อมูล',
                '5.1 มาตรการรักษาความปลอดภัย:\n'
                '• เข้ารหัสข้อมูลด้วย SSL/TLS 256-bit\n'
                '• เซิร์ฟเวอร์มีการสำรองข้อมูลทุก 24 ชั่วโมง\n'
                '• ระบบตรวจจับการเข้าถึงผิดปกติ\n'
                '• การยืนยันตัวตนด้วย Passcode\n\n'
                '5.2 ระยะเวลาเก็บรักษาข้อมูล:\n'
                '• ข้อมูลงาน: เก็บไว้ 3 ปี เพื่อการอ้างอิง\n'
                '• ข้อมูลตำแหน่ง: ลบอัตโนมัติเมื่อไม่จำเป็น\n'
                '• ข้อมูลส่วนตัว: เก็บตลอดระยะเวลาการทำงาน\n'
                '• รูปภาพ: เก็บไว้ 1 ปี หลังจากส่งงาน',
                fontProvider,
              ),

              _buildSection(
                '6. สิทธิของผู้ใช้งาน',
                'ตามกฎหมายคุ้มครองข้อมูลส่วนบุคคล ท่านมีสิทธิ:\n\n'
                '6.1 สิทธิในการเข้าถึง:\n'
                '• ดูข้อมูลส่วนตัวที่เราเก็บรักษาไว้\n'
                '• ขอสำเนาข้อมูลในรูปแบบที่อ่านได้\n\n'
                '6.2 สิทธิในการแก้ไข:\n'
                '• แก้ไขข้อมูลส่วนตัวที่ไม่ถูกต้อง\n'
                '• อัปเดตข้อมูลให้เป็นปัจจุบัน\n\n'
                '6.3 สิทธิในการลบข้อมูล:\n'
                '• ขอลบข้อมูลส่วนตัว (ยกเว้นข้อมูลที่กฎหมายกำหนด)\n'
                '• ยกเลิกบัญชีผู้ใช้งานโดยแจ้งกับเจ้าหน้าที่\n\n'
                '6.4 สิทธิในการคัดค้าน:\n'
                '• คัดค้านการใช้ข้อมูลในบางวัตถุประสงค์\n'
                '• ถอนความยินยอม (อาจส่งผลต่อการใช้งาน)',
                fontProvider,
              ),

              _buildSection(
                '7. ข้อจำกัดการใช้งาน',
                '7.1 ห้ามใช้แอปพลิเคชันเพื่อ:\n'
                '• กิจกรรมที่ผิดกฎหมาย\n'
                '• ส่งข้อมูลเท็จหรือหลอกลวง\n'
                '• รบกวนหรือทำอันตรายต่อระบบ\n'
                '• แชร์บัญชีให้บุคคลอื่นใช้งาน\n\n'
                '7.2 การละเมิดข้อตกลง:\n'
                '• บัญชีอาจถูกระงับหรือยกเลิก\n'
                '• ดำเนินการทางกฎหมาย (หากจำเป็น)\n'
                '• แจ้งหน่วยงานที่เกี่ยวข้อง',
                fontProvider,
              ),

              _buildSection(
                '8. การแก้ไขข้อตกลง',
                '8.1 การปรับปรุงข้อตกลง:\n'
                '• บริษัทสงวนสิทธิ์แก้ไขข้อตกลงได้ตามความเหมาะสม\n'
                '• จะแจ้งให้ทราบล่วงหน้าอย่างน้อย 30 วัน\n'
                '• การใช้งานต่อหลังการแจ้ง ถือว่ายอมรับข้อตกลงใหม่\n\n'
                '8.2 วิธีการแจ้ง:\n'
                '• แจ้งเตือนผ่านแอปพลิเคชัน\n'
                '• ประกาศในเว็บไซต์บริษัท',
                fontProvider,
              ),

              _buildSection(
                '9. การติดต่อและร้องเรียน',
                '9.1 ติดต่อเรื่องข้อมูลส่วนบุคคล:\n'
                'บริษัท เจโซลูชั่นส์เน็กซ์ จำกัด\n'
                'อีเมล: jassadaporn@jsolutionsnext.com\n'
                'โทรศัพท์: 091-872-1062\n'
                'เวลาติดต่อ: จันทร์-ศุกร์ 08:00-17:00 น.\n\n'
                '9.2 การร้องเรียน:\n'
                '• กรอกแบบฟอร์มร้องเรียนที่เว็บไซต์\n'
                '• ส่งอีเมลพร้อมระบุรายละเอียด\n'
                '• โทรติดต่อในเวลาทำการ\n\n'
                '9.3 ระยะเวลาตอบกลับ: ภายใน 15 วันทำการ',
                fontProvider,
              ),

              SizedBox(height: 32),

              // Version and effective date
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'ข้อตกลงฉบับนี้มีผลบังคับใช้ตั้งแต่วันที่ ${_getCurrentDate()}',
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(12.0),
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'เวอร์ชัน 2.0.0',
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(11.0),
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Important note
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
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
                        'การกด "ยอมรับและเริ่มใช้งาน" หมายความว่าท่านได้อ่านและเข้าใจข้อตกลงทั้งหมด และยินยอมให้เราดำเนินการตามที่ระบุไว้ข้างต้น',
                        style: GoogleFonts.notoSansThai(
                          fontSize: fontProvider.getScaledFontSize(14.0),
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
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
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: GoogleFonts.notoSansThai(
              fontSize: fontProvider.getScaledFontSize(16.0),
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
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

  String _getCurrentDate() {
    return '8 สิงหาคม 2568';
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
                  color: Colors.black.withValues(alpha: 0.1),
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
                                'ข้าพเจ้าได้อ่านและเข้าใจข้อตกลงและเงื่อนไขการใช้งานแล้ว และยินยอมตามวัตถุประสงค์ที่ระบุไว้',
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
                                  color: _primaryColor.withValues(alpha: 0.3),
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