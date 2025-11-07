import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterButton extends StatelessWidget{
  final bool isLoading;
  final VoidCallback onPressed;

  const RegisterButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.sw,
      height: 48.h,
      child: ElevatedButton(
        style:ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53E3E),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        onPressed: isLoading ? null: onPressed,
        child: isLoading
        ? SizedBox(
          width: 20.w,
          height: 20.w,
          child: const CircularProgressIndicator(color: Colors.red),
        ) 
        :Text(
          "Register",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
        ),
    );
  }
}