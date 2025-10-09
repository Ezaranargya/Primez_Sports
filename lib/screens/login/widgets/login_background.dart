import 'package:flutter/material.dart';

class LoginBackground extends StatelessWidget{
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage("https://i.ibb.co.com/6RBt2GGH/login2.jpg"),
              fit: BoxFit.cover, 
              ),
          ),
        ),
          Container(color: Colors.black54),
      ],
    );
  }
}