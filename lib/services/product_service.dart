import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_app/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'products';

  bool get _isAdmin => true;

  CollectionReference<Map<String, dynamic>> get _productRef =>
      _firestore.collection(_collection);

  // ============================================================
  // 🔹 SAVE OR UPDATE PRODUCT (FINAL STABLE VERSION)
  // ============================================================
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

      // 🔧 Bentuk data dari model atau parameter
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

      // ✅ Bentuk ulang dengan tipe aman
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
        'userId': data['userId'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ✅ Validasi data
      final nameValid = (productData['name'] as String).isNotEmpty;
      final hargaValid = (productData['price'] as num) > 0;
      final categoriesValid = productData['categories'] is List &&
          (productData['categories'] as List).isNotEmpty;

      if (!nameValid || !hargaValid || !categoriesValid) {
        print('❌ Data produk tidak valid');
        print(
            '➡️ nameValid: $nameValid, hargaValid: $hargaValid, categoriesValid: $categoriesValid');
        return false;
      }

      // Hapus ID internal
      productData.remove('id');

      // ✅ Tambah atau update produk
      if (productId == null || productId.isEmpty) {
        print('➕ Menambahkan produk baru...');
        productData['createdAt'] = FieldValue.serverTimestamp();
        await _productRef.add(productData);
      } else {
        print('🔄 Update produk dengan ID: $productId');
        await _productRef.doc(productId).update(productData);
      }

      print('✅ Produk berhasil disimpan ke Firestore');
      return true;
    } catch (e, stack) {
      print('❌ Gagal saveOrUpdateProduct: $e');
      print('📜 Stack trace:\n$stack');

      if (e is FirebaseException) {
        print('🔥 Firebase error code: ${e.code}');
        print('🔥 Firebase message: ${e.message}');
      }

      return false;
    }
  }

  // ============================================================
  // 🔹 DELETE PRODUCT
  // ============================================================
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

  // ============================================================
  // 🔹 GET ALL PRODUCTS
  // ============================================================
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

  // ============================================================
  // 🔹 FETCH PRODUCT BY ID
  // ============================================================
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

  // ============================================================
  // 🔹 REALTIME PRODUCT BY ID
  // ============================================================
  Stream<Product?> getProductById(String id) {
    return _productRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Product.fromMap(doc.data()!, doc.id);
    });
  }

  // ============================================================
  // 🔹 GET PRODUCTS BY CATEGORY
  // ============================================================
  Stream<List<Product>> getProductsByCategory(String category) {
    return _productRef
        .where('categories', arrayContains: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============================================================
  // 🔹 SEARCH PRODUCTS
  // ============================================================
  Stream<List<Product>> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _productRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .where((p) => p.name.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  // ============================================================
  // 🔹 TRENDING PRODUCTS
  // ============================================================
  Stream<List<Product>> getTrendingProducts() {
    return _productRef
        .where('categories', arrayContains: 'Trending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============================================================
  // 🔹 UPLOAD IMAGE
  // ============================================================
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

  // ============================================================
  // 🔹 GET PRODUCT COUNT
  // ============================================================
  Future<int> getProductsCount() async {
    try {
      final snapshot = await _productRef.get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getProductsCount: $e');
      return 0;
    }
  }

  // ============================================================
  // 🔹 CHECK PRODUCT EXISTENCE
  // ============================================================
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
