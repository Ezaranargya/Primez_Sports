import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_app/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'products';

  bool get _isAdmin => true;

  CollectionReference<Map<String, dynamic>> get _productRef =>
      _firestore.collection(_collection);

  Future<void> addProductAndNotify(Product product) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User tidak login");

    final productRef = await _firestore.collection('products').add(product.toMap());
    print('✅ Produk berhasil disimpan dengan ID: ${productRef.id}');

    final usersSnapshot = await _firestore.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Produk Baru Tersedia!',
        'message': 'Produk "${product.name}" baru saja ditambahkan oleh admin.',
        'productId': productRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    await _sendFCMNotificationToAllUsers(product);

    print('✅ Produk baru berhasil ditambahkan dan notifikasi terkirim ke semua user!');
  } catch (e) {
    print('❌ Error addProductAndNotify: $e');
    throw e;
  }
}

  // Method untuk kirim FCM notification ke semua user
  Future<void> _sendFCMNotificationToAllUsers(Product product) async {
    try {
      // Ambil semua FCM tokens dari collection users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      List<String> fcmTokens = [];
      for (var doc in usersSnapshot.docs) {
        String? token = doc.data() != null 
            ? (doc.data() as Map<String, dynamic>)['fcmToken'] 
            : null;
        if (token != null && token.isNotEmpty) {
          fcmTokens.add(token);
        }
      }

      if (fcmTokens.isEmpty) {
        print('⚠️ Tidak ada FCM token yang ditemukan');
        return;
      }

      // Kirim notifikasi menggunakan Firebase Cloud Messaging
      await _sendFCMNotification(
        tokens: fcmTokens,
        title: '🎉 Produk Baru!',
        body: '${product.name} - ${product.brand} sekarang tersedia!',
        productId: product.id,
      );

      print('✅ FCM Notifikasi berhasil dikirim ke ${fcmTokens.length} user');
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
    }
  }

  // Method untuk kirim FCM notification via HTTP
  Future<void> _sendFCMNotification({
    required List<String> tokens,
    required String title,
    required String body,
    String? productId,
  }) async {

    print('⚠️ FCM Push Notification membutuhkan backend server.');
    print('📝 Notifikasi sudah tersimpan di Firestore: users/{userId}/notifications');
    
    const String serverKey = 'YOUR_FIREBASE_SERVER_KEY';
    
    for (String token in tokens) {
      try {
        final response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': token,
            'notification': {
              'title': title,
              'body': body,
              'sound': 'default',
            },
            'data': {
              'productId': productId ?? '',
              'type': 'new_product',
            },
            'priority': 'high',
          }),
        );

        if (response.statusCode == 200) {
          print('✅ FCM Notifikasi terkirim ke token: ${token.substring(0, 20)}...');
        } else {
          print('❌ Gagal kirim FCM notifikasi: ${response.body}');
        }
      } catch (e) {
        print('❌ Error kirim FCM ke token $token: $e');
      }
    }
  }

  // ================================================================
  // 🧩 FUNGSI UTAMA SAVE / UPDATE PRODUK
  // ================================================================
  Future<bool> saveOrUpdateProduct({
    String? productId,
    String? name,
    String? brand,
    String? description,
    double? price,
    List<String>? categories,
    List<Map<String, dynamic>>? purchaseOptions,
    String? imageBase64,
    Product? product,
  }) async {
    try {
      print('💾 ===== SAVE OR UPDATE PRODUCT =====');

      final data = product != null
          ? product.toMap()
          : {
              'name': name?.trim() ?? '',
              'brand': brand?.trim() ?? '',
              'description': description?.trim() ?? '',
              'price': price ?? 0.0,
              'categories': categories ?? [],
              'purchaseOptions': purchaseOptions ?? [],
              'imageBase64': imageBase64 ?? '',
              'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
            };

      print('🧩 Data sebelum validasi: $data');

      final productData = {
        'name': data['name'] ?? '',
        'brand': data['brand'] ?? '',
        'description': data['description'] ?? '',
        'price': (data['price'] is num)
            ? (data['price'] as num).toDouble()
            : double.tryParse(data['price']?.toString() ?? '0') ?? 0,
        'categories': data['categories'] ?? [],
        'purchaseOptions': data['purchaseOptions'] ?? [],
        'imageBase64': data['imageBase64'] ?? '',
        'bannerImage': data['bannerImage'] ?? '',
        'userId': data['userId'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final nameValid = (productData['name'] as String).isNotEmpty;
      final hargaValid = (productData['price'] as num) > 0;
      final categoriesValid = productData['categories'] is List &&
          (productData['categories'] as List).isNotEmpty;

      if (!nameValid || !hargaValid || !categoriesValid) {
        print('❌ Data produk tidak valid');
        return false;
      }

      productData.remove('id');

      final existing = await _productRef
          .where('name', isEqualTo: productData['name'])
          .where('brand', isEqualTo: productData['brand'])
          .get();

      final alreadyExists = existing.docs.isNotEmpty;

      if (alreadyExists && (productId == null || productId.isEmpty)) {
        print('❌ Produk duplikat ditemukan: ${productData['name']}');
        return false;
      }

      if (alreadyExists &&
          productId != null &&
          productId.isNotEmpty &&
          existing.docs.first.id != productId) {
        print('❌ Produk lain dengan nama & brand sama sudah ada');
        return false;
      }

      if (productId == null || productId.isEmpty) {
        print('➕ Menambahkan produk baru...');
        productData['createdAt'] = FieldValue.serverTimestamp();
        await _productRef.add(productData);
      } else {
        print('🔄 Update produk dengan ID: $productId');
        await _productRef.doc(productId).set(productData, SetOptions(merge: true));
      }

      print('✅ Produk berhasil disimpan ke Firestore');
      return true;
    } catch (e, stack) {
      print('❌ Gagal saveOrUpdateProduct: $e');
      print('📜 Stack trace:\n$stack');
      return false;
    }
  }

  // ================================================================
  // 🗑️ DELETE PRODUK
  // ================================================================
  Future<bool> deleteProduct(String id) async {
    if (!_isAdmin) {
      print('❌ User tidak memiliki akses admin');
      return false;
    }

    try {
      await _productRef.doc(id).delete();
      print('✅ Produk $id berhasil dihapus');
      return true;
    } catch (e) {
      print('❌ Gagal menghapus produk: $e');
      return false;
    }
  }

  // ================================================================
  // 🔄 STREAM DAN FETCH PRODUK
  // ================================================================
  Stream<List<Product>> getAllProducts() {
    return _productRef.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) {
            try {
              return Product.fromMap(doc.data(), doc.id);
            } catch (e) {
              print('⚠️ Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Product>()
          .toList();

      print('📦 Loaded ${products.length} products');
      return products;
    });
  }

  Future<Product?> fetchProductById(String id) async {
    try {
      final doc = await _productRef.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error fetchProductById: $e');
      return null;
    }
  }

  Stream<Product?> getProductById(String id) {
    return _productRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Product.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<Product>> getProductsByCategory(String category) {
    return _productRef
        .where('categories', arrayContains: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Product>> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _productRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .where((p) => p.name.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  Stream<List<Product>> getTrendingProducts() {
    return _productRef
        .where('categories', arrayContains: 'Trending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ================================================================
  // 📸 UPLOAD GAMBAR
  // ================================================================
  Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      final ref = _storage.ref().child('products/$fileName');
      final uploadTask = await ref.putFile(imageFile);
      final url = await uploadTask.ref.getDownloadURL();
      print('✅ Gambar berhasil diupload: $url');
      return url;
    } catch (e) {
      print('❌ Gagal upload gambar: $e');
      rethrow;
    }
  }

  // ================================================================
  // 🔢 STATISTIK PRODUK
  // ================================================================
  Future<int> getProductsCount() async {
    try {
      final snapshot = await _productRef.get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getProductsCount: $e');
      return 0;
    }
  }

  Future<bool> productExists(String id) async {
    try {
      final doc = await _productRef.doc(id).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error productExists: $e');
      return false;
    }
  }
}