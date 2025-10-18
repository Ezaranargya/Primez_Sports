import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_app/firebase_options.dart';
import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/screen/test_launcher_page.dart';
import 'package:my_app/screens/register/register_page.dart';
import 'package:my_app/screens/login/login_page.dart';
import 'package:my_app/screens/splash/splash_screen.dart';
import 'package:my_app/pages/user/user_home_page.dart';
import 'package:my_app/pages/user/home_content_page.dart';
import 'package:my_app/home_page.dart';
import 'package:my_app/pages/favorite/favorite_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/admin/pages/admin_home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(),
          lazy: false, 
        ),
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
          home: const SplashToAuthWrapper(),
          routes: {
            '/auth': (context) => const AuthWrapper(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const HomePage(title: 'Primez Sports'),
            '/test': (context) => const TestLauncherPage(),
            '/favorite': (context) => const UserFavoritesPage(),
          },
        );
      },
    );
  }
}

class SplashToAuthWrapper extends StatefulWidget {
  const SplashToAuthWrapper({super.key});

  @override
  State<SplashToAuthWrapper> createState() => _SplashToAuthWrapperState();
}

class _SplashToAuthWrapperState extends State<SplashToAuthWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  void _navigateToAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String?> _getUserRole(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['role'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          Future.microtask(() {
            Provider.of<FavoriteProvider>(context, listen: false)
                .loadFavorites();
          });

          return FutureBuilder<String?>(
            future: _getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              if (roleSnapshot.hasError) {
                return const LoginPage();
              }

              final role = roleSnapshot.data;

              if (role == 'admin') {
                return const AdminHomePage();
              } else {
                return const UserHomePage();
              }
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}