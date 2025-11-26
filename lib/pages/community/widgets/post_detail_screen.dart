import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/models/comment_model.dart';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    debugPrint('📄 PostDetail opened for post: ${widget.post.id}');
    debugPrint('   Brand: ${widget.post.brand}');
    debugPrint('   Username: ${widget.post.username}');
    debugPrint('   Has image: ${widget.post.imageUrl1 != null && widget.post.imageUrl1!.isNotEmpty}');
  }

  String formatRupiah(num price) {
    final formatter = NumberFormat('#,##0', 'de_DE');
    return 'Rp${formatter.format(price)}';
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

  void _showUserProfileDialog(String username, String? userPhotoUrl) {
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
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _showUserProfileDialog(
                            widget.post.username, 
                            widget.post.userPhotoUrl
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
                              widget.post.userPhotoUrl
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
                        
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.post.brand,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (widget.post.imageUrl1 != null && widget.post.imageUrl1!.isNotEmpty)
                    _buildImage(widget.post.imageUrl1!),

                  if (widget.post.description.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        widget.post.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                  if (widget.post.links.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shopping_cart, size: 16.sp, color: Colors.red),
                              SizedBox(width: 6.w),
                              Text(
                                'Opsi Pembelian',
                                style: TextStyle(
                                  fontSize: 13.sp,
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

                  Divider(height: 32.h, thickness: 1),
                  
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
            CircleAvatar(
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
                            Text(
                              comment.username,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                color: Colors.black87,
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
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.4,
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
    if (link.store.toLowerCase().contains('lazada')) {
      buttonColor = Colors.blue;
    } else if (link.store.toLowerCase().contains('shopee')) {
      buttonColor = Colors.orange;
    } else if (link.store.toLowerCase().contains('tokopedia')) {
      buttonColor = Colors.green;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () => _launchURL(link.url),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[300]!),
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
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (link.store.isNotEmpty)
                      Text(
                        link.store,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Beli',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    debugPrint('📄 PostDetail disposed');
    super.dispose();
  }
}