import 'package:flutter/material.dart';

class AdminCommunityPage extends StatefulWidget{
  const AdminCommunityPage({super.key});

  @override
  State<AdminCommunityPage> createState () => _AdminCommunityPageState();
}

class _AdminCommunityPageState extends State<AdminCommunityPage> {
  final List<String> _posts = ["komunitas sepatu"];
  final TextEditingController _controller = TextEditingController();

  void _addPost() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _posts.add(_controller.text);
      _controller.clear();
      });
    }
  }

  void _editPost(int index) {
    _controller.text = _posts[index];
    showDialog(
      context: context,
       builder: (context) => AlertDialog(
        title: const Text("Edit Posts"),
        content: TextField(controller: _controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed:  () {
              if (_controller.text.isNotEmpty) {
                setState(() {
                  _posts[index] = _controller.text;
                });
                _controller.clear();
              }
              Navigator.pop(context);
            }, 
            child: const Text("Save"),
            ),
        ],
       )
       );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Komunitas")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: "Tambah Post",
                      border: OutlineInputBorder(),
                    ),
                  ), 
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _addPost, child: const Text("Add")),
              ],
            ), 
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(_posts[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit,color: Colors.red),
                    onPressed: () => _editPost(index),
                    ),
                ),
                ),
              ),
        ],
      ),
    );
  }
}