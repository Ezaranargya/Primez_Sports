import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class NewsDetailPage extends StatefulWidget {
  final News news;

  const NewsDetailPage({super.key, required this.news});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  String? userId;
  bool isMarking = false;
  bool hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _markAsRead();
      }
    });
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      userId = user?.uid;
    });
  }

  Future<void> _markAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('⚠️ User not logged in');
      return;
    }

    if (isMarking) {
      print('⏳ Already marking as read...');
      return;
    }

    if (widget.news.isReadBy(userId)) {
      print('✅ News already marked as read (from local): ${widget.news.id}');
      hasMarkedAsRead = false;
      return;
    }

    setState(() {
      isMarking = true;
    });

    try {
      print('📖 Attempting to mark news as read: ${widget.news.id}');
      
      try {
        await FirebaseFirestore.instance
            .collection('news')
            .doc(widget.news.id)
            .update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
        
        print('✅ Method 1 Success: Updated news.readBy array');
        hasMarkedAsRead = true;
        
      } catch (e) {
        print('⚠️ Method 1 Failed: $e');
        print('🔄 Trying Method 2: User readNews collection...');
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('readNews')
            .doc(widget.news.id)
            .set({
          'newsId': widget.news.id,
          'readAt': FieldValue.serverTimestamp(),
          'title': widget.news.title,
        }, SetOptions(merge: true));
        
        print('✅ Method 2 Success: Saved to users/$userId/readNews');
        hasMarkedAsRead = true;
      }
      
    } catch (e) {
      print('❌ All methods failed: $e');
      hasMarkedAsRead = false;
    } finally {
      if (mounted) {
        setState(() {
          isMarking = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatDate = DateFormat('dd MMMM yyyy', 'id_ID');

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, hasMarkedAsRead);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              expandedHeight: 300.h,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context, hasMarkedAsRead);
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(
                      image: widget.news.imageUrl1,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.zero,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.news.categories.isNotEmpty)
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: widget.news.categories.map((category) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      SizedBox(height: 16.h),
                      Text(
                        widget.news.title,
                        style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),

                      SizedBox(height: 10.h),
                      if (widget.news.subtitle.isNotEmpty)
                        Text(
                          widget.news.subtitle,
                          textAlign: TextAlign.justify,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            color: Colors.black87,
                            height: 1.35,
                            letterSpacing: -1,
                            wordSpacing: 0,
                          ),
                        ),

                      SizedBox(height: 16.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          if (widget.news.author.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline,
                                    size: 16.sp, color: Colors.grey[600]),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    'By ${widget.news.author}',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[600],
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16.sp, color: Colors.grey[600]),
                              SizedBox(width: 4.w),
                              Text(
                                formatDate.format(widget.news.date),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),
                      Divider(color: Colors.grey[300], thickness: 1),
                      SizedBox(height: 24.h),

                      ...widget.news.content.map((block) => _buildContentBlock(block)),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBlock(ContentBlock block) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.type == 'text' && block.value.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Text(
                block.value,
                textAlign: TextAlign.justify,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  height: 1.7,
                  letterSpacing: 0.3,
                  wordSpacing: 1,
                  color: Colors.black87,
                ),
              ),
            ),

          if (block.type == 'image' && block.value.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ProductImage(
              image: block.value,
              width: double.infinity,
              height: 200.h,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12.r),
            ),
            if (block.caption != null && block.caption!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                block.caption!,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}