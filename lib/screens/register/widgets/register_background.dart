import 'package:flutter/material.dart';

class RegisterBackground extends StatelessWidget{
  const RegisterBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          height: double.infinity,
          child: Image(
            image: AssetImage("assets/register.jpg"),
            fit: BoxFit.cover,
            ),
        );
  }
}