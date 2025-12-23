import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/pages/news/widgets/news_header.dart';
import 'package:my_app/pages/news/widgets/news_card.dart';
import 'package:my_app/pages/news/news_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class UserNewsPage extends StatefulWidget {
  const UserNewsPage({super.key});

  @override
  State<UserNewsPage> createState() => _UserNewsPageState();
}

class _UserNewsPageState extends State<UserNewsPage> with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  int _currentPage = 0;

  List<News> allNews = [];
  bool isLoading = true;
  String? userId;
  
  StreamSubscription<QuerySnapshot>? _newsSubscription;

  static const int _infiniteMultiplier = 10000;
  int get _initialPage => latestNews.isEmpty ? 0 : _infiniteMultiplier * latestNews.length;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _setupNewsListener();
  }

  void _initializePageController() {
    if (latestNews.isNotEmpty) {
      _pageController = PageController(
        initialPage: _initialPage,
        viewportFraction: 0.9,
      );
      _startAutoPlay();
    }
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      userId = user?.uid;
    });
  }

  int get unreadNewsCount {
    if (userId == null) return 0;
    return allNews.where((news) => !news.isReadBy(userId!)).length;
  }

  void _setupNewsListener() {
    print('📡 Setting up news listener...');
    
    _newsSubscription = FirebaseFirestore.instance
        .collection('news')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            print('🔄 News snapshot received: ${snapshot.docs.length} documents');
            
            final allNewsList = snapshot.docs.map((doc) {
              return News.fromFirestore(doc.data(), doc.id);
            }).toList();

            for (var news in allNewsList) {
              final isRead = userId != null && news.isReadBy(userId!);
              print('📰 ${news.id}: readBy=${news.readBy.length}, isRead=$isRead');
            }

            if (mounted) {
              setState(() {
                allNews = allNewsList;
                isLoading = false;
              });
              
              _initializePageController();
              
              final unread = unreadNewsCount;
              print('📊 Unread count updated: $unread');
            }
          },
          onError: (error) {
            print('❌ Error in news listener: $error');
            if (mounted) {
              setState(() => isLoading = false);
            }
          },
        );
  }

  Future<void> fetchNews() async {
    try {
      print('🔄 Manual refresh triggered');
      
      final newsSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('date', descending: true)
          .get();

      final allNewsList = newsSnapshot.docs.map((doc) {
        return News.fromFirestore(doc.data(), doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          allNews = allNewsList;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading news: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<News> get trendingNews => allNews
      .where((n) => n.categories.any((c) => c.toLowerCase().contains('trending')))
      .toList();

  List<News> get latestNews {
    final trendingIds = trendingNews.map((n) => n.id).toSet();
    return allNews
        .where((n) => !trendingIds.contains(n.id))
        .take(5)
        .toList();
  }

  void _startAutoPlay() {
    if (latestNews.isEmpty) return;
    Future.delayed(const Duration(seconds: 3), _autoSlide);
  }

  void _autoSlide() {
    if (!mounted || latestNews.isEmpty || !_pageController.hasClients) return;

    final currentPageValue = _pageController.page ?? _initialPage.toDouble();

    _pageController.animateToPage(
      currentPageValue.toInt() + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(seconds: 3), _autoSlide);
  }

  Future<void> _navigateToDetail(News news) async {
    print('🚀 Navigating to news detail: ${news.id}');
    print('   Current readBy: ${news.readBy}');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailPage(news: news),
      ),
    );
    
    print('⬅️ Returned from detail page. Result: $result');
    
    if (result == true) {
      print('🔄 News was marked as read, waiting for listener update...');
    }
  }

  @override
  void dispose() {
    if (latestNews.isNotEmpty) {
      _pageController.dispose();
    }
    _newsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Berita',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
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
              : RefreshIndicator(
                  onRefresh: fetchNews,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (trendingNews.isNotEmpty)
                          _buildTrendingSection('Trending', trendingNews),
                        
                        if (latestNews.isNotEmpty)
                          _buildLatestSection('Terbaru', latestNews),
                        
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTrendingSection(String title, List<News> newsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        // Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Card Container with horizontal scroll
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 12.w),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(newsList.length, (index) {
                final news = newsList[index];
                return Row(
                  children: [
                    _buildTrendingCard(news),

                    // Divider between cards
                    if (index != newsList.length - 1)
                      Container(
                        height: 120.h,
                        width: 1.2.w,
                        margin: EdgeInsets.symmetric(horizontal: 10.w),
                        color: Colors.grey.shade300,
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(News news) {
    return GestureDetector(
      onTap: () => _navigateToDetail(news),
      child: Container(
        width: 115.w,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: ProductImage(
                image: news.imageUrl1,
                width: double.infinity,
                height: 100.h,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 6.h),

            // Date
            Text(
              DateFormat('dd MMM yyyy').format(news.date),
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            // Title
            Text(
              news.title,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'Poppins',
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestSection(String title, List<News> newsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        _buildCarousel(newsList),
      ],
    );
  }

  Widget _buildCarousel(List<News> newsList) {
    if (newsList.isEmpty) {
      return Container(
        height: 180.h,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: Text(
            'No News Available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: null,
            onPageChanged: (index) {
              setState(() => _currentPage = index % newsList.length);
            },
            itemBuilder: (context, index) {
              final actualIndex = index % newsList.length;
              final news = newsList[actualIndex];

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: GestureDetector(
                  onTap: () => _navigateToDetail(news),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.r),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background color
                          Container(color: Colors.grey[200]),
                          
                          // News Image
                          ProductImage(
                            image: news.imageUrl1,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),

                          // Title at top
                          Positioned(
                            top: 20.h,
                            left: 20.w,
                            right: 20.w,
                            child: Text(
                              news.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Date and Read More at bottom
                          Positioned(
                            bottom: 20.h,
                            left: 20.w,
                            right: 20.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy').format(news.date),
                                  style: TextStyle(
                                    color: AppColors.backgroundColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Baca selengkapnya',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 16.h),

        // Page Indicator
        SmoothPageIndicator(
          controller: _pageController,
          count: newsList.length,
          effect: WormEffect(
            dotHeight: 8.h,
            dotWidth: 8.w,
            spacing: 8.w,
            activeDotColor: AppColors.primary,
            dotColor: Colors.grey.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}