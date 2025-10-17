import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/home_page.dart';
import 'package:my_app/theme/app_colors.dart';
import '../../login/login_page.dart';
import 'register_button.dart';

class RegisterForm extends StatefulWidget{
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState () => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackbar("Semua field harus di isi");
      return;
    }
    setState(() => _isLoading = true);

    try{
      UserCredential userCredential = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.updateDisplayName(name);

      _showSnackbar("Registerasi berhasil, selamat datang $name!");
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const LoginPage()),
          );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'Password terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah digunakan';
      } else {
        message = e.message ?? 'Terajadi kesalahan';
      }
      _showSnackbar(message);
    } catch (e) {
      _showSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontSize: 14.sp))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8.sw,
      padding: EdgeInsets.symmetric(horizontal:16.w,vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black26,width: 1.w),
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
            "Register",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _nameController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: "Nama Lengkap",
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w,vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          TextField(
            controller: _emailController,
            style: TextStyle(color: Colors.black),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Email",
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w,vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.red,width: 2),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          TextField(
            controller: _passwordController,
            style: TextStyle(color: Colors.black),
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: "Password",
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w,vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.red,width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                  size: 20.sp,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                ),
            ),
          ),
          SizedBox(height: 16.h),

          RegisterButton(
            isLoading: _isLoading,
            onPressed:_register,
          ),
          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Sudah punya akun?",
                style: TextStyle(fontSize: 13.sp, color: Colors.grey, fontFamily: 'Poppins'),
              ),
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                },
                child: Text(
                  "Login",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp, 
                    color: AppColors.primary, 
                    fontWeight: FontWeight.w600, 
                    decoration: TextDecoration.underline,
                    ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}