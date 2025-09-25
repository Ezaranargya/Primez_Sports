import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/register_page.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'auth_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Primez Sportz',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/register': (context) => const RegisterPage(),
        '/test': (context) => const TestLauncherPage(),
      },
    );
  }
}

class TestLauncherPage extends StatelessWidget {
  const TestLauncherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test URL Launcher")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final uri = Uri.parse("https://www.google.com");
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              debugPrint("Gagal membuka link");
            }
          },
          child: const Text("Test buka link"),
        ),
      ),
    );
  }
}
