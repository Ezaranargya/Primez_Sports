import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class CommunityPost {
  final String id;
  final String brand;
  final String title;
  final String content;
  final String description;
  final String imageBase64; 
  final List<PurchaseLink> links;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CommunityPost({
    required this.id,
    required this.brand,
    required this.title,
    this.content = '',
    this.description = '',
    this.imageBase64 = '', 
    this.links = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> data, String docId) {
    final linksList = data['links'] as List<dynamic>? ?? [];
    final links = linksList
        .map((e) => PurchaseLink.fromMap(e as Map<String, dynamic>))
        .toList();

    return CommunityPost(
      id: docId,
      brand: data['brand']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageBase64: data['imageBase64']?.toString() ?? '', 
      links: links,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'title': title,
      'content': content,
      'description': description,
      'imageBase64': imageBase64, 
      'links': links.map((e) => e.toMap()).toList(),
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}


class PurchaseLink {
  final String url;
  final String store;
  final int price;
  final String logoUrl;

  const PurchaseLink({
    required this.url,
    this.store = '',
    this.price = 0,
    this.logoUrl = '',
  });

  factory PurchaseLink.fromMap(Map<String, dynamic> map) {
    return PurchaseLink(
      url: map['url']?.toString() ?? '',
      store: map['store']?.toString() ?? '',
      price: map['price'] is int ? map['price'] as int : 0,
      logoUrl: map['logoUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'store': store,
      'price': price,
      'logoUrl': logoUrl,
    };
  }
}


class PostService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'posts';

  PostService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _postRef =>
      _firestore.collection(_collection);

  
  Future<bool> get isAdmin async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      
      final idTokenResult = await user.getIdTokenResult();
      return idTokenResult.claims?['admin'] == true;
    } catch (e) {
      print('❌ Error checking admin status: $e');
      return false;
    }
  }

  
  
  
  Future<String> imageFileToBase64(File imageFile) async {
    try {
      print('🔄 Converting image to base64...');
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      print('✅ Image converted to base64 (${base64String.length} chars)');
      return base64String;
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      rethrow;
    }
  }

  
  
  
  Future<File> base64ToImageFile(String base64String, String fileName) async {
    try {
      print('🔄 Converting base64 to image file...');
      final bytes = base64Decode(base64String);
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      print('✅ Base64 converted to file: ${file.path}');
      return file;
    } catch (e) {
      print('❌ Error converting base64 to file: $e');
      rethrow;
    }
  }

  
  
  
  Future<String> createPost({
    required String brand,
    required String title,
    String? content,
    String? description,
    String? imageBase64, 
    List<Map<String, dynamic>>? links,
  }) async {
    try {
      print('📝 Creating new post for brand: $brand');

      if (!await isAdmin) {
        throw Exception('User does not have admin permissions');
      }

      if (title.trim().isEmpty) {
        throw Exception('Title cannot be empty');
      }

      final postData = {
        'brand': brand.trim(),
        'title': title.trim(),
        'content': content?.trim() ?? '',
        'description': description?.trim() ?? '',
        'imageBase64': imageBase64 ?? '', 
        'links': links ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid ?? '',
      };

      final docRef = await _postRef.add(postData);
      print('✅ Post created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating post: $e');
      rethrow;
    }
  }

  
  
  
  Future<String> createPostWithImageFile({
    required String brand,
    required String title,
    String? content,
    String? description,
    File? imageFile, 
    List<Map<String, dynamic>>? links,
  }) async {
    String? imageBase64;
    if (imageFile != null) {
      imageBase64 = await imageFileToBase64(imageFile);
    }

    return createPost(
      brand: brand,
      title: title,
      content: content,
      description: description,
      imageBase64: imageBase64,
      links: links,
    );
  }

  
  
  
  Future<void> updatePost({
    required String postId,
    String? brand,
    String? title,
    String? content,
    String? description,
    String? imageBase64, 
    List<Map<String, dynamic>>? links,
  }) async {
    try {
      print('🔄 Updating post: $postId');

      if (!await isAdmin) {
        throw Exception('User does not have admin permissions');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (brand != null) updateData['brand'] = brand.trim();
      if (title != null) updateData['title'] = title.trim();
      if (content != null) updateData['content'] = content.trim();
      if (description != null) updateData['description'] = description.trim();
      if (imageBase64 != null) updateData['imageBase64'] = imageBase64; 
      if (links != null) updateData['links'] = links;

      await _postRef.doc(postId).update(updateData);
      print('✅ Post updated successfully');
    } catch (e) {
      print('❌ Error updating post: $e');
      rethrow;
    }
  }

  
  
  
  Future<void> updatePostWithImageFile({
    required String postId,
    String? brand,
    String? title,
    String? content,
    String? description,
    File? imageFile, 
    List<Map<String, dynamic>>? links,
  }) async {
    String? imageBase64;
    if (imageFile != null) {
      imageBase64 = await imageFileToBase64(imageFile);
    }

    return updatePost(
      postId: postId,
      brand: brand,
      title: title,
      content: content,
      description: description,
      imageBase64: imageBase64,
      links: links,
    );
  }

  
  
  
  Future<void> deletePost(String postId) async {
    try {
      print('🗑️ Deleting post: $postId');

      if (!await isAdmin) {
        throw Exception('User does not have admin permissions');
      }

      await _postRef.doc(postId).delete();
      print('✅ Post deleted successfully');
    } catch (e) {
      print('❌ Error deleting post: $e');
      rethrow;
    }
  }

  
  
  
  Stream<List<CommunityPost>> getPostsByBrand(String brand) {
    return _postRef
        .where('brand', isEqualTo: brand)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommunityPost.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  
  
  
  Stream<List<CommunityPost>> getAllPosts() {
    return _postRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommunityPost.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  
  
  
  Future<CommunityPost?> getPostById(String postId) async {
    try {
      final doc = await _postRef.doc(postId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CommunityPost.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error fetching post: $e');
      return null;
    }
  }

  
  
  
  Future<int> getPostsCount({String? brand}) async {
    try {
      Query<Map<String, dynamic>> query = _postRef;
      if (brand != null) {
        query = query.where('brand', isEqualTo: brand);
      }
      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting posts count: $e');
      return 0;
    }
  }

  
  
  
  Future<bool> postExists(String postId) async {
    try {
      final doc = await _postRef.doc(postId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking post existence: $e');
      return false;
    }
  }
}