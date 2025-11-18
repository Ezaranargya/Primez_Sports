import 'package:flutter/material.dart';
import 'package:my_app/theme/app_colors.dart';

class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.primary,
    );
  }
}
