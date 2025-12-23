import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ TAMBAHAN untuk Clipboard
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app/pages/profile/profile_page.dart';
import 'package:my_app/pages/community/widgets/post_detail_screen.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/pages/community/widgets/create_post_page.dart'; 

class UserCommunityChatPage extends StatefulWidget {
  final String brand;

  const UserCommunityChatPage({super.key, required this.brand});

  @override
  State<UserCommunityChatPage> createState() => _UserCommunityChatPageState();
}

class _UserCommunityChatPageState extends State<UserCommunityChatPage> {
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  final ImagePicker _picker = ImagePicker();
  List<String> _mainCategories = [];
  List<String> _subCategories = [];
  Map<String, List<String>> _categoryMap = {};
  final CommunityService _communityService = CommunityService();
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });
      
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc('shoes')
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _categoryMap = Map<String, List<String>>.from(
              data.map((key, value) {
                if (value is List) {
                  return MapEntry(key, List<String>.from(value));
                }
                return MapEntry(key, <String>[]);
              }),
            );
            _mainCategories = _categoryMap.keys.toList();
            _isLoadingCategories = false;
          });
          return;
        }
      }
      
      setState(() {
        _categoryMap = {
          'Running': ['Road Running', 'Trail Running', 'Track Running'],
          'Basketball': ['High Top', 'Low Top', 'Mid Top'],
          'Casual': ['Sneakers', 'Loafers', 'Slip-ons'],
          'Training': ['Gym', 'Cross Training', 'Aerobics'],
        };
        _mainCategories = _categoryMap.keys.toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _categoryMap = {
          'Running': ['Road Running', 'Trail Running', 'Track Running'],
          'Basketball': ['High Top', 'Low Top', 'Mid Top'],
          'Casual': ['Sneakers', 'Loafers', 'Slip-ons'],
          'Training': ['Gym', 'Cross Training', 'Aerobics'],
        };
        _mainCategories = _categoryMap.keys.toList();
        _isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> brandLogos = {
      "Nike": "assets/logo_nike.png",
      "Jordan": "assets/logo_jordan.png",
      "Adidas": "assets/logo_adidas.png",
      "Under Armour": "assets/logo_under_armour.png",
      "Puma": "assets/logo_puma.png",
      "Mizuno": "assets/logo_mizuno.png",
    };

    final logoPath = brandLogos[widget.brand] ?? "assets/default_logo.png";

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePost(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 40.w,
                    height: 40.w,
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Image.asset(logoPath, fit: BoxFit.contain, errorBuilder: 
                      (context, error, stackTrace) => Icon(Icons.store, color: AppColors.primary),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Kumpulan Brand Sepatu  ${widget.brand}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildPostList(context)),
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    return StreamBuilder<List<CommunityPost>>(
      stream: _communityService.getPostsByBrand(widget.brand),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Terjadi kesalahan',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.red, fontSize: 13.sp),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: posts.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            return _buildPostCard(context, posts[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 80.sp, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            Text(
              'Belum ada posting untuk "${widget.brand}"',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Jadilah yang pertama untuk berbagi produk',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildPostImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          height: 180.h,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 180.h,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 180.h,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48.sp, color: Colors.grey[400]),
                SizedBox(height: 8.h),
                Text(
                  'Gambar tidak dapat dimuat',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, CommunityPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
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
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (post.userId.isEmpty) {
                      _showGuestProfileBottomSheet(context, post.username, post.userPhotoUrl);
                    } else {
                      _navigateToUserProfile(context, post.userId);
                    }
                  },
                  child: CircleAvatar(
                    radius: 20.r,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: post.userPhotoUrl != null && post.userPhotoUrl!.isNotEmpty
                        ? NetworkImage(post.userPhotoUrl!)
                        : null,
                    child: post.userPhotoUrl == null || post.userPhotoUrl!.isEmpty
                        ? Icon(Icons.person, size: 20.sp, color: Colors.grey.shade600)
                        : null,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (post.userId.isEmpty) {
                        _showGuestProfileBottomSheet(context, post.username, post.userPhotoUrl);
                      } else {
                        _navigateToUserProfile(context, post.userId);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.username.isEmpty ? 'User' : post.username,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12.sp,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _formatTimeAgo(post.createdAt),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_canEditPost(post.userId))
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showPostOptions(context, post),
                  ),
              ],
            ),

            SizedBox(height: 12.h),
            Divider(height: 1, color: Colors.grey.shade300),
            SizedBox(height: 12.h),

            if (post.title != null && post.title!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  post.title!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: Colors.black,
                  ),
                ),
              ),

            if (post.mainCategory != null && post.mainCategory!.isNotEmpty || 
                post.subCategory != null && post.subCategory!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Wrap(
                  spacing: 6.w,
                  children: [
                    if (post.mainCategory != null && post.mainCategory!.isNotEmpty)
                      Chip(
                        label: Text(post.mainCategory!),
                        backgroundColor: Colors.red[50],
                        labelStyle: TextStyle(fontSize: 11.sp, color: Colors.black),
                      ),
                    if (post.subCategory != null && post.subCategory!.isNotEmpty)
                      Chip(
                        label: Text(post.subCategory!),
                        backgroundColor: Colors.orange.shade50,
                        labelStyle: TextStyle(fontSize: 11.sp, color: Colors.black),
                      ),
                  ],
                ),
              ),

            _buildPostImage(post.imageUrl1),

            if (post.content.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Harga: ', style: TextStyle(fontSize: 13.sp)),
                      Text(
                        'Rp ${_formatPrice(post.content)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (post.description.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  post.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.6),
                ),
              ),

            _buildPurchaseOptions(post.links),

            SizedBox(height: 8.h),
            Text(
              "Diposting: ${DateFormat('dd MMM yyyy, HH:mm').format(post.createdAt)}",
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOptions(List<PostLink> links) {
    if (links.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 6.w),
              Text(
                'Opsi pembelian:',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          
          ...links.map((link) => _buildPurchaseLinkCard(link)),
        ],
      ),
    );
  }

  Widget _buildPurchaseLinkCard(PostLink link) {
    debugPrint('========== DEBUG LINK DATA ==========');
    debugPrint('Store: ${link.store}');
    debugPrint('Price: ${link.price}');
    debugPrint('URL: ${link.url}');
    debugPrint('=====================================');
    
    Color buttonColor = Colors.grey;
    String logoAsset = '';
    final store = link.store ?? '';
    final url = link.url ?? '';
    
    final storeLower = store.toLowerCase();
    final urlLower = url.toLowerCase();
    
    if (storeLower.contains('pro soccer') || storeLower.contains('official store') || 
        urlLower.contains('prosoccer.com') || urlLower.contains('mzsports.com') || 
        storeLower.contains('adidas official') || storeLower.contains('nike official') || 
        storeLower.contains('mizuno official')) {
      if (urlLower.contains('adidas') || storeLower.contains('adidas')) {
        buttonColor = Colors.black;
        logoAsset = 'assets/logo_adidas.png';
      } else if (urlLower.contains('nike') || storeLower.contains('nike')) {
        buttonColor = Colors.black;
        logoAsset = 'assets/logo_nike.png';
      } else if (urlLower.contains('puma') || storeLower.contains('puma')) {
        buttonColor = Colors.black;
        logoAsset = 'assets/logo_puma.png';
      } else if (urlLower.contains('jordan') || storeLower.contains('jordan')) {
        buttonColor = Colors.black;
        logoAsset = 'assets/logo_jordan.png';
      } else if (urlLower.contains('mizuno') || storeLower.contains('mizuno')) {
        buttonColor = Colors.blue;
        logoAsset = 'assets/logo_mizuno.png';
      } else if (urlLower.contains('under') && urlLower.contains('armour')) {
        buttonColor = Colors.black;
        logoAsset = 'assets/logo_under_armour.png';
      }
    } else if (storeLower.contains('under armour') || storeLower.contains('underarmour')) {
      buttonColor = Colors.black;
      logoAsset = 'assets/logo_under_armour.png';
    } else if (storeLower.contains('shopee')) {
      buttonColor = Colors.orange;
      logoAsset = 'assets/logo_shopee.png';
    } else if (storeLower.contains('tokopedia')) {
      buttonColor = Colors.green;
      logoAsset = 'assets/logo_tokopedia.png';
    } else if (storeLower.contains('blibli')) {
      buttonColor = Colors.blue;
      logoAsset = 'assets/logo_blibli.jpg';
    } else if (storeLower.contains('nike')) {
      buttonColor = Colors.black;
      logoAsset = 'assets/logo_nike.png';
    } else if (storeLower.contains('adidas')) {
      buttonColor = Colors.black;
      logoAsset = 'assets/logo_adidas.png';
    } else if (storeLower.contains('jordan')) {
      buttonColor = Colors.black;
      logoAsset = 'assets/logo_jordan.png';
    } else if (storeLower.contains('puma')) {
      buttonColor = Colors.black;
      logoAsset = 'assets/logo_puma.png';
    } else if (storeLower.contains('mizuno')) {
      buttonColor = Colors.blue;
      logoAsset = 'assets/logo_mizuno.png';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: () {
          final url = link.url ?? '';
          if (url.isNotEmpty) {
            _launchURL(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link pembelian tidak tersedia'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Row(
          children: [
            if (logoAsset.isNotEmpty)
              Container(
                width: 40.w,
                height: 40.w,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Image.asset(
                  logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.store, size: 24.sp, color: buttonColor);
                  },
                ),
              )
            else
              Container(
                width: 40.w,
                height: 40.w,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(
                  Icons.store,
                  size: 24.sp,
                  color: buttonColor,
                ),
              ),
            SizedBox(width: 12.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (store.isNotEmpty && store != 'Other')
                    Text(
                      store,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Text(
                    'Rp ${_formatPrice(link.price)}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward,
              size: 20.sp,
              color: buttonColor,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ IMPROVED URL LAUNCHER METHOD
  Future<void> _launchURL(String url) async {
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link tidak tersedia'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      // Clean and validate URL
      String cleanUrl = url.trim();
      
      debugPrint('🔗 Original URL: $cleanUrl');
      
      // Add https:// if no protocol is specified
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
        debugPrint('✅ Added protocol: $cleanUrl');
      }

      // Parse URI
      final uri = Uri.parse(cleanUrl);
      debugPrint('🔍 Parsed URI: ${uri.toString()}');
      
      // Validate URI scheme
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw Exception('URL tidak valid: ${uri.scheme}');
      }

      // Check if URL can be launched
      debugPrint('🔄 Checking if URL can be launched...');
      bool canLaunch = false;
      
      try {
        canLaunch = await canLaunchUrl(uri);
        debugPrint('✅ canLaunchUrl result: $canLaunch');
      } catch (e) {
        debugPrint('⚠️ canLaunchUrl check failed: $e');
      }

      if (!canLaunch) {
        debugPrint('⚠️ canLaunchUrl returned false, trying anyway...');
      }

      // Try to launch with different modes
      bool launched = false;
      Exception? lastException;
      
      // Method 1: External Application
      if (!launched) {
        try {
          debugPrint('🚀 Attempting LaunchMode.externalApplication...');
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) {
            debugPrint('✅ SUCCESS: Launched with externalApplication');
            return;
          }
        } catch (e) {
          debugPrint('❌ externalApplication failed: $e');
          lastException = e as Exception;
        }
      }

      // Method 2: Platform Default
      if (!launched) {
        try {
          debugPrint('🚀 Attempting LaunchMode.platformDefault...');
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          if (launched) {
            debugPrint('✅ SUCCESS: Launched with platformDefault');
            return;
          }
        } catch (e) {
          debugPrint('❌ platformDefault failed: $e');
          lastException = e as Exception;
        }
      }

      // Method 3: External Non-Browser Application
      if (!launched) {
        try {
          debugPrint('🚀 Attempting LaunchMode.externalNonBrowserApplication...');
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          if (launched) {
            debugPrint('✅ SUCCESS: Launched with externalNonBrowserApplication');
            return;
          }
        } catch (e) {
          debugPrint('❌ externalNonBrowserApplication failed: $e');
          lastException = e as Exception;
        }
      }

      if (!launched) {
        throw lastException ?? Exception('Tidak dapat membuka link');
      }

    } catch (e, stackTrace) {
      debugPrint('════════════════════════════════════════');
      debugPrint('❌ FINAL ERROR launching URL');
      debugPrint('URL: $url');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('════════════════════════════════════════');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tidak bisa membuka link',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pastikan browser atau aplikasi tersedia',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Salin Link',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Link berhasil disalin!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _navigateToCreatePost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCreatePostPage(brand: widget.brand),
      ),
    );
  }

  void _navigateToEditPost(BuildContext context, CommunityPost post) {
    final Map<String, dynamic> initialData = {
      'title': post.title,
      'content': post.content,
      'description': post.description,
      'imageUrl1': post.imageUrl1,
      'mainCategory': post.mainCategory,
      'subCategory': post.subCategory,
      'links': post.links.map((link) => link.toMap()).toList(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCreatePostPage(
          brand: widget.brand,
          postId: post.id,
          initialData: initialData,
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditPost(context, post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(post.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Batal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus postingan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  bool _canEditPost(String postUserId) {
    return currentUserId == postUserId;
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await _showDeleteConfirmation(context);
    if (confirm == true) {
      try {
        await _communityService.deletePost(postId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus postingan: $e')),
        );
      }
    }
  }

  void _showGuestProfileBottomSheet(BuildContext context, String username, String? userPhotoUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            ClipOval(
              child: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: userPhotoUrl,
                      width: 100.w,
                      height: 100.w,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100.w,
                        height: 100.w,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 100.w,
                        height: 100.w,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.person, size: 50.sp, color: Colors.grey.shade600),
                      ),
                    )
                  : Container(
                      width: 100.w,
                      height: 100.w,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.person, size: 50.sp, color: Colors.grey.shade600),
                    ),
            ),
            SizedBox(height: 16.h),
            Text(
              username.isEmpty ? 'User' : username,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Member Community',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context, String userId) {
    if (userId.isEmpty || userId == 'null' || userId == 'undefined') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pengguna tidak tersedia untuk ditampilkan'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(userId: userId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka profil pengguna')),
      );
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit yang lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam yang lalu";
    if (diff.inDays < 7) return "${diff.inDays} hari yang lalu";

    return DateFormat('dd MMM yyyy').format(time);
  }

  String _formatPrice(dynamic price) {
    try {
      String priceStr = price.toString();
      priceStr = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
      if (priceStr.isEmpty) return '0';
      final numPrice = int.parse(priceStr);
      return numPrice
          .toString()
          .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    } catch (_) {
      return price.toString();
    }
  }
}