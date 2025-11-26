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
      const defaultRole = 'user'; 
      
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return defaultRole;
    }
  } catch (_) {
    return 'user'; 
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
      debugPrint("🔐 Memulai login...");
      
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      debugPrint("✅ Login Firebase berhasil: ${credential.user?.email}");
      
      final User user = credential.user!;
      final role = await _getUserRole(user.uid, user.email!);
      
      debugPrint("👤 Role yang didapat: '$role'");
      
      if (!mounted) {
        debugPrint("⚠️ Widget tidak mounted setelah getUserRole");
        return;
      }

      setState(() => _isLoading = false);

      // ✅ PERBAIKAN CRITICAL: HAPUS SEMUA NAVIGASI MANUAL
      // Biarkan GoRouter redirect di main.dart yang handle navigasi otomatis
      
      debugPrint("✅ Login selesai, menunggu GoRouter redirect otomatis...");
      
      _showSnackBar("Login berhasil sebagai $role");
      
      // ❌ HAPUS INI - INI YANG MENYEBABKAN ERROR!
      // Future.microtask(() {
      //   if (!mounted) return;
      //   debugPrint("📍 Navigasi ke ${role.toLowerCase().trim() == 'admin' ? 'Admin' : 'User'}HomePage...");
      //   if (role.toLowerCase().trim() == 'admin') {
      //     context.go('/admin-home');
      //   } else {
      //     context.go('/user-home');
      //   }
      // });

    } on FirebaseAuthException catch (e) {
      debugPrint("❌ FirebaseAuthException: ${e.code} - ${e.message}");
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = "Login gagal. Cek kembali email dan password Anda.";
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
           errorMessage = "Email atau password yang Anda masukkan salah.";
        }
        _showSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error tidak terduga: $e");
      debugPrint("📋 Stack trace: $stackTrace");
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80.w,
                  height: 80.h,
                  margin: EdgeInsets.only(bottom: 30.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset(
                      'assets/Primez_Sports.jpg', 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                Container(
                  width: 300.w,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
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
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 14.h),

                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: Colors.black, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: Colors.black, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ), 
                    ),
                  ),
                  SizedBox(height: 10.h),

                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.black),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "password",
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: Colors.black, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ), 
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[400],
                          size: 20.sp,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        debugPrint("🔑 Lupa Password diklik");
                        context.push('/reset-password');
                      },
                      child: Text(
                        "Lupa Password?",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

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
                          debugPrint("👉 DAFTAR DIKLIK");
                          context.push('/register'); 
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}