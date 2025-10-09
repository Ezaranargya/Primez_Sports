import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/screens/login/widgets/login_background.dart';
import 'widgets/login_background.dart';
import 'widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          LoginBackground(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: LoginForm(),
            ),
          )
        ],
      ),
    );
  }
}
