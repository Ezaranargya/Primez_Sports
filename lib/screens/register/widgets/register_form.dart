import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/theme/app_colors.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveUserData(String uid, String username, String email) async {
    final defaultRole = email.contains('admin') ? 'admin' : 'user';
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("✅ Firestore: User $uid dengan username '$username' dan role '$defaultRole' tersimpan.");
    } catch (e) {
      print("❌ Firestore Error: Gagal menyimpan data user: $e");
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    
    try {
      print("🔐 Memulai pendaftaran...");
      
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final User user = credential.user!;
      print("✅ Pendaftaran Firebase berhasil: ${user.email}");

      await _saveUserData(user.uid, username, user.email!);

      if (!mounted) return;
      
      _showSnackBar("Pendaftaran berhasil! Silakan login.", success: true);

      Future.microtask(() {
        if (!mounted) return;
        context.go('/login');
      });

    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code} - ${e.message}");
      if (mounted) {
        String errorMessage = "Pendaftaran gagal. Cek kembali data Anda.";
        if (e.code == 'weak-password') {
          errorMessage = "Password terlalu lemah. Gunakan minimal 6 karakter.";
        } else if (e.code == 'email-already-in-use') {
          errorMessage = "Email ini sudah terdaftar. Silakan login.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Format email tidak valid.";
        }
        _showSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      print("❌ Error tidak terduga: $e");
      print("📋 Stack trace: $stackTrace");
      if (mounted) {
        _showSnackBar("Terjadi kesalahan sistem.");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username tidak boleh kosong.';
    }
    if (value.length < 3) {
      return 'Username minimal 3 karakter.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Masukkan format email yang valid.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Container(
              width: 300.w,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.black, width: 1.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Daftar",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  TextFormField(
                    controller: _usernameController,
                    validator: _usernameValidator,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Username",
                      hintStyle: TextStyle(fontSize: 14.sp),
                      prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(fontSize: 14.sp),
                      prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _passwordValidator,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(fontSize: 14.sp),
                      prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Daftar',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sudah punya akun? ",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[700],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          print("👉 TOMBOL LOGIN DIKLIK");
                          context.go('/login');
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}