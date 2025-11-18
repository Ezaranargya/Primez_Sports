import 'package:flutter/material.dart';
import 'package:my_app/theme/app_colors.dart';

class RegisterBackground extends StatelessWidget {
  const RegisterBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.primary,
    );
  }
}