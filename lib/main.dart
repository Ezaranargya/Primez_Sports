import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔹 Import internal files
import 'package:my_app/firebase_options.dart';
import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/data/dummy_products.dart';
import 'package:my_app/screen/test_launcher_page.dart';
import 'package:my_app/screens/register/register_page.dart';
import 'package:my_app/screens/login/login_page.dart';
import 'package:my_app/screens/splash/splash_screen.dart';
import 'package:my_app/pages/user/home_content_page.dart';
import 'package:my_app/home_page.dart';
import 'package:my_app/pages/favorite/favorite_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'auth_wrapper.dart';

// 🔹 Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔹 Jalankan aplikasi dengan MultiProvider
  runApp(
    MultiProvider(
      providers: [
        // Favorite Provider — memuat data favorit dari Firestore saat startup
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider()..loadFavorites(),
        ),
        // 🔹 Tambahkan provider lain di sini bila dibutuhkan
      ],
      child: const PrimezSportsApp(),
    ),
  );
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
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Poppins',
            textTheme: Typography.englishLike2018.apply(
              fontSizeFactor: 1.sp,
            ),
          ),

          // 🔹 Halaman pertama saat app dijalankan
          home: const SplashScreen(),

          // 🔹 Semua route aplikasi
          routes: {
            '/auth': (context) => const AuthWrapper(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const HomePage(title: 'Primez Sports'),
            '/test': (context) => const TestLauncherPage(),
            '/favorite': (context) => const UserFavoritePage(),
          },
        );
      },
    );
  }
}
