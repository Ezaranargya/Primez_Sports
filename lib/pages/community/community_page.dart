import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/pages/community/widgets/community_header.dart';
import 'package:my_app/pages/community/widgets/community_card.dart';
import 'package:my_app/pages/community/community_footer.dart';
import 'package:my_app/pages/community/community_chat_page.dart';
import 'package:my_app/theme/app_colors.dart';

class UserCommunityPage extends StatefulWidget {
  const UserCommunityPage({super.key});

  @override
  State<UserCommunityPage> createState() => _UserCommunityPageState();
}

class _UserCommunityPageState extends State<UserCommunityPage> {
  final List<Map<String, dynamic>> communities = [
    {
      "name": "Kumpulan Sepatu Brand Nike Official",
      "brand": "Nike",
      "logo": "assets/logo_nike.png"
    },
    {
      "name": "Kumpulan Sepatu Brand Jordan Official",
      "brand": "Jordan",
      "logo": "assets/logo_jordan.png"
    },
    {
      "name": "Kumpulan Sepatu Brand Adidas Official",
      "brand": "Adidas",
      "logo": "assets/logo_adidas.png"
    },
    {
      "name": "Kumpulan Sepatu Brand Under Armour Official",
      "brand": "Under Armour",
      "logo": "assets/logo_under_armour.png"
    },
    {
      "name": "Kumpulan Sepatu Brand Puma Official",
      "brand": "Puma",
      "logo": "assets/logo_puma.png"
    },
    {
      "name": "Kumpulan Sepatu Brand Mizuno Official",
      "brand": "Mizuno",
      "logo": "assets/logo_mizuno.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Komunitas",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.25),
      ),

      
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: ListView(
          children: [
            ...communities.map(
              (community) => CommunityCard(
                title: community["name"]!,
                brand: community["brand"]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityChatPage(
                        brand: community["brand"]!,
                        logoPath: community["logo"]!,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
            const CommunityFooter(),
          ],
        ),
      ),
    );
  }
}
