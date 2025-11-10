import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class UserCommunityPage extends StatefulWidget {
  const UserCommunityPage({super.key});

  @override
  State<UserCommunityPage> createState() => _UserCommunityPageState();
}

class _UserCommunityPageState extends State<UserCommunityPage> {
  final CommunityService _communityService = CommunityService();

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
                    final unreadCount = posts.length;

                    return _buildBrandCard(brand, unreadCount, posts);
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

  Widget _buildBrandCard(String brand, int count, List<CommunityPost> posts) {
    final logo = _brandLogos[brand] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 1,
      child: InkWell(
        onTap: posts.isNotEmpty
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrandPostsPage(brand: brand, posts: posts),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
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
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (count > 0)
                    Container(
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Icon(Icons.chevron_right,
                      color: posts.isEmpty ? Colors.grey[300] : Colors.grey[400],
                      size: 24.sp),
                ],
              ),
            ],
          ),
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

  String formatRupiah(num price) {
    final formatter = NumberFormat('#,##0', 'de_DE');
    return 'Rp ${formatter.format(price)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Komunitas $brand', style: const TextStyle(color: Colors.white)),
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
                  Text('Belum ada postingan',
                      style: TextStyle(fontSize: 18.sp, color: Colors.grey[600])),
                  SizedBox(height: 8.h),
                  Text('Postingan dari brand $brand akan muncul di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: posts.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) => _buildPostCard(context, posts[index]),
            ),
    );
  }

  Widget _buildPostCard(BuildContext context, CommunityPost post) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin ${post.brand}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),

          if (post.content.isNotEmpty)
            Text(
              '${post.brand} Product #${post.content}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                color: Colors.black,
              ),
            ),

          if (post.imageUrl1 != null && post.imageUrl1!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: _buildImage(post.imageUrl1!),
            ),
          ],

          if (post.links.isNotEmpty && post.links.first.price > 0) ...[
            SizedBox(height: 10.h),
            Text(
              formatRupiah(post.links.first.price),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],

          if (post.description.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              post.description,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
          ],

          if (post.links.isNotEmpty) _buildLinks(context, post.links),

          SizedBox(height: 8.h),
          Text(
            'Diposting: ${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (_isBase64(imagePath)) {
      return Image.memory(
        base64Decode(imagePath),
        fit: BoxFit.cover,
        height: 180.h,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    } else if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        height: 180.h,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        height: 180.h,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    }
  }

  bool _isBase64(String str) {
    if (str.isEmpty || str.startsWith('http') || str.contains('/') || str.length < 100) {
      return false;
    }
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildImageError() {
    return Container(
      height: 180.h,
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48.sp, color: Colors.grey[400]),
          SizedBox(height: 8.h),
          Text('Gambar tidak dapat dimuat',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildLinks(BuildContext context, List<PostLink> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text(
          'Opsi pembelian:',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        ...links.map((link) => _buildLinkCard(context, link)),
        SizedBox(height: 4.h),
        Text(
          '*Harga dapat berubah sewaktu-waktu',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.redAccent,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkCard(BuildContext context, PostLink link) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: GestureDetector(
        onTap: () => _launchURL(link.url),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (link.logoUrl1.isNotEmpty)
                Container(
                  width: 40.w,
                  height: 40.w,
                  margin: EdgeInsets.only(right: 10.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.asset(
                      link.logoUrl1,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.store, size: 24.sp, color: Colors.grey),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (link.store.isNotEmpty)
                      Text(
                        link.store,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    Text(
                      formatRupiah(link.price),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            ],
          ),
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
}