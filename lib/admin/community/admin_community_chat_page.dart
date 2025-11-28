import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/admin/community/create_post_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/admin/community/community_page.dart';

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
        child: Image.network(
          imageUrl1,
          fit: BoxFit.cover,
          height: 180.h,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180.h,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, __, ___) => Container(
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

    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

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
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  "Admin $brand",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
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

          if (title.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
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
              padding: EdgeInsets.only(top: 6.h),
              child: Wrap(
                spacing: 6.w,
                children: [
                  if (mainCategory.isNotEmpty)
                    Chip(
                      label: Text(mainCategory),
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(fontSize: 11.sp, color: Colors.blue[700]),
                    ),
                  if (subCategory.isNotEmpty)
                    Chip(
                      label: Text(subCategory),
                      backgroundColor: Colors.green[50],
                      labelStyle: TextStyle(fontSize: 11.sp, color: Colors.green[700]),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
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
                        color: AppColors.backgroundColor,
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
        Text(
          "Opsi pembelian:",
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        ...linksList.map((linkData) {
          final linkMap = linkData as Map<String, dynamic>? ?? {};
          final url = linkMap['url']?.toString() ?? '';
          final store = linkMap['store']?.toString() ?? '';
          final price = linkMap['price'];
          String logoUrl = linkMap['logoUrl']?.toString() ?? '';

          if (url.isEmpty) return const SizedBox.shrink();

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
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    if (logoUrl.isNotEmpty)
                      Container(
                        width: 40.w,
                        height: 40.w,
                        margin: EdgeInsets.only(right: 10.w),
                        child: Image.asset(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.store, size: 24.sp),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (store.isNotEmpty && store != 'Other')
                            Text(
                              store,
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                            ),
                          if (price != null && price > 0)
                            Text(
                              "Rp ${_formatPrice(price)}",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.backgroundColor,
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