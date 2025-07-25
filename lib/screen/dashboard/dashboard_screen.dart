import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../service/local_storage.dart';
import '../../theme/app_theme.dart' as AppThemeConfig;
import '../../provider/font_size_provider.dart';
import 'job_card_list.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await LocalStorage.getProfile();
    print('📋 Loaded profile from storage: $profile');
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }
  

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'ออกจากระบบ',
              style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'คุณต้องการออกจากระบบหรือไม่?',
              style: GoogleFonts.notoSansThai(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ยกเลิก', style: GoogleFonts.notoSansThai()),
              ),
              ElevatedButton(
                onPressed: () async {
                  await LocalStorage.deleteProfile();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeConfig.AppColorScheme.light().error,
                ),
                child: Text(
                  'ออกจากระบบ',
                  style: GoogleFonts.notoSansThai(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHomeContent() {
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ThistruckOn',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(32.0),
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'ระบบจัดการรถบรรทุก',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(18.0),
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileContent() {
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: colors.primary,
                child: Icon(Icons.person, size: 50, color: colors.onPrimary),
              ),
              SizedBox(height: 20),
              Text(
                _userProfile?['user_name'] ?? 'ไม่ระบุชื่อ',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(24.0),
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _userProfile?['driver_type'] ?? 'ไม่ระบุตำแหน่ง',
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(16.0),
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 30),
              Card(
                child: ListTile(
                  leading: Icon(Icons.email_outlined, color: colors.primary),
                  title: Text(
                    'อีเมล',
                    style: GoogleFonts.notoSansThai(
                      fontWeight: FontWeight.w500,
                      fontSize: fontProvider.getScaledFontSize(16.0),
                    ),
                  ),
                  subtitle: Text(
                    _userProfile?['user_email'] ?? 'ไม่ระบุอีเมล',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.phone_outlined, color: colors.primary),
                  title: Text(
                    'ข้อมูลติดต่อ',
                    style: GoogleFonts.notoSansThai(
                      fontWeight: FontWeight.w500,
                      fontSize: fontProvider.getScaledFontSize(16.0),
                    ),
                  ),
                  subtitle: Text(
                    _userProfile?['contact_info']?.isNotEmpty == true
                        ? _userProfile!['contact_info']
                        : 'ไม่ระบุข้อมูลติดต่อ',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.badge_outlined, color: colors.primary),
                  title: Text(
                    'รหัสใบขับขี่',
                    style: GoogleFonts.notoSansThai(
                      fontWeight: FontWeight.w500,
                      fontSize: fontProvider.getScaledFontSize(16.0),
                    ),
                  ),
                  subtitle: Text(
                    _userProfile?['driver_license_number']?.isNotEmpty == true
                        ? _userProfile!['driver_license_number']
                        : 'ไม่ระบุรหัสใบขับขี่',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.work_outline, color: colors.primary),
                  title: Text(
                    'ประเภทพนักงาน',
                    style: GoogleFonts.notoSansThai(
                      fontWeight: FontWeight.w500,
                      fontSize: fontProvider.getScaledFontSize(16.0),
                    ),
                  ),
                  subtitle: Text(
                    _userProfile?['driver_type'] ?? 'ไม่ระบุประเภท',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildFontSizeSettings(),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout),
                label: Text(
                  'ออกจากระบบ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(16.0),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskContent() {
    return JobCardList();
  }

  Widget _buildFontSizeSettings() {
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_fields, color: colors.primary),
                    SizedBox(width: 12),
                    Text(
                      'ขนาดตัวอักษร',
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(16.0),
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'เลือกขนาดตัวอักษรที่ต้องการ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      fontProvider.fontSizeOptions.map((option) {
                        final isSelected =
                            fontProvider.fontSizeLevel == option['level'];
                        return FilterChip(
                          label: Text(
                            option['name'],
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(14.0),
                              color:
                                  isSelected
                                      ? colors.onPrimary
                                      : colors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              fontProvider.setFontSizeLevel(option['level']);
                            }
                          },
                          selectedColor: colors.primary,
                          backgroundColor: colors.surface,
                          side: BorderSide(
                            color: isSelected ? colors.primary : colors.divider,
                          ),
                        );
                      }).toList(),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Text(
                    'ตัวอย่าง: ขนาดตัวอักษร ${fontProvider.fontSizeName}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(16.0),
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getCurrentContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildTaskContent();
      case 2:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(
              _selectedIndex == 0
                  ? 'หน้าหลัก'
                  : _selectedIndex == 1
                  ? 'รายการงาน'
                  : 'จัดการโปรไฟล์',
              style: GoogleFonts.notoSansThai(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontSize: fontProvider.getScaledFontSize(18.0),
              ),
            ),
            backgroundColor: colors.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.bug_report,
                  color: colors.textSecondary,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notification-debug');
                },
                tooltip: 'Debug Notifications',
              ),
            ],
          ),
          body: _getCurrentContent(),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: colors.surface,
            selectedItemColor: colors.primary,
            unselectedItemColor: colors.textSecondary,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'หน้าหลัก',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'รายการงาน',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'จัดการโปรไฟล์',
              ),
            ],
            selectedLabelStyle: GoogleFonts.notoSansThai(
              fontSize: fontProvider.getScaledFontSize(12.0),
            ),
            unselectedLabelStyle: GoogleFonts.notoSansThai(
              fontSize: fontProvider.getScaledFontSize(12.0),
            ),
          ),
        );
      },
    );
  }
}

