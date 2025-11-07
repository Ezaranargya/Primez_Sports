import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/pages/news/news_detail_page.dart';

class NewsBannerCard extends StatelessWidget {
  final NewsModel news;

  const NewsBannerCard({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsDetailPage(news: news),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              _buildNewsImage(),
              Positioned(
                bottom: 12.h,
                left: 12.w,
                right: 12.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (news.brand.isNotEmpty)
                      Text(
                        news.brand,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      news.title.isNotEmpty ? news.title : "Untitled",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (news.subtitle.isNotEmpty)
                      Text(
                        news.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  
  Widget _buildNewsImage() {
    final image = news.imageUrl;

    if (image.isEmpty) return _placeholder();

    
    if (image.startsWith('data:image')) {
      try {
        final base64Data = image.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          height: 180.h,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      } catch (e) {
        return _placeholder();
      }
    }

    
    if (image.startsWith('http')) {
      return Image.network(
        image,
        height: 180.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    
    return Image.asset(
      news.safeImageAsset,
      height: 180.h,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  
  Widget _placeholder() {
    return Container(
      height: 180.h,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 40.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 4.h),
            Text(
              "Gambar tidak tersedia",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
