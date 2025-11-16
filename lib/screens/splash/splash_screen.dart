import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../auth/login/login_page.dart'; 
import 'widgets/splash_content.dart';

class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState () => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState () {
    super.initState ();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const LoginPage()),
          );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE53E3E),
      body: SplashContent(),
    );
  }
}