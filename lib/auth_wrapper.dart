import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/home_page.dart';
import 'package:my_app/pages/user/user_home_page.dart';
import 'package:my_app/admin/pages/admin_home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role from Firestore: $e');
      return null;
    }
  }

  Future<bool> _isAdmin(User user) async {
    String? role = await getUserRole(user.uid);
    if (role != null) {
      return role == 'admin';
    }
    
    return user.email?.contains('admin') == true;
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
        
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: _isAdmin(snapshot.data!),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (adminSnapshot.data == true) {
                return const AdminHomePage();
              } else {
                return const UserHomePage();
              }
            },
          );
        } else {
          return const HomePage(title: 'Primez Sports',);
        }
      },
    );
  }
}