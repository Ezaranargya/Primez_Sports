import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/pages/community/widgets/community_header.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityChatPage extends StatelessWidget {
  final String brand;
  final String logoPath;

  const CommunityChatPage({
    super.key,
    required this.brand,
    required this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          // 🔴 Header merah + card putih
          CommunityHeader(
            brandName: brand,
            logoPath: logoPath,
            onBack: () => Navigator.pop(context),
          ),

          // 🔘 List chat komunitas dari Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('posts')
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
                    child: Text(
                      'Belum ada posting dari admin brand "$brand".',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>? ?? {};

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
                          Text(
                            "Admin $brand",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8.h),

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

                          if (imagePath.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.network(
                                imagePath,
                                fit: BoxFit.cover,
                                height: 180.h,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150.h,
                                    color: Colors.grey[200],
                                    alignment: Alignment.center,
                                    child: Icon(Icons.image_not_supported_outlined,
                                        size: 40.sp, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 10.h),
                          ],

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
                              final linkMap = linkData as Map<String, dynamic>? ?? {};
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
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6.r),
                                              child: Image.network(
                                                logoUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
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

                          if (createdAt != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              "Diposting: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
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
