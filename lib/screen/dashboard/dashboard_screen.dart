import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../service/local_storage.dart';
import '../../service/api_service.dart';
import '../../service/image_picker_service.dart';
import '../../service/firebase_storage_service.dart';
import '../../service/badge_service.dart';
import '../../theme/app_theme.dart' as AppThemeConfig;
import '../../provider/font_size_provider.dart';
import '../../widgets/profile_image_upload.dart';
import '../notifications/notifications_screen.dart';
import 'job_card_list.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;
  int _unreadNotificationCount = 0;
  List<dynamic> _todayJobs = [];
  bool _isLoadingTodayJobs = false;
  List<dynamic> _incompleteJobs = [];
  bool _isLoadingIncompleteJobs = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUnreadNotificationCount();
    _loadTodayJobs();
    _loadIncompleteJobs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // รีโหลด profile เมื่อกลับมาที่หน้านี้
    _loadUserProfile();
    _loadUnreadNotificationCount();
    _loadTodayJobs();
    _loadIncompleteJobs();
    
    // Reset badge when user returns to dashboard (app is in focus)
    _resetBadgeWhenAppInFocus();
  }

  Future<void> _resetBadgeWhenAppInFocus() async {
    // Only reset badge if user has actually seen notifications
    // by checking the unread count from server
    final profile = await LocalStorage.getProfile();
    if (profile != null && profile['id'] != null) {
      final count = await ApiService.getUnreadNotificationCount(profile['id']);
      await BadgeService.setBadgeCountFromAPI(count);
    }
  }

  /// รีเฟรชข้อมูลทั้งหมดในหน้า Dashboard
  Future<void> _refreshDashboardData() async {
    try {
      // แสดง loading indicator เล็กน้อย
      await Future.wait([
        _loadUserProfile(),
        _loadUnreadNotificationCount(),
        _loadTodayJobs(),
        _loadIncompleteJobs(),
      ]);
      
      // รอให้ animation เสร็จ
      await Future.delayed(Duration(milliseconds: 500));
      
      // แสดงข้อความสำเร็จเล็กน้อย
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ข้อมูลถูกอัปเดตแล้ว'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // หากเกิดข้อผิดพลาดในการรีเฟรช
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถอัปเดตข้อมูลได้'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await LocalStorage.getProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final profile = await LocalStorage.getProfile();
      if (profile != null && profile['id'] != null) {
        final int mobileUserId = profile['id'];
        final int count = await ApiService.getUnreadNotificationCount(mobileUserId);
        
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
        
        // Set badge count from API F=29 - this is the source of truth
        await BadgeService.setBadgeCountFromAPI(count);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  Future<void> _loadTodayJobs() async {
    try {
      setState(() {
        _isLoadingTodayJobs = true;
      });

      final profile = await LocalStorage.getProfile();
      if (profile != null && profile['driver_id'] != null) {
        final int driverId = int.parse(profile['driver_id'].toString());
        
        // เรียก Function 13 เพื่อดึงข้อมูลงานของ driver วันนี้
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        final result = await ApiService.getJobOrderTripsByDriverId(
          driverId,
          dateFrom: todayStr,
          dateTo: todayStr,
          limitRecords: 10,
        );
        
        
        if (result['success'] == true && result['trips'] != null) {
          final data = result['trips'];
          
          // ตรวจสอบว่ามีข้อมูลงานหรือไม่
          List<dynamic> jobs = [];
          
          
          if (data is List) {
            // ถ้า data เป็น List โดยตรง (รายการงาน) และกรองเฉพาะงานวันนี้
            jobs = data.where((job) {
              // กรองเฉพาะงานที่มี job_date เป็นวันนี้
              final String? jobDate = job['job_date']?.toString();
              if (jobDate == null) return false;
              
              // แปลงวันที่จาก API เป็นรูปแบบ yyyy-MM-dd
              try {
                DateTime jobDateTime;
                if (jobDate.length == 10) {
                  // รูปแบบ yyyy-MM-dd
                  jobDateTime = DateTime.parse(jobDate);
                } else if (jobDate.contains(' ')) {
                  // รูปแบบ yyyy-MM-dd HH:mm:ss
                  jobDateTime = DateTime.parse(jobDate.split(' ')[0]);
                } else {
                  return false;
                }
                
                // เปรียบเทียบเฉพาะวันที่ (ไม่รวมเวลา)
                final today = DateTime.now();
                return jobDateTime.year == today.year &&
                       jobDateTime.month == today.month &&
                       jobDateTime.day == today.day;
              } catch (e) {
                return false;
              }
            }).map((job) => {
              'id': job['id'] ?? job['tripNo'],
              'title': '${job['job_name'] ?? job['job_no'] ?? 'งานขนส่ง'}',
              'status': _mapJobStatus(job['status']),
              'time': _extractTime(job['jobStartDateTime']),
              'destination': 'สถานะ: ${job['status'] ?? 'ไม่ระบุสถานะ'}',
              'trip_date': job['job_date'],
              'random_code': job['random_code'],
              'job_no': job['job_no'],
              'trip_no': job['tripNo'],
            }).toList();
          } else {
            // ถ้า data ไม่ใช่ List ให้ใช้ข้อมูลทดสอบ
            jobs = [
              {
                'id': '1',
                'title': 'งานขนส่งสินค้า - บางนา',
                'status': 'pending',
                'time': '09:00',
                'destination': 'บางนา ไปยัง สมุทรปราการ'
              },
              {
                'id': '2', 
                'title': 'งานขนส่งสินค้า - ลาดกระบัง',
                'status': 'in_progress',
                'time': '14:00',
                'destination': 'ลาดกระบัง ไปยัง มีนบุรี'
              },
              {
                'id': '3',
                'title': 'งานขนส่งสินค้า - รามอินทรา',
                'status': 'pending',
                'time': '16:30',
                'destination': 'รามอินทรา ไปยัง สนามบิน'
              }
            ];
          }
            
          if (mounted) {
            setState(() {
              _todayJobs = jobs;
              _isLoadingTodayJobs = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _todayJobs = [];
              _isLoadingTodayJobs = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _todayJobs = [];
          _isLoadingTodayJobs = false;
        });
      }
    }
  }

  Future<void> _loadIncompleteJobs() async {
    try {
      setState(() {
        _isLoadingIncompleteJobs = true;
      });

      final profile = await LocalStorage.getProfile();
      if (profile != null && profile['driver_id'] != null) {
        final int driverId = int.parse(profile['driver_id'].toString());
        
        // เรียก Function 13 โดยไม่ระบุวันที่ เพื่อดึงงานทั้งหมดของ driver
        final result = await ApiService.getJobOrderTripsByDriverId(
          driverId,
          limitRecords: 50, // ดึงงานล่าสุด 50 งาน
        );
        
        
        if (result['success'] == true && result['trips'] != null) {
          final data = result['trips'];
          
          // กรองเฉพาะงานที่ยังไม่เสร็จ
          List<dynamic> jobs = [];
          
          if (data is List) {
            jobs = data.where((job) {
              final String status = job['status']?.toString() ?? '';
              
              // กรองออกสถานะที่เสร็จแล้ว
              return status != 'รอเจ้าหน้าที่ยืนยัน' && 
                     status != 'ยกเลิก' && 
                     status != 'คนขับยืนยันจบงานแล้ว' &&
                     status != 'จบงาน';
            }).map((job) => {
              'id': job['id'] ?? job['tripNo'],
              'title': '${job['job_name'] ?? job['job_no'] ?? 'งานขนส่ง'}',
              'status': _mapJobStatus(job['status']),
              'time': _extractTime(job['jobStartDateTime']),
              'destination': 'สถานะ: ${job['status'] ?? 'ไม่ระบุสถานะ'}',
              'trip_date': job['job_date'],
              'random_code': job['random_code'],
              'job_no': job['job_no'],
              'trip_no': job['tripNo'],
              'original_status': job['status'], // เก็บ status เดิมไว้ debug
            }).toList();
          }
          
          
          if (mounted) {
            setState(() {
              _incompleteJobs = jobs;
              _isLoadingIncompleteJobs = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _incompleteJobs = [];
              _isLoadingIncompleteJobs = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _incompleteJobs = [];
          _isLoadingIncompleteJobs = false;
        });
      }
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
                  Navigator.pop(context); // ปิด dialog ก่อน
                  
                  try {
                    // ดึง device ID และเรียก API เพื่อลบ device record
                    String? deviceId = await ApiService.getDeviceId();
                    if (deviceId != null) {
                      await ApiService.logoutAndRemoveDevice(deviceId);
                    }
                  } catch (e) {
                    // ไม่ให้ error นี้กระทบต่อการ logout
                  }
                  
                  // ลบ profile ในเครื่องและไปหน้า login
                  await LocalStorage.deleteProfile();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
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
        return RefreshIndicator(
          onRefresh: _refreshDashboardData,
          color: colors.primary,
          backgroundColor: colors.surface,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(), // ให้สามารถ scroll ได้เสมอ
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Section
                _buildUserProfileSection(colors, fontProvider),
                
                SizedBox(height: 24),
                
                // Action Buttons Section
                _buildActionButtonsSection(colors, fontProvider),
                
                SizedBox(height: 24),
                
                // Today's Jobs Section
                _buildTodayJobsSection(colors, fontProvider),
                
                SizedBox(height: 24),
                
                // Incomplete Jobs Section
                _buildIncompleteJobsSection(colors, fontProvider),
                
                SizedBox(height: 24),
                
                // Categories Section
                _buildCategoriesSection(colors, fontProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserProfileSection(colors, FontSizeProvider fontProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue[300]!, width: 2),
            ),
            child: ClipOval(
              child: _userProfile?['profile_image'] != null && 
                     _userProfile!['profile_image'].toString().isNotEmpty
                ? FadeInImage(
                    placeholder: MemoryImage(
                      // Create a simple 1x1 transparent placeholder
                      Uint8List.fromList([
                        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
                        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
                        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
                        0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
                        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
                        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
                      ])
                    ),
                    image: NetworkImage(_userProfile!['profile_image']),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration(milliseconds: 300),
                    fadeOutDuration: Duration(milliseconds: 100),
                    placeholderErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.blue[600],
                        ),
                      );
                    },
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.blue[600],
                        ),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blue[600],
                    ),
                  ),
            ),
          ),
          
          SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating Stars
                Row(
                  children: List.generate(5, (index) => Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  )),
                ),
                
                SizedBox(height: 8),
                
                // User Name
                Text(
                  _userProfile?['user_name'] ?? 'นายคนหนึ่ง โซ่ใฟ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(16.0),
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                
                SizedBox(height: 4),
                
                // User ID
                Text(
                  'OP${_userProfile?['driver_id']?.toString().padLeft(5, '0') ?? '00005'}',
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(14.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection(colors, FontSizeProvider fontProvider) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildActionButton(
          title: 'งานเดือนนี้',
          icon: Icons.assignment,
          color: Colors.grey[300]!,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('งานเดือนนี้')),
            );
          },
          fontProvider: fontProvider,
        ),
        _buildActionButton(
          title: 'เติมอีกจำนวน',
          icon: Icons.local_gas_station,
          color: Colors.grey[300]!,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เติมอีกจำนวน')),
            );
          },
          fontProvider: fontProvider,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required FontSizeProvider fontProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(14.0),
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayJobsSection(colors, FontSizeProvider fontProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'งานวันนี้',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(18.0),
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            if (_isLoadingTodayJobs)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        
        // แสดงข้อมูลงานจาก API
        if (_todayJobs.isEmpty && !_isLoadingTodayJobs)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.work_off, color: Colors.grey[500], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'ไม่มีงานในวันนี้',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._todayJobs.map((job) => GestureDetector(
            onTap: () => _onJobTap(job),
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getJobStatusColor(job['status']).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getJobStatusColor(job['status']),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getJobStatusIcon(job['status']),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job title
                        Text(
                          job['title'] ?? 'งานไม่ระบุชื่อ',
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(16.0),
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Status
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getJobStatusColor(job['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            job['destination'] ?? 'ไม่ระบุสถานะ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(12.0),
                              fontWeight: FontWeight.w700,
                              color: _getJobStatusColor(job['status']),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time badge
                  if (job['time'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _getJobStatusColor(job['status']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(height: 2),
                          Text(
                            job['time'],
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(12.0),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          )).toList(),
      ],
    );
  }

  IconData _getJobStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.work;
    }
  }

  Color _getJobStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange[600]!;
      case 'in_progress':
        return Colors.blue[600]!;
      case 'completed':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _mapJobStatus(String? status) {
    // แปลง status จาก API ให้เป็นรูปแบบที่ต้องการ
    if (status == null) return 'pending';
    
    // ตรวจสอบ status ภาษาไทย
    if (status.contains('เริ่ม') || status.contains('กำลัง')) {
      return 'in_progress';
    } else if (status.contains('เสร็จ') || status.contains('จบ') || status.contains('สำเร็จ')) {
      return 'completed';
    } else {
      // แปลง status ภาษาอังกฤษ
      switch (status.toLowerCase()) {
        case 'pending':
        case 'waiting':
        case 'scheduled':
          return 'pending';
        case 'in_progress':
        case 'ongoing':
        case 'started':
        case 'picked_up':
          return 'in_progress';
        case 'completed':
        case 'finished':
        case 'delivered':
          return 'completed';
        default:
          return 'pending';
      }
    }
  }

  String? _extractTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return null;
    
    try {
      // แปลง "2025-08-03 08:00:00" เป็น "08:00"
      final parts = dateTime.split(' ');
      if (parts.length >= 2) {
        final timePart = parts[1];
        final timeComponents = timePart.split(':');
        if (timeComponents.length >= 2) {
          return '${timeComponents[0]}:${timeComponents[1]}';
        }
      }
    } catch (e) {
      // Error extracting time
    }
    
    return null;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    
    try {
      // แปลง "2025-08-03" เป็น "03/08"
      final parts = dateString.split('-');
      if (parts.length >= 3) {
        return '${parts[2]}/${parts[1]}';
      }
    } catch (e) {
      // Error formatting date
    }
    
    return dateString;
  }

  void _onJobTap(Map<String, dynamic> job) {
    final String? randomCode = job['random_code'];
    
    if (randomCode != null && randomCode.isNotEmpty) {
      
      // Navigate to job detail screen with randomCode
      Navigator.pushNamed(
        context, 
        '/job-detail', 
        arguments: {
          'randomCode': randomCode,
        }
      );
    } else {
      
      // Show message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเข้าสู่รายละเอียดงานได้ ไม่พบรหัสงาน',
              style: GoogleFonts.notoSansThai(),
            ),
          ),
        );
      }
    }
  }

  Widget _buildIncompleteJobsSection(colors, FontSizeProvider fontProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'งานยังไม่เสร็จสิ้น',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(18.0),
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            if (_isLoadingIncompleteJobs)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        
        // แสดงข้อมูลงานที่ยังไม่เสร็จจาก API
        if (_incompleteJobs.isEmpty && !_isLoadingIncompleteJobs)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[500], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'ไม่มีงานค้าง งานทั้งหมดเสร็จสิ้นแล้ว',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._incompleteJobs.map((job) => GestureDetector(
            onTap: () => _onJobTap(job),
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getJobStatusColor(job['status']).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getJobStatusColor(job['status']),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getJobStatusIcon(job['status']),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job title
                        Text(
                          job['title'] ?? 'งานไม่ระบุชื่อ',
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(16.0),
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Status
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getJobStatusColor(job['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            job['destination'] ?? 'ไม่ระบุสถานะ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(12.0),
                              fontWeight: FontWeight.w700,
                              color: _getJobStatusColor(job['status']),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Date badge
                  if (job['trip_date'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _getJobStatusColor(job['status']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(height: 2),
                          Text(
                            _formatDate(job['trip_date']),
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(10.0),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildCategoriesSection(colors, FontSizeProvider fontProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ประเภท',
          style: GoogleFonts.notoSansThai(
            fontSize: fontProvider.getScaledFontSize(18.0),
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.yellow[200]!),
          ),
          child: Center(
            child: Text(
              'ประเภทต่างๆ',
              style: GoogleFonts.notoSansThai(
                fontSize: fontProvider.getScaledFontSize(16.0),
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
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
              ProfileImageUpload(
                userProfile: _userProfile,
                onImageUpdated: () {
                  // Reload profile after image update
                  _loadUserProfile();
                },
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // เรียก ImagePickerService ตรงๆ แล้วทำการ upload (image_picker will handle permissions automatically)
                    final File? imageFile = await ImagePickerService.pickProfileImage(context);
                    
                    if (imageFile != null && mounted) {
                      // เรียก upload method (จำลองจาก ProfileImageUpload)
                      _handleDashboardImageUpload(imageFile);
                    }
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text(
                    'อัพโหลดรูปโปรไฟล์',
                    style: GoogleFonts.notoSansThai(
                      fontSize: fontProvider.getScaledFontSize(14.0),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
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

  Future<void> _handleDashboardImageUpload(File imageFile) async {
    try {
      // Get driver ID
      final String? driverId = _userProfile?['driver_id']?.toString();
      
      if (driverId == null) {
        return;
      }
      
      // Upload to Firebase Storage
      final uploadResult = await FirebaseStorageService.uploadProfileImage(
        imageFile: imageFile,
        driverId: driverId,
      );
      
      if (uploadResult['success']) {
        // Update database with new image URL
        final String imageUrl = uploadResult['downloadUrl'];
        
        final apiResult = await ApiService.updateProfileImage(
          driverId: driverId,
          imageUrl: imageUrl,
        );
        
        if (apiResult['success']) {
          // Update local storage with new profile data
          if (apiResult['profile_data'] != null) {
            await LocalStorage.saveProfile(apiResult['profile_data']);
          }
          
          // Reload profile
          _loadUserProfile();
        }
      }
    } catch (e) {
      // Silent error handling
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
                  : 'รายการงาน',
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
              // Notification button
              IconButton(
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: colors.primary,
                      size: 28,
                    ),
                    // Unread count badge
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            _unreadNotificationCount > 99 
                                ? '99+' 
                                : '$_unreadNotificationCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () async {
                  // Navigate to notifications screen and refresh count when returning
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(),
                    ),
                  );
                  
                  // Refresh unread count when returning from notifications screen
                  _loadUnreadNotificationCount();
                },
                tooltip: 'การแจ้งเตือน',
              ),
              // Profile button
              IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: colors.primary,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
                tooltip: 'จัดการโปรไฟล์',
              ),
            ],
          ),
          body: _getCurrentContent(),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: colors.surface,
            selectedItemColor: colors.primary,
            unselectedItemColor: colors.textSecondary,
            currentIndex: _selectedIndex > 1 ? 1 : _selectedIndex,
            onTap: (index) {
              if (index < 2) {
                _onItemTapped(index);
              }
            },
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

