// ══════════════════════════════════════════════════════════════════════
// main.dart — Battery Assistant & Health Tracker
// Entry point: init services, request permissions, launch UI.
// ══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/battery_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation — the ring looks best in portrait.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar so the dark background bleeds through.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Init notification channels before the service starts firing.
  await NotificationService().init();

  // Request notification permission (Android 13+).
  await Permission.notification.request();

  // Start the foreground battery monitoring service.
  await initBatteryService();

  runApp(const BatteryAssistantApp());
}

class BatteryAssistantApp extends StatelessWidget {
  const BatteryAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Assistant',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF39FF14),   // neon green — safe
        error:   Color(0xFFFF2020),   // neon red — danger
        surface: Color(0xFF12121E),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF39FF14),
      ),
    );
  }
}
