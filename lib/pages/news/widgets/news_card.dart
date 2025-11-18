import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';
import 'package:my_app/pages/news/news_detail_page.dart';

class NewsCard extends StatelessWidget {
  final News news;
  final String? userId; 

  const NewsCard({
    super.key,
    required this.news,
    this.userId, 
  });

  @override
  Widget build(BuildContext context) {
    final formatDate = DateFormat('dd MMM yyyy');
    
    final isRead = userId != null && userId!.isNotEmpty && news.isReadBy(userId!);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(news: news),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: !isRead ? Border.all(
            color: Colors.blue,
            width: 2,
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                  child: ProductImage(
                    image: news.imageUrl1,
                    width: 120.w,
                    height: 120.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    if (news.categories.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          news.categories.first.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            height: 1.0, // 👈 Kurangi line height
                          ),
                        ),
                      ),

                    SizedBox(height: 4.h), // 👈 UBAH: dari 8.h → 4.h (lebih rapat)
                    Text(
                      news.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                        height: 1.2, // 👈 TAMBAH: Kurangi line height title
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 4.h), // 👈 UBAH: dari 6.h → 4.h (lebih rapat)
                    if (news.subtitle.isNotEmpty)
                      Text(
                        news.subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                          height: 1.2, // 👈 TAMBAH: Kurangi line height subtitle
                        ),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),

                    SizedBox(height: 4.h), // 👈 UBAH: dari 8.h → 4.h (lebih rapat)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12.sp,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          formatDate.format(news.date),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[500],
                            fontFamily: 'Poppins',
                            height: 1.0, // 👈 TAMBAH: Kurangi line height tanggal
                          ),
                        ),
                        if (news.author.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              news.author,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[500],
                                fontFamily: 'Poppins',
                                height: 1.0, // 👈 TAMBAH: Kurangi line height author
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}