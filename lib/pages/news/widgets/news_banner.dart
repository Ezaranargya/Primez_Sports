import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/pages/user/widgets/banner_carousel.dart';
import 'package:my_app/models/product_model.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/news_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/theme/app_colors.dart';

class NewsBanner extends StatelessWidget {
  const NewsBanner({super.key});

  Future<List<Product>> fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .limit(3)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error fetching products: $e');
      return []; 
    }
  }

  Future<int> fetchUnreadNewsCount() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await FirebaseFirestore.instance
          .collection('news')
          .get();

      final newsList = snapshot.docs
          .map((doc) => News.fromMap(doc.data(), doc.id))
          .toList();

      return newsList.where((news) => !news.isReadBy(userId)).length;
    } catch (e) {
      print('❌ Error fetching unread news count: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest product',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              FutureBuilder<int>(
                future: fetchUnreadNewsCount(), 
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/news');
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.newspaper,
                            size: 24.sp,
                            color: Colors.black87,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20.w,
                                minHeight: 20.h,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  );
                },
              )
            ],
          ),
        ),

        FutureBuilder<List<Product>>(
          future: fetchProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 180.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return SizedBox(
                height: 180.h,
                child: Center(
                  child: Text(
                    'Error loading products',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: 180.h,
                child: Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              );
            } else {
              final products = snapshot.data!;

              return BannerCarousel(
                banners: products,
                height: 180.h,
                borderRadius: 16.r,
                activeColor: Colors.redAccent,
                onBannerTap: (product) {
                  print('Banner ${product.name} diklik');
                },
              );
            }
          },
        ),
      ],
    );
  }
}