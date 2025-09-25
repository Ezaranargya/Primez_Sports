import 'package:flutter/material.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState () => _AdminProfilePage();
}

class _AdminProfilePage extends State<AdminProfilePage> {
  String _name = "Admin";
  final TextEditingController _controller = TextEditingController();

  void _editProfile () {
    _controller.text = _name;
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title:  const Text("Edit Profile"),
        content: TextField(controller: _controller),
        actions: [
          TextButton(
            onPressed: () {
              if (_controller.text.isNotEmpty){
                setState(() {
                  _name = _controller.text;
                });
              }
              Navigator.pop(context);
            }, 
            child: const Text("Save"),
            )
        ],
      )
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Nama: $_name", style:   const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _editProfile, 
              child: const Text("Edit Profile"),
              )
          ],
        ),
      ),
    );
  }
}