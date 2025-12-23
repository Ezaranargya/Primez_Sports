import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ TAMBAHAN untuk Clipboard
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/models/comment_model.dart';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/pages/profile/profile_page.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ TAMBAHAN untuk Google Fonts

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    try {
      debugPrint('📄 PostDetail opened for post: ${widget.post.id}');
      debugPrint('   Brand: ${widget.post.brand ?? "null"}');
      debugPrint('   Username: ${widget.post.username}');
      debugPrint('   Has image: ${widget.post.imageUrl1 != null && widget.post.imageUrl1!.isNotEmpty}');
    } catch (e) {
      debugPrint('❌ Error in initState: $e');
    }
  }

  String formatRupiah(num price) {
    final formatter = NumberFormat('#,##0', 'de_DE');
    return 'Rp ${formatter.format(price)}';
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
      return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
    }
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(userId: userId),
      ),
    );
  }

  void _showUserProfileDialog(String username, String? userPhotoUrl, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                  ? NetworkImage(userPhotoUrl)
                  : null,
              child: userPhotoUrl == null || userPhotoUrl.isEmpty
                  ? Icon(Icons.person, size: 32.sp, color: Colors.grey.shade600)
                  : null,
            ),
            SizedBox(height: 16.h),
            
            Text(
              username,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToUserProfile(userId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
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
          ],
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar tidak boleh kosong'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isSubmittingComment) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final commentText = _commentController.text.trim();
      
      debugPrint('💬 Sending comment...');
      debugPrint('   Post ID: ${widget.post.id}');
      debugPrint('   Comment: $commentText');

      await _service.addComment(
        postId: widget.post.id,
        comment: commentText,
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();

      debugPrint('✅ Comment sent successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Komentar berhasil dikirim'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error sending comment: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengirim komentar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      debugPrint('🗑️ Deleting comment: $commentId');
      
      await _service.deleteComment(widget.post.id, commentId);
      
      debugPrint('✅ Comment deleted successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Komentar berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting comment: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menghapus komentar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDeleteCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    debugPrint('┌─────────────────────────────────────────────────────────────');
    debugPrint('│ 🖼️ POST DETAIL - BUILDING IMAGE');
    debugPrint('├─────────────────────────────────────────────────────────────');
    debugPrint('│ 📏 Path length: ${imagePath.length}');
    
    final preview = imagePath.length > 50 ? imagePath.substring(0, 50) : imagePath;
    debugPrint('│ 📝 Preview: $preview...');
    
    debugPrint('│ 🌐 Type: Network URL (Supabase Storage)');
    debugPrint('└─────────────────────────────────────────────────────────────');
    
    return Image.network(
      imagePath,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 300.h,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (_, error, stackTrace) {
        debugPrint('❌ Network image error: $error');
        return _buildImageError();
      },
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 300.h,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Postingan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan User Info
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _showUserProfileDialog(
                            widget.post.username, 
                            widget.post.userPhotoUrl,
                            widget.post.userId
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          child: CircleAvatar(
                            radius: 20.r,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: widget.post.userPhotoUrl != null && 
                                            widget.post.userPhotoUrl!.isNotEmpty
                                ? NetworkImage(widget.post.userPhotoUrl!)
                                : null,
                            child: widget.post.userPhotoUrl == null || 
                                  widget.post.userPhotoUrl!.isEmpty
                                ? Icon(Icons.person, size: 20.sp, color: Colors.grey.shade600)
                                : null,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        
                        Expanded(
                          child: InkWell(
                            onTap: () => _showUserProfileDialog(
                              widget.post.username, 
                              widget.post.userPhotoUrl,
                              widget.post.userId
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _formatTimestamp(widget.post.createdAt),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Judul Produk
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      widget.post.title ?? '',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Kategori Badges
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        if (widget.post.mainCategory != null && widget.post.mainCategory!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              widget.post.mainCategory!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (widget.post.subCategory != null && widget.post.subCategory!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              widget.post.subCategory!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Gambar Produk
                  if (widget.post.imageUrl1 != null && widget.post.imageUrl1!.isNotEmpty)
                    _buildImage(widget.post.imageUrl1!),
                  SizedBox(height: 16.h),

                  // Harga Produk Utama
                  if (widget.post.content.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,                
                          borderRadius: BorderRadius.circular(12.r), 
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Harga:',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              formatRupiah(int.tryParse(widget.post.content) ?? 0),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16.h),

                  // Deskripsi Produk - ✅ UPDATED WITH GOOGLE FONTS
                  if (widget.post.description != null && widget.post.description!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            widget.post.description!,
                            textAlign: TextAlign.start,
                            textWidthBasis: TextWidthBasis.parent,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              height: 1.75,
                              letterSpacing: 0.2,
                              wordSpacing: 0,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16.h),

                  // Opsi Pembelian
                  if (widget.post.links.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shopping_cart, size: 18.sp, color: AppColors.primary),
                              SizedBox(width: 8.w),
                              Text(
                                '${widget.post.links.length} opsi pembelian',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          ...widget.post.links.map((link) => _buildPurchaseLink(link)),
                        ],
                      ),
                    ),

                  // Timestamp Posting
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 14.sp, color: Colors.grey.shade500),
                        SizedBox(width: 6.w),
                        Text(
                          'Diposting: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(widget.post.createdAt)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 16.h),
                  
                  // Section Komentar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 20.sp, color: Colors.grey.shade700),
                        SizedBox(width: 8.w),
                        Text(
                          'Komentar',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  StreamBuilder<List<Comment>>(
                    stream: _service.getComments(widget.post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.w),
                            child: const CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        debugPrint('❌ Error loading comments: ${snapshot.error}');
                        return Padding(
                          padding: EdgeInsets.all(32.w),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.error_outline, size: 48.sp, color: Colors.red[300]),
                                SizedBox(height: 8.h),
                                Text(
                                  'Gagal memuat komentar',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final comments = snapshot.data ?? [];

                      if (comments.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(32.w),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 48.sp, color: Colors.grey[300]),
                                SizedBox(height: 8.h),
                                Text(
                                  'Belum ada komentar',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Jadilah yang pertama berkomentar!',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                        itemBuilder: (context, index) {
                          return _buildCommentItem(comments[index]);
                        },
                      );
                    },
                  ),

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),

          // Input Komentar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar...',
                        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      enabled: !_isSubmittingComment,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      color: _isSubmittingComment 
                          ? Colors.grey.shade300 
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSubmittingComment ? null : _sendComment,
                      icon: _isSubmittingComment
                          ? SizedBox(
                              width: 20.sp,
                              height: 20.sp,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white, size: 20.sp),
                      padding: EdgeInsets.all(8.w),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return FutureBuilder<bool>(
      future: _service.isCommentOwner(widget.post.id, comment.id),
      builder: (context, snapshot) {
        final isOwner = snapshot.data ?? false;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showUserProfileDialog(
                comment.username,
                comment.userPhotoUrl,
                comment.userId,
              ),
              child: CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: comment.userPhotoUrl != null && 
                                 comment.userPhotoUrl!.isNotEmpty
                    ? NetworkImage(comment.userPhotoUrl!)
                    : null,
                child: comment.userPhotoUrl == null || comment.userPhotoUrl!.isEmpty
                    ? Icon(Icons.person, size: 16.sp, color: Colors.grey.shade600)
                    : null,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8.w,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _showUserProfileDialog(
                                comment.username,
                                comment.userPhotoUrl,
                                comment.userId,
                              ),
                              child: Text(
                                comment.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              _formatTimestamp(comment.createdAt),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, size: 18.sp, color: Colors.grey[600]),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteCommentDialog(comment.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16.sp, color: Colors.red),
                                  SizedBox(width: 8.w),
                                  const Text('Hapus', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    comment.comment,
                    textAlign: TextAlign.start,
                    textWidthBasis: TextWidthBasis.parent,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      height: 1.75,
                      letterSpacing: 0.2,
                      wordSpacing: 0,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurchaseLink(PostLink link) {
    Color buttonColor = Colors.red;
    final store = link.store ?? '';
    if (store.toLowerCase().contains('lazada')) {
      buttonColor = Colors.blue;
    } else if (store.toLowerCase().contains('shopee')) {
      buttonColor = Colors.orange;
    } else if (store.toLowerCase().contains('tokopedia')) {
      buttonColor = Colors.green;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () {
          final url = link.url ?? '';
          if (url.isNotEmpty) {
            _launchURL(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link pembelian tidak tersedia'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
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
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (store.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          store,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Beli',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward, size: 16.sp, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    debugPrint('📄 PostDetail disposed');
    super.dispose();
  }
}