import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart'; 
import 'package:my_app/auth/register/register_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/auth/register/widgets/register_form.dart';
import 'package:my_app/admin/pages/admin_home_page.dart';
import 'package:my_app/pages/user/user_home_page.dart';
import 'login_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _getUserRole(String uid, String email) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['role'] ?? 'user';
      } else {
        // Logika pembuatan role default jika dokumen user tidak ada
        final defaultRole = email.contains('admin') ? 'admin' : 'user';
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'role': defaultRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return defaultRole;
      }
    } catch (_) {
      // Fallback jika ada error Firestore
      return email.contains('admin') ? 'admin' : 'user';
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Email & Password tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("🔐 Memulai login...");
      
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      print("✅ Login Firebase berhasil: ${credential.user?.email}");
      
      final User user = credential.user!;
      final role = await _getUserRole(user.uid, user.email!);
      
      print("👤 Role yang didapat: '$role'");
      
      if (!mounted) {
        print("⚠️ Widget tidak mounted setelah getUserRole");
        return;
      }

      // Matikan loading state dulu
      setState(() => _isLoading = false);

      print("🚀 Menjadwalkan navigasi untuk role: $role");

      // ✅ GUNAKAN GoRouter untuk navigasi setelah login
      Future.microtask(() {
        if (!mounted) return;

        print("📍 Navigasi ke ${role.toLowerCase().trim() == 'admin' ? 'Admin' : 'User'}HomePage...");

        // Gunakan GoRouter, bukan Navigator
        if (role.toLowerCase().trim() == 'admin') {
          context.go('/admin-home');
        } else {
          context.go('/user-home');
        }
      });

      _showSnackBar("Login berhasil sebagai $role");
      
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code} - ${e.message}");
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = "Login gagal. Cek kembali email dan password Anda.";
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
           errorMessage = "Email atau password yang Anda masukkan salah.";
        }
        _showSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      print("❌ Error tidak terduga: $e");
      print("📋 Stack trace: $stackTrace");
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Terjadi kesalahan: $e");
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('berhasil') ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 300.w,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.black, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Login",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 14.h),

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Email",
                  hintStyle: TextStyle(fontSize: 14.sp),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.primary),
                  ), 
                ),
              ),
              SizedBox(height: 10.h),

              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.black),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: TextStyle(fontSize: 14.sp),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.primary),
                  ), 
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 18.sp,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              LoginButton(
                isLoading: _isLoading,
                onPressed: _login,
              ),

              SizedBox(height: 10.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Belum punya akun? ",
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      print("👉 DAFTAR DIKLIK");
                      // ✅ GUNAKAN context.go() atau context.push() BUKAN Navigator.push()
                      context.push('/register'); // atau context.go('/register')
                    },
                    child: Text(
                      "Daftar",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}