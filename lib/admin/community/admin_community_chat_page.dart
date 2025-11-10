import 'dart:convert';
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.red, fontSize: 13.sp),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        
        print('📊 Found ${docs.length} posts for brand: $brand');
        
        if (docs.isEmpty) return _buildEmptyState(brand);

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final postId = doc.id;
            
            
            print('📄 Post $index: ${data['title']}');
            
            return _buildPostCard(context, brand, postId, data);
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
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  
  bool _isBase64(String str) {
    if (str.isEmpty) return false;
    
    try {
      if (str.startsWith('http') || 
          str.startsWith('https') || 
          str.startsWith('assets/') ||
          str.contains('.png') || 
          str.contains('.jpg') || 
          str.contains('.jpeg') ||
          str.contains('.webp') ||
          str.contains('/') && str.length < 100) {
        return false;
      }
      
      if (str.length < 100) {
        return false;
      }
      
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  
  Widget _buildPostImage(String imagePath) {
    if (imagePath.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: _isBase64(imagePath)
            ? Image.memory(
                base64Decode(imagePath),
                fit: BoxFit.cover,
                height: 180.h,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImageError();
                },
              )
            : imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    height: 180.h,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageError();
                    },
                  )
                : Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    height: 180.h,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageError();
                    },
                  ),
      ),
    );
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
          Text(
            'Gambar tidak dapat dimuat',
            style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
          ),
        ],
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
    final imagePath = data['imageUrl']?.toString() ?? '';
    final linksList = data['links'] as List<dynamic>? ?? [];
    final mainCategory = data['mainCategory']?.toString() ?? '';
    final subCategory = data['subCategory']?.toString() ?? '';
    final communityId = data['communityId']?.toString();

    // DEBUG: Check links
    print('🎯 POST DEBUG: $title');
    print('🎯 Links count: ${linksList.length}');
    print('🎯 Links data: $linksList');

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
                      labelStyle: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.blue[700],
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (subCategory.isNotEmpty)
                    Chip(
                      label: Text(subCategory),
                      backgroundColor: Colors.green[50],
                      labelStyle: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.green[700],
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),

          
          _buildPostImage(imagePath),

          
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
                    Text(
                      'Harga Utama: ',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Rp ${_formatPrice(content)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black87,
                  height: 1.6,
                ),
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

  
  Widget _buildLinks(BuildContext context, List<dynamic> linksList) {
    print('🔗 _buildLinks dipanggil dengan ${linksList.length} links');
    
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
          String logoUrl = linkMap['logoUrl']?.toString() ?? '';

          // DEBUG: Print semua data
          print('🔍 ========== DEBUG LINK ==========');
          print('🔍 URL: $url');
          print('🔍 Store from Firestore: $store');
          print('🔍 LogoUrl from Firestore: $logoUrl');
          print('🔍 LogoUrl isEmpty: ${logoUrl.isEmpty}');
          
          // PERBAIKAN: Fallback logo detection jika logoUrl kosong
          if (logoUrl.isEmpty && url.isNotEmpty) {
            print('⚠️ LogoUrl kosong, mencoba detect dari URL...');
            logoUrl = _detectLogoFromUrl(url);
            print('✅ Hasil detect: $logoUrl');
          } else if (logoUrl.isNotEmpty) {
            print('✅ LogoUrl sudah ada: $logoUrl');
          }
          
          print('🔍 Final LogoUrl yang digunakan: $logoUrl');
          print('🔍 ==================================');

          if (url.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.only(top: 8.h),
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: Image.asset(
                            logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Error loading logo: $logoUrl - $error');
                              return Icon(
                                Icons.store,
                                size: 24.sp,
                                color: Colors.grey[400],
                              );
                            },
                          ),
                        ),
                      ),
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
                              ),
                            ),
                          if (price != null && price > 0)
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
    );
  }

  // TAMBAHAN: Method helper untuk detect logo
  String _detectLogoFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    print('🔎 Detecting logo from URL: $lowerUrl');
    
    final Map<String, String> storeLogos = {
      'tokopedia': 'assets/logo_tokopedia.png',
      'shopee': 'assets/logo_shopee.png',
      'blibli': 'assets/logo_blibli.jpg',
      'underarmour': 'assets/logo_under_armour.png',
      'under-armour': 'assets/logo_under_armour.png',
      'under armour': 'assets/logo_under_armour.png',
      'jordan': 'assets/logo_jordan.png',
      'puma': 'assets/logo_puma.png',
      'mizuno': 'assets/logo_mizuno.png',
      'nike': 'assets/logo_nike.png',
      'adidas': 'assets/logo_adidas.png',
    };
    
    for (var entry in storeLogos.entries) {
      // Remove spaces and special characters for comparison
      final cleanKey = entry.key.replaceAll(' ', '').replaceAll('-', '');
      final cleanUrl = lowerUrl.replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '');
      
      print('🔎 Checking: $cleanKey vs $cleanUrl');
      
      if (cleanUrl.contains(cleanKey)) {
        print('✅ MATCH! Detected logo for ${entry.key}: ${entry.value}');
        return entry.value;
      }
    }
    
    print('⚠️ No logo detected for URL: $url');
    return ''; // Return empty string instead of non-existent path
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

                
                if (communityId != null && communityId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('communities')
                      .doc(communityId)
                      .collection('posts')
                      .doc(postId)
                      .delete();
                }

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