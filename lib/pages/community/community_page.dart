import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class UserCommunityPage extends StatefulWidget {
  const UserCommunityPage({super.key});

  @override
  State<UserCommunityPage> createState() => _UserCommunityPageState();
}

class _UserCommunityPageState extends State<UserCommunityPage> {
  final CommunityService _communityService = CommunityService();
  final Set<String> _readBrands = {}; // ✅ Track brand yang sudah dibaca

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
    _loadReadBrands(); // ✅ Load brand yang sudah dibaca
  }

  // ✅ Load read brands dari Firestore
  Future<void> _loadReadBrands() async {
    for (var brand in _allBrands) {
      _communityService.isBrandRead(brand).listen((isRead) {
        if (mounted) {
          setState(() {
            if (isRead) {
              _readBrands.add(brand);
            } else {
              _readBrands.remove(brand);
            }
          });
        }
      });
    }
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

          // ✅ Group posts by brand
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
              // ✅ Brand list - Tampilkan SEMUA brand
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _allBrands.length,
                  itemBuilder: (context, index) {
                    final brand = _allBrands[index];
                    final posts = groupedPosts[brand] ?? [];
                    // ✅ Hanya tampilkan badge jika belum dibaca
                    final unreadCount = _readBrands.contains(brand) ? 0 : posts.length;

                    return _buildBrandCard(brand, unreadCount, posts);
                  },
                ),
              ),

              // ✅ Footer info
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

  Widget _buildBrandCard(String brand, int count, List<CommunityPost> posts) {
    final logo = _brandLogos[brand] ?? '';

    return Card(
      color: posts.isEmpty ? Colors.grey[100] : Colors.white,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 1,
      child: InkWell(
        onTap: posts.isNotEmpty
            ? () async {
                // ✅ Mark as read sebelum navigate
                await _communityService.markBrandPostsAsRead(brand);
                if (mounted) {
                  setState(() {
                    _readBrands.add(brand);
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrandPostsPage(brand: brand, posts: posts),
                    ),
                  );
                }
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
                            child: Image.asset(logo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.store, size: 24.sp, color: Colors.grey)),
                          )
                        : Icon(Icons.store, size: 24.sp, color: Colors.grey),
                  ),
                  SizedBox(width: 12.w),

                  // Brand name
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
                          posts.isEmpty ? 'Belum ada postingan' : '${posts.length} postingan',
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
            
            // ✅ Badge di pojok kanan atas - UKURAN LEBIH KECIL
            if (count > 0)
              Positioned(
                right: 12.w,
                top: 12.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), // ✅ Padding lebih kecil
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.r), // ✅ Border radius lebih kecil
                  ),
                  constraints: BoxConstraints(
                    minWidth: 18.w, // ✅ Min width lebih kecil
                    minHeight: 18.h, // ✅ Min height lebih kecil
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp, // ✅ Font size lebih kecil
                        fontWeight: FontWeight.bold,
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

  // ✅ Tambahkan map untuk logo brand
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
      appBar: AppBar(
        title: Text('Kumpulan Sepatu Brand $brand', style: const TextStyle(color: Colors.white)),
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
                    style: TextStyle(fontSize: 18.sp, color: Colors.white),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Postingan dari brand $brand akan muncul di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Colors.white),
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
    final brandLogo = _brandLogos[post.brand] ?? ''; // ✅ Get logo berdasarkan brand

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // ✅ Gunakan logo brand sebagai avatar
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
                      // ✅ Nama admin sesuai brand
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
                    ? Image.network(post.imageUrl1!,
                        width: double.infinity, height: 200.h, fit: BoxFit.cover)
                    : Image.memory(base64Decode(post.imageUrl1!),
                        width: double.infinity, height: 200.h, fit: BoxFit.cover),
              ),

            SizedBox(height: 12.h),
            Text(post.description, style: TextStyle(fontSize: 14.sp, height: 1.4)),

            SizedBox(height: 12.h),

            // Links
            if (post.links.isNotEmpty)
              ...post.links.map((link) => _buildLinkCard(context, link)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, PostLink link) {
    return Container(
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
            Image.asset(link.logoUrl1,
                width: 32.w,
                height: 32.w,
                errorBuilder: (_, __, ___) => Icon(Icons.store, size: 32.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(link.store,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                Text(link.formattedPrice,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.black)
        ],
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