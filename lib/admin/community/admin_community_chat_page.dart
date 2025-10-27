import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/admin/community/create_post_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/admin/community/community_page.dart';
import 'package:my_app/pages/community/widgets/community_header.dart';

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
          // 🔹 Header custom seperti di Figma
          CommunityHeader(
            brandName: brand,
            logoPath: logoPath,
            onBack: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminCommunityPage()),
              );
            },
          ),

          // 🔹 Isi postingan
          Expanded(child: _buildPostList(context, brand)),
        ],
      ),

      // 🔹 Tombol tambah posting
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

  /// 🔹 Header merah + card putih (sesuai Figma)
  Widget _buildHeader(String brand, String logoPath, BuildContext context) {
    return CommunityHeader(
      brandName: brand,
      logoPath: logoPath,
      onBack: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminCommunityPage()),
        );
      },
    );
  }

  /// 🔹 StreamBuilder untuk menampilkan daftar posting
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
            child: Text(
              '❌ Terjadi kesalahan: ${snapshot.error}',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
              textAlign: TextAlign.center,
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
            final postId = doc.id;
            return _buildPostCard(context, brand, postId, data);
          },
        );
      },
    );
  }

  /// 🔹 Widget tampil jika belum ada posting
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
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  /// 🔹 Card posting
  Widget _buildPostCard(
      BuildContext context, String brand, String postId, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? '';
    final content = data['content']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final imagePath = data['imageUrl']?.toString() ?? '';
    final linksList = data['links'] as List<dynamic>? ?? [];

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
                onPressed: () => _showDeleteDialog(context, postId),
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
          if (imagePath.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  height: 180.h,
                  width: double.infinity,
                ),
              ),
            ),
          if (content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                content,
                textAlign: TextAlign.justify,
                style:
                    TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.6),
              ),
            ),
          if (description.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                description,
                textAlign: TextAlign.justify,
                style:
                    TextStyle(fontSize: 13.sp, color: Colors.black54, height: 1.6),
              ),
            ),
          if (linksList.isNotEmpty) _buildLinks(context, linksList),
          if (createdAt != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                "Diposting: ${createdAt.day}/${createdAt.month}/${createdAt.year} "
                "- ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  /// 🔹 Daftar link toko
  Widget _buildLinks(BuildContext context, List<dynamic> linksList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text(
          "Opsi pembelian:",
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        ...linksList.map((linkData) {
          final linkMap = linkData as Map<String, dynamic>? ?? {};
          final url = linkMap['url']?.toString() ?? '';
          final store = linkMap['store']?.toString() ?? '';
          final price = linkMap['price'];
          final logoUrl = linkMap['logoUrl']?.toString() ?? '';

          if (url.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal membuka tautan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
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
                    if (logoUrl.isNotEmpty)
                      Container(
                        width: 40.w,
                        height: 40.w,
                        margin: EdgeInsets.only(right: 10.w),
                        child: Image.asset(logoUrl, fit: BoxFit.contain),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (store.isNotEmpty)
                            Text(store,
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600)),
                          if (price != null)
                            Text(
                              "Rp ${_formatPrice(price)}",
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16.sp, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, String postId) {
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
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
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
