import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  bool get _isAdmin => true;

  CollectionReference<Map<String, dynamic>> get _productRef =>
      _firestore.collection(_collection);

  // Ambil semua produk
  Stream<List<Product>> getAllProducts() {
    return _productRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // Ambil produk berdasarkan kategori
  Stream<List<Product>> getProductsByCategory(String category) {
    return _productRef
        .where('categories', arrayContains: category)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // Ambil produk berdasarkan id
  Stream<Product?> getProductById(String id) {
    return _productRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Product.fromMap(doc.data()!, doc.id);
    });
  }

  Future<Product?> fetchProductById(String id) async {
    final doc = await _productRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Product.fromMap(doc.data()!, doc.id);
  }

  // Simpan produk (baru / update) -> base64
  Future<bool> saveProduct({
    String? productId,
    required String nama,
    String? brand,
    String? deskripsi,
    required double harga,
    required String kategori,
    required String subKategori,
    required List<Map<String, dynamic>> opsiPembelian,
    required String imageBase64,
  }) async {
    try {
      if (nama.trim().isEmpty || harga <= 0) return false;

      if (imageBase64.length > 900000) {
        print('❌ Gambar terlalu besar (${imageBase64.length})');
        return false;
      }

      final data = {
        'name': nama,
        'nama': nama,
        'brand': brand ?? '',
        'description': deskripsi ?? '',
        'deskripsi': deskripsi ?? '',
        'price': harga.toInt(),
        'harga': harga,
        'kategori': kategori,
        'subKategori': subKategori,
        'categories': [kategori, subKategori],
        'purchaseOptions': opsiPembelian,
        'opsiPembelian': opsiPembelian,
        'imageBase64': imageBase64,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (productId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _productRef.add(data);
        print('✅ Produk baru berhasil ditambahkan');
      } else {
        await _productRef.doc(productId).update(data);
        print('✅ Produk berhasil diperbarui');
      }

      return true;
    } catch (e) {
      print('❌ Error saveProduct: $e');
      return false;
    }
  }

  // Hapus produk
  Future<bool> deleteProduct(String id) async {
    if (!_isAdmin) return false;
    try {
      await _productRef.doc(id).delete();
      return true;
    } catch (e) {
      print('❌ Error deleteProduct: $e');
      return false;
    }
  }

  // ✅ Tambahan: addProduct / updateProduct untuk kompatibilitas AdminAddProductPage
  Future<void> addProduct(Product product) async {
    await _productRef.add(product.toMap());
    print('✅ addProduct called');
  }

  Future<void> updateProduct(String id, Product product) async {
    await _productRef.doc(id).update(product.toMap());
    print('✅ updateProduct called');
  }
}
