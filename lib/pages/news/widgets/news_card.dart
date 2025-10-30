import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/pages/news/news_detail_page.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';




class NewsCard extends StatelessWidget {
  final NewsModel news;

  const NewsCard({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsDetailPage(news: news)),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: ProductImage(
                  image: news.imageUrl1.isNotEmpty
                      ? news.imageUrl1
                      : news.imageAsset.isNotEmpty
                          ? news.imageAsset
                          : '',
                  width: 100.w,
                  height: 100.h,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12.w),

              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Text(
                      news.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    
                    if (news.subtitle.isNotEmpty)
                      Text(
                        news.subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[700],
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 6.h),

                    
                    Row(
                      children: [
                        Icon(Icons.person, size: 14.sp, color: Colors.grey[600]),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            news.author.isNotEmpty ? news.author : 'Unknown',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (news.brand.isNotEmpty) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              news.brand,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontFamily: 'Poppins',
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 4.h),

                    
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: news.categories.map((category) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[700],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
