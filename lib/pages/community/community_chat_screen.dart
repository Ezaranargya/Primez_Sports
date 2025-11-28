import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityChatScreen extends StatefulWidget {
  final String brand;
  final String communityId;

  const CommunityChatScreen({
    super.key,
    required this.brand,
    required this.communityId,
  });

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late Stream<QuerySnapshot> _postsStream;
  int _streamRebuildCount = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 CommunityChatScreen INIT for brand: ${widget.brand}');
    _initializeStream();
  }

  void _initializeStream() {
    debugPrint('🌊 Initializing Firestore stream...');
    _postsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('brand', isEqualTo: widget.brand)
        .orderBy('createdAt', descending: true)
        .snapshots();
    
    // Subscribe untuk debug
    _postsStream.listen((snapshot) {
      debugPrint('🔥 STREAM UPDATE RECEIVED!');
      debugPrint('   Documents count: ${snapshot.docs.length}');
      debugPrint('   Metadata: from cache=${snapshot.metadata.isFromCache}');
      
      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint('   Latest post: ${latestDoc['content']}');
      }
    }, onError: (error) {
      debugPrint('❌ STREAM ERROR: $error');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    debugPrint('🔴 CommunityChatScreen disposed');
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kumpulan Brand ${widget.brand} Official'),
        actions: [
          // Debug button untuk manual refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('🔄 MANUAL REFRESH triggered');
              setState(() {
                _initializeStream();
              });
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _postsStream,
        builder: (context, snapshot) {
          _streamRebuildCount++;
          debugPrint('📊 StreamBuilder REBUILD #$_streamRebuildCount');
          debugPrint('   Connection state: ${snapshot.connectionState}');
          debugPrint('   Has data: ${snapshot.hasData}');
          debugPrint('   Has error: ${snapshot.hasError}');
          
          if (snapshot.hasError) {
            debugPrint('❌ STREAM ERROR DETAILS: ${snapshot.error}');
            debugPrint('❌ ERROR STACK: ${snapshot.stackTrace}');
          }
          
          if (snapshot.hasData) {
            debugPrint('   Document count: ${snapshot.data!.docs.length}');
            if (snapshot.data!.docs.isNotEmpty) {
              final latestPost = snapshot.data!.docs.first.data() as Map<String, dynamic>;
              debugPrint('   Latest post content: ${latestPost['content']}');
            }
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  Text('${snapshot.stackTrace}', 
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeStream();
                      });
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada postingan",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Jadilah yang pertama membuat postingan!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Stream rebuild count: $_streamRebuildCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1, // +1 untuk debug info
            itemBuilder: (context, i) {
              // Debug info di atas
              if (i == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 Debug Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Stream rebuilds: $_streamRebuildCount',
                        style: const TextStyle(fontSize: 12)),
                      Text('Total posts: ${docs.length}',
                        style: const TextStyle(fontSize: 12)),
                      Text('Brand: ${widget.brand}',
                        style: const TextStyle(fontSize: 12)),
                      Text('From cache: ${snapshot.data!.metadata.isFromCache}',
                        style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }
              
              final data = docs[i - 1].data() as Map<String, dynamic>;

              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: _buildPostCard(
                  postId: docs[i - 1].id,
                  userId: data['userId'] ?? '',
                  username: data['username'] ?? 'User',
                  userPhoto: data['userPhotoUrl'] ?? '',
                  imageUrl: data['imageUrl1'] ?? '',
                  content: data['content'] ?? '',
                  description: data['description'] ?? '',
                  createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          debugPrint('➕ FAB PRESSED - Opening CreatePost screen...');
          debugPrint('   Current brand: ${widget.brand}');
          
          final result = await Navigator.pushNamed(
            context,
            '/create-post',
            arguments: {'brand': widget.brand},
          );

          debugPrint('🔙 RETURNED from CreatePost');
          debugPrint('   Result: $result');
          debugPrint('   Result type: ${result.runtimeType}');

          if (result == true) {
            debugPrint('✅ Post created successfully!');
            debugPrint('📜 Waiting for stream to update...');
            
            // Tunggu stream update
            await Future.delayed(const Duration(milliseconds: 1000));
            
            debugPrint('📜 Scrolling to top...');
            _scrollToTop();
          } else {
            debugPrint('❌ Post creation cancelled or failed');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostCard({
    required String postId,
    required String userId,
    required String username,
    required String userPhoto,
    required String imageUrl,
    required String content,
    required String description,
    required DateTime createdAt,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == userId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 2),
            blurRadius: 5,
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showUserProfileBottomSheet(
                  userId: userId,
                  username: username,
                  userPhoto: userPhoto,
                ),
                child: _buildUserAvatar(userPhoto),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editPost(postId);
                    } else if (value == 'delete') {
                      _deletePost(postId, imageUrl);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (imageUrl.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildPostImage(imageUrl),
          ],

          if (content.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              content,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],

          if (description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editPost(String postId) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-post',
      arguments: {'postId': postId},
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Postingan berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deletePost(String postId, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: const Text('Apakah Anda yakin ingin menghapus postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      if (imageUrl.isNotEmpty) {
        debugPrint('🗑️ Deleting image: $imageUrl');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Postingan berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error deleting post: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menghapus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserProfileBottomSheet({
    required String userId,
    required String username,
    required String userPhoto,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              _buildUserAvatar(userPhoto, radius: 40),

              SizedBox(height: 12.h),
              Text(
                username,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToUserProfile(userId, username);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Lihat Profil',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  void _navigateToUserProfile(String userId, String username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membuka profil $username'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildUserAvatar(String url, {double radius = 22}) {
    final trimmed = url.trim();

    if (trimmed.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: const Icon(Icons.person),
      );
    }

    if (trimmed.startsWith("http")) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(trimmed),
      );
    }

    final bytes = _decodeBase64(trimmed);
    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: const Icon(Icons.person),
    );
  }

  Widget _buildPostImage(String url) {
    final trimmed = url.trim();

    if (trimmed.isEmpty) return _imagePlaceholder();

    if (trimmed.startsWith("http")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          trimmed,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 240,
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    }

    final bytes = _decodeBase64(trimmed);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
        ),
      );
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: const Center(
        child: Text("Gambar tidak dapat dimuat"),
      ),
    );
  }

  Uint8List? _decodeBase64(String src) {
    try {
      String cleaned = src
          .replaceAll("\n", "")
          .replaceAll("\r", "")
          .replaceAll(" ", "")
          .trim();

      if (cleaned.contains(",")) {
        cleaned = cleaned.split(",").last;
      }

      cleaned = cleaned.replaceAll(RegExp(r"\s+"), "");

      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
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
}