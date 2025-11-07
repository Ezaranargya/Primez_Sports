import 'package:flutter/material.dart';
import 'package:my_app/pages/user/user_home_page.dart';
import 'package:my_app/pages/product/product_page.dart';
import 'package:my_app/pages/community/community_page.dart';
import 'package:my_app/pages/news/news_page.dart';
import 'package:my_app/pages/profile/profile_page.dart';
import 'package:my_app/pages/favorite/favorite_page.dart';

class BottomNav extends StatefulWidget {
    const BottomNav ({super.key});

    @override
    State<BottomNav> createState () => _BottomNavState();
}
    
class _BottomNavState extends State<BottomNav> {
    int _selectedIndex = 0;

    final List<Widget> _pages = [
        UserHomePage(),
        UserFavoritesPage(),
        UserProductPage(),
        UserCommunityPage(),
        UserNewsPage(),
        UserProfilePage(),
    ];

    void _onItemTapped(int index) {
        setState(() {
          _selectedIndex = index;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const[
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                    BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorite"),
                    BottomNavigationBarItem(icon: Icon(Icons.message), label: "Komunitas"),
                    BottomNavigationBarItem(icon: Icon(Icons.article), label: "News"),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
                ],
            ),
        );
    }
}