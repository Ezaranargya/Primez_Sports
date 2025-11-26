import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/pages/community/widgets/edit_post_screen.dart';
import 'package:my_app/pages/community/widgets/post_detail_screen.dart';
import 'package:my_app/pages/community/widgets/create_post_screen.dart';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _createTestPost() async {
    print('🐛 TEST: Starting create test post...');
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('🐛 TEST: Current user: ${user?.uid}');
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('🐛 TEST: Creating post in Firestore...');
      final docRef = await FirebaseFirestore.instance.collection('posts').add({
        'brand': 'Nike',
        'content': 'Test Nike Post ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Ini adalah test post untuk Nike. Sepatu basket premium dengan teknologi terbaru untuk performa maksimal di lapangan!',
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl1': 'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/99486859-0ff3-46b4-949b-2d16af2ad421/custom-nike-dunk-high-by-you-shoes.png',
        'links': [
          {
            'logoUrl1': '',
            'price': 1890000,
            'store': 'Shopee',
            'url': 'https://shopee.co.id',
          },
          {
            'logoUrl1': '',
            'price': 1909000,
            'store': 'Nike Official',
            'url': 'https://nike.com',
          }
        ],
        'userId': user.uid,
        'username': user.displayName ?? 'Test User',
        'userEmail': user.email ?? '',
        'userPhotoUrl': user.photoURL ?? '',
      });

      print('✅ TEST: Post created with ID: ${docRef.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test post created! ID: ${docRef.id}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ TEST ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      title: const Text('Chat Komunitas', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.primary,
      centerTitle: true,
      elevation: 0,
      actions: [],
    ),
    body: Stack(
      children: [
        StreamBuilder<List<CommunityPost>>(
          stream: _communityService.getAllPosts(),
          builder: (context, snapshot) {
            print('📊 Connection State: ${snapshot.connectionState}');
            print('📊 Has Data: ${snapshot.hasData}');
            print('📊 Data Length: ${snapshot.data?.length ?? 0}');
            
            if (snapshot.hasError) {
              print('❌ Error: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _createTestPost,
                      child: Text('Create Test Post'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allPosts = snapshot.data ?? [];
            print('📦 Total posts from DB: ${allPosts.length}');

            final Map<String, List<CommunityPost>> groupedPosts = {};
            for (var post in allPosts) {
              final brand = post.brand;
              print('   - Brand: "${post.brand}" (ID: ${post.id})');
              if (!groupedPosts.containsKey(brand)) {
                groupedPosts[brand] = [];
              }
              groupedPosts[brand]!.add(post);
            }

            return ListView.builder(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 16.h,
                bottom: 70.h,
              ),
              itemCount: _allBrands.length,
              itemBuilder: (context, index) {
                final brand = _allBrands[index];
                final posts = groupedPosts[brand] ?? [];
                return _buildBrandCard(brand, posts);
              },
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildBrandCard(String brand, List<CommunityPost> posts) {
    final logo = _brandLogos[brand] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BrandPostsPage(brand: brand, posts: posts),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: logo.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.all(10.w),
                          child: Image.asset(
                            logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.store, size: 24.sp, color: Colors.grey),
                          ),
                        )
                      : Icon(Icons.store, size: 24.sp, color: Colors.grey),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kumpulan Sepatu Brand $brand Official',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        posts.isNotEmpty 
                            ? '${posts.length} post tersedia' 
                            : 'Belum ada post',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: posts.isNotEmpty 
                              ? Colors.green[600] 
                              : Colors.grey[500],
                          fontWeight: posts.isNotEmpty 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Messenger',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class BrandPostsPage extends StatefulWidget {
  final String brand;
  final List<CommunityPost> posts;

  const BrandPostsPage({
    super.key,
    required this.brand,
    required this.posts,
  });

  @override
  State<BrandPostsPage> createState() => _BrandPostsPageState();
}

class _BrandPostsPageState extends State<BrandPostsPage> {
  final CommunityService _communityService = CommunityService();

  @override
  void initState() {
    super.initState();
    _communityService.markBrandPostsAsRead(widget.brand);
  }

  String formatRupiah(num price) {
    final formatter = NumberFormat('#,##0', 'de_DE');
    return 'Rp${formatter.format(price)}';
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }

  void _editPost(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(post: post),
      ),
    );
  }

  void _confirmDelete(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Postingan'),
        content: Text('Apakah Anda yakin ingin menghapus postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _communityService.deletePost(postId);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Postingan berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Kumpulan Brand ${widget.brand} Official',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePostScreen(brand: widget.brand),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white, size: 28.sp),
      ),
      body: widget.posts.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [            
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: widget.posts.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) => _buildCompactPostCard(widget.posts[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text('Belum ada postingan',
              style: TextStyle(fontSize: 18.sp, color: Colors.grey[600])),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text('Postingan dari brand ${widget.brand} akan muncul di sini',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPostCard(CommunityPost post) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16.r,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: post.userPhotoUrl != null && post.userPhotoUrl!.isNotEmpty
                        ? NetworkImage(post.userPhotoUrl!)
                        : null,
                    child: post.userPhotoUrl == null || post.userPhotoUrl!.isEmpty
                        ? Icon(Icons.person, size: 18.sp, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<bool>(
                    future: _communityService.isPostOwner(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 20.sp, color: Colors.grey[600]),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editPost(post);
                            } else if (value == 'delete') {
                              _confirmDelete(post.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18.sp, color: Colors.blue),
                                  SizedBox(width: 8.w),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18.sp, color: Colors.red),
                                  SizedBox(width: 8.w),
                                  Text('Hapus', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            if (post.imageUrl1 != null && post.imageUrl1!.isNotEmpty)
              Container(
                height: 200.h,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: _buildImage(post.imageUrl1!),
                ),
              ),

            if (post.description.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  post.description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            if (post.links.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Opsi pembelian',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.arrow_drop_down, size: 16.sp, color: Colors.black54),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...post.links.take(4).map((link) => _buildCompactLink(link)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLink(PostLink link) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: InkWell(
        onTap: () => _launchURL(link.url),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatRupiah(link.price),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (link.store.isNotEmpty)
                      Text(
                        link.store,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: link.store.toLowerCase().contains('lazada') 
                      ? Colors.blue 
                      : Colors.red,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Beli',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.arrow_forward_ios, size: 12.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (_isBase64(imagePath)) {
      return Image.memory(
        base64Decode(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    } else if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
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
      height: 200.h,
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

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}