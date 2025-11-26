import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/pages/community/widgets/community_post_card.dart';
import 'package:my_app/pages/community/widgets/create_post_screen.dart';
import 'package:my_app/theme/app_colors.dart';

class CommunityBrandPostsScreen extends StatefulWidget {
  final String brand;

  const CommunityBrandPostsScreen({
    super.key,
    required this.brand,
  });

  @override
  State<CommunityBrandPostsScreen> createState() => _CommunityBrandPostsScreenState();
}

class _CommunityBrandPostsScreenState extends State<CommunityBrandPostsScreen> {
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Kumpulan Brand ${widget.brand} Official',
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: const Text(
              'Ayo ikuti komunitas ini untuk mendapatkan informasi terbaru',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          
          // Posts list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('brand', isEqualTo: widget.brand)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                debugPrint('📊 ========================================');
                debugPrint('📊 StreamBuilder State:');
                debugPrint('   hasError: ${snapshot.hasError}');
                debugPrint('   connectionState: ${snapshot.connectionState}');
                
                if (snapshot.hasError) {
                  debugPrint('   ❌ Error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('   ⏳ Loading...');
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                debugPrint('   📦 Total docs: ${docs.length}');

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada postingan',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    debugPrint('📄 ========================================');
                    debugPrint('📄 Post #$index:');
                    debugPrint('   Doc ID: ${doc.id}');
                    debugPrint('   Brand: ${data['brand']}');
                    debugPrint('   Content: ${data['content']}');
                    debugPrint('   Username: ${data['username']}');
                    debugPrint('   UserId: ${data['userId']}');
                    
                    // 🔍 CEK IMAGEURL1
                    final imageUrl1 = data['imageUrl1'];
                    if (imageUrl1 != null) {
                      final imageStr = imageUrl1.toString();
                      debugPrint('   🖼️ imageUrl1 EXISTS:');
                      debugPrint('      Type: ${imageUrl1.runtimeType}');
                      debugPrint('      Length: ${imageStr.length} chars');
                      debugPrint('      Prefix: ${imageStr.substring(0, imageStr.length > 80 ? 80 : imageStr.length)}...');
                      debugPrint('      Is data URL: ${imageStr.startsWith('data:image')}');
                    } else {
                      debugPrint('   ⚠️ imageUrl1 is NULL');
                    }
                    
                    // 🔍 CEK USERPHOTOURL
                    final userPhotoUrl = data['userPhotoUrl'];
                    if (userPhotoUrl != null) {
                      final photoStr = userPhotoUrl.toString();
                      debugPrint('   👤 userPhotoUrl EXISTS:');
                      debugPrint('      Type: ${userPhotoUrl.runtimeType}');
                      debugPrint('      Length: ${photoStr.length} chars');
                      debugPrint('      Prefix: ${photoStr.substring(0, photoStr.length > 80 ? 80 : photoStr.length)}...');
                    } else {
                      debugPrint('   ⚠️ userPhotoUrl is NULL');
                    }
                    
                    debugPrint('📄 ========================================');

                    try {
                      // ✅ Parse post dari Firestore
                      final post = CommunityPost.fromMap(data, doc.id);
                      
                      debugPrint('✅ Post object created successfully:');
                      debugPrint('   Post ID: ${post.id}');
                      debugPrint('   Username: ${post.username}');
                      debugPrint('   Content: ${post.content}');
                      debugPrint('   imageUrl1: ${post.imageUrl1 == null ? "NULL" : "${post.imageUrl1!.length} chars"}');
                      debugPrint('   userPhotoUrl: ${post.userPhotoUrl == null ? "NULL" : "${post.userPhotoUrl!.length} chars"}');
                      
                      final isOwner = post.userId == _currentUserId;
                      
                      return CommunityPostCard(
                        post: post,
                        showActions: true,
                        isOwner: isOwner,
                        isAdmin: false, // Set sesuai role user
                        onEdit: isOwner ? () => _editPost(post) : null,
                        onDelete: isOwner ? () => _deletePost(post) : null,
                      );
                    } catch (e, stackTrace) {
                      debugPrint('❌ ERROR creating post object:');
                      debugPrint('   Error: $e');
                      debugPrint('   Stack: $stackTrace');
                      
                      return Card(
                        margin: const EdgeInsets.all(16),
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Error loading post',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Error: $e'),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // FAB untuk create post
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createPost(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.secondary),
      ),
    );
  }

  void _createPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(brand: widget.brand),
      ),
    );
  }

  void _editPost(CommunityPost post) {
    // TODO: Implement edit post
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur edit belum tersedia')),
    );
  }

  Future<void> _deletePost(CommunityPost post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: const Text('Yakin ingin menghapus postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(post.id)
            .delete();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Postingan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}