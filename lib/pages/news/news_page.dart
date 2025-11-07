import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/pages/news/widgets/news_header.dart';
import 'package:my_app/pages/news/widgets/news_card.dart';
import 'package:my_app/pages/news/news_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';


class UserNewsPage extends StatefulWidget {
  const UserNewsPage({super.key});

  @override
  State<UserNewsPage> createState() => _UserNewsPageState();
}

class _UserNewsPageState extends State<UserNewsPage> {
  int _currentBanner = 0;
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;

  List<News> allNews = [];
  bool isLoading = true;

  Future<void> fetchNews() async {
    try {
      print('🔄 Fetching news from Firestore...');

      final newsSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('date', descending: true)
          .get();

      print('📦 Found ${newsSnapshot.docs.length} news documents');

      if (newsSnapshot.docs.isEmpty) {
        print('⚠️ No news found in collection!');
      }

      final allNewsList = newsSnapshot.docs.map((doc) {
        return News.fromFirestore(doc.data(), doc.id);
      }).toList();

      print('✅ Successfully loaded ${allNewsList.length} news');

      setState(() {
        allNews = allNewsList;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading news: $e');
      print('Stack trace: $stackTrace');
      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading news: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNews();
    _startAutoPlay();
  }

  List<News> get trendingNews => allNews
      .where((n) => n.categories.any((c) => c.toLowerCase().contains('trending')))
      .toList();

  List<News> get soccerNews => allNews
      .where((n) => n.categories.any((c) => c.toLowerCase().contains('soccer')))
      .toList();

  List<News> get latestNews => allNews.take(5).toList();

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (latestNews.isEmpty) return;
      final itemCount = latestNews.length;
      if (itemCount <= 1) return;

      setState(() {
        _currentBanner = (_currentBanner + 1) % itemCount;
      });

      _pageController.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _navigateToDetail(News news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailPage(news: news),
      ),
    );
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allNews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
                      SizedBox(height: 16.h),
                      Text(
                        'Belum ada berita',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Berita akan muncul di sini',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: NewsHeader()),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          if (trendingNews.isNotEmpty)
                            _buildSection('Trending', trendingNews, isHorizontal: true),
                          if (latestNews.isNotEmpty)
                            _buildSection('Terbaru', latestNews, useCarousel: true),
                          SizedBox(height: 80.h),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSection(
    String title,
    List<News> newsList, {
    bool isHorizontal = false,
    bool useCarousel = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
        ),

        if (useCarousel)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    height: 200.h,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentBanner = index);
                      },
                      itemCount: newsList.length,
                      itemBuilder: (context, index) {
                        final news = newsList[index];
                        
                        print('📰 Terbaru #$index - Image URL: ${news.imageUrl1}');
                        
                        return GestureDetector(
                          onTap: () => _navigateToDetail(news),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ProductImage(
                                image: news.imageUrl1,
                                width: double.infinity,
                                height: 200.h,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(12.r),
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
                              Positioned(
                                bottom: 16.h,
                                left: 16.w,
                                right: 16.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      news.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (news.subtitle.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        news.subtitle,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12.sp,
                                          fontFamily: 'Poppins',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(newsList.length, (index) {
                  bool isActive = index == _currentBanner;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    height: isActive ? 10.w : 8.w,
                    width: isActive ? 10.w : 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 12.h),
            ],
          )
        else if (isHorizontal)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildHorizontalList(newsList),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildVerticalCards(newsList),
          ),
      ],
    );
  }

  Widget _buildHorizontalList(List<News> newsList) {
    final formatDate = DateFormat('dd MMM yyyy');
    return SizedBox(
      height: 220.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: newsList.length > 3 ? 3 : newsList.length,
        separatorBuilder: (_, __) => Container(
          width: 1.2,
          height: 180.h,
          color: Colors.grey.shade400,
          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        ),
        itemBuilder: (context, index) {
          final news = newsList[index];
          
          print('📰 Trending #$index - Image URL: ${news.imageUrl1}');
          
          return GestureDetector(
            onTap: () => _navigateToDetail(news),
            child: SizedBox(
              width: 160.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(
                    image: news.imageUrl1,
                    width: 160.w,
                    height: 110.h,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  SizedBox(height: 8.h),
                  if (news.categories.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        news.categories.first,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Text(
                    news.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: "Poppins",
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    formatDate.format(news.date),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey,
                      fontFamily: "Poppins",
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalCards(List<News> newsList) {
    final displayNews = newsList.length > 2 ? newsList.sublist(0, 2) : newsList;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: displayNews.map((news) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: NewsCard(news: news),
          );
        }).toList(),
      ),
    );
  }
}