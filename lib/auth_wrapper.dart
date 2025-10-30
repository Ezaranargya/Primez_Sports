import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/screens/login/login_page.dart';
import 'package:my_app/pages/user/user_home_page.dart';
import 'package:my_app/admin/pages/admin_home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String?> _getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        final role = doc.data()?['role'] as String?;
        print('✅ User role loaded: $role');
        return role;
      }
      print('⚠️ User document not found');
      return null;
    } catch (e) {
      print('❌ Error getting user role: $e');
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
              child: CircularProgressIndicator(),
            ),
          );
        }

        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AuthWrapper(),
                        ),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        
        if (snapshot.hasData) {
          final user = snapshot.data!;
          print('✅ User is logged in: ${user.email}');
          
          
          Future.microtask(() {
            try {
              Provider.of<FavoriteProvider>(context, listen: false)
                  .loadFavorites();
            } catch (e) {
              print('❌ Error loading favorites: $e');
            }
          });

          return FutureBuilder<String?>(
            future: _getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat data pengguna...'),
                      ],
                    ),
                  ),
                );
              }

              
              if (roleSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gagal memuat data pengguna',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '${roleSnapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Logout & Login Ulang'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final role = roleSnapshot.data;
              print('✅ Navigating to: ${role == 'admin' ? 'Admin' : 'User'} page');
              
              
              if (role == 'admin') {
                return const AdminHomePage();
              } else {
                
                return const UserHomePage();
              }
            },
          );
        }

        
        print('ℹ️ No user logged in, showing login page');
        return const LoginPage();
      },
    );
  }
}