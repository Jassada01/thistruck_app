import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Simple Theme Switcher ที่ไม่ต้องใช้ Provider
class SimpleThemeSwitcher extends StatefulWidget {
  final Function(bool isDark) onThemeChanged;
  final bool initialDarkMode;
  
  const SimpleThemeSwitcher({
    Key? key,
    required this.onThemeChanged,
    this.initialDarkMode = false,
  }) : super(key: key);

  @override
  _SimpleThemeSwitcherState createState() => _SimpleThemeSwitcherState();
}

class _SimpleThemeSwitcherState extends State<SimpleThemeSwitcher> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    widget.onThemeChanged(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ธีม',
            style: GoogleFonts.notoSansThai(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildThemeOption(
                context,
                Icons.light_mode,
                'สว่าง',
                !_isDarkMode,
                () {
                  if (_isDarkMode) _toggleTheme();
                },
              ),
              _buildThemeOption(
                context,
                Icons.dark_mode,
                'มืด',
                _isDarkMode,
                () {
                  if (!_isDarkMode) _toggleTheme();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? Colors.white
                    : Theme.of(context).iconTheme.color,
                size: 24,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.notoSansThai(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Toggle Switch
class SimpleThemeToggle extends StatefulWidget {
  final Function(bool isDark) onThemeChanged;
  final bool initialDarkMode;
  
  const SimpleThemeToggle({
    Key? key,
    required this.onThemeChanged,
    this.initialDarkMode = false,
  }) : super(key: key);

  @override
  _SimpleThemeToggleState createState() => _SimpleThemeToggleState();
}

class _SimpleThemeToggleState extends State<SimpleThemeToggle> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          'โหมดมืด',
          style: GoogleFonts.notoSansThai(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Text(
          _isDarkMode ? 'เปิดใช้งาน' : 'ปิดใช้งาน',
          style: GoogleFonts.notoSansThai(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        value: _isDarkMode,
        onChanged: (value) {
          setState(() {
            _isDarkMode = value;
          });
          widget.onThemeChanged(value);
        },
        activeColor: Theme.of(context).primaryColor,
        secondary: Icon(
          _isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

// Floating Action Button for Theme
class SimpleThemeFloatingButton extends StatefulWidget {
  final Function(bool isDark) onThemeChanged;
  final bool initialDarkMode;
  
  const SimpleThemeFloatingButton({
    Key? key,
    required this.onThemeChanged,
    this.initialDarkMode = false,
  }) : super(key: key);

  @override
  _SimpleThemeFloatingButtonState createState() => _SimpleThemeFloatingButtonState();
}

class _SimpleThemeFloatingButtonState extends State<SimpleThemeFloatingButton> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    widget.onThemeChanged(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _toggleTheme,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: Icon(
          _isDarkMode ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(_isDarkMode),
        ),
      ),
    );
  }
}

// App Bar Action
class SimpleThemeAppBarAction extends StatefulWidget {
  final Function(bool isDark) onThemeChanged;
  final bool initialDarkMode;
  
  const SimpleThemeAppBarAction({
    Key? key,
    required this.onThemeChanged,
    this.initialDarkMode = false,
  }) : super(key: key);

  @override
  _SimpleThemeAppBarActionState createState() => _SimpleThemeAppBarActionState();
}

class _SimpleThemeAppBarActionState extends State<SimpleThemeAppBarAction> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    widget.onThemeChanged(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleTheme,
      icon: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: Icon(
          _isDarkMode ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(_isDarkMode),
        ),
      ),
      tooltip: _isDarkMode ? 'เปลี่ยนเป็นโหมดสว่าง' : 'เปลี่ยนเป็นโหมดมืด',
    );
  }
}