import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screen/splash/splash_screen.dart';
import 'screen/terms/terms_screen.dart';
import 'screen/auth/login_screen.dart';
import 'screen/dashboard/dashboard_screen.dart';
import 'screen/push_notification/push_notification_screen.dart';
import 'screen/job_detail/job_detail_screen.dart';
import 'screen/notifications/notifications_screen.dart';
import 'service/notification_service.dart';
import 'service/notification_navigation_service.dart';
import 'service/badge_service.dart';
import 'provider/font_size_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize font size provider
  final fontSizeProvider = FontSizeProvider();
  await fontSizeProvider.initialize();
  
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // เรียกใช้ app โดยไม่ต้อง initialize ที่นี่
  // เพราะจะให้ splash screen จัดการ
  runApp(MyApp(fontSizeProvider: fontSizeProvider));
}

class MyApp extends StatelessWidget {
  final FontSizeProvider fontSizeProvider;
  
  const MyApp({Key? key, required this.fontSizeProvider}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: fontSizeProvider),
      ],
      child: Consumer<FontSizeProvider>(
        builder: (context, fontProvider, child) {
          return MaterialApp(
            navigatorKey: NotificationNavigationService.navigatorKey,
            title: 'This Truck',
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('th', 'TH'),
              Locale('en', 'US'),
            ],
            locale: const Locale('th', 'TH'),
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.light,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: GoogleFonts.notoSansThai().fontFamily,
              textTheme: GoogleFonts.notoSansThaiTextTheme(
                Theme.of(context).textTheme,
              ).copyWith(
                displayLarge: GoogleFonts.notoSansThai(fontSize: fontProvider.displayLargeSize),
                displayMedium: GoogleFonts.notoSansThai(fontSize: fontProvider.displayMediumSize),
                displaySmall: GoogleFonts.notoSansThai(fontSize: fontProvider.displaySmallSize),
                headlineLarge: GoogleFonts.notoSansThai(fontSize: fontProvider.headlineSize),
                headlineMedium: GoogleFonts.notoSansThai(fontSize: fontProvider.titleSize),
                headlineSmall: GoogleFonts.notoSansThai(fontSize: fontProvider.subtitleSize),
                titleLarge: GoogleFonts.notoSansThai(fontSize: fontProvider.titleSize),
                titleMedium: GoogleFonts.notoSansThai(fontSize: fontProvider.subtitleSize),
                titleSmall: GoogleFonts.notoSansThai(fontSize: fontProvider.bodySize),
                bodyLarge: GoogleFonts.notoSansThai(fontSize: fontProvider.bodySize),
                bodyMedium: GoogleFonts.notoSansThai(fontSize: fontProvider.bodySmallSize),
                bodySmall: GoogleFonts.notoSansThai(fontSize: fontProvider.captionSize),
                labelLarge: GoogleFonts.notoSansThai(fontSize: fontProvider.bodySize),
                labelMedium: GoogleFonts.notoSansThai(fontSize: fontProvider.bodySmallSize),
                labelSmall: GoogleFonts.notoSansThai(fontSize: fontProvider.captionSize),
              ),
            ),
            home: SplashScreen(), // เริ่มต้นที่ splash screen
            routes: {
              '/terms': (context) => TermsScreen(),
              '/login': (context) => LoginScreen(),
              '/dashboard': (context) => DashboardScreen(),
              '/notification-debug': (context) => PushNotificationDebugScreen(),
              '/notifications': (context) => NotificationsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/job-detail') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => JobDetailScreen(
                    randomCode: args['randomCode'],
                  ),
                );
              }
              return null;
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}


