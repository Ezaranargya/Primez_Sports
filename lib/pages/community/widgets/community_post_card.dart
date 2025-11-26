import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/widgets/user_avatar.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:readmore/readmore.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isOwner;
  final bool isAdmin;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isOwner = false,
    this.isAdmin = false,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(timestamp);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  String applyWrapFix(String text) {
    return text.replaceAllMapped(
      RegExp(r'([=/\._-])'),
      (m) => '${m.group(0)}\u200B',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    photoUrl: post.userPhotoUrl,
                    userId: post.userId,
                    username: post.username,
                    bio: bio,
                    size: 40,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (showActions && (isOwner || isAdmin))
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                        size: 20.sp,
                      ),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) onEdit!();
                        if (value == 'delete' && onDelete != null) onDelete!();
                      },
                      itemBuilder: (context) => [
                        if (isOwner)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 18),
                                const SizedBox(width: 8),
                                Text("Edit", style: TextStyle(fontSize: 14.sp)),
                              ],
                            ),
                          ),
                        if (isOwner || isAdmin)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  "Hapus",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              SizedBox(height: 12.h),
              if (post.imageUrl1 != null && post.imageUrl1!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: _buildImage(post.imageUrl1!),
                ),
                SizedBox(height: 12.h),
              ],

              if (post.content.isNotEmpty) ...[
                Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8.h),
              ],

              if (post.description.isNotEmpty)
                ReadMoreText(
                  applyWrapFix(post.description),
                  trimLines: 3,
                  trimMode: TrimMode.Line,
                  trimCollapsedText: "Baca selengkapnya",
                  trimExpandedText: "Tampilkan lebih sedikit",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  moreStyle: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  lessStyle: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              if (post.links.isNotEmpty) ...[
                SizedBox(height: 12.h),
                ...post.links.map((link) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: InkWell(
                        onTap: () => _launchUrl(link.url),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link, size: 20.sp, color: Colors.blue),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  link.url,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(Icons.open_in_new,
                                  size: 16.sp, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],

              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer,
                        size: 14.sp, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    Text(
                      post.brand,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) return _errorPlaceholder("Gambar kosong");

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 250.h,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: 250.h,
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _errorPlaceholder("Gagal memuat gambar"),
      );
    }

    return _errorPlaceholder("Format gambar tidak didukung");
  }

  Widget _errorPlaceholder(String message) {
    return Container(
      width: double.infinity,
      height: 250.h,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined,
              size: 48.sp, color: Colors.grey.shade400),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}