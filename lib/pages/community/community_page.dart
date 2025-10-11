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
  final List<Map<String, String>> communities = [
    {"name": "Kumpulan Sepatu Brand Nike Official", "brand": "Nike"},
    {"name": "Kumpulan Sepatu Brand Jordan Official", "brand": "Jordan"},
    {"name": "Kumpulan Sepatu Brand Adidas Official", "brand": "Adidas"},
    {"name": "Kumpulan Sepatu Brand Under Armour Official", "brand": "Under Armour"},
    {"name": "Kumpulan Sepatu Brand Puma Official", "brand": "Puma"},
    {"name": "Kumpulan Sepatu Brand Mizuno Official", "brand": "Mizuno"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.h),
        child: const CommunityHeader(title: "Komunitas"),
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
                      builder: (_) =>
                          CommunityChatPage(brand: community["brand"]!),
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