import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../service/api_service.dart';
import '../../service/local_storage.dart';
import '../../theme/app_theme.dart' as AppThemeConfig;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6, 
    (index) => TextEditingController()
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  late AnimationController _animationController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Setup listeners for auto-focus
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        // Additional listener for real-time updates if needed
      });
    }
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _animationController.forward();
  }
  
  void _onPasscodeChanged(int index) {
    final text = _controllers[index].text;
    
    if (text.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All fields filled, attempt login
        _focusNodes[index].unfocus();
        _attemptLogin();
      }
    }
    
    // Clear error when user starts typing
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }
  }
  
  void _onKeyPressed(int index, String value) {
    if (value.isEmpty && index > 0) {
      // Move to previous field when deleting
      _focusNodes[index - 1].requestFocus();
    }
  }
  
  void _clearPasscode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }
  
  String _getPasscode() {
    return _controllers.map((controller) => controller.text).join();
  }
  
  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
    
    // Auto clear error after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
      }
    });
  }
  
  Future<void> _attemptLogin() async {
    final passcode = _getPasscode();
    
    if (passcode.length != 6) {
      _showError('กรุณากรอกรหัสผ่าน 6 หลัก');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check network connectivity first
      final hasConnection = await ApiService.checkConnectivity();
      if (!hasConnection) {
        _showError('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
        setState(() => _isLoading = false);
        return;
      }
      
      // Attempt login
      final result = await ApiService.loginWithPasscode(passcode);
      
      if (result['success']) {
        // Save profile to local storage
        final userData = result['data'] ?? {};
        print('📋 Saving user data: $userData');
        await LocalStorage.saveProfile(userData);
        
        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        _showError(result['message']);
        _clearPasscode();
      }
      
    } catch (e) {
      _showError('เกิดข้อผิดพลาดในการเข้าสู่ระบบ');
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _animationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  
  Widget _buildPasscodeField(int index) {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _hasError ? Offset(_shakeAnimation.value * 2, 0) : Offset.zero,
          child: Container(
            width: 50,
            height: 60,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasError
                    ? colors.error
                    : _focusNodes[index].hasFocus
                        ? colors.primary
                        : colors.divider,
                width: _focusNodes[index].hasFocus ? 2 : 1,
              ),
              boxShadow: _focusNodes[index].hasFocus
                  ? [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansThai(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              keyboardType: TextInputType.number,
              maxLength: 1,
              obscureText: false,
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                if (value.length > 1) {
                  _controllers[index].text = value.substring(value.length - 1);
                }
                if (value.isEmpty) {
                  _onKeyPressed(index, value);
                } else {
                  _onPasscodeChanged(index);
                }
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return Column(
      children: [
        // App Icon
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primaryVariant],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.security,
              size: 50,
              color: colors.onPrimary,
            ),
          ),
        ),
        
        SizedBox(height: 32),
        
        // Title
        Text(
          'เข้าสู่ระบบ',
          style: GoogleFonts.notoSansThai(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        
        SizedBox(height: 8),
        
        // Subtitle
        Text(
          'กรุณากรอกรหัสผ่าน 6 หลัก',
          style: GoogleFonts.notoSansThai(
            fontSize: 16,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPasscodeInput() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => _buildPasscodeField(index),
          ),
        ),
        
        if (_hasError) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppThemeConfig.AppColorScheme.light().error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppThemeConfig.AppColorScheme.light().error.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppThemeConfig.AppColorScheme.light().error,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  _errorMessage,
                  style: GoogleFonts.notoSansThai(
                    color: AppThemeConfig.AppColorScheme.light().error,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildActionButtons() {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return Column(
      children: [
        // Clear button
        TextButton.icon(
          onPressed: _isLoading ? null : _clearPasscode,
          icon: Icon(Icons.clear),
          label: Text(
            'ล้างรหัส',
            style: GoogleFonts.notoSansThai(),
          ),
          style: TextButton.styleFrom(
            foregroundColor: colors.textSecondary,
          ),
        ),
        
        SizedBox(height: 16),
        
        // Login button
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _attemptLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 8,
              shadowColor: colors.primary.withOpacity(0.4),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'เข้าสู่ระบบ',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = AppThemeConfig.AppColorScheme.light();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 48),
                          _buildPasscodeInput(),
                          SizedBox(height: 32),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                    
                    // Footer
                    Text(
                      'เวอร์ชัน 1.0.0',
                      style: GoogleFonts.notoSansThai(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}