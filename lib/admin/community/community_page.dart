import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/admin/pages/admin_home_page.dart';
import 'package:my_app/pages/community/widgets/community_header.dart';
import 'package:my_app/pages/community/widgets/community_card.dart';
import 'package:my_app/admin/community/admin_community_chat_page.dart';
import 'package:my_app/theme/app_colors.dart';

class AdminCommunityPage extends StatefulWidget {
  const AdminCommunityPage({super.key});

  @override
  State<AdminCommunityPage> createState() => _AdminCommunityPageState();
}

class _AdminCommunityPageState extends State<AdminCommunityPage> {
  final List<Map<String, String>> communities = [
    {"name": "Kumpulan Brand Nike Official", "brand": "Nike"},
    {"name": "Kumpulan Brand Jordan Official", "brand": "Jordan"},
    {"name": "Kumpulan Brand Adidas Official", "brand": "Adidas"},
    {"name": "Kumpulan Brand Under Armour Official", "brand": "Under Armour"},
    {"name": "Kumpulan Brand Puma Official", "brand": "Puma"},
    {"name": "Kumpulan Brand Mizuno Official", "brand": "Mizuno"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Admin Komunitas",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.backgroundColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: ListView(
          children: [
            
            SizedBox(height: 8.h), 
            ...communities.map(
              (community) => CommunityCard(
                title: community["name"]!,
                brand: community["brand"]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminCommunityChatPage(brand: community["brand"]!),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Text(
                "*Pilih brand untuk membuat posting atau mengelola konten komunitas.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}