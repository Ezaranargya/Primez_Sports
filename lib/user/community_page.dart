import 'package:flutter/material.dart';
import 'community_chat_page.dart';

class UserCommunityPage extends StatefulWidget {
  const UserCommunityPage({super.key});

  @override
  State<UserCommunityPage> createState() => _UserCommunityPageState();
}

class _UserCommunityPageState extends State<UserCommunityPage> {
  int selectedIndex = 2;

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
    final communities = [
      {"name": "Kumpulan Brand Nike Official", "brand": "Nike"},
      {"name": "Kumpulan Brand Jordan Official", "brand": "Jordan"},
      {"name": "Kumpulan Brand Adidas Official", "brand": "Adidas"},
      {"name": "Kumpulan Brand Under Armour Official", "brand": "Under Armour"},
      {"name": "Kumpulan Brand Puma Official", "brand": "Puma"},
      {"name": "Kumpulan Brand Mizuno Official", "brand": "Mizuno"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Komunitas"),
        backgroundColor: const Color(0xFFE53E3E),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: communities.length,
        itemBuilder: (context, index) {
          final community = communities[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Text(
                  community["brand"]![0],
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              title: Text(
                community["name"]!,
                style: const TextStyle(color: Colors.black),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommunityChatPage(
                      brand: community["brand"]!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
