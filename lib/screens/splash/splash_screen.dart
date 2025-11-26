import 'package:flutter/material.dart';
import 'widgets/splash_content.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ TIDAK PERLU NAVIGASI MANUAL DI SINI
    // _AuthDecisionWrapper di main.dart yang handle navigasi setelah 3 detik
    debugPrint('🎬 SplashScreen loaded');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE53E3E), // Warna merah sesuai desain Anda
      body: SplashContent(),
    );
  }
}