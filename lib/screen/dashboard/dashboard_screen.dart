import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../service/local_storage.dart';
import '../../service/api_service.dart';
import '../../theme/app_theme.dart' as AppThemeConfig;
import '../../provider/font_size_provider.dart';

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
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return _JobOrderTripsList();
      },
    );
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

class _JobOrderTripsList extends StatefulWidget {
  @override
  _JobOrderTripsListState createState() => _JobOrderTripsListState();
}

class _JobOrderTripsListState extends State<_JobOrderTripsList> {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _filteredTrips = [];
  String _errorMessage = '';
  Map<String, dynamic>? _userProfile;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // ไม่ทำ infinite scroll ถ้ากำลังค้นหา
    if (_searchQuery.isNotEmpty) return;
    
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreTrips();
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

    if (profile != null && profile['driver_id'] != null) {
      _loadJobOrderTrips();
    }
  }

  Future<void> _loadJobOrderTrips() async {
    if (_userProfile == null || _userProfile!['driver_id'] == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'ไม่พบข้อมูลคนขับรถ';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _currentPage = 0;
        _trips.clear();
        _hasMoreData = true;
      });
    }

    try {
      final driverId = _userProfile!['driver_id'];
      
      final result = await ApiService.getJobOrderTripsByDriverId(
        driverId,
        limitRecords: _pageSize,
      );

      if (result['success']) {
        final newTrips = List<Map<String, dynamic>>.from(result['trips'] ?? []);
        setState(() {
          _trips = newTrips;
          _filteredTrips = newTrips;
          _isLoading = false;
          _hasMoreData = newTrips.length >= _pageSize;
          if (_hasMoreData) _currentPage = 1;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTrips() async {
    if (_userProfile == null || _userProfile!['driver_id'] == null || !_hasMoreData) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final driverId = _userProfile!['driver_id'];
      
      // คำนวณ offset สำหรับ pagination
      final offset = _currentPage * _pageSize;
      
      final result = await ApiService.getJobOrderTripsByDriverId(
        driverId,
        limitRecords: _pageSize,
        offsetRecords: offset,
      );

      if (result['success']) {
        final newTrips = List<Map<String, dynamic>>.from(result['trips'] ?? []);
        setState(() {
          _trips.addAll(newTrips);
          _filteredTrips = _searchQuery.isEmpty ? _trips : _filterTrips(_trips, _searchQuery);
          _isLoadingMore = false;
          _hasMoreData = newTrips.length >= _pageSize;
          if (newTrips.isNotEmpty) _currentPage++;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // ฟังก์ชันกรองข้อมูลตามคำค้นหา
  List<Map<String, dynamic>> _filterTrips(List<Map<String, dynamic>> trips, String query) {
    if (query.isEmpty) return trips;
    
    final lowerQuery = query.toLowerCase();
    return trips.where((trip) {
      // ค้นหาใน JOB NO
      final jobNo = (trip['job_no'] ?? '').toString().toLowerCase();
      if (jobNo.contains(lowerQuery)) return true;
      
      // ค้นหาใน TRIP NO
      final tripNo = (trip['tripNo'] ?? '').toString().toLowerCase();
      if (tripNo.contains(lowerQuery)) return true;
      
      // ค้นหาในชื่องาน
      final jobName = (trip['job_name'] ?? '').toString().toLowerCase();
      if (jobName.contains(lowerQuery)) return true;
      
      // ค้นหาในชื่อลูกค้า
      final customerName = (trip['customer_name'] ?? '').toString().toLowerCase();
      if (customerName.contains(lowerQuery)) return true;
      
      // ค้นหาในชื่อผู้ว่าจ้าง
      final clientName = (trip['client_name'] ?? '').toString().toLowerCase();
      if (clientName.contains(lowerQuery)) return true;
      
      // ค้นหาในประเภทงาน
      final jobType = (trip['job_type'] ?? '').toString().toLowerCase();
      if (jobType.contains(lowerQuery)) return true;
      
      // ค้นหาในชื่อคนขับ
      final driverName = (trip['driver_name'] ?? '').toString().toLowerCase();
      if (driverName.contains(lowerQuery)) return true;
      
      // ค้นหาในทะเบียนรถ
      final truckLicenseNo = (trip['truck_licenseNo'] ?? '').toString().toLowerCase();
      if (truckLicenseNo.contains(lowerQuery)) return true;
      
      // ค้นหาในสถานะ
      final status = (trip['status'] ?? '').toString().toLowerCase();
      if (status.contains(lowerQuery)) return true;
      
      // ค้นหาในเลขงานลูกค้า
      final customerJobNo = (trip['customer_job_no'] ?? '').toString().toLowerCase();
      if (customerJobNo.contains(lowerQuery)) return true;
      
      // ค้นหาในเลข PO ลูกค้า
      final customerPoNo = (trip['customer_po_no'] ?? '').toString().toLowerCase();
      if (customerPoNo.contains(lowerQuery)) return true;
      
      // ค้นหาในเลขใบแจ้งหนี้ลูกค้า
      final customerInvoiceNo = (trip['customer_invoice_no'] ?? '').toString().toLowerCase();
      if (customerInvoiceNo.contains(lowerQuery)) return true;
      
      // ค้นหาในรายละเอียดสินค้า
      final goods = (trip['goods'] ?? '').toString().toLowerCase();
      if (goods.contains(lowerQuery)) return true;
      
      // ค้นหาในเลขบุ๊คกิ้ง
      final booking = (trip['booking'] ?? '').toString().toLowerCase();
      if (booking.contains(lowerQuery)) return true;
      
      // ค้นหาในเลข Bill of Lading
      final billOfLading = (trip['bill_of_lading'] ?? '').toString().toLowerCase();
      if (billOfLading.contains(lowerQuery)) return true;
      
      // ค้นหาในชื่อเอเจนต์
      final agent = (trip['agent'] ?? '').toString().toLowerCase();
      if (agent.contains(lowerQuery)) return true;
      
      // ค้นหาในจำนวนสินค้า
      final quantity = (trip['quantity'] ?? '').toString().toLowerCase();
      if (quantity.contains(lowerQuery)) return true;
      
      // ค้นหาในเบอร์ตู้ - ลองหาจากหลาย field
      String containerId = '';
      if (trip['container_id'] != null) {
        containerId = trip['container_id'].toString();
      } else if (trip['containerID'] != null) {
        containerId = trip['containerID'].toString();
      } else if (trip['CONTAINER_ID'] != null) {
        containerId = trip['CONTAINER_ID'].toString();
      } else if (trip['containerId'] != null) {
        containerId = trip['containerId'].toString();
      } else if (trip['containerid'] != null) {
        containerId = trip['containerid'].toString();
      } else if (trip['container'] != null) {
        containerId = trip['container'].toString();
      } else if (trip['cntr_no'] != null) {
        containerId = trip['cntr_no'].toString();
      } else if (trip['cntr_id'] != null) {
        containerId = trip['cntr_id'].toString();
      }
      
      if (containerId.toLowerCase().contains(lowerQuery)) return true;
      
      // ค้นหาในเลขตู้คอนเทนเนอร์
      final containerNo = (trip['container_no'] ?? '').toString().toLowerCase();
      if (containerNo.contains(lowerQuery)) return true;
      
      // ค้นหาในเลขซีล
      final sealNo = (trip['seal_no'] ?? '').toString().toLowerCase();
      if (sealNo.contains(lowerQuery)) return true;
      
      return false;
    }).toList();
  }

  // ฟังก์ชันอัพเดทการค้นหา
  void _onSearchChanged(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
        _filteredTrips = _filterTrips(_trips, query);
      });
    }
  }

  // ฟังก์ชันเคลียร์การค้นหา
  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _searchQuery = '';
        _filteredTrips = _trips;
      });
    }
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return GestureDetector(
          onTap: () {
            if (trip['random_code'] != null) {
              Navigator.pushNamed(
                context,
                '/job-detail',
                arguments: {
                  'randomCode': trip['random_code'],
                  'jobNo': trip['job_no'] ?? 'ไม่ระบุ',
                  'tripNo': trip['tripNo'] ?? 'ไม่ระบุ',
                },
              );
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  // Job order header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.7),
                          colors.primary.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THISTRUCK TRANSPORT',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(
                                    12.0,
                                  ),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'ใบงานขนส่ง',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(
                                    10.0,
                                  ),
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(trip['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            trip['status'] ?? 'ไม่ระบุ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(10.0),
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Perforated border effect
                  Container(
                    height: 20,
                    child: Row(
                      children: List.generate(
                        20,
                        (index) => Expanded(
                          child: Container(
                            height: 1,
                            margin: EdgeInsets.symmetric(horizontal: 2),
                            color:
                                index % 2 == 0
                                    ? Colors.grey[300]
                                    : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Ticket body
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Job No and Trip No section
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'JOB NO.',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: fontProvider
                                            .getScaledFontSize(10.0),
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      trip['job_no'] ?? 'ไม่ระบุ',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: fontProvider
                                            .getScaledFontSize(16.0),
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.warning.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colors.warning.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TRIP NO.',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: fontProvider
                                            .getScaledFontSize(10.0),
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      trip['tripNo'] ?? 'ไม่ระบุ',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: fontProvider
                                            .getScaledFontSize(16.0),
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Route information
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Basic job information
                              _buildTicketInfoRow(
                                label: 'ชื่องาน',
                                value: trip['job_name'] ?? 'ไม่ระบุ',
                                icon: Icons.work,
                                colors: colors,
                                fontProvider: fontProvider,
                              ),
                              SizedBox(height: 8),
                              _buildTicketInfoRow(
                                label: 'ลูกค้า',
                                value: trip['customer_name'] ?? 'ไม่ระบุ',
                                icon: Icons.business,
                                colors: colors,
                                fontProvider: fontProvider,
                              ),
                              SizedBox(height: 8),
                              _buildTicketInfoRow(
                                label: 'ประเภท',
                                value: trip['job_type'] ?? 'ไม่ระบุ',
                                icon: Icons.category,
                                colors: colors,
                                fontProvider: fontProvider,
                              ),
                              SizedBox(height: 8),
                              _buildTicketInfoRow(
                                label: 'วันเริ่มงาน',
                                value: _formatDateTime(
                                  trip['jobStartDateTime'],
                                ),
                                icon: Icons.schedule,
                                colors: colors,
                                fontProvider: fontProvider,
                              ),
                              
                              // Customer Information (only show if has data)
                              ...(_buildCustomerInfoRows(trip, colors, fontProvider)),
                              
                              // Cargo/Shipment Information (only show if has data)
                              ...(_buildCargoInfoRows(trip, colors, fontProvider)),
                              
                              // Container Information (only show if has data)
                              ...(_buildContainerInfoRows(trip, colors, fontProvider)),
                            ],
                          ),
                        ),

                        // Latest status (if available)
                        if (trip['latest_action'] != null) ...[
                          SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.success.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.success.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: colors.success,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'สถานะปัจจุบัน',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: fontProvider
                                              .getScaledFontSize(10.0),
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        trip['job_status'] ??
                                            'ไม่ระบุ',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: fontProvider
                                              .getScaledFontSize(12.0),
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Job order footer
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Text(
                      'ใบงานนี้สร้างเมื่อ ${_formatDateTime(trip['create_date'])} • สร้างโดย ${trip['create_user'] ?? 'ระบบ'}',
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(9.0),
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
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

  // Helper function to build customer information rows (only if data exists)
  List<Widget> _buildCustomerInfoRows(Map<String, dynamic> trip, dynamic colors, dynamic fontProvider) {
    List<Widget> rows = [];
    
    // Customer Job No
    if (trip['customer_job_no'] != null && trip['customer_job_no'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'เลขงานลูกค้า',
          value: trip['customer_job_no'],
          icon: Icons.receipt_long,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    // Customer PO No
    if (trip['customer_po_no'] != null && trip['customer_po_no'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'เลข PO',
          value: trip['customer_po_no'],
          icon: Icons.description,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    // Customer Invoice No
    if (trip['customer_invoice_no'] != null && trip['customer_invoice_no'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'เลขใบแจ้งหนี้',
          value: trip['customer_invoice_no'],
          icon: Icons.payment,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    return rows;
  }

  // Helper function to build cargo information rows (only if data exists)
  List<Widget> _buildCargoInfoRows(Map<String, dynamic> trip, dynamic colors, dynamic fontProvider) {
    List<Widget> rows = [];
    
    // Goods
    if (trip['goods'] != null && trip['goods'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'สินค้า',
          value: trip['goods'],
          icon: Icons.inventory_2,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    // Booking
    if (trip['booking'] != null && trip['booking'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'บุ๊คกิ้ง',
          value: trip['booking'],
          icon: Icons.book_online,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    // Bill of Lading
    if (trip['bill_of_lading'] != null && trip['bill_of_lading'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'Bill of Lading',
          value: trip['bill_of_lading'],
          icon: Icons.article,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    // Agent
    if (trip['agent'] != null && trip['agent'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'เอเจนต์',
          value: trip['agent'],
          icon: Icons.support_agent,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    // Quantity
    if (trip['quantity'] != null && trip['quantity'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'จำนวน',
          value: trip['quantity'],
          icon: Icons.numbers,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    return rows;
  }

  // Helper function to build container information rows (only if data exists)
  List<Widget> _buildContainerInfoRows(Map<String, dynamic> trip, dynamic colors, dynamic fontProvider) {
    List<Widget> rows = [];
    
    // Debug: ตรวจสอบ keys ทั้งหมดที่มี container
    print('=== DEBUG Container Fields ===');
    trip.keys.where((key) => key.toLowerCase().contains('container')).forEach((key) {
      print('Container key: $key = ${trip[key]}');
    });
    print('================================');
    
    // Container ID (เบอร์ตู้) - ลองหาจากหลาย field ที่เป็นไปได้
    String? containerId;
    if (trip['container_id'] != null && trip['container_id'].toString().isNotEmpty) {
      containerId = trip['container_id'].toString();
    } else if (trip['containerID'] != null && trip['containerID'].toString().isNotEmpty) {
      containerId = trip['containerID'].toString();
    } else if (trip['CONTAINER_ID'] != null && trip['CONTAINER_ID'].toString().isNotEmpty) {
      containerId = trip['CONTAINER_ID'].toString();
    } else if (trip['containerId'] != null && trip['containerId'].toString().isNotEmpty) {
      containerId = trip['containerId'].toString();
    } else if (trip['containerid'] != null && trip['containerid'].toString().isNotEmpty) {
      containerId = trip['containerid'].toString();
    } else if (trip['container'] != null && trip['container'].toString().isNotEmpty) {
      containerId = trip['container'].toString();
    } else if (trip['cntr_no'] != null && trip['cntr_no'].toString().isNotEmpty) {
      containerId = trip['cntr_no'].toString();
    } else if (trip['cntr_id'] != null && trip['cntr_id'].toString().isNotEmpty) {
      containerId = trip['cntr_id'].toString();
    }
    
    if (containerId != null) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'เบอร์ตู้',
          value: containerId,
          icon: Icons.view_in_ar,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    // Container No
    if (trip['container_no'] != null && trip['container_no'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'เลขตู้',
          value: trip['container_no'],
          icon: Icons.inventory,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    // Seal No
    if (trip['seal_no'] != null && trip['seal_no'].toString().isNotEmpty) {
      rows.addAll([
        SizedBox(height: 8),
        _buildTicketInfoRow(
          label: 'เลขซีล',
          value: trip['seal_no'],
          icon: Icons.lock,
          colors: colors,
          fontProvider: fontProvider,
        ),
      ]);
    }
    
    return rows;
  }

  Widget _buildTicketInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required dynamic colors,
    required dynamic fontProvider,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(11.0),
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.notoSansThai(
                    fontSize: fontProvider.getScaledFontSize(11.0),
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    final colors = AppThemeConfig.AppColorScheme.light();
    if (status == null) return colors.textSecondary;

    final statusLower = status.toLowerCase();

    // 🔴 RED - Error/Cancel/Suspended states
    if (statusLower.contains('ยกเลิก') ||
        statusLower.contains('ระงับชั่วคราว') ||
        statusLower.contains('cancelled') ||
        statusLower.contains('cancel')) {
      return colors.error; // Red
    }
    
    // 🟠 ORANGE - Waiting/Pending states
    else if (statusLower.contains('รอเจ้าหน้าที่ยืนยัน') ||
             statusLower.contains('รอ') ||
             statusLower.contains('draft')) {
      return colors.warning; // Orange/Amber
    }
    
    // 🟢 GREEN - Completed/Success states
    else if (statusLower.contains('ดำเนินการเสร็จ') ||
             statusLower.contains('ออกจากสถานที่แล้ว') ||
             statusLower.contains('จบงาน') ||
             statusLower.contains('คนขับยืนยันจบงานแล้ว') ||
             statusLower.contains('เสร็จสิ้น') ||
             statusLower.contains('completed') ||
             statusLower.contains('complete')) {
      return colors.success; // Green
    }
    
    // 🔵 BLUE - In Progress/Active states
    else if (statusLower.contains('กำลังดำเนินการ') ||
             statusLower.contains('เริ่มดำเนินการ') ||
             statusLower.contains('in_progress') ||
             statusLower.contains('active')) {
      return Color(0xFF2196F3); // Blue
    }
    
    // 🟣 PURPLE - Arrived/Location-based states
    else if (statusLower.contains('เข้าสถานที่แล้ว')) {
      return Color(0xFF9C27B0); // Purple
    }
    
    // 🟡 YELLOW - Confirmation states
    else if (statusLower.contains('เจ้าหน้าที่ยืนยันแล้ว') ||
             statusLower.contains('คนขับยืนยันแล้ว') ||
             statusLower.contains('ยืนยันเริ่มงานแล้ว')) {
      return Color(0xFFFFC107); // Amber/Yellow
    }
    
    // 🟢 TEAL - Container/Cargo specific operations
    else if (statusLower.contains('รับตู้หนัก') ||
             statusLower.contains('รับตู้เปล่า') ||
             statusLower.contains('คืนตู้หนัก') ||
             statusLower.contains('คืนตู้เปล่า')) {
      return Color(0xFF009688); // Teal
    }
    
    // 🔵 INDIGO - Delivery/Pickup operations
    else if (statusLower.contains('ส่งสินค้า') ||
             statusLower.contains('รับสินค้า')) {
      return Color(0xFF3F51B5); // Indigo
    }
    
    // 🟫 BROWN - Other operations
    else if (statusLower.contains('อื่นๆ')) {
      return Color(0xFF8D6E63); // Brown
    }

    return colors.primary; // Default fallback
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'ไม่ระบุเวลา';

    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return RefreshIndicator(
          onRefresh: _loadJobOrderTrips,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Title Row
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          color: colors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'รายการงานของคุณ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(18.0),
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (_trips.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_filteredTrips.length}/${_trips.length}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: fontProvider.getScaledFontSize(12.0),
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Search Bar
                    if (_trips.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.notoSansThai(
                            fontSize: fontProvider.getScaledFontSize(14.0),
                          ),
                          decoration: InputDecoration(
                            hintText: 'ค้นหาใบงาน, ลูกค้า, เลขตู้, เลขซีล, บุ๊คกิ้ง...',
                            hintStyle: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(14.0),
                              color: colors.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: colors.textSecondary,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: colors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Content
              Expanded(
                child:
                    _isLoading
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: colors.primary),
                              SizedBox(height: 16),
                              Text(
                                'กำลังโหลดข้อมูล...',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(
                                    16.0,
                                  ),
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                        : _errorMessage.isNotEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: colors.error,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(
                                    16.0,
                                  ),
                                  color: colors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadJobOrderTrips,
                                icon: Icon(Icons.refresh),
                                label: Text(
                                  'ลองใหม่',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: fontProvider.getScaledFontSize(
                                      14.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        : _trips.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: colors.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'ยังไม่มีรายการงาน',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(
                                    18.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'รายการงานจะแสดงที่นี่เมื่อมีงานใหม่',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(
                                    14.0,
                                  ),
                                  color: colors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : _filteredTrips.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: colors.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'ไม่พบผลลัพธ์',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(
                                    18.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'ไม่พบรายการงานที่ตรงกับ "$_searchQuery"',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(
                                    14.0,
                                  ),
                                  color: colors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _clearSearch,
                                icon: Icon(Icons.clear_all),
                                label: Text(
                                  'ล้างการค้นหา',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: fontProvider.getScaledFontSize(
                                      14.0,
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount: _filteredTrips.length + (_isLoadingMore && _searchQuery.isEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _filteredTrips.length) {
                              // แสดง loading indicator ที่ท้ายรายการ
                              return Container(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                      ),
                                      SizedBox(height: 8),
                                      Consumer<FontSizeProvider>(
                                        builder: (context, fontProvider, child) {
                                          return Text(
                                            'กำลังโหลดข้อมูลเพิ่มเติม...',
                                            style: GoogleFonts.notoSansThai(
                                              fontSize: fontProvider.getScaledFontSize(14.0),
                                              color: colors.textSecondary,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            // แสดง end-of-list indicator ถ้าไม่มีข้อมูลเพิ่มแล้ว (แต่ไม่แสดงเมื่อค้นหา)
                            if (index == _filteredTrips.length - 1 && !_hasMoreData && !_isLoadingMore && _searchQuery.isEmpty) {
                              return Column(
                                children: [
                                  _buildTripCard(_filteredTrips[index]),
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    child: Consumer<FontSizeProvider>(
                                      builder: (context, fontProvider, child) {
                                        return Text(
                                          _searchQuery.isEmpty 
                                              ? 'แสดงครบทุกรายการแล้ว (${_trips.length} รายการ)'
                                              : 'แสดงผลลัพธ์การค้นหาครบแล้ว (${_filteredTrips.length} จาก ${_trips.length} รายการ)',
                                          style: GoogleFonts.notoSansThai(
                                            fontSize: fontProvider.getScaledFontSize(12.0),
                                            color: colors.textTertiary,
                                          ),
                                          textAlign: TextAlign.center,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                            
                            return _buildTripCard(_filteredTrips[index]);
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
