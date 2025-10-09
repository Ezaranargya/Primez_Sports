import 'package:flutter/material.dart';

class RegisterBackground extends StatelessWidget{
  const RegisterBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage("https://i.ibb.co.com/RGSj4JLn/register.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black54, 
            BlendMode.darken,
            )
          ),
      ),
    );
  }
}