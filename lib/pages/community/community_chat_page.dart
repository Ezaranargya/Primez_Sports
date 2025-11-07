import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/pages/community/widgets/community_header.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:my_app/utils/image_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';


class CommunityChatPage extends StatelessWidget {
  final String brand;
  final String logoPath;

  const CommunityChatPage({
    super.key,
    required this.brand,
    required this.logoPath,
  });

    String formatCurrency(num price) {
    final formatter = NumberFormat('#,##0', 'de_DE');
    return 'Rp ${formatter.format(price)}';
  }

    String formatRupiah(num price) {
    final formatter = NumberFormat('#,##0', 'de_DE');
    return 'Rp ${formatter.format(price)}';
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

    final logoPath = brandLogos[brand] ?? "assets/default_logo.png";

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          CommunityHeader(
            brandName: brand,
            logoPath: logoPath,
            onBack: () => Navigator.pop(context),
          ),
          SizedBox(height: 16.h),           Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                    final data =
                        docs[index].data() as Map<String, dynamic>? ?? {};

                    final title = data['title']?.toString() ?? '';
                    final content = data['content']?.toString() ?? '';
                    final description = data['description']?.toString() ?? '';
                    final imagePath = data['imageUrl']?.toString() ?? '';
                    final linksList = data['links'] as List<dynamic>? ?? [];
                    final price = data['price'];
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
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8.h),

                          if (title.isNotEmpty) ...[
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                          ],

                          if (price != null) ...[
                            Text(
                              formatCurrency(
                                num.tryParse(price.toString()) ?? 0,
                              ),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                          ],

                          if (imagePath.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: _isBase64(imagePath)
                                  ? Image.memory(
                                      base64Decode(imagePath),
                                      fit: BoxFit.cover,
                                      height: 180.h,
                                      width: double.infinity,
                                    )
                                  : Image.network(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      height: 180.h,
                                      width: double.infinity,
                                    ),
                            ),
                            SizedBox(height: 10.h),
                          ],

                          if (content.isNotEmpty)
                            Text(
                                                            num.tryParse(content) != null
                                  ? formatCurrency(num.parse(content))
                                  : content,
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
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: Colors.black54,
                                height: 1.6,
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
                              final linkMap =
                                  linkData as Map<String, dynamic>? ?? {};
                              final url = linkMap['url']?.toString() ?? '';
                              final store = linkMap['store']?.toString() ?? '';
                              final price = linkMap['price'];
                              final logoUrl =
                                  linkMap['logoUrl']?.toString() ?? '';

                              if (url.isEmpty) return const SizedBox.shrink();

                              return Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.tryParse(url);
                                    if (uri != null &&
                                        await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode:
                                              LaunchMode.externalApplication);
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
                                          color:
                                              Colors.black.withOpacity(0.05),
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
                                            margin:
                                                EdgeInsets.only(right: 10.w),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                              child: buildLogo(logoUrl),
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
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              if (price != null)
                                                Text(
                                                  formatRupiah(
                                                    price is num
                                                        ? price
                                                        : num.tryParse(
                                                                price
                                                                    .toString()) ??
                                                            0,
                                                  ),
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
                                          Iconsax.arrow_left,
                                          size: 16.sp,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            SizedBox(height: 4.h),
                            Text(
                              "*Harga dapat berubah sewaktu-waktu",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.redAccent,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],

                          if (createdAt != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              "Diposting: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
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

  bool _isBase64(String str) {
    if (str.isEmpty) return false;

    try {
      if (str.startsWith('http') ||
          str.startsWith('https') ||
          str.startsWith('assets/') ||
          str.contains('.png') ||
          str.contains('.jpg') ||
          str.contains('.jpeg') ||
          str.contains('.webp')) {
        return false;
      }

      if (str.length < 100) return false;

      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }
}