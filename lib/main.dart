import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';

import 'firebase_options.dart';
import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/screen/test_launcher_page.dart';
import 'package:my_app/screens/register/register_page.dart';
import 'package:my_app/screens/login/login_page.dart';
import 'package:my_app/screens/splash/splash_screen.dart';
import 'package:my_app/pages/user/user_home_page.dart';
import 'package:my_app/pages/favorite/favorite_page.dart';
import 'package:my_app/pages/notifications/notifications_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/home_page.dart';
import 'package:my_app/admin/pages/admin_home_page.dart';
import 'package:my_app/pages/encode.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/models/product_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeDateFormatting('id_ID', null);

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

class PrimezSportsApp extends StatefulWidget {
  const PrimezSportsApp({super.key});

  @override
  State<PrimezSportsApp> createState() => _PrimezSportsAppState();
}

class _PrimezSportsAppState extends State<PrimezSportsApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    
    _setupFirebaseMessaging();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted permission');
    }
    
    String? token = await messaging.getToken();
    debugPrint('📱 FCM Token: $token');
    
    if (token != null) {
      await _saveFCMToken(token);
    }

    // ✅ Listen untuk token refresh
    messaging.onTokenRefresh.listen(_saveFCMToken);
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground message: ${message.notification?.title}');
      _showNotificationDialog(message);
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 Notification clicked!');
      String? productId = message.data['productId'];
      if (productId != null) {
        navigatorKey.currentState?.pushNamed(
          '/product-detail',
          arguments: productId,
        );
      }
    });
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        debugPrint('✅ FCM Token saved to Firestore: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  void _showNotificationDialog(RemoteMessage message) {
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(message.notification?.title ?? ''),
          content: Text(message.notification?.body ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _initDeepLinks() {
    _appLinks.getInitialAppLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Deep Link Received: $uri');
    debugPrint('   Scheme: ${uri.scheme}');
    debugPrint('   Host: ${uri.host}');
    debugPrint('   Path: ${uri.path}');
    debugPrint('   Segments: ${uri.pathSegments}');
    
    String? productId;
    
    if (uri.scheme == 'primezsports') {
      if (uri.host == 'products' && uri.pathSegments.isNotEmpty) {
        productId = uri.pathSegments[0];
      }

      else if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'products') {
        if (uri.pathSegments.length > 1) {
          productId = uri.pathSegments[1];
        }
      }
    }
    
    else if (uri.scheme == 'https' && uri.host == 'primez-sports.com') {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'products') {
        if (uri.pathSegments.length > 1) {
          productId = uri.pathSegments[1];
        }
      }
    }
    
    if (productId != null && productId.isNotEmpty) {
      debugPrint('✅ Navigating to product: $productId');
      
      Future.delayed(const Duration(milliseconds: 500), () {
        navigatorKey.currentState?.pushNamed(
          '/product-detail',
          arguments: productId,
        );
      });
    } else {
      debugPrint('❌ Invalid deep link format');
    }
  }

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
          
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('id', 'ID'),
            Locale('en', 'US'),
          ],
          locale: const Locale('id', 'ID'),

          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.interTextTheme(
              Theme.of(context).textTheme,
            ).copyWith(
              bodyMedium: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                letterSpacing: 0,
                color: Colors.black87,
              ),
              titleLarge: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
              headlineSmall: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
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
            '/notifications': (context) => const NotificationPage(),
            '/encode': (context) => const EncodecodeExample(),
          },
          
          onGenerateRoute: (settings) {
            if (settings.name == '/product-detail') {
              final productId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => ProductDetailLoader(productId: productId),
              );
            }
            return null;
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

  Future<void> _navigateToAuth() async {
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
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
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
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }

              if (roleSnapshot.hasError || !roleSnapshot.hasData) {
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

class ProductDetailLoader extends StatelessWidget {
  final String productId;

  const ProductDetailLoader({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Memuat Produk...'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorPage(context);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return _buildProductPreview(context, productId, data);
      },
    );
  }

  Widget _buildErrorPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Produk Tidak Ditemukan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'Produk Tidak Ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Produk yang Anda cari tidak tersedia atau telah dihapus',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/auth',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Kembali ke Beranda',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductPreview(
    BuildContext context,
    String productId,
    Map<String, dynamic> data,
  ) {
    try {
      final product = Product.fromMap(data, productId);
      
      return UserProductDetailPage(
        product: product,
        showFavoriteInAppBar: false,
      );
    } catch (e) {
      debugPrint('Error parsing product: $e');
      return _buildErrorPage(context);
    }
  }
}