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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const AdminCommunityPage()));
          }, 
          ),
        title: Text(
          "Admin $brand",
          style: TextStyle(fontSize: 18.sp, color: AppColors.secondary),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.secondary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Informasi Admin'),
                  content: const Text(
                    'Anda dapat:\n'
                    '• Membuat posting baru\n'
                    '• Mengedit posting\n'
                    '• Menghapus posting\n'
                    '• Menambahkan opsi pembelian',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                '❌ Terjadi kesalahan saat memuat data.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add,
                    size: 80.sp,
                    color: Colors.grey.shade400,
                  ),
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
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final postId = doc.id;

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
                    // Header with Admin badge and actions
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
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
                        // Edit button
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 20.sp,
                            color: Colors.blue,
                          ),
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
                        // Delete button
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 20.sp,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _showDeleteDialog(context, postId);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Title
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 6.h),
                    ],

                    // Image
                    if (imagePath.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          height: 180.h,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150.h,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 40.sp,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],

                    // Content
                    if (content.isNotEmpty)
                      Text(
                        content,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                          height: 1.6,
                          fontFamily: 'Poppins',
                        ),
                      ),

                    // Description
                    if (description.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        description,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black54,
                          height: 1.6,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],

                    // Purchase Options
                    if (linksList.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Text(
                        "Opsi pembelian:",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ...linksList.map((linkData) {
                        final linkMap =
                            linkData as Map<String, dynamic>? ?? {};
                        final url = linkMap['url']?.toString() ?? '';
                        final store = linkMap['store']?.toString() ?? '';
                        final price = linkMap['price'];
                        final logoUrl = linkMap['logoUrl']?.toString() ?? '';

                        if (url.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: GestureDetector(
                            onTap: () async {
                              final uri = Uri.tryParse(url);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Gagal membuka tautan'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
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
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        child: Image.asset(
                                          logoUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.store,
                                              size: 24.sp,
                                              color: Colors.grey,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (store.isNotEmpty)
                                          Text(
                                            store,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        if (price != null)
                                          Text(
                                            "Rp ${_formatPrice(price)}",
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16.sp,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    // Timestamp
                    if (createdAt != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        "Diposting: ${createdAt.day}/${createdAt.month}/${createdAt.year} - ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
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
        child: Icon(Icons.add, size: 28.sp, color: Colors.white),
      ),
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
    if (price == null) return '0';

    try {
      final numPrice = price is int ? price : int.parse(price.toString());
      return numPrice.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    } catch (e) {
      return price.toString();
    }
  }
}