import 'package:flutter/material.dart';

class UserFavoritePage extends StatefulWidget {
  const UserFavoritePage({super.key});

  @override
  State<UserFavoritePage> createState() => _UserFavoritePageState();
}

class _UserFavoritePageState extends State<UserFavoritePage> {
  int selectedIndex = 1;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        backgroundColor: const Color(0xFFE53E3E),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          "Belum ada produk favorite",
          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
        ),
      ),
    );
  }
}
