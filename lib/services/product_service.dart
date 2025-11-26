import 'dart:io';
import 'dart:typed_data'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';
  final CommunityService _communityService = CommunityService();

  bool get _isAdmin => true;

  CollectionReference<Map<String, dynamic>> get _productRef =>
      _firestore.collection(_collection);

  Future<String> uploadImage(File file, String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      final path = 'products/$fileName';

      final bytes = await file.readAsBytes();

      await supabase.storage
          .from('product-images')
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

      final publicUrl =
          supabase.storage.from('product-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print("❌ Gagal upload di supabase: $e");
      rethrow;
    }
  }

  Future<String?> addProduct(Product product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User tidak login");

      if (product.name.isEmpty || product.price <= 0 || product.categories.isEmpty) {
        print('❌ Data produk tidak valid');
        return null;
      }

      final existing = await _productRef
          .where('name', isEqualTo: product.name)
          .where('brand', isEqualTo: product.brand)
          .get();

      if (existing.docs.isNotEmpty) {
        print('❌ Produk duplikat');
        return null;
      }

      final productRef = await _productRef.add(product.toMap());
      return productRef.id;

    } catch (e) {
      print('❌ Error addProduct: $e');
      return null;
    }
  }

  Future<String?> addProductWithNotifications(Product product) async {
    try {
      final ref = await _productRef.add(product.toMap());
      final productId = ref.id;

      final usersSnapshot = await _firestore.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .add({
          'title': 'Produk Baru Tersedia!',
          'message': 'Produk "${product.name}" baru ditambahkan.',
          'productId': productId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      await _sendFCMNotificationToAllUsers(product);

      final contentId = DateTime.now().millisecondsSinceEpoch.toString().substring(6);

      final links = product.purchaseOptions.map((option) {
        return PostLink(
          logoUrl1: option.logoUrl,
          price: option.price,
          store: option.storeName,
          url: option.link,
        );
      }).toList();

      File? imageFile;
      
      if (product.imageUrl.isNotEmpty && 
          !product.imageUrl.startsWith('http') && 
          File(product.imageUrl).existsSync()) {
        imageFile = File(product.imageUrl);
      }

      await _communityService.createPost(
        brand: product.brand,
        content: contentId,
        description: product.description,
        imageFile: imageFile, 
        links: links,
      );

      return productId;

    } catch (e) {
      print('❌ Error addProductWithNotifications: $e');
      return null;
    }
  }

  Future<void> _sendFCMNotificationToAllUsers(Product product) async {
    try {
      final snapshot = await _firestore.collection('users').get();

      List<String> tokens = [];
      for (var doc in snapshot.docs) {
        final token = doc['fcmToken'];
        if (token != null && token.isNotEmpty) tokens.add(token);
      }

      if (tokens.isEmpty) return;

      await _sendFCMNotification(
        tokens: tokens,
        title: '🎉 Produk Baru!',
        body: '${product.name} - ${product.brand} sekarang tersedia!',
        productId: product.id,
      );

    } catch (e) {
      print('❌ Error send FCM: $e');
    }
  }

  Future<void> _sendFCMNotification({
    required List<String> tokens,
    required String title,
    required String body,
    String? productId,
  }) async {
    print('⚠️ Butuh server backend untuk push FCM. (Firestore notification sudah disimpan)');
  }

  Future<bool> saveOrUpdateProduct({
    String? productId,
    String? name,
    String? brand,
    String? description,
    double? price,
    List<String>? categories,
    List<Map<String, dynamic>>? purchaseOptions,
    String? imageUrl,
    File? imageFile,
    Uint8List? imageBytes, 
    String? imageFileName, 
    String? existingImageUrl, 
    Product? product,
  }) async {
    try {
      String? finalImageUrl = existingImageUrl ?? imageUrl;
      
      if (imageFile != null || imageBytes != null) {
        final fileName = imageFileName ?? 
                        '${name ?? 'product'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        if (imageFile != null) {
          finalImageUrl = await uploadImage(imageFile, fileName);
        } else if (imageBytes != null) {
          final tempFile = File(fileName);
          await tempFile.writeAsBytes(imageBytes!);
          finalImageUrl = await uploadImage(tempFile, fileName);
        }
      }

      final data = product != null
          ? product.toMap()
          : {
              'name': name ?? '',
              'brand': brand ?? '',
              'description': description ?? '',
              'price': price ?? 0,
              'categories': categories ?? [],
              'purchaseOptions': purchaseOptions ?? [],
              'imageUrl': finalImageUrl ?? '',
              'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
            };

      final parsed = {
        'name': data['name'],
        'brand': data['brand'],
        'description': data['description'],
        'price': (data['price'] as num).toDouble(),
        'categories': data['categories'],
        'purchaseOptions': data['purchaseOptions'],
        'imageUrl': finalImageUrl ?? data['imageUrl'],
        'userId': data['userId'],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (productId == null || productId.isEmpty) {
        parsed['createdAt'] = FieldValue.serverTimestamp();
        await _productRef.add(parsed);
      } else {
        await _productRef.doc(productId).set(parsed, SetOptions(merge: true));
      }

      return true;

    } catch (e) {
      print('❌ Error saveOrUpdateProduct: $e');
      return false;
    }
  }

  Future<void> migrateProductsToSupabase() async {
    try {
      print('🔄 Starting migration to Supabase...');
      
      final snapshot = await _productRef.get();
      int migrated = 0;
      int skipped = 0;
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final imageUrl = data['imageUrl'] as String?;
          
          if (imageUrl == null || 
              imageUrl.isEmpty || 
              imageUrl.startsWith('http')) {
            skipped++;
            continue;
          }
          
          if (imageUrl.startsWith('data:image')) {
            print('⚠️ Skipping base64 image for ${doc.id}');
            skipped++;
            continue;
          }
          
          migrated++;
          print('✅ Already migrated: ${doc.id}');
          
        } catch (e) {
          print('❌ Error migrating ${doc.id}: $e');
        }
      }
      
      print('🎉 Migration complete!');
      print('   Migrated: $migrated');
      print('   Skipped: $skipped');
      
    } catch (e) {
      print('❌ Migration error: $e');
      rethrow;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _productRef.doc(id).delete();
      return true;
    } catch (e) {
      print('❌ Gagal delete: $e');
      return false;
    }
  }

  Stream<List<Product>> getAllProducts() {
    return _productRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Product>> getProductsByCategory(String category) {
    return _productRef
        .where('categories', arrayContains: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  
  Stream<Product?> getProductById(String id) {
    return _productRef.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return Product.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  Future<Product?> fetchProductById(String id) async {
    final doc = await _productRef.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.data()!, doc.id);
  }
}