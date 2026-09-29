import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/call_screening_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Android native CallScreeningService bridge
  CallScreeningService.initialize();
  runApp(const VoxGuardApp());
}

class VoxGuardApp extends StatelessWidget {
  const VoxGuardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoxGuard AI Call Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
