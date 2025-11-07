import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/screens/register/widgets/register_background.dart';
import 'package:my_app/screens/register/widgets/register_form.dart';
import '../../screens/login/login_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          RegisterBackground(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: RegisterForm(),
            ),
          )
        ],
      ),
    );
  }
}
