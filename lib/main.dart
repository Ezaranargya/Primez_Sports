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
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';

import 'firebase_options.dart';
import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/screen/test_launcher_page.dart';
import 'package:my_app/auth/register/register_page.dart';
import 'package:my_app/auth/login/login_page.dart';
import 'package:my_app/auth/reset_password/reset_password_page.dart';
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
import 'package:my_app/pages/product/product_detail_page.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _pendingDeepLinkLocation;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('_debugLocked')) {
      debugPrint('⚠️ Hot reload error ignored: ${details.exception}');
      return;
    }
    FlutterError.presentError(details);
  };

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
  late final GoRouter _router;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _setupFirebaseMessaging();
    _router = _createRouter();
    _checkInitialLink();
  }

  Future<void> _checkInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('🔗 Initial Deep Link Detected: $uri');
        final location = _parseDeepLink(uri);
        if (location != null) {
          debugPrint('🔗 Parsed Initial Location: $location');

          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint('✅ User logged in, navigating immediately');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _router.go(location);
              }
            });
          } else {
            debugPrint('⏳ User not logged in, saving pending deep link');
            _pendingDeepLinkLocation = location;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting initial link: $e');
    }

    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 Deep Link Stream: $uri');
      final location = _parseDeepLink(uri);
      if (location != null && mounted) {
        debugPrint('🔗 Navigating to: $location');

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _router.go(location);
        } else {
          _pendingDeepLinkLocation = location;
          _router.go('/login');
        }
      }
    });
  }

  String? _parseDeepLink(Uri uri) {
    debugPrint('🔗 Parsing Deep Link:');
    debugPrint('   Scheme: ${uri.scheme}');
    debugPrint('   Host: ${uri.host}');
    debugPrint('   Path: ${uri.path}');
    debugPrint('   Segments: ${uri.pathSegments}');
    debugPrint('   Query: ${uri.queryParameters}');

    String? productId;

    if (uri.queryParameters.containsKey('link')) {
      final deepLink = Uri.parse(uri.queryParameters['link']!);
      debugPrint('🔗 Extracted Firebase Dynamic Link: $deepLink');

      if (deepLink.pathSegments.length >= 2) {
        if (deepLink.pathSegments[0] == 'product' || deepLink.pathSegments[0] == 'products') {
          productId = deepLink.pathSegments[1];
        }
      }
    } else if (uri.scheme == 'primezsports') {
      if (uri.host == 'products' || uri.host == 'product') {
        if (uri.pathSegments.isNotEmpty) {
          productId = uri.pathSegments[0];
        }
      } else if (uri.pathSegments.isNotEmpty) {
        if (uri.pathSegments[0] == 'products' || uri.pathSegments[0] == 'product') {
          if (uri.pathSegments.length > 1) {
            productId = uri.pathSegments[1];
          }
        }
      }
    } else if (uri.scheme == 'https') {
      if (uri.pathSegments.isNotEmpty) {
        if (uri.pathSegments[0] == 'product' || uri.pathSegments[0] == 'products') {
          if (uri.pathSegments.length > 1) {
            productId = uri.pathSegments[1];
          }
        }
      }
    }

    if (productId == null && uri.queryParameters.containsKey('id')) {
      productId = uri.queryParameters['id'];
    }

    if (productId != null && productId.isNotEmpty) {
      debugPrint('✅ Product ID found: $productId');
      return '/product/$productId';
    }

    debugPrint('❌ No product ID found in deep link');
    return null;
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

    messaging.onTokenRefresh.listen(_saveFCMToken);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground message: ${message.notification?.title}');
      _showNotificationDialog(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 Notification clicked!');
      String? productId = message.data['productId'];
      if (productId != null) {
        _router.push('/product/$productId');
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

  GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      restorationScopeId: 'app', 

      redirect: (context, state) async {
        final currentLocation = state.matchedLocation;
        debugPrint('🔀 Redirect check for: $currentLocation');

        if (_pendingDeepLinkLocation != null) {
          if (!currentLocation.startsWith('/product')) {
            debugPrint('🔗 Processing pending deep link: $_pendingDeepLinkLocation');
            final location = _pendingDeepLinkLocation;
            _pendingDeepLinkLocation = null;
            return location;
          }
        }

        if (currentLocation.startsWith('/product')) {
          debugPrint('✅ Allowing navigation to product detail');
          return null;
        }

        final user = FirebaseAuth.instance.currentUser;
        final isLoggedIn = user != null;

        final isGoingToLogin = currentLocation == '/login';
        final isGoingToRegister = currentLocation == '/register';
        final isGoingToResetPassword = currentLocation == '/reset-password';
        final isGoingToRoot = currentLocation == '/';

        if (isGoingToRegister || isGoingToResetPassword) {
          debugPrint('✅ Allowing navigation to register/reset-password');
          return null;
        }

        if (!isLoggedIn && !isGoingToLogin && !isGoingToRoot) {
          debugPrint('⚠️ Not logged in, redirecting to login');
          return '/login';
        }

        if (isLoggedIn && (isGoingToRoot || isGoingToLogin || isGoingToRegister)) {
          final role = await _getUserRole(user.uid);

          if (role == 'admin') {
            debugPrint('🔀 Redirecting logged-in admin to /admin-home');
            return '/admin-home';
          } else {
            debugPrint('🔀 Redirecting logged-in user to /user-home');
            return '/user-home';
          }
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _AuthDecisionWrapper(),
        ),

        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),

        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),

        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordPage(),
        ),

        GoRoute(
          path: '/user-home',
          builder: (context, state) {
            if (_pendingDeepLinkLocation != null) {
              final location = _pendingDeepLinkLocation;
              _pendingDeepLinkLocation = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go(location!);
              });
            }
            Future.microtask(() {
              if (FirebaseAuth.instance.currentUser != null) {
                Provider.of<FavoriteProvider>(context, listen: false).loadFavorites();
              }
            });
            return const UserHomePage();
          },
        ),

        GoRoute(
          path: '/admin-home',
          builder: (context, state) {
            if (_pendingDeepLinkLocation != null) {
              final location = _pendingDeepLinkLocation;
              _pendingDeepLinkLocation = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go(location!);
              });
            }
            return const AdminHomePage();
          },
        ),

        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(title: 'Primez Sports'),
        ),

        GoRoute(
          path: '/test',
          builder: (context, state) => const TestLauncherPage(),
        ),

        GoRoute(
          path: '/favorite',
          builder: (context, state) => const UserFavoritesPage(),
        ),

        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationPage(),
        ),

        GoRoute(
          path: '/encode',
          builder: (context, state) => const EncodecodeExample(),
        ),

        GoRoute(
          path: '/product/:productId',
          builder: (context, state) {
            final productId = state.pathParameters['productId']!;
            debugPrint('📱 Building ProductDetailLoader for: $productId');
            return ProductDetailLoader(productId: productId);
          },
        ),

        GoRoute(
          path: '/products/:id',
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            debugPrint('📱 Building ProductDetailLoader for: $productId');
            return ProductDetailLoader(productId: productId);
          },
        ),

        GoRoute(
          path: '/product-detail',
          builder: (context, state) {
            final productId = state.uri.queryParameters['id'] ?? '';
            debugPrint('📱 Building ProductDetailLoader for: $productId');
            return ProductDetailLoader(productId: productId);
          },
        ),
      ],

      errorBuilder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Halaman Tidak Ditemukan'),
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
                  Icons.error_outline,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'Halaman Tidak Ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Path: ${state.uri}',
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
                    onPressed: () => context.go('/'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          title: 'Primez Sports',
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },

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
        );
      },
    );
  }
}

class _AuthDecisionWrapper extends StatefulWidget {
  const _AuthDecisionWrapper();

  @override
  State<_AuthDecisionWrapper> createState() => _AuthDecisionWrapperState();
}

class _AuthDecisionWrapperState extends State<_AuthDecisionWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToNextRoute();
  }

  Future<void> _navigateToNextRoute() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.go('/'); 
      } else {
        context.go('/login'); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
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
                  onPressed: () => context.go('/'),
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