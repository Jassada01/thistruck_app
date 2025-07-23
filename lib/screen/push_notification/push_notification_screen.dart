import 'package:flutter/material.dart';
import '../../service/notification_service.dart';

class PushNotificationDebugScreen extends StatefulWidget {
  @override
  _PushNotificationDebugScreenState createState() => _PushNotificationDebugScreenState();
}

class _PushNotificationDebugScreenState extends State<PushNotificationDebugScreen> {
  final NotificationService _notificationService = NotificationService();
  String? _deviceToken;
  List<String> _debugLogs = [];
  bool _isLoading = true;
  String _permissionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _addDebugLog(String message) {
    if (!mounted) return;
    
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    
    // Print to console for debugging
    print(logMessage);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _debugLogs.insert(0, logMessage);
          // Keep only last 100 logs
          if (_debugLogs.length > 100) {
            _debugLogs = _debugLogs.take(100).toList();
          }
        });
      }
    });
  }

  Future<void> _initializeNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    _addDebugLog('🚀 Starting notification initialization...');

    try {
      // Initialize notification service
      _addDebugLog('📱 Requesting notification permissions...');
      String permissionStatus = await _notificationService.initializeNotifications(
        onMessage: (message) {
          if (mounted) {
            _addDebugLog('📥 Foreground message received: $message');
          }
        },
        onTap: (message) {
          if (mounted) {
            _addDebugLog('👆 Notification tapped: $message');
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _permissionStatus = permissionStatus;
      });
      _addDebugLog('✅ Permission status: $permissionStatus');

      // Get device token
      _addDebugLog('🔑 Retrieving device token...');
      String? token = await _notificationService.getDeviceToken();
      if (!mounted) return;
      setState(() {
        _deviceToken = token;
      });
      
      if (token != null) {
        _addDebugLog('✅ Device token retrieved successfully');
        _addDebugLog('🔗 Token: ${token.substring(0, 20)}...');
      } else {
        _addDebugLog('❌ Failed to retrieve device token');
      }

    } catch (e) {
      _addDebugLog('💥 Error initializing notifications: $e');
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    _addDebugLog('🎯 Initialization completed');
  }

  Future<void> _refreshToken() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    _addDebugLog('🔄 Refreshing token...');
    
    try {
      String? token = await _notificationService.refreshToken();
      if (!mounted) return;
      setState(() {
        _deviceToken = token;
      });
      if (token != null) {
        _addDebugLog('✅ Token refreshed successfully');
        _addDebugLog('🔗 New token: ${token.substring(0, 20)}...');
      } else {
        _addDebugLog('❌ Failed to refresh token');
      }
    } catch (e) {
      _addDebugLog('💥 Error refreshing token: $e');
    }
    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testLocalNotification() async {
    _addDebugLog('🧪 Sending test notification...');
    try {
      await _notificationService.sendTestNotification();
      _addDebugLog('✅ Test notification sent successfully');
    } catch (e) {
      _addDebugLog('💥 Error sending test notification: $e');
    }
  }

  Future<void> _logNotificationSettings() async {
    _addDebugLog('📋 Logging notification settings...');
    try {
      await _notificationService.logNotificationSettings();
      _addDebugLog('✅ Notification settings logged to console');
    } catch (e) {
      _addDebugLog('💥 Error logging settings: $e');
    }
  }

  Future<void> _logPendingNotifications() async {
    _addDebugLog('📄 Logging pending notifications...');
    try {
      await _notificationService.logPendingNotifications();
      _addDebugLog('✅ Pending notifications logged to console');
    } catch (e) {
      _addDebugLog('💥 Error logging pending notifications: $e');
    }
  }

  Future<void> _runDiagnostic() async {
    _addDebugLog('🔍 Running comprehensive diagnostic...');
    try {
      await _notificationService.runNotificationDiagnostic();
      _addDebugLog('✅ Diagnostic completed - check console for details');
    } catch (e) {
      _addDebugLog('💥 Error running diagnostic: $e');
    }
  }

  void _clearLogs() {
    if (mounted) {
      setState(() {
        _debugLogs.clear();
      });
      _addDebugLog('🧹 Debug logs cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Push Notification Debug'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: Icon(Icons.clear_all),
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _isLoading && _debugLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing notifications...'),
                ],
              ),
            )
          : Column(
              children: [
                // Status Bar
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  color: _permissionStatus == 'authorized' 
                      ? Colors.green[100] 
                      : Colors.orange[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: $_permissionStatus',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Logs: ${_debugLogs.length}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _refreshToken,
                              icon: Icon(Icons.refresh),
                              label: Text('Refresh Token'),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _testLocalNotification,
                              icon: Icon(Icons.notifications),
                              label: Text('Test Notification'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _logNotificationSettings,
                              icon: Icon(Icons.settings),
                              label: Text('Log Settings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[100],
                                foregroundColor: Colors.blue[800],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _logPendingNotifications,
                              icon: Icon(Icons.pending_actions),
                              label: Text('Log Pending'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[100],
                                foregroundColor: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _runDiagnostic,
                          icon: Icon(Icons.bug_report),
                          label: Text('🔍 Run Full Diagnostic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                            foregroundColor: Colors.red[800],
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Debug Logs
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,
                    ),
                    child: _debugLogs.isEmpty
                        ? Center(
                            child: Text(
                              'No debug logs yet...',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(8),
                            itemCount: _debugLogs.length,
                            itemBuilder: (context, index) {
                              final log = _debugLogs[index];
                              Color textColor = Colors.white;
                              
                              // Color coding for different log types
                              if (log.contains('❌') || log.contains('💥')) {
                                textColor = Colors.red[300]!;
                              } else if (log.contains('✅')) {
                                textColor = Colors.green[300]!;
                              } else if (log.contains('🔄') || log.contains('🧪')) {
                                textColor = Colors.blue[300]!;
                              } else if (log.contains('📥') || log.contains('👆')) {
                                textColor = Colors.orange[300]!;
                              }
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 2),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 4
                                ),
                                decoration: BoxDecoration(
                                  color: index == 0 
                                      ? Colors.grey[800] 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SelectableText(
                                  log,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: textColor,
                                    fontWeight: index == 0 
                                        ? FontWeight.w500 
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                
                SizedBox(height: 16),
              ],
            ),
    );
  }
}