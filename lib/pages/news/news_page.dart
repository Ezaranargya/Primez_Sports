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

class UserNewsPage extends StatefulWidget {
  const UserNewsPage({super.key});

  @override
  State<UserNewsPage> createState() => _UserNewsPageState();
}

class _UserNewsPageState extends State<UserNewsPage> with AutomaticKeepAliveClientMixin {
  int _currentBanner = 0;
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;

  List<News> allNews = [];
  bool isLoading = true;
  String? userId;
  
  StreamSubscription<QuerySnapshot>? _newsSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _setupNewsListener();
    _startAutoPlay();
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
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (latestNews.isEmpty) return;
      final itemCount = latestNews.length;
      if (itemCount <= 1) return;

      setState(() {
        _currentBanner = (_currentBanner + 1) % itemCount;
      });

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentBanner,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
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
    _autoPlayTimer?.cancel();
    _pageController.dispose();
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
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
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
                    ],
                  ),
                ),
    );
  }

  // ✅ NEW: Trending Section dengan card seperti product
  Widget _buildTrendingSection(String title, List<News> newsList) {
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
        SizedBox(
          height: 240.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: newsList.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final news = newsList[index];
              return _buildTrendingCard(news);
            },
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Trending Card (mirip product card)
  Widget _buildTrendingCard(News news) {
    return GestureDetector(
      onTap: () => _navigateToDetail(news),
      child: Container(
        width: 160.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
              child: ProductImage(
                image: news.imageUrl1,
                width: 160.w,
                height: 120.h,
                fit: BoxFit.cover,
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date (acts as price in product card)
                    Text(
                      DateFormat('dd MMM yyyy').format(news.date),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // Title
                    Text(
                      news.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

  // ✅ Latest Section dengan carousel (tetap seperti sebelumnya)
  Widget _buildLatestSection(String title, List<News> newsList) {
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
        _buildCarousel(newsList),
      ],
    );
  }

  Widget _buildCarousel(List<News> newsList) {
    return Column(
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
    );
  }
}