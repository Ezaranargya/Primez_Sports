import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/admin/community/create_post_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/admin/community/community_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app/pages/profile/profile_page.dart';

class AdminCommunityChatPage extends StatelessWidget {
  final String brand;

  const AdminCommunityChatPage({super.key, required this.brand});

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

    final logoPath = brandLogos[brand] ?? "assets/default_logo.png";

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
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
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminCommunityPage()),
                      );
                    },
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
                    child: Image.asset(logoPath, fit: BoxFit.contain),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Kumpulan Brand Sepatu $brand...',
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
          Expanded(child: _buildPostList(context, brand)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreatePostPage(brand: brand),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostList(BuildContext context, String brand) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('brand', isEqualTo: brand)
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
                  '❌ Terjadi kesalahan',
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

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) return _buildEmptyState(brand);

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return _buildPostCard(context, brand, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String brand) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 80.sp, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            Text(
              'Belum ada posting untuk "$brand"',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tekan tombol + untuk membuat posting pertama',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildPostImage(String? imageUrl1) {
    if (imageUrl1 == null || imageUrl1.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: CachedNetworkImage(
          imageUrl: imageUrl1,
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

  Widget _buildPostCard(
    BuildContext context,
    String brand,
    String postId,
    Map<String, dynamic> data,
  ) {
    final title = data['title']?.toString() ?? '';
    final content = data['content']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final imageUrl1 = data['imageUrl1']?.toString();
    final linksList = data['links'] as List<dynamic>? ?? [];
    final mainCategory = data['mainCategory']?.toString() ?? '';
    final subCategory = data['subCategory']?.toString() ?? '';
    final communityId = data['communityId']?.toString();
    final userId = data['userId']?.toString() ?? '';
    final username = data['username']?.toString() ?? 
                     data['userName']?.toString() ??
                     data['name']?.toString() ??
                     data['displayName']?.toString() ??
                     '';
    final userPhotoUrl = data['userPhotoUrl']?.toString() ??
                         data['photoURL']?.toString();

    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

        print('========== DEBUG POST DATA ==========');
        print('Post ID: $postId');
        print('data[username]: ${data['username']}');
        print('data[userName]: ${data['userName']}');
        print('data[name]: ${data['name']}');
        print('data[displayName]: ${data['displayName']}');
        print('Final username: "$username"');
        print('Is username empty: ${username.isEmpty}');
        print('=====================================');

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
          // Header dengan User Avatar dan Info - CLICKABLE
          Row(
            children: [
              // User Avatar - Clickable
              GestureDetector(
                onTap: () {
                  if (userId.isEmpty) {
                    _showGuestProfileBottomSheet(context, username, userPhotoUrl);
                  } else {
                    _navigateToUserProfile(context, userId);
                  }
                },
                child: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl)
                      : null,
                  child: userPhotoUrl == null || userPhotoUrl.isEmpty
                      ? Icon(Icons.person, size: 20.sp, color: Colors.grey.shade600)
                      : null,
                ),
              ),
              SizedBox(width: 10.w),
              // Username dan Badge - Clickable
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (userId.isEmpty) {
                      _showGuestProfileBottomSheet(context, username, userPhotoUrl);
                    } else {
                      _navigateToUserProfile(context, userId);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            username.isEmpty ? 'User' : username,
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
                        createdAt != null ? _formatTimeAgo(createdAt) : 'Baru saja',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              IconButton(
                icon: Icon(Icons.edit, size: 20.sp, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePostPage(
                        brand: brand,
                        postId: postId,
                        initialData: data,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 20.sp, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, postId, communityId),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Divider(height: 1, color: Colors.grey.shade300),
          SizedBox(height: 12.h),

          if (title.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
              ),
            ),

          if (mainCategory.isNotEmpty || subCategory.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Wrap(
                spacing: 6.w,
                children: [
                  if (mainCategory.isNotEmpty)
                    Chip(
                      label: Text(mainCategory),
                      backgroundColor: Colors.red.shade50,
                      labelStyle: TextStyle(fontSize: 11.sp, color: Colors.black),
                    ),
                  if (subCategory.isNotEmpty)
                    Chip(
                      label: Text(subCategory),
                      backgroundColor: Colors.orange.shade50,
                      labelStyle: TextStyle(fontSize: 11.sp, color: Colors.black),
                    ),
                ],
              ),
            ),

          _buildPostImage(imageUrl1),

          if (content.isNotEmpty)
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
                    Text('Harga Utama: ', style: TextStyle(fontSize: 13.sp)),
                    Text(
                      'Rp ${_formatPrice(content)}',
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

          if (description.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                description,
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.6),
              ),
            ),

          if (linksList.isNotEmpty) _buildLinks(context, linksList),

          if (createdAt != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                "Diposting: ${createdAt.day}/${createdAt.month}/${createdAt.year} - ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinks(BuildContext context, List<dynamic> linksList) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 12.h),
      Row(
        children: [
          SizedBox(width: 6.w),
          Text(
            "Opsi pembelian:",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      ...linksList.map((linkData) {
        final linkMap = linkData as Map<String, dynamic>? ?? {};
        final url = linkMap['url']?.toString() ?? '';
        final store = linkMap['store']?.toString() ?? '';
        final price = linkMap['price'];

        if (url.isEmpty) return const SizedBox.shrink();

        // Debug print untuk melihat data store
        debugPrint('========== DEBUG STORE DATA ==========');
        debugPrint('Store name: "$store"');
        debugPrint('Store toLowerCase: "${store.toLowerCase()}"');
        debugPrint('=====================================');

        // Determine button color and logo asset based on store
        Color buttonColor = Colors.grey;
        String logoAsset = ''; // Ubah dari nullable ke empty string
        
        final storeLower = store.toLowerCase();
        if (storeLower.contains('shopee')) {
          buttonColor = Colors.orange;
          logoAsset = 'assets/logo_shopee.png';
          debugPrint('✅ Detected: Shopee');
        } else if (storeLower.contains('tokopedia')) {
          buttonColor = Colors.green;
          logoAsset = 'assets/logo_tokopedia.png';
          debugPrint('✅ Detected: Tokopedia');
          } else if (storeLower.contains('blibli')) {
          logoAsset = 'assets/logo_blibli.jpg';
          debugPrint('✅ Detected: Tokopedia');
          } else if (storeLower.contains('nike')) {
          logoAsset = 'assets/logo_nike.png';
          debugPrint('✅ Detected: Nike');
          } else if (storeLower.contains('adidas')) {
          logoAsset = 'assets/logo_adidas.png';
          debugPrint('✅ Detected: Adidas');
          } else if (storeLower.contains('jordan')) {
          logoAsset = 'assets/logo_jordan.png';
          debugPrint('✅ Detected: Jordan');
          } else if (storeLower.contains('puma')) {
          logoAsset = 'assets/logo_puma.png';
          debugPrint('✅ Detected: Puma');
          } else if (storeLower.contains('mizuno')) {
          logoAsset = 'assets/logo_mizuno.png';
          debugPrint('✅ Detected: Mizuno');
        } else {
          debugPrint('⚠️ Store tidak terdeteksi, menggunakan icon default');
        }

        return Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  // Store icon/logo - MENGGUNAKAN IMAGE ASSET
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
                          debugPrint('❌ Error loading asset: $logoAsset');
                          debugPrint('Error: $error');
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
                  
                  // Store name and price
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
                        if (price != null && price > 0)
                          Text(
                            "Rp ${_formatPrice(price)}",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Buy button arrow
                  Icon(
                    Icons.arrow_forward,
                    size: 20.sp,
                    color: buttonColor,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ],
  );
}

  void _showDeleteDialog(BuildContext context, String postId, String? communityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Posting'),
        content: const Text('Apakah Anda yakin ingin menghapus posting ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Posting berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showGuestProfileBottomSheet(BuildContext context, String username, String? userPhotoUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
            // Avatar
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
    // Validasi userId lebih ketat
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

    // Fetch user data dan tampilkan bottom sheet profile
    _showUserProfileBottomSheet(context, userId);
  }

  void _showUserProfileBottomSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          String username = 'User';
          String? userPhotoUrl;
          String? bio;

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            username = userData?['username'] ?? userData?['name'] ?? 'User';
            userPhotoUrl = userData?['photoURL'] ?? userData?['userPhotoUrl'];
            bio = userData?['bio'] ?? userData?['description'];
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.5,
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
                // Avatar dengan CachedNetworkImage
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
                  username,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.h),
                if (bio != null && bio.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    'Member Community',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
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
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigasi ke halaman profile lengkap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfilePage(userId: userId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text(
                          'Lihat Profile',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
              ],
            ),
          );
        },
      ),
    );
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
      final numPrice = price is int ? price : int.parse(price.toString());
      return numPrice
          .toString()
          .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    } catch (_) {
      return price.toString();
    }
  }
}