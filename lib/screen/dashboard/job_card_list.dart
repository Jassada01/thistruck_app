import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../service/local_storage.dart';
import '../../service/api_service.dart';
import '../../theme/app_theme.dart' as AppThemeConfig;
import '../../provider/font_size_provider.dart';
import 'job_card_item.dart';

class JobCardList extends StatefulWidget {
  @override
  _JobCardListState createState() => _JobCardListState();
}

class _JobCardListState extends State<JobCardList> {
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


  @override
  Widget build(BuildContext context) {
    final colors = AppThemeConfig.AppColorScheme.light();

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return RefreshIndicator(
          onRefresh: _loadJobOrderTrips,
          child: Column(
            children: [
              // Bangchak-style Header with Gradient
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary,
                      colors.primary.withValues(alpha: 0.8),
                      colors.primary.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      children: [
                        // Header Row
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.assignment_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'รายการงานของคุณ',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: fontProvider.getScaledFontSize(20.0),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_trips.isNotEmpty)
                                    Text(
                                      'ทั้งหมด ${_trips.length} รายการ',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: fontProvider.getScaledFontSize(14.0),
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_trips.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${_filteredTrips.length}/${_trips.length}',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: fontProvider.getScaledFontSize(12.0),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // Search Bar
                        if (_trips.isNotEmpty) ...[
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: GoogleFonts.notoSansThai(
                                fontSize: fontProvider.getScaledFontSize(14.0),
                                color: colors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ค้นหาใบงาน, ลูกค้า, เลขตู้, เลขซีล, บุ๊คกิ้ง...',
                                hintStyle: GoogleFonts.notoSansThai(
                                  fontSize: fontProvider.getScaledFontSize(14.0),
                                  color: colors.textSecondary,
                                ),
                                prefixIcon: Container(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: colors.primary,
                                    size: 22,
                                  ),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? Container(
                                        padding: EdgeInsets.all(8),
                                        child: IconButton(
                                          icon: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: colors.textSecondary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.clear_rounded,
                                              color: colors.textSecondary,
                                              size: 16,
                                            ),
                                          ),
                                          onPressed: _clearSearch,
                                        ),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Content with spacing
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 8),
                  child: _isLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: CircularProgressIndicator(
                                color: colors.primary,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'กำลังโหลดข้อมูล...',
                              style: GoogleFonts.notoSansThai(
                                fontSize: fontProvider.getScaledFontSize(16.0),
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
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
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _filteredTrips.length + (_isLoadingMore && _searchQuery.isEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _filteredTrips.length) {
                              // แสดง loading indicator ที่ท้ายรายการ
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: CircularProgressIndicator(
                                          color: colors.primary,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Consumer<FontSizeProvider>(
                                        builder: (context, fontProvider, child) {
                                          return Text(
                                            'กำลังโหลดข้อมูลเพิ่มเติม...',
                                            style: GoogleFonts.notoSansThai(
                                              fontSize: fontProvider.getScaledFontSize(14.0),
                                              color: colors.textSecondary,
                                              fontWeight: FontWeight.w500,
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
                                  JobCardItem(trip: _filteredTrips[index]),
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 20),
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: colors.primary.withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Consumer<FontSizeProvider>(
                                      builder: (context, fontProvider, child) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline_rounded,
                                              color: colors.success,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _searchQuery.isEmpty 
                                                  ? 'แสดงครบทุกรายการแล้ว (${_trips.length} รายการ)'
                                                  : 'แสดงผลลัพธ์การค้นหาครบแล้ว (${_filteredTrips.length} จาก ${_trips.length} รายการ)',
                                              style: GoogleFonts.notoSansThai(
                                                fontSize: fontProvider.getScaledFontSize(12.0),
                                                color: colors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                            
                            return JobCardItem(trip: _filteredTrips[index]);
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}