import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/data/dummy_products.dart';
import 'package:my_app/screen/test_launcher_page.dart';
import 'package:my_app/screens/register/register_page.dart';
import 'firebase_options.dart';
import '../screens/splash/splash_screen.dart';
import '../../screens/login/login_page.dart';
import 'home_page.dart';
import 'auth_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'package:my_app/pages/user/home_content_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PrimezSportsApp());
}

class PrimezSportsApp extends StatelessWidget {
  const PrimezSportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Primez Sports',
          theme: ThemeData(
            primaryColor: const Color(0xFFE53E3E),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Poppins',
            textTheme: Typography.englishLike2018.apply(
              fontSizeFactor: 1.sp,
            ),
          ),
          home: child,
          routes: {  
            '/auth': (context) => const AuthWrapper(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(title: 'Primez Sports'),
            '/register': (context) => const RegisterPage(),
            '/test': (context) => const TestLauncherPage(),
          },
        );
      },
      child: const SplashScreen(),
    );
  }
}
