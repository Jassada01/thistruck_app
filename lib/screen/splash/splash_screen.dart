import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../firebase_options.dart';
import '../../service/notification_service.dart';
import '../../service/local_storage.dart';
import '../../service/api_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _progressAnimationController;
  late AnimationController _floatingAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;
  late Animation<double> _floatingAnimation;

  String _currentStep = 'กำลังเริ่มต้น...';
  bool _hasError = false;
  String _errorMessage = '';
  double _progress = 0.0;
  String _appVersion = '';

  // Colors (Blue/White theme)
  final Color _primaryColor = Color(0xFF2196F3);
  final Color _primaryVariant = Color(0xFF1976D2);
  // final Color _backgroundColor = Color(0xFFFAFAFA);
  final Color _surfaceColor = Colors.white;
  final Color _errorColor = Color(0xFFE53E3E);
  final Color _textPrimary = Color(0xFF1A1A1A);
  final Color _textSecondary = Color(0xFF6B7280);

  final List<Map<String, dynamic>> _setupSteps = [
    {'text': 'กำลังโหลดการตั้งค่า...', 'icon': Icons.settings_outlined},
    {'text': 'กำลังเชื่อมต่อ Firebase...', 'icon': Icons.cloud_outlined},
    {
      'text': 'กำลังตั้งค่าการแจ้งเตือน...',
      'icon': Icons.notifications_outlined,
    },
    {
      'text': 'กำลังตรวจสอบการเข้าสู่ระบบ...',
      'icon': Icons.person_search_outlined,
    },
    {'text': 'เกือบเสร็จแล้ว...', 'icon': Icons.check_circle_outline},
  ];

  List<Color> get backgroundGradient => [
    Color(0xFFE3F2FD),
    Color(0xFFBBDEFB),
    Color(0xFF90CAF9),
    Color(0xFF64B5F6),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getAppVersion();
    _startInitialization();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingAnimationController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _floatingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _mainAnimationController.forward();
    _floatingAnimationController.repeat(reverse: true);
  }

  Future<void> _getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'เวอร์ชัน ${packageInfo.version}';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'เวอร์ชัน 1.0.0';
      });
    }
  }

  Future<void> _startInitialization() async {
    try {
      // Step 1: Load environment variables
      await _updateProgress('กำลังโหลดการตั้งค่า...', 0.2);
      await dotenv.load(fileName: ".env");
      await Future.delayed(Duration(milliseconds: 800));

      // Step 2: Initialize Firebase
      await _updateProgress('กำลังเชื่อมต่อ Firebase...', 0.4);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await Future.delayed(Duration(milliseconds: 800));

      // Step 3: Setup notifications and request permission immediately
      await _updateProgress('กำลังตั้งค่าการแจ้งเตือน...', 0.6);
      await NotificationService.createNotificationChannel();
      
      // Initialize notification service and request permission right away
      final notificationService = NotificationService();
      await notificationService.initializeNotifications();
      
      await Future.delayed(Duration(milliseconds: 800));

      // Step 4: Check terms acceptance and login status
      await _updateProgress('กำลังตรวจสอบการเข้าสู่ระบบ...', 0.8);
      final termsAccepted = await LocalStorage.isTermsAccepted();
      final hasProfile = await LocalStorage.hasProfile();
      await Future.delayed(Duration(milliseconds: 800));

      // Step 5: Final setup
      await _updateProgress('เกือบเสร็จแล้ว...', 1.0);

      // *** เพิ่มส่วนนี้: Check device และ update last active หาก user login แล้ว ***
      if (hasProfile) {
        try {
          String? deviceId = await _getDeviceId();
          
          if (deviceId != null) {
            final checkResult = await ApiService.checkDeviceAndUpdateActive(deviceId);
            
            if (checkResult['success'] == true) {
              print('✅ Device validated and last active updated');
              
              // อัพเดท profile ใน Local Storage ถ้ามีข้อมูลใหม่
              if (checkResult['profile_data'] != null) {
                await LocalStorage.saveProfile(checkResult['profile_data']);
                print('✅ Profile updated from device check');
              }
            } else {
              // Device ไม่พบหรือ user inactive - ลบ profile และไปหน้า login
              if (checkResult['action'] == 'redirect_to_passcode_login') {
                await LocalStorage.deleteProfile();
                print('⚠️ Device validation failed: ${checkResult['message']}');
                
                // Navigate to login instead of dashboard
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                  return;
                }
              }
            }
          }
        } catch (e) {
          print('⚠️ Failed to check device: $e');
          // ไม่ให้ error นี้กระทบต่อการทำงานของ app
        }
      }

      await Future.delayed(Duration(milliseconds: 1000));

      // Navigate based on terms acceptance and login status
      if (mounted) {
        if (!termsAccepted) {
          // First time user - show terms screen
          Navigator.pushReplacementNamed(context, '/terms');
        } else if (hasProfile) {
          // Terms accepted and user logged in - go to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // Terms accepted but not logged in - go to login
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _currentStep = 'การตั้งค่าล้มเหลว';
        });
      }
    }
  }

  Future<void> _updateProgress(String step, double progress) async {
    if (mounted) {
      setState(() {
        _currentStep = step;
      });

      // Animate from previous progress to new progress
      _progressAnimationController.reset();
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: progress,
      ).animate(
        CurvedAnimation(
          parent: _progressAnimationController,
          curve: Curves.easeInOut,
        ),
      );

      _previousProgress = progress;
      _progress = progress;
      _progressAnimationController.forward();
    }
  }

  void _retrySetup() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _progress = 0.0;
        _currentStep = 'กำลังเริ่มต้น...';
      });
      _progressAnimationController.reset();
      _startInitialization();
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _progressAnimationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
  }

  Widget _buildFloatingCard(
    Widget child, {
    double? width,
    double? height,
    EdgeInsets? margin,
    Color? color,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color ?? _surfaceColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildProgressCard() {
    return _buildFloatingCard(
      Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current step icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryVariant],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value * 3),
                    child: Icon(_getStepIcon(), color: Colors.white, size: 32),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // Progress text
            Text(
              _currentStep,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            // Progress bar
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width *
                          0.6 *
                          _progressAnimation.value,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _primaryVariant],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 12),

            // Progress percentage
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      ),
      width: 280,
    );
  }

  Widget _buildErrorCard() {
    return _buildFloatingCard(
      Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_errorColor, _errorColor.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _errorColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.error_outline, color: Colors.white, size: 28),
            ),

            SizedBox(height: 20),

            Text(
              'การตั้งค่าล้มเหลว',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _errorColor,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'ไม่สามารถเริ่มต้นแอปพลิเคชันได้',
              style: TextStyle(fontSize: 14, color: _textSecondary),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'ข้อผิดพลาด: $_errorMessage',
                style: TextStyle(
                  fontSize: 12,
                  color: _errorColor,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 20),

            // Retry button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_errorColor, _errorColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _errorColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _retrySetup,
                  borderRadius: BorderRadius.circular(25),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ลองอีกครั้ง',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      width: 320,
    );
  }

  IconData _getStepIcon() {
    final stepIndex = ((_progress * _setupSteps.length) - 1).round().clamp(
      0,
      _setupSteps.length - 1,
    );
    return _setupSteps[stepIndex]['icon'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background floating elements
              Positioned(
                top: 100,
                right: 50,
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatingAnimation.value * 10),
                      child: _buildFloatingCard(
                        Container(
                          width: 80,
                          height: 80,
                          child: Icon(
                            Icons.local_shipping_outlined,
                            color: _primaryColor.withOpacity(0.7),
                            size: 32,
                          ),
                        ),
                        width: 80,
                        height: 80,
                        color: _surfaceColor.withOpacity(0.7),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 200,
                left: 30,
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_floatingAnimation.value * 8),
                      child: _buildFloatingCard(
                        Container(
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.route_outlined,
                            color: _primaryColor.withOpacity(0.7),
                            size: 24,
                          ),
                        ),
                        width: 60,
                        height: 60,
                        color: _surfaceColor.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ),

              // Main content
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App logo
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_primaryColor, _primaryVariant],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryColor.withOpacity(0.4),
                                        blurRadius: 25,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.local_shipping,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              SizedBox(height: 32),

                              // App title
                              _buildFloatingCard(
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'This Truck',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: _textPrimary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'ระบบจัดการรถ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _textSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 48),

                              // Progress or Error card
                              if (!_hasError) _buildProgressCard(),
                              if (_hasError) _buildErrorCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildFloatingCard(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Text(
                                _appVersion.isEmpty
                                    ? 'เวอร์ชัน 1.0.0'
                                    : _appVersion,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'power by JSolutionsNext',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// เพิ่ม helper method สำหรับดึง device ID
Future<String?> _getDeviceId() async {
  try {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    }
  } catch (e) {
    print('Error getting device ID: $e');
  }
  return null;
}
