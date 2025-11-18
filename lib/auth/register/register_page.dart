import 'package:flutter/material.dart';
import 'package:my_app/auth/register/widgets/register_form.dart';
import 'package:my_app/auth/register/widgets/register_background.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const RegisterBackground(),
          SafeArea(
            child: const RegisterForm(),
          ),
        ],
      ),
    );
  }
}