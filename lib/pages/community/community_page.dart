import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';

class UserCommunityPage extends StatefulWidget {
  const UserCommunityPage({super.key});

  @override
  State<UserCommunityPage> createState() => _UserCommunityPageState();
}

class _UserCommunityPageState extends State<UserCommunityPage> {
  final CommunityService _communityService = CommunityService();
  
  static final Map<String, bool> _staticReadStatusCache = {};
  final List<StreamSubscription> _subscriptions = [];
  bool _isInitializing = true;

  final List<String> _allBrands = [
    'Nike',
    'Jordan',
    'Adidas',
    'Under Armour',
    'Puma',
    'Mizuno',
  ];

  final Map<String, String> _brandLogos = {
    'Nike': 'assets/logo_nike.png',
    'Jordan': 'assets/logo_jordan.png',
    'Adidas': 'assets/logo_adidas.png',
    'Under Armour': 'assets/logo_under_armour.png',
    'Puma': 'assets/logo_puma.png',
    'Mizuno': 'assets/logo_mizuno.png',
  };

  @override
  void initState() {
    super.initState();
    _communityService.markCommunityAsVisited();
    
    if (_staticReadStatusCache.isEmpty) {
      debugPrint('🔄 Cache empty, loading fresh data...');
      _initializeReadStatus();
    } else {
      debugPrint('✅ Using cached read status (${_staticReadStatusCache.length} brands cached)');
      _isInitializing = false;
      _subscribeToStreams();
    }
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  Future<void> _initializeReadStatus() async {
    debugPrint('🔄 Initializing read status for all brands...');
  
    final futures = _allBrands.map((brand) async {
      try {
        final isRead = await _communityService.isBrandRead(brand).first.timeout(
          const Duration(milliseconds: 800),
          onTimeout: () {
            debugPrint('⏱️ Timeout for $brand, using false');
            return false;
          },
        );
        debugPrint('✅ Initial read status for $brand: $isRead');
        return MapEntry(brand, isRead);
      } catch (e) {
        debugPrint('❌ Error getting initial status for $brand: $e');
        return MapEntry(brand, false);
      }
    }).toList();

    final results = await Future.wait(futures);
    
    if (mounted) {
      setState(() {
        for (var entry in results) {
          _staticReadStatusCache[entry.key] = entry.value;
        }
        _isInitializing = false;
      });
    }

    debugPrint('✅ All read statuses loaded in parallel');

    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    for (var brand in _allBrands) {
      final subscription = _communityService.isBrandRead(brand).listen(
        (isRead) {
          if (mounted && !_isInitializing) {
            if (_staticReadStatusCache[brand] != isRead) {
              setState(() {
                _staticReadStatusCache[brand] = isRead;
              });
              debugPrint('🔔 Stream update for $brand: $isRead');
            }
          }
        },
        onError: (error) {
          debugPrint('❌ Stream error for $brand: $error');
        },
      );
      _subscriptions.add(subscription);
    }
    debugPrint('✅ Subscribed to ${_subscriptions.length} streams');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komunitas', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: _communityService.getAllPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allPosts = snapshot.data ?? [];

          final Map<String, List<CommunityPost>> groupedPosts = {};
          for (var post in allPosts) {
            final brand = post.brand;
            if (!groupedPosts.containsKey(brand)) {
              groupedPosts[brand] = [];
            }
            groupedPosts[brand]!.add(post);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _allBrands.length,
                  itemBuilder: (context, index) {
                    final brand = _allBrands[index];
                    final posts = groupedPosts[brand] ?? [];

                    return _buildBrandCard(brand, posts);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  '*Ayo ikuti salah satu komunitas ini agar mudah untuk mendapatkan informasi terbaru mengenai sepatu olahraga terkini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandCard(String brand, List<CommunityPost> posts) {
  final logo = _brandLogos[brand] ?? '';
  
  final isRead = _staticReadStatusCache[brand] ?? false;
  
  final shouldShowBadge = posts.isNotEmpty && !isRead;
  final unreadCount = shouldShowBadge ? posts.length : 0;

  return Card(
    color: posts.isEmpty ? Colors.grey[100] : Colors.white,
    margin: EdgeInsets.only(bottom: 12.h),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    elevation: 1,
    child: InkWell(
      onTap: posts.isNotEmpty
          ? () {
              debugPrint('🖱️ Tapped on $brand card');
              
              // Update UI langsung tanpa await
              setState(() {
                _staticReadStatusCache[brand] = true;
              });
              
              // Navigasi LANGSUNG tanpa menunggu operasi lain
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BrandPostsPage(
                    brand: brand,
                    posts: posts,
                  ),
                ),
              );
              
              // Mark as read di background (tanpa await)
              _communityService.markBrandPostsAsRead(brand).then((_) {
                debugPrint('✅ Marked $brand as read in background');
              }).catchError((error) {
                debugPrint('❌ Error marking as read: $error');
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: logo.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Image.asset(
                            logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.store,
                              size: 24.sp,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Icon(Icons.store, size: 24.sp, color: Colors.grey),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kumpulan Sepatu Brand $brand Official Mengikuti',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: posts.isEmpty ? Colors.grey : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        posts.isEmpty
                            ? 'Belum ada postingan'
                            : '${posts.length} postingan',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 12.w,
              top: 12.h,
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 18.w,
                    minHeight: 18.h,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}

class BrandPostsPage extends StatelessWidget {
  final String brand;
  final List<CommunityPost> posts;

  const BrandPostsPage({
    super.key,
    required this.brand,
    required this.posts,
  });

  final Map<String, String> _brandLogos = const {
    'Nike': 'assets/logo_nike.png',
    'Jordan': 'assets/logo_jordan.png',
    'Adidas': 'assets/logo_adidas.png',
    'Under Armour': 'assets/logo_under_armour.png',
    'Puma': 'assets/logo_puma.png',
    'Mizuno': 'assets/logo_mizuno.png',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Kumpulan Sepatu Brand $brand',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'Belum ada postingan',
                    style: TextStyle(fontSize: 18.sp, color: Colors.black),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Postingan dari brand $brand akan muncul di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: posts.length,
              itemBuilder: (context, index) => _buildPostCard(context, posts[index]),
            ),
    );
  }

  Widget _buildPostCard(BuildContext context, CommunityPost post) {
    final brandLogo = _brandLogos[post.brand] ?? '';

    return Card(
      color: AppColors.secondary,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: brandLogo.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Image.asset(
                            brandLogo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.store,
                              size: 20.sp,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Icon(Icons.store, size: 20.sp, color: Colors.grey),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin ${post.brand}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (post.imageUrl1 != null && post.imageUrl1!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: post.imageUrl1!.startsWith('http')
                    ? Image.network(
                        post.imageUrl1!,
                        width: double.infinity,
                        height: 260.h,
                        fit: BoxFit.contain,
                      )
                    : Image.memory(
                        base64Decode(post.imageUrl1!),
                        width: double.infinity,
                        height: 260.h,
                        fit: BoxFit.contain,
                      ),
              ),
            SizedBox(height: 12.h),
            Text(
              post.description,
              style: TextStyle(fontSize: 14.sp, height: 1.4),
            ),
            SizedBox(height: 12.h),
            if (post.links.isNotEmpty)
              ...post.links.map((link) => _buildLinkCard(context, link)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, PostLink link) {
    return InkWell(
      onTap: () => _launchURL(link.url),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            if (link.logoUrl1.isNotEmpty)
              Image.asset(
                link.logoUrl1,
                width: 32.w,
                height: 32.w,
                errorBuilder: (_, __, ___) => Icon(Icons.store, size: 32.sp),
              ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.store,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    link.formattedPrice,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit yang lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}