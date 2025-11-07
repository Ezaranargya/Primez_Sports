import 'package:flutter/material.dart';

class LoginBackground extends StatelessWidget{
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: Image(
            image: AssetImage("assets/login2.jpg"),
            fit: BoxFit.cover,
            ),
        ),
          Container(color: Colors.black54),
      ],
    );
  }
}